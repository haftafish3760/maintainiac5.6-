import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/backup/cloud_backup_sync_attempt_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('keeps a rolling 24-hour local sync-attempt ledger', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 16, 12);

    await store.recordAttempt(
      'org-user-device',
      at: now.subtract(const Duration(hours: 25)),
    );
    await store.recordAttempt(
      'org-user-device',
      at: now.subtract(const Duration(hours: 1)),
    );

    expect(store.attemptsFor('org-user-device', now: now), [
      now.subtract(const Duration(hours: 1)),
    ]);
  });

  test('never claims an attempt when local storage is full', () async {
    final store = CloudBackupSyncAttemptStore.memory(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: 1,
        requiredBytes: 2,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(
      store.recordAttempt('org-user-device', at: DateTime.utc(2026, 7, 16)),
      throwsStateError,
    );
    expect(
      store.attemptsFor('org-user-device', now: DateTime.utc(2026, 7, 16)),
      isEmpty,
    );
  });

  test('clock rollback cannot erase a consumed local sync allowance', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final original = DateTime.utc(2026, 7, 16, 12);
    final rolledBack = original.subtract(const Duration(hours: 2));

    await store.recordAttempt('org-user-device', at: original);
    await store.recordAttempt('org-user-device', at: rolledBack);

    final attempts = store.attemptsFor('org-user-device', now: rolledBack);
    expect(attempts, hasLength(2));
    expect(attempts.first, original);
    expect(attempts.last, original.add(const Duration(microseconds: 1)));
  });

  test('keeps local attempt ledgers isolated by durable scope', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 16, 12);

    await store.recordAttempt('org-a-user-device', at: now);

    expect(store.attemptsFor('org-a-user-device', now: now), hasLength(1));
    expect(store.attemptsFor('org-b-user-device', now: now), isEmpty);
  });

  test('rejects unsafe scope identifiers before writing', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 16, 12);

    await expectLater(
      store.recordAttempt(' org-user-device', at: now),
      throwsArgumentError,
    );
    await expectLater(
      store.recordAttempt('org:user:device', at: now),
      throwsArgumentError,
    );
    await expectLater(
      store.recordAttempt('org user device', at: now),
      throwsArgumentError,
    );
    await expectLater(
      store.recordAttempt('x' * 257, at: now),
      throwsArgumentError,
    );

    expect(store.attemptsFor('org-user-device', now: now), isEmpty);
  });

  test('a missing local attempt ledger remains empty', () {
    final store = CloudBackupSyncAttemptStore.memory();

    expect(
      store.attemptsFor('missing-scope', now: DateTime.utc(2026, 7, 16, 12)),
      isEmpty,
    );
  });

  test('corrupt stored attempt evidence fails closed', () async {
    final directory = await Directory.systemTemp.createTemp(
      'cloud_backup_sync_attempt_corrupt_',
    );
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    final store = await CloudBackupSyncAttemptStore.create();
    await Hive.box<dynamic>(
      CloudBackupSyncAttemptStore.boxName,
    ).put('org-user-device', ['not-a-date']);

    expect(
      () => store.attemptsFor(
        'org-user-device',
        now: DateTime.utc(2026, 7, 16, 12),
      ),
      throwsStateError,
    );
  });
}
