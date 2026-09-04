import '../../../shared/profiles/user_profile_models.dart';

/// Centralizes dashboard visibility decisions so the UI never invents access
/// rules independently from the active account profile.
class ContractorDashboardAccess {
  const ContractorDashboardAccess({
    required this.memberId,
    required this.canStartOwnDay,
    required this.canViewAssignedJobs,
    required this.canViewAllJobs,
    required this.canReviewReceipts,
    required this.canViewUnpaidInvoices,
  });

  factory ContractorDashboardAccess.fromProfile(UserProfileRecord? profile) {
    // Older local installs without a profile scope are the account owner. This
    // preserves their existing access while migrated profiles use explicit
    // permissions below.
    if (profile == null) {
      return const ContractorDashboardAccess(
        memberId: 'local-owner',
        canStartOwnDay: true,
        canViewAssignedJobs: true,
        canViewAllJobs: true,
        canReviewReceipts: true,
        canViewUnpaidInvoices: true,
      );
    }
    return ContractorDashboardAccess(
      memberId: profile.id,
      canStartOwnDay:
          profile.can(UserPermission.startOwnMileageSession) &&
          profile.can(UserPermission.recordMileage),
      canViewAssignedJobs: profile.can(UserPermission.viewAssignedJobs),
      canViewAllJobs:
          profile.can(UserPermission.viewAllJobs) ||
          profile.can(UserPermission.manageJobs),
      canReviewReceipts:
          profile.can(UserPermission.manageReceiptParsing) ||
          profile.can(UserPermission.approveExpenses) ||
          profile.can(UserPermission.editOwnExpenses),
      canViewUnpaidInvoices: profile.can(UserPermission.viewUnpaidBalances),
    );
  }

  final String memberId;
  final bool canStartOwnDay;
  final bool canViewAssignedJobs;
  final bool canViewAllJobs;
  final bool canReviewReceipts;
  final bool canViewUnpaidInvoices;

  bool get canViewJobs => canViewAssignedJobs || canViewAllJobs;
}
