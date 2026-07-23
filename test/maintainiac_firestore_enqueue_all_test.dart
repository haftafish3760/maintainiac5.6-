import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_enqueue_all_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('batch validation completes before any queue entry is written', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();

    await expectLater(
      queue.enqueueAll([
        _draft('parserHealth/valid'),
        const MaintainiacFirestoreDocumentDraft(
          path: 'unknownCollection/unsafe',
          data: {'schema': 'unsafe'},
        ),
      ]),
      throwsArgumentError,
    );

    expect(queue.records, isEmpty);
  });

  test('one batch performs one device storage admission check', () async {
    var checks = 0;
    final queue = await MaintainiacFirestoreUploadQueueStore.create(
      storageCheck: () async {
        checks += 1;
        return const AppStorageCheck(
          availableBytes: 1024 * 1024,
          operationBytes: 1024,
          requiredBytes: 1024,
          purpose: AppStoragePurpose.smallRecordWrite,
        );
      },
    );

    await queue.enqueueAll([
      _draft('parserHealth/first'),
      _draft('parserHealth/second'),
    ]);

    expect(checks, 1);
    expect(queue.pendingRecords, hasLength(2));
  });
}

MaintainiacFirestoreDocumentDraft _draft(String path) =>
    MaintainiacFirestoreDocumentDraft(
      path: path,
      data: const {'schema': 'qa_safe_document_v1', 'event': 'queuecheck'},
    );
