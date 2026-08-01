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
          AccountCreationGateContract.appInstallationHashField,
          first.installationIdSha256,
        ),
      );
      expect(first.installationIdSha256, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(
        first.toSignupSignalPayload().values,
        isNot(contains(first.installationId)),
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

    test(
      'repairs malformed timestamps without rotating the stable ID',
      () async {
        final vault = _MemoryInstallationVault({
          AppInstallationIdentityStore.installIdKey:
              'mai_install_12345678901234567890123456789012',
          AppInstallationIdentityStore.installCreatedAtKey: 'not-a-date',
        });
        final store = AppInstallationIdentityStore(
          vault: vault,
          now: () => DateTime.utc(2026, 6, 20, 10),
          idFactory: () => 'mai_install_new45678901234567890123456789012',
        );

        final identity = await store.getOrCreate();

        expect(
          identity.installationId,
          'mai_install_12345678901234567890123456789012',
        );
        expect(identity.createdAt, DateTime.utc(2026, 6, 20, 10));
        expect(
          vault.values[AppInstallationIdentityStore.installCreatedAtKey],
          DateTime.utc(2026, 6, 20, 10).toIso8601String(),
        );
      },
    );

    test('serializes concurrent stores onto one durable identity', () async {
      final vault = _DelayedInstallationVault();
      var factoryCalls = 0;
      AppInstallationIdentityStore newStore() => AppInstallationIdentityStore(
        vault: vault,
        now: () => DateTime.utc(2026, 6, 20, 10),
        idFactory: () {
          factoryCalls += 1;
          return 'mai_install_12345678901234567890123456789012';
        },
      );

      final identities = await Future.wait(
        List<Future<AppInstallationIdentity>>.generate(
          20,
          (_) => newStore().getOrCreate(),
        ),
      );

      expect(factoryCalls, 1);
      expect(identities.map((identity) => identity.installationId).toSet(), {
        'mai_install_12345678901234567890123456789012',
      });
    });

    test(
      'rejects an invalid generated identity before committing it',
      () async {
        final vault = _MemoryInstallationVault();
        final store = AppInstallationIdentityStore(
          vault: vault,
          idFactory: () => 'invalid',
        );

        await expectLater(store.getOrCreate(), throwsStateError);

        expect(vault.values[AppInstallationIdentityStore.installIdKey], isNull);
      },
    );
  });

  group('AccountCreationGateContract', () {
    test('keeps server-only collections and required fields explicit', () {
      expect(
        AccountCreationGateContract.requiredRequestFields,
        containsAll(['appInstallationHash', 'providerId', 'appCheckVerified']),
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

class _DelayedInstallationVault extends _MemoryInstallationVault {
  @override
  Future<String?> read(String key) async {
    await Future<void>.delayed(Duration.zero);
    return super.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    await super.write(key, value);
  }
}
