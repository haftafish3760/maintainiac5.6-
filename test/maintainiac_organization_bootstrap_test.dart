import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/app_installation_identity.dart';
import 'package:maintaniac/shared/firebase/maintainiac_callable_functions.dart';
import 'package:maintaniac/shared/firebase/maintainiac_organization_bootstrap.dart';

void main() {
  const uid = 'firebase-user-1';
  final installationHash = sha256
      .convert(utf8.encode(_installationId))
      .toString();

  test('uses an opaque deterministic workspace ID', () {
    final first = MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(
      uid,
    );
    final second =
        MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid);

    expect(first, second);
    expect(first, startsWith('personal_'));
    expect(first, isNot(contains(uid)));
  });

  test('delegates the whole atomic bootstrap to one callable', () async {
    final expectedId =
        MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid);
    final client = _RecordingCallableClient({
      'organizationId': expectedId,
      'ownerUid': uid,
      'planId': 'freeConfigurable',
      'installationHash': installationHash,
    });
    final bootstrapper = MaintainiacOrganizationBootstrapper(
      gateway: _callableGateway(client),
    );

    final workspace = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: uid,
    );
    final cached = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: uid,
    );

    expect(client.names, ['requestHostedAccountCreation']);
    expect(client.payloads.single['appInstallationHash'], installationHash);
    expect(identical(cached, workspace), isTrue);
    expect(workspace.organizationId, expectedId);
    expect(workspace.ownerUid, uid);
    expect(workspace.planId, 'freeConfigurable');
  });

  test('fails closed when the server returns another workspace identity', () {
    final client = _RecordingCallableClient({
      'organizationId': 'personal_wrong',
      'ownerUid': uid,
      'installationHash': installationHash,
    });
    final gateway = _callableGateway(client);

    expect(
      gateway.ensurePersonalWorkspace(authenticatedUid: uid),
      throwsA(isA<FormatException>()),
    );
  });

  test('fails closed when the server returns an unsafe plan identity', () {
    final expectedId =
        MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(uid);
    final gateway = CallableMaintainiacOrganizationBootstrapGateway(
      client: _RecordingCallableClient({
        'organizationId': expectedId,
        'ownerUid': uid,
        'planId': '../another-plan',
        'installationHash': installationHash,
      }),
      installationIdentityStore: _installationStore(),
    );

    expect(
      gateway.ensurePersonalWorkspace(authenticatedUid: uid),
      throwsA(isA<FormatException>()),
    );
  });

  test('does not cache a failed bootstrap attempt', () async {
    final gateway = _RetryGateway();
    final bootstrapper = MaintainiacOrganizationBootstrapper(gateway: gateway);

    await expectLater(
      bootstrapper.ensurePersonalWorkspace(authenticatedUid: uid),
      throwsStateError,
    );
    final workspace = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: uid,
    );

    expect(gateway.attempts, 2);
    expect(workspace.ownerUid, uid);
  });

  test(
    'coalesces concurrent bootstrap requests for the same account',
    () async {
      final gateway = _DelayedGateway();
      final bootstrapper = MaintainiacOrganizationBootstrapper(
        gateway: gateway,
      );

      final first = bootstrapper.ensurePersonalWorkspace(authenticatedUid: uid);
      final second = bootstrapper.ensurePersonalWorkspace(
        authenticatedUid: uid,
      );
      gateway.release.complete();
      final workspaces = await Future.wait([first, second]);

      expect(gateway.attempts, 1);
      expect(identical(workspaces.first, workspaces.last), isTrue);
    },
  );
}

const _installationId =
    'mai_install_abcdefghijklmnopqrstuvwxyzABCDEFGH12345678';

CallableMaintainiacOrganizationBootstrapGateway _callableGateway(
  MaintainiacCallableFunctionClient client,
) => CallableMaintainiacOrganizationBootstrapGateway(
  client: client,
  installationIdentityStore: _installationStore(),
);

AppInstallationIdentityStore _installationStore() =>
    AppInstallationIdentityStore(
      vault: _MemoryIdentityVault(),
      now: () => DateTime.utc(2026, 8, 1),
      idFactory: () => _installationId,
    );

class _MemoryIdentityVault implements InstallationIdentityVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _RecordingCallableClient implements MaintainiacCallableFunctionClient {
  _RecordingCallableClient(this.response);

  final Map<String, Object?> response;
  final names = <String>[];
  final payloads = <Map<String, Object?>>[];

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    names.add(name);
    payloads.add(data);
    return response;
  }
}

class _RetryGateway implements MaintainiacOrganizationBootstrapGateway {
  var attempts = 0;

  @override
  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
  }) async {
    attempts += 1;
    if (attempts == 1) throw StateError('transient failure');
    return MaintainiacOrganizationWorkspace(
      organizationId:
          MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(
            authenticatedUid,
          ),
      ownerUid: authenticatedUid,
    );
  }
}

class _DelayedGateway implements MaintainiacOrganizationBootstrapGateway {
  final release = Completer<void>();
  var attempts = 0;

  @override
  Future<MaintainiacOrganizationWorkspace> ensurePersonalWorkspace({
    required String authenticatedUid,
  }) async {
    attempts += 1;
    await release.future;
    return MaintainiacOrganizationWorkspace(
      organizationId:
          MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(
            authenticatedUid,
          ),
      ownerUid: authenticatedUid,
    );
  }
}
