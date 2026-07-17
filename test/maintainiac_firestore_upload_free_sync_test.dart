import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_upload_free_sync_test_',
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
    'records a free sync attempt before uploading a non-empty batch',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingFirestoreSink();
      final recorded = <DateTime>[];
      final now = DateTime.utc(2026, 7, 17, 12);
      await queue.enqueue(_safeDraft('parserHealth/free_sync_recorded'));

      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
        freeSyncsUsedInWindow: 0,
        freeSyncAttemptRecorder: (at) async => recorded.add(at),
      ).uploadPending(nowUtc: now);

      expect(result.status, MaintainiacFirestoreUploadStatus.uploaded);
      expect(recorded, [now]);
      expect(sink.writes, hasLength(1));
    },
  );

  test('does not record free sync attempts for an empty queue', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final sink = _RecordingFirestoreSink();
    var recorded = 0;

    final result = await MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      freeSyncsUsedInWindow: 0,
      freeSyncAttemptRecorder: (_) async => recorded += 1,
    ).uploadPending(nowUtc: DateTime.utc(2026, 7, 17, 12));

    expect(result.status, MaintainiacFirestoreUploadStatus.empty);
    expect(recorded, 0);
    expect(sink.writes, isEmpty);
  });

  test(
    'failed free sync attempt recording fails closed before upload',
    () async {
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final sink = _RecordingFirestoreSink();
      await queue.enqueue(_safeDraft('parserHealth/free_sync_record_failure'));

      final result = await MaintainiacFirestoreUploadCoordinator(
        queue: queue,
        sink: sink,
        uploadEnabled: true,
        freeSyncsUsedInWindow: 0,
        freeSyncAttemptRecorder: (_) async {
          throw StateError('attempt ledger unavailable');
        },
      ).uploadPending(nowUtc: DateTime.utc(2026, 7, 17, 12));

      expect(result.status, MaintainiacFirestoreUploadStatus.quotaExceeded);
      expect(result.reason, contains('could not be recorded locally'));
      expect(result.attemptedCount, 0);
      expect(sink.writes, isEmpty);
      expect(queue.pendingRecords, hasLength(1));
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
  final writes = <String, Map<String, Object?>>{};

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    writes[path] = data;
  }
}
