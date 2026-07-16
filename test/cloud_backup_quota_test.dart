import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_quota.dart';
import 'package:maintaniac/shared/backup/cloud_backup_service.dart';
import 'package:maintaniac/shared/backup/cloud_backup_status.dart';

void main() {
  group('CloudBackupQuotaPolicy', () {
    const freeEntitlement = CloudBackupEntitlement(
      planId: 'early_access',
      displayName: 'Early access backup',
      quotaBytes: 100 * 1024 * 1024,
      dailySyncLimit: 4,
      immediateSyncAllowed: false,
      policyVersion: 1,
    );

    test('accepts a complete server-provided entitlement', () {
      final entitlement = CloudBackupEntitlement.tryParseServerPayload({
        'planId': 'early_access',
        'displayName': 'Early access backup',
        'storageQuotaBytes': 100 * 1024 * 1024,
        'dailySyncLimit': 4,
        'immediateSyncAllowed': false,
        'policyVersion': 1,
      });

      expect(entitlement, isNotNull);
      expect(entitlement!.quotaLabel, '100 MB');
      expect(entitlement.dailySyncLimit, 4);
      expect(entitlement.immediateSyncAllowed, isFalse);
    });

    test('fails closed for incomplete server entitlement data', () {
      final entitlement = CloudBackupEntitlement.tryParseServerPayload({
        'planId': 'bad',
        'storageQuotaBytes': 100,
      });

      expect(entitlement, isNull);
    });

    test('local-only mode never treats pending files as cloud uploads', () {
      final check = CloudBackupQuotaPolicy.check(
        entitlement: freeEntitlement,
        usedBytes: 96 * 1024 * 1024,
        pendingBytes: 4 * 1024 * 1024,
      );

      expect(check.isLocalOnly, isTrue);
      expect(check.allowsLocalSave, isTrue);
      expect(check.willAttemptCloudBackup, isFalse);
      expect(check.statusLabel, 'Off');
      expect(check.detailLabel, contains('Cloud backup is off'));
      expect(check.detailLabel, contains('Local saving still works'));
    });

    test('enabled backup detects files that fit the current tier', () {
      final check = CloudBackupQuotaPolicy.check(
        entitlement: freeEntitlement,
        usedBytes: 10 * 1024 * 1024,
        pendingBytes: 5 * 1024 * 1024,
        backupEnabled: true,
      );

      expect(check.isLocalOnly, isFalse);
      expect(check.wouldFitCloudTier, isTrue);
      expect(check.wouldExceedCloudTier, isFalse);
      expect(check.allowsLocalSave, isTrue);
      expect(check.willAttemptCloudBackup, isTrue);
      expect(check.remainingAfterSaveLabel, '85 MB');
      expect(check.statusLabel, 'Ready');
    });

    test(
      'enabled backup flags over-limit saves without blocking local save',
      () {
        final check = CloudBackupQuotaPolicy.check(
          entitlement: freeEntitlement,
          usedBytes: 99 * 1024 * 1024,
          pendingBytes: 3 * 1024 * 1024,
          backupEnabled: true,
        );

        expect(check.wouldFitCloudTier, isFalse);
        expect(check.wouldExceedCloudTier, isTrue);
        expect(check.allowsLocalSave, isTrue);
        expect(check.willAttemptCloudBackup, isFalse);
        expect(check.statusLabel, 'Over limit');
        expect(check.detailLabel, contains('102 MB of 100 MB'));
      },
    );

    test('different server plans can supply independent quotas', () {
      const plan = CloudBackupEntitlement(
        planId: 'paid',
        displayName: 'Paid backup',
        quotaBytes: 250 * 1024 * 1024,
        dailySyncLimit: 24,
        immediateSyncAllowed: true,
        policyVersion: 9,
      );

      expect(plan.quotaLabel, '250 MB');
      expect(plan.immediateSyncAllowed, isTrue);
    });

    test('negative byte inputs are sanitized', () {
      final check = CloudBackupQuotaPolicy.check(
        entitlement: freeEntitlement,
        usedBytes: -1,
        pendingBytes: -1,
        backupEnabled: true,
      );

      expect(check.usedBytes, 0);
      expect(check.pendingBytes, 0);
      expect(check.remainingLabel, '100 MB');
    });
  });

  group('CloudBackupSyncAllowance', () {
    const entitlement = CloudBackupEntitlement(
      planId: 'free',
      displayName: 'Free backup',
      quotaBytes: 100 * 1024 * 1024,
      dailySyncLimit: 4,
      immediateSyncAllowed: false,
      policyVersion: 1,
    );

    test('enforces the server-provided rolling 24-hour sync limit', () {
      final now = DateTime.utc(2026, 7, 16, 12);
      final allowance = CloudBackupSyncAllowance.evaluate(
        entitlement: entitlement,
        now: now,
        attemptedAt: [
          now.subtract(const Duration(hours: 23, minutes: 59)),
          now.subtract(const Duration(hours: 12)),
          now.subtract(const Duration(hours: 6)),
          now.subtract(const Duration(hours: 1)),
        ],
      );

      expect(allowance.used, 4);
      expect(allowance.remaining, 0);
      expect(allowance.allowsAttempt, isFalse);
      expect(allowance.nextEligibleAtUtc, DateTime.utc(2026, 7, 16, 12, 1));
    });

    test('ignores stale and future attempt timestamps', () {
      final now = DateTime.utc(2026, 7, 16, 12);
      final allowance = CloudBackupSyncAllowance.evaluate(
        entitlement: entitlement,
        now: now,
        attemptedAt: [
          now.subtract(const Duration(hours: 25)),
          now.subtract(const Duration(hours: 1)),
          now.add(const Duration(minutes: 1)),
        ],
      );

      expect(allowance.used, 1);
      expect(allowance.remaining, 3);
      expect(allowance.allowsAttempt, isTrue);
    });

    test('never grants cloud sync without a cloud entitlement', () {
      final allowance = CloudBackupSyncAllowance.evaluate(
        entitlement: const CloudBackupEntitlement.localOnly(),
        now: DateTime.utc(2026, 7, 16, 12),
        attemptedAt: const [],
      );

      expect(allowance.allowsAttempt, isFalse);
    });
  });

  group('CloudBackupStatusSnapshot', () {
    test('not connected snapshot is local-only with the trial tier ready', () {
      const status = CloudBackupStatusSnapshot.notConnected();
      final check = status.checkPendingBytes(1024);

      expect(status.isEnabled, isFalse);
      expect(status.connectionState.label, 'Not connected');
      expect(status.entitlement.hasCloudStorage, isFalse);
      expect(check.isLocalOnly, isTrue);
    });

    test('unavailable cloud keeps receipt save local-first', () {
      const status = CloudBackupStatusSnapshot.unavailable(
        usedBytes: 24 * 1024 * 1024,
      );
      final check = status.checkPendingBytes(4 * 1024 * 1024);

      expect(status.connectionState, CloudBackupConnectionState.unavailable);
      expect(status.isEnabled, isFalse);
      expect(check.isLocalOnly, isTrue);
      expect(check.allowsLocalSave, isTrue);
      expect(check.willAttemptCloudBackup, isFalse);
      expect(check.detailLabel, contains('Cloud backup is off'));
    });
  });

  group('LocalOnlyCloudBackupService', () {
    test('does not upload or connect to a backend', () async {
      const service = LocalOnlyCloudBackupService();
      final status = await service.currentStatus();

      expect(status.connectionState, CloudBackupConnectionState.notConnected);
      expect(status.usedBytes, 0);
      expect(status.isEnabled, isFalse);
    });
  });
}
