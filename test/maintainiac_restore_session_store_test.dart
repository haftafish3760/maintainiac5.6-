import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  const mb = 1024 * 1024;

  MaintainiacRestoreStoragePlan plan({int availableBytes = 500 * mb}) =>
      MaintainiacRestoreStoragePlan(
        structuredBytes: 4 * mb,
        thumbnailBytes: 2 * mb,
        proofBytes: 20 * mb,
        temporaryBytes: 3 * mb,
        availableBytes: availableBytes,
      );

  Future<AppStorageCheck> enough({required int operationBytes}) async =>
      AppStorageCheck(
        availableBytes: 500 * mb,
        operationBytes: operationBytes,
        requiredBytes:
            operationBytes + AppStorageGuard.minimumDeviceReserveBytes,
        purpose: AppStoragePurpose.restoreImport,
      );

  test('restore modes produce distinct storage requirements', () {
    final storage = plan();
    expect(
      storage.transferBytesFor(MaintainiacRestoreMode.recordsOnly),
      4 * mb,
    );
    expect(storage.transferBytesFor(MaintainiacRestoreMode.smart), 6 * mb);
    expect(storage.transferBytesFor(MaintainiacRestoreMode.full), 26 * mb);
    expect(storage.operationBytesFor(MaintainiacRestoreMode.full), 29 * mb);
    expect(storage.canFit(MaintainiacRestoreMode.full), isTrue);
    expect(
      plan(availableBytes: 70 * mb).canFit(MaintainiacRestoreMode.full),
      isFalse,
    );
  });

  test('restore never overwrites a newer or divergent equal revision', () {
    const hashA =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const hashB =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    const remote = MaintainiacRestoreRecordVersion(
      revision: 4,
      schemaVersion: 2,
      contentSha256: hashA,
      isDeleted: false,
    );
    expect(
      MaintainiacRestoreConflictPolicy.decide(
        remote: remote,
        maximumSupportedSchemaVersion: 2,
      ),
      MaintainiacRestoreDisposition.applyRemote,
    );
    expect(
      MaintainiacRestoreConflictPolicy.decide(
        remote: remote,
        local: const MaintainiacRestoreRecordVersion(
          revision: 5,
          schemaVersion: 2,
          contentSha256: hashB,
          isDeleted: false,
        ),
        maximumSupportedSchemaVersion: 2,
      ),
      MaintainiacRestoreDisposition.keepNewerLocal,
    );
    expect(
      MaintainiacRestoreConflictPolicy.decide(
        remote: remote,
        local: const MaintainiacRestoreRecordVersion(
          revision: 4,
          schemaVersion: 2,
          contentSha256: hashB,
          isDeleted: false,
        ),
        maximumSupportedSchemaVersion: 2,
      ),
      MaintainiacRestoreDisposition.conflict,
    );
    expect(
      MaintainiacRestoreConflictPolicy.decide(
        remote: remote,
        local: remote,
        maximumSupportedSchemaVersion: 2,
      ),
      MaintainiacRestoreDisposition.alreadyCurrent,
    );
  });

  test(
    'session persists resumable monotonic progress without a delete API',
    () async {
      final store = MaintainiacRestoreSessionStore.memory(storageCheck: enough);
      final created = await store.prepare(
        id: 'restoreA',
        accountScopeId: 'accountA',
        deviceId: 'deviceA',
        authorizationId: 'authorizationA',
        mode: MaintainiacRestoreMode.recordsOnly,
        storagePlan: plan(),
        totalItems: 2,
        nowUtc: DateTime.utc(2026, 7, 22, 12),
      );
      expect(created.state, MaintainiacRestoreSessionState.prepared);
      await store.start('restoreA');
      final progress = await store.updateProgress(
        id: 'restoreA',
        completedItems: 1,
        completedBytes: 2 * mb,
        cursor: 'page_1',
      );
      expect(progress.cursor, 'page_1');
      await store.pause('restoreA');
      await store.start('restoreA');
      await store.updateProgress(
        id: 'restoreA',
        completedItems: 2,
        completedBytes: 4 * mb,
        cursor: 'page_2',
      );
      final completed = await store.complete('restoreA');
      expect(completed.state, MaintainiacRestoreSessionState.completed);
      expect(store.sessionById('restoreA')?.revision, greaterThan(1));
      expect(store.sessionsForAccount('accountA'), hasLength(1));
    },
  );

  test('dotted account scopes retain their resumable sessions', () async {
    final store = MaintainiacRestoreSessionStore.memory(storageCheck: enough);
    await store.prepare(
      id: 'restoreDotted',
      accountScopeId: 'orgA.userA',
      deviceId: 'deviceA',
      authorizationId: 'authorizationDotted',
      mode: MaintainiacRestoreMode.recordsOnly,
      storagePlan: plan(),
      totalItems: 1,
    );

    expect(store.sessionsForAccount('orgA.userA'), hasLength(1));
  });

  test(
    'progress cannot move backward, exceed plan, or complete early',
    () async {
      final store = MaintainiacRestoreSessionStore.memory(storageCheck: enough);
      await store.prepare(
        id: 'restoreB',
        accountScopeId: 'accountA',
        deviceId: 'deviceA',
        authorizationId: 'authorizationB',
        mode: MaintainiacRestoreMode.smart,
        storagePlan: plan(),
        totalItems: 3,
      );
      await store.start('restoreB');
      await store.updateProgress(
        id: 'restoreB',
        completedItems: 1,
        completedBytes: 2 * mb,
        cursor: 'one',
      );
      await expectLater(
        store.updateProgress(
          id: 'restoreB',
          completedItems: 0,
          completedBytes: mb,
          cursor: 'backward',
        ),
        throwsStateError,
      );
      await expectLater(store.complete('restoreB'), throwsStateError);
    },
  );

  test(
    'prepare blocks insufficient device storage and preserves no partial session',
    () async {
      final store = MaintainiacRestoreSessionStore.memory(
        storageCheck: ({required operationBytes}) async => AppStorageCheck(
          availableBytes: 20 * mb,
          operationBytes: operationBytes,
          requiredBytes:
              operationBytes + AppStorageGuard.minimumDeviceReserveBytes,
          purpose: AppStoragePurpose.restoreImport,
        ),
      );
      await expectLater(
        store.prepare(
          id: 'restoreLowSpace',
          accountScopeId: 'accountA',
          deviceId: 'deviceA',
          authorizationId: 'authorizationC',
          mode: MaintainiacRestoreMode.recordsOnly,
          storagePlan: plan(availableBytes: 20 * mb),
          totalItems: 1,
        ),
        throwsStateError,
      );
      expect(store.sessionById('restoreLowSpace'), isNull);
    },
  );

  test(
    'serialized sessions reject corrupt progress and unsupported hashes',
    () {
      final now = DateTime.utc(2026, 7, 22);
      final corrupt = <String, Object?>{
        'id': 'restoreC',
        'accountScopeId': 'accountA',
        'deviceId': 'deviceA',
        'authorizationId': 'authorizationC',
        'mode': 'recordsOnly',
        'state': 'running',
        'storagePlan': plan().toMap(),
        'totalItems': 1,
        'completedItems': 2,
        'completedBytes': 0,
        'createdAtUtc': now.toIso8601String(),
        'updatedAtUtc': now.toIso8601String(),
        'revision': 1,
      };
      expect(
        () => MaintainiacRestoreSession.fromMap(corrupt),
        throwsFormatException,
      );
      expect(
        MaintainiacRestoreConflictPolicy.decide(
          remote: const MaintainiacRestoreRecordVersion(
            revision: 1,
            schemaVersion: 99,
            contentSha256: 'not-a-hash',
            isDeleted: false,
          ),
          maximumSupportedSchemaVersion: 2,
        ),
        MaintainiacRestoreDisposition.rejectCorrupt,
      );
    },
  );

  test('one corrupt stored session cannot hide another recovery', () async {
    final directory = await Directory.systemTemp.createTemp(
      'maintainiac_restore_sessions_corrupt_',
    );
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    final store = await MaintainiacRestoreSessionStore.create(
      storageCheck: enough,
    );
    await store.prepare(
      id: 'restoreValid',
      accountScopeId: 'orgA.userA',
      deviceId: 'deviceA',
      authorizationId: 'authorizationValid',
      mode: MaintainiacRestoreMode.recordsOnly,
      storagePlan: plan(),
      totalItems: 1,
    );
    await Hive.box<dynamic>(
      MaintainiacRestoreSessionStore.boxName,
    ).put('restoreCorrupt', {'state': 'broken'});

    expect(store.sessionsForAccount('orgA.userA'), hasLength(1));
    expect(store.sessionById('restoreCorrupt'), isNull);
    expect(store.corruptSessionIds, ['restoreCorrupt']);
  });
}
