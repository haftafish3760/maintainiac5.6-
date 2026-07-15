import 'expense_cloud_restore_codec.dart';
import 'expense_ledger_models.dart';
import 'expense_ledger_store.dart';
import 'expense_reminder_store.dart';
import 'expense_work_profile_store.dart';
import '../../../shared/state/app_state.dart';

/// Plans a receipt restore without overwriting device data.
///
/// A caller must obtain explicit restore authorization before applying a plan.
/// Newer or divergent local records are always surfaced for review instead of
/// being replaced by cloud metadata.
class ExpenseCloudRestorePlanner {
  const ExpenseCloudRestorePlanner._();

  static ExpenseCloudReceiptRestorePlan planReceipt({
    required ExpenseLedgerController ledger,
    required ExpenseCloudRestoredReceipt cloudRecord,
  }) {
    final local = ledger.receiptById(cloudRecord.receipt.id);
    if (local == null) {
      final duplicateCandidates = ledger.duplicateCandidatesFor(
        cloudRecord.receipt,
      );
      if (duplicateCandidates.isNotEmpty) {
        return ExpenseCloudReceiptRestorePlan.duplicateCandidatesNeedReview(
          cloudRecord: cloudRecord,
          duplicateCandidates: duplicateCandidates,
        );
      }
      return ExpenseCloudReceiptRestorePlan.create(cloudRecord);
    }
    final cloudRevision = cloudRecord.receipt.localRevision;
    final localRevision = local.localRevision;
    if (localRevision > cloudRevision) {
      return ExpenseCloudReceiptRestorePlan.localNewer(
        cloudRecord: cloudRecord,
        localRevision: localRevision,
      );
    }
    if (localRevision < cloudRevision) {
      return ExpenseCloudReceiptRestorePlan.cloudNewerNeedsReview(
        cloudRecord: cloudRecord,
        localRevision: localRevision,
      );
    }
    return ExpenseCloudReceiptRestorePlan.sameRevisionNeedsReview(
      cloudRecord: cloudRecord,
      localRevision: localRevision,
    );
  }

  /// Writes only a record that remains absent at the final local check.
  /// It deliberately refuses every overwrite path.
  static Future<ExpenseCloudRestoreApplyResult> createIfMissing({
    required ExpenseLedgerController ledger,
    required ExpenseCloudReceiptRestorePlan plan,
  }) async {
    if (plan.disposition != ExpenseCloudRestoreDisposition.createLocal) {
      return const ExpenseCloudRestoreApplyResult.notApplied();
    }
    final saved = await ledger.importReceiptIfMissing(plan.cloudRecord.receipt);
    return saved == null
        ? const ExpenseCloudRestoreApplyResult.localRecordExists()
        : ExpenseCloudRestoreApplyResult.created(saved.id);
  }

  static ExpenseCloudWorkProfileRestorePlan planWorkProfiles({
    required ExpenseWorkProfileController localProfiles,
    required ExpenseCloudRestoredWorkProfiles cloudProfiles,
  }) {
    final missing = <ExpenseWorkProfile>[];
    final conflicts = <ExpenseWorkProfile>[];
    for (final cloudProfile in cloudProfiles.profiles) {
      final local = localProfiles.profileById(cloudProfile.id);
      if (local == null) {
        missing.add(cloudProfile);
      } else if (!_sameProfile(local, cloudProfile)) {
        conflicts.add(cloudProfile);
      }
    }
    return ExpenseCloudWorkProfileRestorePlan(
      missingProfiles: List.unmodifiable(missing),
      conflictingCloudProfiles: List.unmodifiable(conflicts),
      proposedActiveProfileId: cloudProfiles.activeProfileId,
    );
  }

  /// Restores only unknown IDs. Existing local profiles, including the active
  /// selection, remain untouched until the user resolves a conflict explicitly.
  static Future<int> createMissingWorkProfiles({
    required ExpenseWorkProfileController localProfiles,
    required ExpenseCloudWorkProfileRestorePlan plan,
  }) async {
    var created = 0;
    for (final profile in plan.missingProfiles) {
      if (localProfiles.profileById(profile.id) != null) continue;
      await localProfiles.save(profile);
      created += 1;
    }
    return created;
  }

