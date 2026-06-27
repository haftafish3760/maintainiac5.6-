import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

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
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    await queue.enqueueAll([
      MaintainiacFirestoreDocumentBuilder.catalogPackDocument(manifest),
      MaintainiacFirestoreDocumentBuilder.catalogManifestDocument(manifest),
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

  test('uploads enabled batches and marks records uploaded', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    await queue.enqueueAll([
      MaintainiacFirestoreDocumentBuilder.catalogPackDocument(manifest),
      MaintainiacFirestoreDocumentBuilder.catalogManifestDocument(manifest),
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
    expect(
      queue.records.where((record) => record.uploadedAtUtc != null),
      hasLength(2),
    );
  });

  test('replaces pending documents for the same path', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final draft = MaintainiacFirestoreDocumentBuilder.catalogPackDocument(
      manifest,
    );

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

  test('retains failed writes with retry metadata', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink(failPathsContaining: 'manifests');
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    await queue.enqueueAll([
      MaintainiacFirestoreDocumentBuilder.catalogPackDocument(manifest),
      MaintainiacFirestoreDocumentBuilder.catalogManifestDocument(manifest),
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
  });

  test('enforces max batch size even when caller asks for more', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    final parsed = parseExpenseReceiptText('''
STORE
06/12/2026
ITEM 1.00
Total 1.00
''');

    for (var i = 0; i < 25; i++) {
      final record = PrivacySafeReceiptEventRecord(
        id: 'event_$i',
        queuedAtUtc: DateTime.utc(2026, 6, 23, 13, i),
        payload: ReceiptPrivacyEventPolicy.sanitize(
          PrivacySafeReceiptEvent.fromParseResult(result: parsed),
        ),
      );
      await queue.enqueue(
        MaintainiacFirestoreDocumentBuilder.receiptDiagnosticDocument(
          orgId: 'ORG-1',
          record: record,
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

class _RecordingFirestoreSink implements MaintainiacFirestoreDocumentSink {
  _RecordingFirestoreSink({this.failPathsContaining});

  final String? failPathsContaining;
  final writes = <String, Map<String, Object?>>{};

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    if (failPathsContaining != null && path.contains(failPathsContaining!)) {
      throw StateError('simulated upload failure');
    }
    writes[path] = data;
  }
}
