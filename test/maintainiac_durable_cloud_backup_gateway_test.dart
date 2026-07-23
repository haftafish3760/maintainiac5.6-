import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'durable_cloud_backup_gateway_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('gateway owns Firestore path and authenticated account scope', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final record = await records.save(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
      now: DateTime.utc(2026, 7, 22),
    );
    final gateway = MaintainiacDurableCloudBackupGateway(
      records: records,
      queue: queue,
      identityProvider: const _Identity('user-a'),
    );

    final queued = await gateway.queueRecord(
      organizationId: 'org-a',
      record: record,
    );

    expect(queued.path, startsWith('orgs/org-a/records/'));
    expect(queued.data['accountScopeId'], 'org-a.user-a');
    expect(queued.data['createdByUid'], 'user-a');
    expect(queued.data['updatedByUid'], 'user-a');
    expect(queue.pendingRecords, hasLength(1));
  });

  test('gateway refuses unauthenticated cloud queueing', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final record = await records.save(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
    );
    final gateway = MaintainiacDurableCloudBackupGateway(
      records: records,
      queue: queue,
      identityProvider: const _Identity(null),
    );

    await expectLater(
      gateway.queueRecord(organizationId: 'org-a', record: record),
      throwsStateError,
    );
    expect(queue.pendingRecords, isEmpty);
  });

  test('updated records replace rather than amplify pending writes', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final gateway = MaintainiacDurableCloudBackupGateway(
      records: records,
      queue: queue,
      identityProvider: const _Identity('user-a'),
    );
    final first = await records.save(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
      now: DateTime.utc(2026, 7, 22),
    );
    await gateway.queueRecord(organizationId: 'org-a', record: first);
    final second = await records.save(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'light'},
      expectedRevision: first.lifecycle.revision,
      now: DateTime.utc(2026, 7, 22, 1),
    );
    await gateway.queueRecord(organizationId: 'org-a', record: second);

    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.data['localRevision'], 2);
    expect(
      (queue.pendingRecords.single.data['recordPayload'] as Map)['theme'],
      'light',
    );
  });

  test('module backup includes durable tombstones for cloud removal', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    final saved = await records.save(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
      now: DateTime.utc(2026, 7, 22),
    );
    await records.delete(
      saved.module,
      saved.id,
      now: DateTime.utc(2026, 7, 22, 1),
    );
    final gateway = MaintainiacDurableCloudBackupGateway(
      records: records,
      queue: queue,
      identityProvider: const _Identity('user-a'),
    );

    await gateway.queueModule(organizationId: 'org-a', module: 'settings');

    expect(queue.pendingRecords, hasLength(1));
    expect(queue.pendingRecords.single.data['recordState'], 'deleted');
  });
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}
