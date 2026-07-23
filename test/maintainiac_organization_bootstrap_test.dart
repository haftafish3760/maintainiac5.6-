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
