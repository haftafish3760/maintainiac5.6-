import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/account_creation_gate_contract.dart';
import 'package:maintaniac/shared/firebase/app_installation_identity.dart';

void main() {
  group('AppInstallationIdentityStore', () {
    test('creates and reuses a stable install identity', () async {
      final vault = _MemoryInstallationVault();
      final store = AppInstallationIdentityStore(
        vault: vault,
        now: () => DateTime.utc(2026, 6, 20, 10),
        idFactory: () => 'mai_install_12345678901234567890123456789012',
      );

      final first = await store.getOrCreate();
      final second = await store.getOrCreate();

      expect(first.installationId, second.installationId);
      expect(
        vault.values[AppInstallationIdentityStore.installIdKey],
        first.installationId,
      );
      expect(
        first.toSignupSignalPayload(),
        containsPair(
          AccountCreationGateContract.appInstallationIdField,
          first.installationId,
        ),
      );
    });

    test('replaces invalid stored install identity', () async {
      final vault = _MemoryInstallationVault({
        AppInstallationIdentityStore.installIdKey: 'not-a-valid-id',
        AppInstallationIdentityStore.installCreatedAtKey: DateTime.utc(
          2026,
          6,
          20,
        ).toIso8601String(),
      });
      final store = AppInstallationIdentityStore(
        vault: vault,
        idFactory: () => 'mai_install_abcdefghijklmnopqrstuvwxyzABCDEF',
      );

      final identity = await store.getOrCreate();

      expect(
        identity.installationId,
        'mai_install_abcdefghijklmnopqrstuvwxyzABCDEF',
      );
    });
  });

  group('AccountCreationGateContract', () {
    test('keeps server-only collections and required fields explicit', () {
      expect(
        AccountCreationGateContract.requiredRequestFields,
        containsAll(['appInstallationId', 'providerId', 'appCheckVerified']),
      );
      expect(
        AccountCreationGateContract.serverOnlyCollections,
        containsAll([
          'accountAbuseInstalls',
          'accountAbuseIpWindows',
          'accountCreationReviews',
          'aiAbuseSecurityEvents',
          'aiEnforcementActions',
        ]),
      );
      expect(
        AccountCreationGateContract.freeAccountThresholds['perInstall'],
        2,
      );
      expect(
        AccountCreationGateContract.freeAccountThresholds['perIpWindow'],
        2,
      );
    });
  });
}

class _MemoryInstallationVault implements InstallationIdentityVault {
  _MemoryInstallationVault([Map<String, String>? values])
    : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
