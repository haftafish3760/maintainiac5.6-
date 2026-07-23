import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_queue_deduplication_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('identical enqueue retries reuse one durable queue entry', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final first = await queue.enqueue(
      _draft(),
      queuedAtUtc: DateTime.utc(2026, 7, 22, 12),
    );
    final second = await queue.enqueue(
      _draft(),
      queuedAtUtc: DateTime.utc(2026, 7, 22, 13),
    );

    expect(second.id, first.id);
    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.queuedAtUtc, first.queuedAtUtc);
  });

  test('duplicate enqueue preserves durable retry backoff', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final attemptedAt = DateTime.utc(2026, 7, 22, 12);
    final queued = await queue.enqueue(_draft(), queuedAtUtc: attemptedAt);
    await queue.markAttempted(queued, error: 'offline', nowUtc: attemptedAt);

    final duplicate = await queue.enqueue(
      _draft(),
      queuedAtUtc: attemptedAt.add(const Duration(hours: 1)),
    );

    expect(duplicate.attemptCount, 1);
    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.nextAttemptAtUtc, isNotNull);
  });

  test('changed payload remains a distinct pending revision', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_draft(revision: 1));
    await queue.enqueue(_draft(revision: 2));

    expect(queue.pendingRecords, hasLength(2));
  });
}

MaintainiacFirestoreDocumentDraft _draft({int revision = 1}) =>
    MaintainiacFirestoreDocumentDraft(
      path: 'parserHealth/deduplication',
      data: {
        'schema': 'qa_safe_document_v1',
        'event': 'queuecheck',
        'revision': revision,
      },
    );
