import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_quota.dart';
import 'package:maintaniac/shared/firebase/hosted_sync_scope.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';

void main() {
  group('HostedSyncScope', () {
    test('backs up every first-release app record module', () {
      expect(
        HostedSyncScope.backupModules,
        containsAll(const [
          HostedSyncModule.mileage,
          HostedSyncModule.expenses,
          HostedSyncModule.receiptProofs,
          HostedSyncModule.jobs,
          HostedSyncModule.estimates,
          HostedSyncModule.invoices,
          HostedSyncModule.inventoryItems,
          HostedSyncModule.inventoryTransactions,
          HostedSyncModule.maintenanceRecords,
          HostedSyncModule.vehicles,
          HostedSyncModule.employeePermissions,
          HostedSyncModule.employeeInvites,
          HostedSyncModule.calendarTimeline,
          HostedSyncModule.customerPortal,
          HostedSyncModule.settings,
          HostedSyncModule.auditEvents,
          HostedSyncModule.exports,
        ]),
      );
    });

    test('does not collapse hosted sync down to proof uploads only', () {
      expect(
        HostedSyncScope.backupModules.length,
        greaterThan(HostedSyncScope.proofEligibleModules.length),
      );
      expect(HostedSyncScope.isBackupModule('mileage'), isTrue);
      expect(HostedSyncScope.isBackupModule('invoices'), isTrue);
      expect(HostedSyncScope.isBackupModule('inventoryItems'), isTrue);
      expect(HostedSyncScope.isBackupModule('receiptsOnly'), isFalse);
    });

    test('keeps Firebase hosted limits aligned with local quota labels', () {
      expect(
        HostedUsageLimits.freeCloudStorageBytes,
        CloudBackupTier.freeTrial.quotaBytes,
      );
      expect(
        HostedUsageLimits.freeCloudStorageLabel,
        CloudBackupTier.freeTrial.quotaLabel,
      );
      expect(HostedUsageLimits.freeMonthlyExports, 1);
    });
  });
}