  static bool _sameProfile(ExpenseWorkProfile local, ExpenseWorkProfile cloud) {
    return local.name == cloud.name &&
        local.isDefault == cloud.isDefault &&
        local.archivedAt?.toUtc() == cloud.archivedAt?.toUtc();
  }

  static ExpenseCloudVehicleRestorePlan planVehicles({
    required AppStateController localAppState,
    required ExpenseCloudRestoredVehicles cloudVehicles,
  }) {
    final missing = <VehicleProfile>[];
    final conflicts = <VehicleProfile>[];
    for (final cloudVehicle in cloudVehicles.vehicles) {
      final local = localAppState.vehicleById(cloudVehicle.id);
      if (local == null) {
        missing.add(cloudVehicle);
      } else if (!_sameVehicle(local, cloudVehicle)) {
        conflicts.add(cloudVehicle);
      }
    }
    return ExpenseCloudVehicleRestorePlan(
      missingVehicles: List.unmodifiable(missing),
      conflictingCloudVehicles: List.unmodifiable(conflicts),
      proposedActiveVehicleId: cloudVehicles.activeVehicleId,
    );
  }

  /// Restores only unknown vehicle IDs and never changes the selected vehicle.
  static Future<int> createMissingVehicles({
    required AppStateController localAppState,
    required ExpenseCloudVehicleRestorePlan plan,
  }) async {
    var created = 0;
    for (final vehicle in plan.missingVehicles) {
      if (localAppState.vehicleById(vehicle.id) != null) continue;
      await localAppState.addVehicle(vehicle);
      created += 1;
    }
    return created;
  }

  static bool _sameVehicle(VehicleProfile local, VehicleProfile cloud) {
    return local.nickname == cloud.nickname &&
        local.year == cloud.year &&
        local.make == cloud.make &&
        local.model == cloud.model &&
        local.usage == cloud.usage &&
        local.archivedAt?.toUtc() == cloud.archivedAt?.toUtc();
  }

  static ExpenseCloudReminderRestorePlan planReminder({
    required ExpenseReminderController localReminders,
    required ExpenseCloudRestoredReminder cloudReminder,
  }) {
    final local = localReminders.recordById(cloudReminder.record.id);
    if (local == null) {
      return ExpenseCloudReminderRestorePlan.create(cloudReminder);
    }
    final localRevision = local.lifecycle?.revision ?? 1;
    final cloudRevision = cloudReminder.record.lifecycle?.revision ?? 1;
    if (localRevision > cloudRevision) {
      return ExpenseCloudReminderRestorePlan.localNewer(
        cloudReminder: cloudReminder,
        localRevision: localRevision,
      );
    }
    return ExpenseCloudReminderRestorePlan.needsReview(
      cloudReminder: cloudReminder,
      localRevision: localRevision,
    );
  }

  static Future<ExpenseReminderRecord?> createReminderIfMissing({
    required ExpenseReminderController localReminders,
    required ExpenseCloudReminderRestorePlan plan,
  }) {
    if (plan.disposition != ExpenseCloudRestoreDisposition.createLocal) {
      return Future.value(null);
    }
    return localReminders.importIfMissing(plan.cloudReminder.record);
  }
}

enum ExpenseCloudRestoreDisposition {
  createLocal,
  duplicateCandidatesNeedReview,
  localNewer,
  cloudNewerNeedsReview,
  sameRevisionNeedsReview,
}

class ExpenseCloudReceiptRestorePlan {
  const ExpenseCloudReceiptRestorePlan._({
    required this.disposition,
    required this.cloudRecord,
    required this.localRevision,
    this.duplicateCandidates = const [],
  });

  const ExpenseCloudReceiptRestorePlan.create(
    ExpenseCloudRestoredReceipt record,
  ) : this._(
        disposition: ExpenseCloudRestoreDisposition.createLocal,
        cloudRecord: record,
        localRevision: null,
      );

  const ExpenseCloudReceiptRestorePlan.duplicateCandidatesNeedReview({
    required ExpenseCloudRestoredReceipt cloudRecord,
    required List<ExpenseReceiptDuplicateCandidate> duplicateCandidates,
  }) : this._(
         disposition:
             ExpenseCloudRestoreDisposition.duplicateCandidatesNeedReview,
         cloudRecord: cloudRecord,
         localRevision: null,
         duplicateCandidates: duplicateCandidates,
       );

