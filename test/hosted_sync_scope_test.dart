import 'package:flutter_test/flutter_test.dart';
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

    test('requires an explicit server grant for hosted usage limits', () {
      expect(HostedUsageGrant.tryParse(const {}), isNull);
      final grant = HostedUsageGrant.tryParse({
        'storageQuotaBytes': 100,
        'monthlyExportLimit': 1,
        'aiInputTokenLimit': 0,
        'aiOutputTokenLimit': 0,
        'policyVersion': 1,
      });
      expect(grant?.storageQuotaBytes, 100);
      expect(grant?.monthlyExportLimit, 1);
    });
  });
}
