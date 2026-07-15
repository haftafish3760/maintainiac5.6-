import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_planner.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';

void main() {
  ExpenseCloudRestoredReceipt cloudReceipt({int revision = 2}) {
    return ExpenseCloudRestoredReceipt(
      receipt: ExpenseReceiptRecord(
        id: 'restore-me',
        receiptDate: DateTime.utc(2026, 7, 15),
        localRevision: revision,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'restore-line',
            description: 'Parking',
            category: 'Parking',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
      proofPointers: const [],
    );
  }

  test('plans a missing cloud receipt for explicit local creation', () async {
    final ledger = ExpenseLedgerController.memory();
    final plan = ExpenseCloudRestorePlanner.planReceipt(
      ledger: ledger,
      cloudRecord: cloudReceipt(),
    );

    expect(plan.disposition, ExpenseCloudRestoreDisposition.createLocal);
    expect(ledger.receiptById('restore-me'), isNull);

    final result = await ExpenseCloudRestorePlanner.createIfMissing(
      ledger: ledger,
      plan: plan,
    );
    expect(result.wasCreated, isTrue);
    expect(ledger.receiptById('restore-me'), isNotNull);
  });

  test('never overwrites an existing local receipt during restore', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'restore-me',
        receiptDate: DateTime.utc(2026, 7, 15),
        localRevision: 5,
        merchantName: 'Local original',
        lines: const [],
      ),
    );
    final plan = ExpenseCloudRestorePlanner.planReceipt(
      ledger: ledger,
      cloudRecord: cloudReceipt(revision: 2),
    );

    expect(plan.disposition, ExpenseCloudRestoreDisposition.localNewer);
    final result = await ExpenseCloudRestorePlanner.createIfMissing(
      ledger: ledger,
      plan: plan,
    );
    expect(result.wasCreated, isFalse);
    expect(ledger.receiptById('restore-me')?.merchantName, 'Local original');
  });

  test('requires review when cloud has a newer revision', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'restore-me',
        receiptDate: DateTime.utc(2026, 7, 15),
        localRevision: 1,
        lines: const [],
      ),
    );

    final plan = ExpenseCloudRestorePlanner.planReceipt(
      ledger: ledger,
      cloudRecord: cloudReceipt(revision: 5),
    );

    expect(
      plan.disposition,
      ExpenseCloudRestoreDisposition.cloudNewerNeedsReview,
    );
  });

  test(
    'restores only missing work profiles and preserves conflicting locals',
    () async {
      final local = ExpenseWorkProfileController.memory();
      await local.save(
        ExpenseWorkProfile(
          id: 'delivery',
          name: 'Local delivery',
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
        ),
      );
      final cloud = ExpenseCloudRestoredWorkProfiles(
        activeProfileId: 'delivery',
        profiles: [
          ExpenseWorkProfile(
            id: 'delivery',
            name: 'Cloud delivery',
            createdAt: DateTime.utc(2026, 7, 15),
            updatedAt: DateTime.utc(2026, 7, 15),
          ),
          ExpenseWorkProfile(
            id: 'seasonal',
            name: 'Seasonal contract',
            createdAt: DateTime.utc(2026, 7, 15),
            updatedAt: DateTime.utc(2026, 7, 15),
            archivedAt: DateTime.utc(2026, 7, 16),
          ),
        ],
      );

      final plan = ExpenseCloudRestorePlanner.planWorkProfiles(
        localProfiles: local,
        cloudProfiles: cloud,
      );

      expect(plan.missingProfiles.map((profile) => profile.id), ['seasonal']);
      expect(plan.conflictingCloudProfiles.map((profile) => profile.id), [
        'delivery',
      ]);
      expect(
        local.activeWorkProfile.id,
        ExpenseWorkProfileController.defaultProfileId,
      );

      expect(
        await ExpenseCloudRestorePlanner.createMissingWorkProfiles(
          localProfiles: local,
          plan: plan,
        ),
        1,
      );
      expect(local.profileById('seasonal')?.isArchived, isTrue);
      expect(local.profileById('delivery')?.name, 'Local delivery');
    },
  );
}