  const ExpenseCloudReceiptRestorePlan.localNewer({
    required ExpenseCloudRestoredReceipt cloudRecord,
    required int localRevision,
  }) : this._(
         disposition: ExpenseCloudRestoreDisposition.localNewer,
         cloudRecord: cloudRecord,
         localRevision: localRevision,
       );

  const ExpenseCloudReceiptRestorePlan.cloudNewerNeedsReview({
    required ExpenseCloudRestoredReceipt cloudRecord,
    required int localRevision,
  }) : this._(
         disposition: ExpenseCloudRestoreDisposition.cloudNewerNeedsReview,
         cloudRecord: cloudRecord,
         localRevision: localRevision,
       );

  const ExpenseCloudReceiptRestorePlan.sameRevisionNeedsReview({
    required ExpenseCloudRestoredReceipt cloudRecord,
    required int localRevision,
  }) : this._(
         disposition: ExpenseCloudRestoreDisposition.sameRevisionNeedsReview,
         cloudRecord: cloudRecord,
         localRevision: localRevision,
       );

  final ExpenseCloudRestoreDisposition disposition;
  final ExpenseCloudRestoredReceipt cloudRecord;
  final int? localRevision;
  final List<ExpenseReceiptDuplicateCandidate> duplicateCandidates;
}

class ExpenseCloudRestoreApplyResult {
  const ExpenseCloudRestoreApplyResult._(this.createdReceiptId, this.reason);

  const ExpenseCloudRestoreApplyResult.created(String receiptId)
    : this._(receiptId, null);

  const ExpenseCloudRestoreApplyResult.notApplied()
    : this._(null, 'This restore plan requires record review.');

  const ExpenseCloudRestoreApplyResult.localRecordExists()
    : this._(null, 'A local record now exists for this receipt.');

  final String? createdReceiptId;
  final String? reason;

  bool get wasCreated => createdReceiptId != null;
}

class ExpenseCloudWorkProfileRestorePlan {
  const ExpenseCloudWorkProfileRestorePlan({
    required this.missingProfiles,
    required this.conflictingCloudProfiles,
    required this.proposedActiveProfileId,
  });

  final List<ExpenseWorkProfile> missingProfiles;
  final List<ExpenseWorkProfile> conflictingCloudProfiles;
  final String? proposedActiveProfileId;

  bool get needsUserReview => conflictingCloudProfiles.isNotEmpty;
}

class ExpenseCloudVehicleRestorePlan {
  const ExpenseCloudVehicleRestorePlan({
    required this.missingVehicles,
    required this.conflictingCloudVehicles,
    required this.proposedActiveVehicleId,
  });

  final List<VehicleProfile> missingVehicles;
  final List<VehicleProfile> conflictingCloudVehicles;
  final String? proposedActiveVehicleId;

  bool get needsUserReview => conflictingCloudVehicles.isNotEmpty;
}

class ExpenseCloudReminderRestorePlan {
  const ExpenseCloudReminderRestorePlan._({
    required this.disposition,
    required this.cloudReminder,
    required this.localRevision,
  });

  const ExpenseCloudReminderRestorePlan.create(
    ExpenseCloudRestoredReminder reminder,
  ) : this._(
        disposition: ExpenseCloudRestoreDisposition.createLocal,
        cloudReminder: reminder,
        localRevision: null,
      );

  const ExpenseCloudReminderRestorePlan.localNewer({
    required ExpenseCloudRestoredReminder cloudReminder,
    required int localRevision,
  }) : this._(
         disposition: ExpenseCloudRestoreDisposition.localNewer,
         cloudReminder: cloudReminder,
         localRevision: localRevision,
       );

  const ExpenseCloudReminderRestorePlan.needsReview({
    required ExpenseCloudRestoredReminder cloudReminder,
    required int localRevision,
  }) : this._(
         disposition: ExpenseCloudRestoreDisposition.sameRevisionNeedsReview,
         cloudReminder: cloudReminder,
         localRevision: localRevision,
       );

  final ExpenseCloudRestoreDisposition disposition;
  final ExpenseCloudRestoredReminder cloudReminder;
  final int? localRevision;
}
