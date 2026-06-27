enum AccountCreationGateAction {
  allow('Allow'),
  requireAdditionalVerification('Require additional verification'),
  block('Block');

  const AccountCreationGateAction(this.label);

  final String label;
}

class AccountCreationGateResult {
  const AccountCreationGateResult({required this.action, required this.reason});

  final AccountCreationGateAction action;
  final String reason;

  bool get allowsSignup => action == AccountCreationGateAction.allow;
  bool get requiresReview =>
      action == AccountCreationGateAction.requireAdditionalVerification;
}

class AccountCreationRiskSnapshot {
  const AccountCreationRiskSnapshot({
    required this.providerAllowed,
    required this.appCheckVerified,
    required this.accountsForInstall,
    required this.accountsForIpWindow,
    this.additionalVerificationSatisfied = false,
    this.installMarkedAbusive = false,
    this.ipWindowMarkedAbusive = false,
  });

  final bool providerAllowed;
  final bool appCheckVerified;
  final int accountsForInstall;
  final int accountsForIpWindow;
  final bool additionalVerificationSatisfied;
  final bool installMarkedAbusive;
  final bool ipWindowMarkedAbusive;
}

class AccountAbusePolicy {
  const AccountAbusePolicy._();

  static const int freeAccountsPerInstall = 2;
  static const int freeAccountsPerIpWindow = 2;
  static const int manualReviewAccountsPerInstall = 6;
  static const int manualReviewAccountsPerIpWindow = 6;
  static const int ipWindowDays = 30;

  static const String installSignalName = 'appInstallationId';
  static const String ipSignalName = 'coarseIpHash';

  static AccountCreationGateResult evaluateCreation(
    AccountCreationRiskSnapshot snapshot,
  ) {
    if (!snapshot.providerAllowed) {
      return const AccountCreationGateResult(
        action: AccountCreationGateAction.block,
        reason: 'Only Google and Apple sign-in are allowed.',
      );
    }
    if (!snapshot.appCheckVerified) {
      return const AccountCreationGateResult(
        action: AccountCreationGateAction.block,
        reason: 'App Check verification is required for hosted accounts.',
      );
    }
    if (snapshot.installMarkedAbusive || snapshot.ipWindowMarkedAbusive) {
      return const AccountCreationGateResult(
        action: AccountCreationGateAction.block,
        reason: 'This signup signal is already marked abusive.',
      );
    }
    if (snapshot.accountsForInstall >= manualReviewAccountsPerInstall ||
        snapshot.accountsForIpWindow >= manualReviewAccountsPerIpWindow) {
      return const AccountCreationGateResult(
        action: AccountCreationGateAction.block,
        reason: 'Too many account attempts. Manual review is required.',
      );
    }
    if (!snapshot.additionalVerificationSatisfied &&
        (snapshot.accountsForInstall >= freeAccountsPerInstall ||
            snapshot.accountsForIpWindow >= freeAccountsPerIpWindow)) {
      return const AccountCreationGateResult(
        action: AccountCreationGateAction.requireAdditionalVerification,
        reason:
            'This device or network has reached the free account threshold.',
      );
    }
    return const AccountCreationGateResult(
      action: AccountCreationGateAction.allow,
      reason: 'Signup is inside first-release account limits.',
    );
  }
}
