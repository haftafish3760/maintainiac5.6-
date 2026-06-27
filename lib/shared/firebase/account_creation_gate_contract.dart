import 'account_abuse_policy.dart';

class AccountCreationGateContract {
  const AccountCreationGateContract._();

  static const callableName = 'requestHostedAccountCreation';
  static const beforeCreateBlockingFunction = 'beforeCreateAccountGate';

  static const installCollection = 'accountAbuseInstalls';
  static const ipWindowCollection = 'accountAbuseIpWindows';
  static const reviewCollection = 'accountCreationReviews';
  static const aiAbuseSecurityEventsCollection = 'aiAbuseSecurityEvents';
  static const aiEnforcementActionsCollection = 'aiEnforcementActions';

  static const appInstallationIdField = AccountAbusePolicy.installSignalName;
  static const appInstallationHashField = 'appInstallationHash';
  static const coarseIpHashField = AccountAbusePolicy.ipSignalName;
  static const providerIdField = 'providerId';
  static const appCheckVerifiedField = 'appCheckVerified';
  static const additionalVerificationSatisfiedField =
      'additionalVerificationSatisfied';

  static const requiredRequestFields = [
    appInstallationIdField,
    providerIdField,
    appCheckVerifiedField,
  ];

  static const serverOnlyCollections = [
    installCollection,
    ipWindowCollection,
    reviewCollection,
    aiAbuseSecurityEventsCollection,
    aiEnforcementActionsCollection,
  ];

  static const freeAccountThresholds = {
    'perInstall': AccountAbusePolicy.freeAccountsPerInstall,
    'perIpWindow': AccountAbusePolicy.freeAccountsPerIpWindow,
    'ipWindowDays': AccountAbusePolicy.ipWindowDays,
  };
}
