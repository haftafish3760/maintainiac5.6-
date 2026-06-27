import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/account_abuse_policy.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';

void main() {
  group('AccountAbusePolicy', () {
    test('allows first two accounts for a verified install and IP window', () {
      final result = AccountAbusePolicy.evaluateCreation(
        const AccountCreationRiskSnapshot(
          providerAllowed: true,
          appCheckVerified: true,
          accountsForInstall: 1,
          accountsForIpWindow: 1,
        ),
      );

      expect(result.action, AccountCreationGateAction.allow);
      expect(AccountAbusePolicy.freeAccountsPerInstall, 2);
      expect(AccountAbusePolicy.freeAccountsPerIpWindow, 2);
      expect(
        HostedUsageLimits.maxAccountsPerInstallInReviewWindow,
        AccountAbusePolicy.freeAccountsPerInstall,
      );
      expect(
        HostedUsageLimits.maxAccountsPerIpInReviewWindow,
        AccountAbusePolicy.freeAccountsPerIpWindow,
      );
    });

    test('requires extra verification after device or IP threshold', () {
      final deviceResult = AccountAbusePolicy.evaluateCreation(
        const AccountCreationRiskSnapshot(
          providerAllowed: true,
          appCheckVerified: true,
          accountsForInstall: 2,
          accountsForIpWindow: 0,
        ),
      );
      final ipResult = AccountAbusePolicy.evaluateCreation(
        const AccountCreationRiskSnapshot(
          providerAllowed: true,
          appCheckVerified: true,
          accountsForInstall: 0,
          accountsForIpWindow: 2,
        ),
      );

      expect(
        deviceResult.action,
        AccountCreationGateAction.requireAdditionalVerification,
      );
      expect(
        ipResult.action,
        AccountCreationGateAction.requireAdditionalVerification,
      );
    });

    test('allows threshold signup when extra verification is satisfied', () {
      final result = AccountAbusePolicy.evaluateCreation(
        const AccountCreationRiskSnapshot(
          providerAllowed: true,
          appCheckVerified: true,
          accountsForInstall: 2,
          accountsForIpWindow: 2,
          additionalVerificationSatisfied: true,
        ),
      );

      expect(result.action, AccountCreationGateAction.allow);
    });

    test(
      'blocks unsupported providers, missing App Check, and abuse marks',
      () {
        final unsupportedProvider = AccountAbusePolicy.evaluateCreation(
          const AccountCreationRiskSnapshot(
            providerAllowed: false,
            appCheckVerified: true,
            accountsForInstall: 0,
            accountsForIpWindow: 0,
          ),
        );
        final missingAppCheck = AccountAbusePolicy.evaluateCreation(
          const AccountCreationRiskSnapshot(
            providerAllowed: true,
            appCheckVerified: false,
            accountsForInstall: 0,
            accountsForIpWindow: 0,
          ),
        );
        final knownAbuse = AccountAbusePolicy.evaluateCreation(
          const AccountCreationRiskSnapshot(
            providerAllowed: true,
            appCheckVerified: true,
            accountsForInstall: 0,
            accountsForIpWindow: 0,
            installMarkedAbusive: true,
          ),
        );

        expect(unsupportedProvider.action, AccountCreationGateAction.block);
        expect(missingAppCheck.action, AccountCreationGateAction.block);
        expect(knownAbuse.action, AccountCreationGateAction.block);
      },
    );

    test('blocks heavy repeat account attempts for manual review', () {
      final result = AccountAbusePolicy.evaluateCreation(
        const AccountCreationRiskSnapshot(
          providerAllowed: true,
          appCheckVerified: true,
          accountsForInstall: 6,
          accountsForIpWindow: 2,
          additionalVerificationSatisfied: true,
        ),
      );

      expect(result.action, AccountCreationGateAction.block);
      expect(result.reason, contains('Manual review'));
    });
  });
}
