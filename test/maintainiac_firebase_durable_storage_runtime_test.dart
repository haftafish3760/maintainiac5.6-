import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firebase_durable_runtime_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'hosted sink cannot write without a server reservation provider',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueue(_draft());
      final sink = _HostedSink();

      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
        identityProvider: const _Identity('user-a'),
      ).uploadPending(attemptId: 'attempt-a');

      expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, hasLength(1));
    },
  );

  test('central runtime never enables cloud backup implicitly', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_draft());
    final functions = _Functions();
    final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
      queue: queue,
      revisions: MaintainiacDurableCloudRevisionStore.memory(),
      identity: const _Identity('user-a'),
      functions: functions,
    );

    final result = await runtime.uploads.uploadPending(attemptId: 'attempt-a');

    expect(result.status, MaintainiacFirestoreUploadStatus.disabled);
    expect(functions.names, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });

  test('enabled runtime still requires an explicit network policy', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_draft());
    final functions = _Functions();
    final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
      queue: queue,
      revisions: MaintainiacDurableCloudRevisionStore.memory(),
      identity: const _Identity('user-a'),
      functions: functions,
      uploadEnabled: true,
    );

    final result = await runtime.uploads.uploadPending(attemptId: 'attempt-a');

    expect(result.status, MaintainiacFirestoreUploadStatus.networkUnavailable);
    expect(functions.names, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });

  test(
    'central runtime reserves, writes, and checkpoints one shared batch',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final revisions = MaintainiacDurableCloudRevisionStore.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 1000000,
          operationBytes: 1,
          requiredBytes: 1,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      await queue.enqueue(_draft());
      final functions = _Functions();
      final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
        queue: queue,
        revisions: revisions,
        identity: const _Identity('user-a'),
        functions: functions,
        uploadEnabled: true,
        uploadNetworkAllowed: () => true,
      );

      final result = await runtime.uploads.uploadPending(
        attemptId: 'attempt-a',
        nowUtc: DateTime.utc(2026, 7, 22),
      );

      expect(result.status, MaintainiacFirestoreUploadStatus.uploaded);
      expect(result.reservationId, 'reservation-a');
      expect(functions.names, ['commitDurableRecordBatch']);
      expect(revisions.checkpointFor(_draft().path), isNotNull);
      expect(queue.pendingRecords, isEmpty);
    },
  );

  test(
    'server quota rejection preserves an unattempted durable batch',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueue(_draft());
      final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
        queue: queue,
        revisions: MaintainiacDurableCloudRevisionStore.memory(),
        identity: const _Identity('user-a'),
        functions: _Functions(
          failure: const MaintainiacCallableFailure(
            code: 'resource-exhausted',
            message: 'limit reached',
          ),
        ),
        uploadEnabled: true,
        uploadNetworkAllowed: () => true,
      );

      final result = await runtime.uploads.uploadPending(
        attemptId: 'attempt-a',
        nowUtc: DateTime.utc(2026, 7, 22),
      );

      expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
      expect(queue.pendingRecords.single.attemptCount, 0);
    },
  );

  test('server revision conflict is retained for explicit review', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final draft = _draft();
    await queue.enqueue(draft, queuedAtUtc: DateTime.utc(2026, 7, 22));
    final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
      queue: queue,
      revisions: MaintainiacDurableCloudRevisionStore.memory(),
      identity: const _Identity('user-a'),
      functions: _Functions(
        failure: MaintainiacCallableFailure(
          code: 'failed-precondition',
          message: 'revision conflict',
          details: {
            'reason': 'revision_conflict',
            'path': draft.path,
            'localRevision': 1,
            'remoteRevision': 2,
          },
        ),
      ),
      uploadEnabled: true,
      uploadNetworkAllowed: () => true,
    );

    final result = await runtime.uploads.uploadPending(
      attemptId: 'attempt-a',
      nowUtc: DateTime.utc(2026, 7, 23),
    );

    expect(result.status, MaintainiacFirestoreUploadStatus.conflict);
    expect(queue.records.single.conflictedAtUtc, isNotNull);
  });

  test('a mismatched server batch acknowledgment remains retryable', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_draft());
    final runtime = await MaintainiacFirebaseDurableStorageRuntime.create(
      queue: queue,
      revisions: MaintainiacDurableCloudRevisionStore.memory(),
      identity: const _Identity('user-a'),
      functions: _Functions(batchSha256Override: 'f' * 64),
      uploadEnabled: true,
      uploadNetworkAllowed: () => true,
    );

    final result = await runtime.uploads.uploadPending(
      attemptId: 'attempt-a',
      nowUtc: DateTime.utc(2026, 7, 23),
    );

    expect(result.status, MaintainiacFirestoreUploadStatus.failed);
    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.attemptCount, 1);
  });
}

MaintainiacFirestoreDocumentDraft _draft() {
  final record = MaintainiacDurableRecord(
    module: 'settings',
    id: 'settings-a',
    payload: const {'theme': 'dark'},
    lifecycle: MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 22),
      updatedAt: DateTime.utc(2026, 7, 22),
    ),
  );
  return MaintainiacFirestoreDurableRecordCodec.encode(
    organizationId: 'org-a',
    uid: 'user-a',
    accountScopeId: 'org-a.user-a',
    schemaVersion: 1,
    record: record,
  );
}

class _HostedSink
    implements
        MaintainiacFirestoreDocumentSink,
        MaintainiacHostedReservationRequiredSink {
  final writes = <String>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async => writes.add(path);
}

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions({this.failure, this.batchSha256Override});

  final Object? failure;
  final String? batchSha256Override;
  final names = <String>[];

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    names.add(name);
    if (failure != null) throw failure!;
    final documents = (data['documents'] as List)
        .map(
          (value) => MaintainiacFirestoreDocumentDraft(
            path: (value as Map)['path'] as String,
            data: Map<String, Object?>.from(value['data'] as Map),
          ),
        )
        .toList(growable: false);
    return {
      'reservationId': 'reservation-a',
      'used': 1,
      'remaining': 3,
      'limit': 4,
      'windowSeconds': 86400,
      'reservedAt': '2026-07-22T00:00:00.000Z',
      'attemptedCount': 1,
      'writtenCount': 1,
      'batchSha256':
          batchSha256Override ??
          maintainiacFirestoreBatchSha256(documents),
    };
  }
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}
