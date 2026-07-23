import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'firestore_upload_account_isolation_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('account changes never upload another account queue entry', () async {
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final first = _draft(uid: 'user-a', recordId: 'settings-a');
    final second = _draft(uid: 'user-b', recordId: 'settings-b');
    await queue.enqueueAll([first, second]);
    final identity = _MutableIdentity('user-b');
    final sink = _RecordingSink();
    final coordinator = MaintainiacFirestoreUploadCoordinator(
      queue: queue,
      sink: sink,
      uploadEnabled: true,
      identityProvider: identity,
    );

    final secondResult = await coordinator.uploadPending();

    expect(secondResult.uploadedCount, 1);
    expect(sink.paths, [second.path]);
    expect(queue.pendingRecords.map((record) => record.path), [first.path]);

    identity.uid = 'user-a';
    final firstResult = await coordinator.uploadPending();

    expect(firstResult.uploadedCount, 1);
    expect(sink.paths, [second.path, first.path]);
    expect(queue.pendingRecords, isEmpty);
  });
}

MaintainiacFirestoreDocumentDraft _draft({
  required String uid,
  required String recordId,
}) {
  return MaintainiacFirestoreDurableRecordCodec.encode(
    organizationId: 'org-a',
    uid: uid,
    accountScopeId: 'org-a.$uid',
    schemaVersion: 1,
    record: MaintainiacDurableRecord(
      module: 'settings',
      id: recordId,
      payload: const {'theme': 'dark'},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 23),
        updatedAt: DateTime.utc(2026, 7, 23),
      ),
    ),
  );
}

class _MutableIdentity implements MaintainiacCloudIdentityProvider {
  _MutableIdentity(this.uid);

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
