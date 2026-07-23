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
}
