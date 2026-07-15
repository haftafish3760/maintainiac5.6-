import 'expense_cloud_restore_codec.dart';
import 'expense_ledger_store.dart';
import 'expense_work_profile_store.dart';

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
    if (ledger.receiptById(plan.cloudRecord.receipt.id) != null) {
      return const ExpenseCloudRestoreApplyResult.localRecordExists();
    }
    final saved = await ledger.saveReceipt(plan.cloudRecord.receipt);
    return ExpenseCloudRestoreApplyResult.created(saved.id);
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
}

enum ExpenseCloudRestoreDisposition {
  createLocal,
  localNewer,
  cloudNewerNeedsReview,
  sameRevisionNeedsReview,
}

class ExpenseCloudReceiptRestorePlan {
  const ExpenseCloudReceiptRestorePlan._({
    required this.disposition,
    required this.cloudRecord,
    required this.localRevision,
  });

  const ExpenseCloudReceiptRestorePlan.create(
    ExpenseCloudRestoredReceipt record,
  ) : this._(
        disposition: ExpenseCloudRestoreDisposition.createLocal,
        cloudRecord: record,
        localRevision: null,
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
