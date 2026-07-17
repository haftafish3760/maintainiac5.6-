import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_upload_queue_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('queues safe documents but does not upload while disabled', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueueAll([
      _safeDraft('parserHealth/receipt_parser_v1'),
      _safeDraft('catalogHealth/work_supply_core'),
    ], queuedAtUtc: DateTime.utc(2026, 6, 23, 13));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.disabled);
    expect(result.attemptedCount, 0);
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(2));
  });

  test(
    'refuses a retry-ledger write when device storage is critical',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: 1,
          requiredBytes: 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );

      await expectLater(
        () => queue.enqueue(_safeDraft('parserHealth/storage_guard')),
        throwsStateError,
      );
      expect(queue.pendingRecords, isEmpty);
    },
  );

  test(
    'does not replace an existing retry entry when storage is critical',
    () async {
      var allowWrites = true;
      final queue = await MaintainiacFirestoreUploadQueueStore.create(
        storageCheck: () async => AppStorageCheck(
          availableBytes: allowWrites ? 100 : 0,
          operationBytes: 1,
          requiredBytes: 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      final first = _safeDraft('parserHealth/replace_storage_guard');
      await queue.enqueueReplacingPendingForPath(first);
      allowWrites = false;

      await expectLater(
        () => queue.enqueueReplacingPendingForPath(first),
        throwsStateError,
      );
      expect(queue.pendingRecords, hasLength(1));
      expect(queue.pendingRecords.single.path, first.path);
    },
  );

  test('uploads enabled batches and marks records uploaded', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueueAll([
      _safeDraft('parserHealth/receipt_parser_v1'),
      _safeDraft('catalogHealth/work_supply_core'),
    ], queuedAtUtc: DateTime.utc(2026, 6, 23, 13));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.uploaded);
    expect(result.attemptedCount, 2);
    expect(result.uploadedCount, 2);
    expect(result.failedCount, 0);
    expect(sink.writes, hasLength(2));
    expect(queue.pendingRecords, isEmpty);
    expect(queue.records, isEmpty);
  });

  test('free sync quota exhaustion preserves pending uploads', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/free_sync_quota'));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      freeSyncsUsedInWindow: HostedUsageLimits.freeUserSyncsPer24HourWindow,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
    expect(result.attemptedCount, 0);
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
    expect(result.reason, contains('Free backup sync limit reached'));
  });

  test('free sync quota is read at upload time', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    var usedSyncs = HostedUsageLimits.freeUserSyncsPer24HourWindow;
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      freeSyncsUsedInWindowReader: () => usedSyncs,
    );
    await queue.enqueue(_safeDraft('parserHealth/live_free_sync_quota'));

    final blocked = await coordinator.uploadPending(
      nowUtc: DateTime.utc(2026, 6, 23, 14),
    );
    usedSyncs = 0;
    final uploaded = await coordinator.uploadPending(
      nowUtc: DateTime.utc(2026, 6, 23, 14, 1),
    );

    expect(blocked.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
    expect(uploaded.status, MaintainiacFirestoreUploadStatus.uploaded);
    expect(sink.writes, hasLength(1));
  });

  test('broken free sync quota reads fail closed without uploading', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/broken_free_sync_quota'));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      freeSyncsUsedInWindowReader: () => throw StateError('quota read failed'),
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
    expect(result.attemptedCount, 0);
    expect(result.reason, contains('could not be verified'));
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });

  test('malformed free sync quota counts fail closed without uploading', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/malformed_free_sync_quota'));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      freeSyncsUsedInWindow: -1,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
    expect(result.attemptedCount, 0);
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });

  test('network policy block preserves pending uploads', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/wifi_only_block'));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      uploadNetworkAllowed: () => false,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.networkUnavailable);
    expect(result.attemptedCount, 0);
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
    expect(result.reason, contains('selected network'));
  });

  test('broken network policy checks preserve pending uploads', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/broken_network_check'));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      uploadNetworkAllowed: () => throw StateError('network check failed'),
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.networkUnavailable);
    expect(result.attemptedCount, 0);
    expect(sink.writes, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });

  test('concurrent flushes upload a queued document only once', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    await queue.enqueue(_safeDraft('parserHealth/concurrent_upload'));
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    );

    await Future.wait([
      coordinator.uploadPending(),
      coordinator.uploadPending(),
    ]);

    expect(sink.writes, hasLength(1));
    expect(queue.pendingRecords, isEmpty);
  });

  test('replaces pending documents for the same path', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final draft = _safeDraft('parserHealth/receipt_parser_v1');

    await queue.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: DateTime.utc(2026, 6, 23, 13),
    );
    await queue.enqueueReplacingPendingForPath(
      draft,
      queuedAtUtc: DateTime.utc(2026, 6, 23, 13, 5),
    );

    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.path, draft.path);
    expect(
      queue.pendingRecords.single.queuedAtUtc,
      DateTime.utc(2026, 6, 23, 13, 5),
    );
  });

  test(
    'replacement queues the newer document before removing retry evidence',
    () async {
      final implementation = await File(
        'lib/shared/firebase/maintainiac_firestore_upload_store.dart',
      ).readAsString();
      final replacementStart = implementation.indexOf(
        'Future<MaintainiacFirestoreQueuedDocument> enqueueReplacingPendingForPath',
      );
      final replacementEnd = implementation.indexOf(
        'Future<List<MaintainiacFirestoreQueuedDocument>> enqueueAll',
        replacementStart,
      );
      final replacement = implementation.substring(
        replacementStart,
        replacementEnd,
      );

      expect(
        replacement.indexOf('await _enqueueDocument'),
        lessThan(replacement.indexOf('await _box.delete')),
      );
    },
  );

  test(
    'concurrent replacements preserve one newest pending document',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final draft = _safeDraft('parserHealth/concurrent_replacement');

      await Future.wait([
        queue.enqueueReplacingPendingForPath(
          draft,
          queuedAtUtc: DateTime.utc(2026, 7, 15, 12),
        ),
        queue.enqueueReplacingPendingForPath(
          draft,
          queuedAtUtc: DateTime.utc(2026, 7, 15, 12, 1),
        ),
      ]);

      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.queuedAtUtc,
        DateTime.utc(2026, 7, 15, 12, 1),
      );
    },
  );

  test(
    'a stale failed upload cannot resurrect a replaced queue entry',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final first = _safeDraft('parserHealth/replaced_during_upload');
      final original = await queue.enqueueReplacingPendingForPath(
        first,
        queuedAtUtc: DateTime.utc(2026, 7, 16, 12),
      );
      await queue.enqueueReplacingPendingForPath(
        first,
        queuedAtUtc: DateTime.utc(2026, 7, 16, 12, 1),
      );

      await queue.markAttempted(
        original,
        error: 'network unavailable',
        nowUtc: DateTime.utc(2026, 7, 16, 12, 2),
      );

      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.queuedAtUtc,
        DateTime.utc(2026, 7, 16, 12, 1),
      );
      expect(queue.pendingRecords.single.attemptCount, 0);
    },
  );

  test(
    'never discards pending uploads when the queue exceeds its soft cap',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final count = MaintainiacFirestoreUploadPolicy.maxQueuedRecords + 1;

      for (var index = 0; index < count; index += 1) {
        await queue.enqueue(
          _safeDraft('parserHealth/pending_$index'),
          queuedAtUtc: DateTime.utc(2026, 7, 15, 12, 0, index ~/ 1000),
        );
      }

      expect(queue.pendingRecords, hasLength(count));
      expect(
        queue.pendingRecords.map((record) => record.path),
        contains('parserHealth/pending_0'),
      );
    },
  );

  test(
    'pending upload survives a local queue restart without duplication',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final draft = _safeDraft('parserHealth/restart_safe');
      await queue.enqueue(draft, queuedAtUtc: DateTime.utc(2026, 7, 14, 12));

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final reopened = await MaintainiacFirestoreUploadQueueStore.create();

      expect(reopened.pendingRecords, hasLength(1));
      expect(reopened.pendingRecords.single.path, draft.path);
      expect(
        reopened.pendingRecords.single.queuedAtUtc,
        DateTime.utc(2026, 7, 14, 12),
      );
    },
  );

  test('malformed stored retry metadata is sanitized on restore', () {
    final queuedAt = DateTime.utc(2026, 7, 14, 12);
    final restored = MaintainiacFirestoreQueuedDocument.fromStored({
      'id': 'queued_bad_retry_metadata',
      'path': 'parserHealth/bad_retry_metadata',
      'data': {'schema': 'parser_health_v1'},
      'queuedAtUtc': queuedAt.toIso8601String(),
      'attemptCount': -9,
      'lastAttemptAtUtc': queuedAt
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
      'nextAttemptAtUtc': queuedAt
          .subtract(const Duration(seconds: 30))
          .toIso8601String(),
      'uploadedAtUtc': queuedAt
          .subtract(const Duration(seconds: 1))
          .toIso8601String(),
    });

    expect(restored.attemptCount, isZero);
    expect(restored.lastAttemptAtUtc, isNull);
    expect(restored.nextAttemptAtUtc, isNull);
    expect(restored.uploadedAtUtc, isNull);
    expect(restored.isPendingUpload, isTrue);
  });

  test('malformed queued document data is sanitized on restore', () {
    final restored = MaintainiacFirestoreQueuedDocument.fromStored({
      'id': 'queued_bad_data',
      'path': 'parserHealth/bad_data',
      'data': {
        'schema': 'parser_health_v1',
        7: 'non-string-key',
        ' padded ': 'unsafe-key',
        '': 'blank-key',
      },
      'queuedAtUtc': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
    });

    expect(restored.data, {'schema': 'parser_health_v1'});
  });

  test('retains failed writes with retry metadata', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink(
      failPathsContaining: 'catalogHealth',
      failureMessage:
          'token=pk.secret lat:35.123 longitude=-80.456 '
          'near -122.12345,37.12345\nsecond line',
    );
    await queue.enqueueAll([
      _safeDraft('parserHealth/receipt_parser_v1'),
      _safeDraft('catalogHealth/work_supply_core'),
    ], queuedAtUtc: DateTime.utc(2026, 6, 23, 13));

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    ).uploadPending(nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(result.status, MaintainiacFirestoreUploadStatus.partial);
    expect(result.uploadedCount, 1);
    expect(result.failedCount, 1);
    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.attemptCount, 1);
    expect(queue.pendingRecords.single.lastError, isNotEmpty);
    expect(queue.pendingRecords.single.lastError, isNot(contains('pk.secret')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('35.123')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('-80.456')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('-122.12345')));
    expect(queue.pendingRecords.single.lastError, isNot(contains('37.12345')));
    expect(queue.pendingRecords.single.lastError, contains('token redacted'));
    expect(queue.pendingRecords.single.lastError, contains('lat redacted'));
    expect(
      queue.pendingRecords.single.lastError,
      contains('longitude redacted'),
    );
    expect(
      queue.pendingRecords.single.lastError,
      contains('coordinates redacted'),
    );
    expect(
      queue.pendingRecords.single.nextAttemptAtUtc,
      DateTime.utc(2026, 6, 23, 14, 0, 30),
    );
  });

  test(
    'does not retry a failed cloud write before its durable backoff is due',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final draft = _safeDraft('catalogHealth/backoff_due');
      final startedAt = DateTime.utc(2026, 7, 15, 12);
      await queue.enqueue(draft, queuedAtUtc: startedAt);
      await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingFirestoreSink(failPathsContaining: 'catalogHealth'),
        uploadEnabled: true,
      ).uploadPending(nowUtc: startedAt);

      final recoverySink = _RecordingFirestoreSink();
      final early = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: recoverySink,
        uploadEnabled: true,
      ).uploadPending(nowUtc: startedAt.add(const Duration(seconds: 29)));

      expect(early.attemptedCount, 0);
      expect(recoverySink.writes, isEmpty);
      expect(queue.pendingRecords, hasLength(1));
    },
  );

  test('clock rollback cannot shorten a durable cloud retry backoff', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final draft = _safeDraft('catalogHealth/clock_rollback');
    final firstAttempt = DateTime.utc(2026, 7, 16, 13);
    final queued = await queue.enqueue(draft, queuedAtUtc: firstAttempt);
    await queue.markAttempted(queued, error: 'offline', nowUtc: firstAttempt);
    final first = queue.pendingRecords.single;

    await queue.markAttempted(
      first,
      error: 'offline',
      nowUtc: firstAttempt.subtract(const Duration(hours: 1)),
    );
    final retried = queue.pendingRecords.single;

    expect(retried.lastAttemptAtUtc!.isAfter(first.lastAttemptAtUtc!), isTrue);
    expect(retried.nextAttemptAtUtc!.isAfter(first.nextAttemptAtUtc!), isTrue);
  });

  test('enforces max batch size even when caller asks for more', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();

    for (var i = 0; i < 25; i++) {
      await queue.enqueue(
        MaintainiacFirestoreDocumentDraft(
          path: 'orgs/ORG-1/receiptDiagnostics/event_$i',
          data: {
            'schema': 'receipt_diagnostic_v1',
            'event': 'parseCompleted',
            'parserLineCount': i,
          },
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 23, 13, i),
      );
    }

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    ).uploadPending(limit: 200, nowUtc: DateTime.utc(2026, 6, 23, 14));

    expect(
      result.attemptedCount,
      MaintainiacFirestoreUploadPolicy.maxBatchSize,
    );
    expect(
      sink.writes,
      hasLength(MaintainiacFirestoreUploadPolicy.maxBatchSize),
    );
    expect(queue.pendingRecords, hasLength(5));
  });

  test(
    'a failed upload retries successfully after a local queue restart',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final draft = _safeDraft('catalogHealth/restart_retry');
      await queue.enqueue(draft, queuedAtUtc: DateTime.utc(2026, 7, 14, 12));
      final failed = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _RecordingFirestoreSink(failPathsContaining: 'catalogHealth'),
        uploadEnabled: true,
      ).uploadPending(nowUtc: DateTime.utc(2026, 7, 14, 12));
      expect(failed.failedCount, 1);
      expect(queue.pendingRecords.single.attemptCount, 1);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final reopened = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingFirestoreSink();
      final retried = await MaintainiacFirestoreUploadCoordinator(
        queue: reopened,
        sink: sink,
        uploadEnabled: true,
      ).uploadPending(nowUtc: DateTime.utc(2026, 7, 14, 12, 0, 30));

      expect(retried.uploadedCount, 1);
      expect(reopened.pendingRecords, isEmpty);
      expect(sink.writes, contains(draft.path));
    },
  );

  test(
    'rejects unsafe paths, sensitive fields, and per-item catalog reads',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();

      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          const MaintainiacFirestoreDocumentDraft(
            path: '/orgs/ORG-1/receiptDiagnostics/event',
            data: {'schema': 'bad'},
          ),
        ),
        throwsArgumentError,
      );
      for (final path in [
        'parserHealth/${'x' * 201}',
        'parserHealth/bad\nsegment',
      ]) {
        expect(
          () => MaintainiacFirestoreUploadPolicy.validateDraft(
            MaintainiacFirestoreDocumentDraft(
              path: path,
              data: const {'schema': 'bad'},
            ),
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          const MaintainiacFirestoreDocumentDraft(
            path: 'orgs/ORG-1/receiptDiagnostics/event',
            data: {
              'schema': 'bad',
              'rawReceiptText': 'PRIVATE STORE SECRET ITEM 99.99',
            },
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          const MaintainiacFirestoreDocumentDraft(
            path: 'catalogPacks/bad',
            data: {
              'schema': 'bad',
              'deliveryMode': 'item_documents',
              'firestoreItemDocumentReadCount': 1000,
            },
          ),
        ),
        throwsArgumentError,
      );

      await expectLater(
        queue.enqueue(
          const MaintainiacFirestoreDocumentDraft(
            path: 'unknownCollection/doc',
            data: {'schema': 'bad'},
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'allows private expense backup fields only under org expense records',
    () {
      const expenseDoc = MaintainiacFirestoreDocumentDraft(
        path: 'orgs/ORG-1/expenses/expense_1',
        data: {
          'schema': 'expense_receipt_backup_v1',
          'merchantName': 'Private Store',
          'lines': [
            {'description': 'Private item', 'subtotalCents': 1299},
          ],
        },
      );
      const telemetryDoc = MaintainiacFirestoreDocumentDraft(
        path: 'orgs/ORG-1/expenseTelemetrySummaries/latest',
        data: {
          'schema': 'expense_telemetry_summary_v1',
          'merchantName': 'Private Store',
        },
      );
      const rawOcrExpenseDoc = MaintainiacFirestoreDocumentDraft(
        path: 'orgs/ORG-1/expenses/expense_1',
        data: {
          'schema': 'expense_receipt_backup_v1',
          'rawOcrText': 'raw private text',
        },
      );

      MaintainiacFirestoreUploadPolicy.validateDraft(expenseDoc);
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(telemetryDoc),
        throwsArgumentError,
      );
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(rawOcrExpenseDoc),
        throwsArgumentError,
      );
    },
  );
}

MaintainiacFirestoreDocumentDraft _safeDraft(String path) {
  return MaintainiacFirestoreDocumentDraft(
    path: path,
    data: const {'schema': 'qa_safe_document_v1', 'event': 'queuecheck'},
  );
}

class _RecordingFirestoreSink implements MaintainiacFirestoreDocumentSink {
  _RecordingFirestoreSink({
    this.failPathsContaining,
    this.failureMessage = 'simulated upload failure',
  });

  final String? failPathsContaining;
  final String failureMessage;
  final writes = <String, Map<String, Object?>>{};

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    if (failPathsContaining != null && path.contains(failPathsContaining!)) {
      throw StateError(failureMessage);
    }
    writes[path] = data;
  }
}
