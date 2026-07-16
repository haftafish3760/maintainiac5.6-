import 'package:flutter_test/flutter_test.dart';
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
}
