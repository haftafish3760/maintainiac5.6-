import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_queue_integrity_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('corrupt queue evidence remains stored and becomes visible', () async {
    final box = await Hive.openBox<dynamic>(
      MaintainiacFirestoreUploadQueueStore.boxName,
    );
    const corruptEvidence = <String, Object?>{
      'id': 'corrupt-entry',
      'path': 'unknown/private/path',
      'data': {'rawOcrText': 'must not upload'},
      'queuedAtUtc': 'not-a-date',
    };
    await box.put('corrupt-entry', corruptEvidence);

    final queue = await MaintainiacFirestoreUploadQueueStore.create();

    expect(queue.pendingRecords, isEmpty);
    expect(queue.integrityIssues, hasLength(1));
    expect(queue.integrityIssues.single.entryId, 'corrupt-entry');
    expect(queue.integrityIssues.single.reason, isNot(contains('rawOcrText')));
    expect(box.get('corrupt-entry'), corruptEvidence);
  });

  test('valid queue entries do not create integrity warnings', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(
      const MaintainiacFirestoreDocumentDraft(
        path: 'parserHealth/valid-entry',
        data: {'schema': 'qa_safe_document_v1'},
      ),
    );

    expect(queue.integrityIssues, isEmpty);
  });

  test(
    'queue entries with mismatched storage identities fail closed',
    () async {
      final box = await Hive.openBox<dynamic>(
        MaintainiacFirestoreUploadQueueStore.boxName,
      );
      await box.put('stored-under-wrong-key', {
        'id': 'claimed-entry-id',
        'path': 'parserHealth/valid-entry',
        'data': const {'schema': 'qa_safe_document_v1'},
        'queuedAtUtc': DateTime.utc(2026, 7, 23).toIso8601String(),
        'attemptCount': 0,
      });

      final queue = await MaintainiacFirestoreUploadQueueStore.create();

      expect(queue.pendingRecords, isEmpty);
      expect(queue.integrityIssues, hasLength(1));
      expect(queue.integrityIssues.single.entryId, 'stored-under-wrong-key');
      expect(box.containsKey('stored-under-wrong-key'), isTrue);
    },
  );

  test('queue entries with corrupt retry metadata fail closed', () async {
    final box = await Hive.openBox<dynamic>(
      MaintainiacFirestoreUploadQueueStore.boxName,
    );
    const corruptEvidence = <String, Object?>{
      'id': 'corrupt-retry',
      'path': 'parserHealth/valid-entry',
      'data': {'schema': 'qa_safe_document_v1'},
      'queuedAtUtc': 'not-a-date',
      'attemptCount': 'many',
    };
    await box.put('corrupt-retry', corruptEvidence);

    final queue = await MaintainiacFirestoreUploadQueueStore.create();

    expect(queue.pendingRecords, isEmpty);
    expect(queue.integrityIssues, hasLength(1));
    expect(box.get('corrupt-retry'), corruptEvidence);
  });

  test('queue entries with impossible retry chronology fail closed', () async {
    final box = await Hive.openBox<dynamic>(
      MaintainiacFirestoreUploadQueueStore.boxName,
    );
    final queuedAt = DateTime.utc(2026, 7, 23, 12);
    final corruptEvidence = <String, Object?>{
      'id': 'corrupt-chronology',
      'path': 'parserHealth/valid-entry',
      'data': const {'schema': 'qa_safe_document_v1'},
      'queuedAtUtc': queuedAt.toIso8601String(),
      'attemptCount': 1,
      'lastAttemptAtUtc': queuedAt
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
    };
    await box.put('corrupt-chronology', corruptEvidence);

    final queue = await MaintainiacFirestoreUploadQueueStore.create();

    expect(queue.pendingRecords, isEmpty);
    expect(queue.integrityIssues, hasLength(1));
    expect(box.get('corrupt-chronology'), corruptEvidence);
  });
}
