import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic_batch_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('batch-capable sink commits queued documents together', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueueAll([_draft('one'), _draft('two')]);
    final sink = _BatchSink();
    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
    ).uploadPending();
    expect(result.uploadedCount, 2);
    expect(sink.batches, hasLength(1));
    expect(sink.batches.single, hasLength(2));
    expect(queue.pendingRecords, isEmpty);
  });

  test(
    'atomic batch failure leaves every document queued with retry state',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueueAll([_draft('one'), _draft('two')]);
      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _BatchSink(error: StateError('network interrupted')),
        uploadEnabled: true,
      ).uploadPending(nowUtc: DateTime.utc(2026, 7, 22));
      expect(result.status, MaintainiacFirestoreUploadStatus.failed);
      expect(result.failedCount, 2);
      expect(queue.pendingRecords, hasLength(2));
      expect(
        queue.pendingRecords.every((record) => record.attemptCount == 1),
        isTrue,
      );
    },
  );

  test(
    'one batch conflict is isolated while unrelated records remain pending',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await queue.enqueueAll([_draft('one'), _draft('two')]);
      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: _BatchSink(
          error: const MaintainiacFirestoreRevisionConflict(
            path: 'parserHealth/one',
            localRevision: 1,
            remoteRevision: 2,
          ),
        ),
        uploadEnabled: true,
      ).uploadPending();
      expect(result.status, MaintainiacFirestoreUploadStatus.conflict);
      expect(result.conflictedCount, 1);
      expect(
        queue.records.where((record) => record.requiresConflictReview),
        hasLength(1),
      );
      expect(queue.pendingRecords.single.path, 'parserHealth/two');
    },
  );

  test('unknown conflict identity cannot report a false success', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueueAll([_draft('one'), _draft('two')]);
    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: _BatchSink(
        error: const MaintainiacFirestoreRevisionConflict(
          path: 'parserHealth/not-in-batch',
          localRevision: 1,
          remoteRevision: 2,
        ),
      ),
      uploadEnabled: true,
    ).uploadPending();
    expect(result.status, MaintainiacFirestoreUploadStatus.failed);
    expect(result.failedCount, 2);
    expect(queue.pendingRecords, hasLength(2));
  });
}

MaintainiacFirestoreDocumentDraft _draft(String id) =>
    MaintainiacFirestoreDocumentDraft(
      path: 'parserHealth/$id',
      data: const {'schema': 'qa_safe_document_v1', 'event': 'batch'},
    );

class _BatchSink
    implements
        MaintainiacFirestoreDocumentSink,
        MaintainiacFirestoreBatchDocumentSink {
  _BatchSink({this.error});

  final Object? error;
  final batches = <List<MaintainiacFirestoreDocumentDraft>>[];

  @override
  Future<void> writeDocuments(
    List<MaintainiacFirestoreDocumentDraft> documents,
  ) async {
    if (error != null) throw error!;
    batches.add(documents);
  }

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) => throw UnsupportedError('Atomic path expected.');
}
