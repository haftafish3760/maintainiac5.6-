import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_callable_functions.dart';
import 'package:maintaniac/shared/firebase/maintainiac_organization_bootstrap.dart';

void main() {
  const uid = 'firebase-user-1';

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
    });
    final bootstrapper = MaintainiacOrganizationBootstrapper(
      gateway: CallableMaintainiacOrganizationBootstrapGateway(client: client),
    );

    final workspace = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: uid,
    );
    final cached = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: uid,
    );

    expect(client.names, ['bootstrapPersonalWorkspace']);
    expect(client.payloads, [isEmpty]);
    expect(identical(cached, workspace), isTrue);
    expect(workspace.organizationId, expectedId);
    expect(workspace.ownerUid, uid);
    expect(workspace.planId, 'freeConfigurable');
  });

  test('fails closed when the server returns another workspace identity', () {
    final client = _RecordingCallableClient({
      'organizationId': 'personal_wrong',
      'ownerUid': uid,
    });
    final gateway = CallableMaintainiacOrganizationBootstrapGateway(
      client: client,
    );

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
      }),
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
