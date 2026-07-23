import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account_queue_test_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('personal paths reject another authenticated account', () {
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'users/user-a/mileageSummaries/day-1',
        data: const {'updatedByUid': 'user-a'},
        authenticatedUid: 'user-b',
      ),
      throwsA(isA<MaintainiacFirestoreScopeMismatch>()),
    );
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'users/user-a/mileageSummaries/day-1',
        data: const {'updatedByUid': 'user-b'},
        authenticatedUid: 'user-a',
      ),
      throwsA(isA<MaintainiacFirestoreScopeMismatch>()),
    );
  });

  test('account switch leaves stale queue items untouched', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_expenseDraft('user-a', 'expense-a'));
    await queue.enqueue(_expenseDraft('user-b', 'expense-b'));
    final sink = _RecordingSink();
    final identity = _Identity('user-b');
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      identityProvider: identity,
    );

    final result = await coordinator.uploadPending();
    expect(result.uploadedCount, 1);
    expect(sink.paths, ['orgs/org-1/expenses/expense-b']);
    expect(queue.pendingRecords.single.path, endsWith('/expense-a'));

    identity.uid = 'user-a';
    final resumed = await coordinator.uploadPending();
    expect(resumed.uploadedCount, 1);
    expect(queue.pendingRecords, isEmpty);
  });

  test('signed-out coordinator does not inspect or mutate the queue', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await queue.enqueue(_expenseDraft('user-a', 'expense-a'));
    final sink = _RecordingSink();
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      identityProvider: _Identity(null),
    );

    final result = await coordinator.uploadPending();
    expect(result.status, MaintainiacFirestoreUploadStatus.disabled);
    expect(sink.paths, isEmpty);
    expect(queue.pendingRecords, hasLength(1));
  });
}

MaintainiacFirestoreDocumentDraft _expenseDraft(String uid, String id) =>
    MaintainiacFirestoreDocumentDraft(
      path: 'orgs/org-1/expenses/$id',
      data: {
        'schema': 'expense_receipt_backup_v1',
        'orgId': 'org-1',
        'createdByUid': uid,
        'updatedByUid': uid,
      },
    );

class _Identity implements MaintainiacCloudIdentityProvider {
  _Identity(this.uid);
  String? uid;

  @override
  String? get currentUid => uid;
}

class _RecordingSink implements MaintainiacFirestoreDocumentSink {
  final paths = <String>[];

  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    paths.add(path);
  }
}
