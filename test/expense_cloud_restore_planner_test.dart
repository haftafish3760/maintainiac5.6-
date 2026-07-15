import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_planner.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_reminder_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:maintaniac/shared/state/app_state.dart';

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

  test(
    'requires review before restoring a duplicate receipt under a new ID',
    () async {
      final ledger = ExpenseLedgerController.memory();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'local-receipt',
          receiptDate: DateTime.utc(2026, 7, 15),
          fileHashSha256: 'abcdef',
          lines: const [],
        ),
      );
      final cloud = ExpenseCloudRestoredReceipt(
        receipt: ExpenseReceiptRecord(
          id: 'cloud-receipt',
          receiptDate: DateTime.utc(2026, 7, 15),
          fileHashSha256: 'abcdef',
          lines: const [],
        ),
        proofPointers: const [],
      );

      final plan = ExpenseCloudRestorePlanner.planReceipt(
        ledger: ledger,
        cloudRecord: cloud,
      );

      expect(
        plan.disposition,
        ExpenseCloudRestoreDisposition.duplicateCandidatesNeedReview,
      );
      expect(plan.duplicateCandidates.single.receiptId, 'local-receipt');
      final result = await ExpenseCloudRestorePlanner.createIfMissing(
        ledger: ledger,
        plan: plan,
      );
      expect(result.wasCreated, isFalse);
      expect(ledger.receiptById('cloud-receipt'), isNull);
    },
  );

  test('restores a missing receipt tombstone without reviving it', () async {
    final ledger = ExpenseLedgerController.memory();
    final cloud = ExpenseCloudRestoredReceipt(
      receipt: ExpenseReceiptRecord(
        id: 'deleted-cloud-receipt',
        receiptDate: DateTime.utc(2026, 7, 15),
        createdAt: DateTime.utc(2026, 7, 15, 8),
        updatedAt: DateTime.utc(2026, 7, 15, 12),
        recordState: MaintainiacRecordState.deleted,
        deletedAt: DateTime.utc(2026, 7, 15, 12),
        localRevision: 4,
        auditEvents: const [
          '2026-07-15T12:00:00.000Z deleted receipt deleted-cloud-receipt',
        ],
        lines: const [],
      ),
      proofPointers: const [],
    );
    final plan = ExpenseCloudRestorePlanner.planReceipt(
      ledger: ledger,
      cloudRecord: cloud,
    );

    expect(plan.disposition, ExpenseCloudRestoreDisposition.createLocal);
    expect(
      (await ExpenseCloudRestorePlanner.createIfMissing(
        ledger: ledger,
        plan: plan,
      )).wasCreated,
      isTrue,
    );
    final restored = ledger.receiptById('deleted-cloud-receipt')!;
    expect(restored.isDeleted, isTrue);
    expect(restored.localRevision, 4);
    expect(restored.createdAt, DateTime.utc(2026, 7, 15, 8));
    expect(restored.updatedAt, DateTime.utc(2026, 7, 15, 12));
    expect(restored.auditEvents, [
      '2026-07-15T12:00:00.000Z deleted receipt deleted-cloud-receipt',
    ]);
    expect(ledger.receipts, isEmpty);
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

  test(
    'restores only missing vehicles and keeps local selection untouched',
    () async {
      final local = AppStateController();
      await local.addVehicle(
        VehicleProfile(
          id: 'van-1',
          nickname: 'Local van',
          year: '2024',
          make: 'Ford',
          model: 'Transit',
        ),
      );
      final selectedId = local.activeVehicle!.id;
      final cloud = ExpenseCloudRestoredVehicles(
        activeVehicleId: 'van-1',
        vehicles: [
          VehicleProfile(
            id: 'van-1',
            nickname: 'Cloud van',
            year: '2024',
            make: 'Ford',
            model: 'Transit',
          ),
          VehicleProfile(
            id: 'old-van',
            nickname: 'Old van',
            year: '2016',
            make: 'Ford',
            model: 'Transit',
            archivedAt: DateTime.utc(2026, 7, 16),
          ),
        ],
      );

      final plan = ExpenseCloudRestorePlanner.planVehicles(
        localAppState: local,
        cloudVehicles: cloud,
      );

      expect(plan.missingVehicles.map((vehicle) => vehicle.id), ['old-van']);
      expect(plan.conflictingCloudVehicles.map((vehicle) => vehicle.id), [
        'van-1',
      ]);
      expect(
        await ExpenseCloudRestorePlanner.createMissingVehicles(
          localAppState: local,
          plan: plan,
        ),
        1,
      );
      expect(local.vehicleById('old-van')?.isArchived, isTrue);
      expect(local.activeVehicle?.id, selectedId);
      expect(local.vehicleById('van-1')?.nickname, 'Local van');
    },
  );

  test(
    'restores a missing reminder tombstone without replacing local records',
    () async {
      final local = ExpenseReminderController.memory();
      final cloud = ExpenseCloudRestoredReminder(
        ExpenseReminderRecord(
          id: 'reminder-restore',
          title: 'Registration',
          category: 'Registration',
          channel: 'in_app',
          dueAt: DateTime.utc(2026, 8, 1),
          cadence: ExpenseReminderCadence.yearly,
          createdAt: DateTime.utc(2026, 7, 1),
          updatedAt: DateTime.utc(2026, 7, 15),
          active: false,
          lifecycle: MaintainiacRecordLifecycle(
            createdAt: DateTime.utc(2026, 7, 1),
            updatedAt: DateTime.utc(2026, 7, 15),
            revision: 4,
            state: MaintainiacRecordState.deleted,
            deletedAt: DateTime.utc(2026, 7, 15),
          ),
        ),
      );
      final plan = ExpenseCloudRestorePlanner.planReminder(
        localReminders: local,
        cloudReminder: cloud,
      );

      expect(plan.disposition, ExpenseCloudRestoreDisposition.createLocal);
      final imported = await ExpenseCloudRestorePlanner.createReminderIfMissing(
        localReminders: local,
        plan: plan,
      );
      expect(imported?.isDeleted, isTrue);
      expect(local.recordById('reminder-restore')?.lifecycle?.revision, 4);
    },
  );
}
