import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_organization_bootstrap.dart';

void main() {
  test('uses an opaque deterministic workspace ID', () {
    final first = MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(
      'firebase-user-1',
    );
    final second =
        MaintainiacOrganizationBootstrapper.personalOrganizationIdFor(
          'firebase-user-1',
        );

    expect(first, second);
    expect(first, startsWith('personal_'));
    expect(first, isNot(contains('firebase-user-1')));
  });

  test('creates only the owner workspace and member enrollment', () async {
    final writer = _RecordingWriter();
    final bootstrapper = MaintainiacOrganizationBootstrapper(writer: writer);

    final workspace = await bootstrapper.ensurePersonalWorkspace(
      authenticatedUid: 'firebase-user-1',
      nowUtc: DateTime.utc(2026, 7, 15, 12),
    );

    expect(writer.documents, hasLength(2));
    expect(writer.documents.keys.first, 'orgs/${workspace.organizationId}');
    final memberPath =
        'orgs/${workspace.organizationId}/members/firebase-user-1';
    expect(writer.documents, contains(memberPath));
    final member = writer.documents[memberPath]!;
    expect(member['role'], 'owner');
    expect(member['status'], 'active');
    expect(member['allowedModules'], contains('expenses'));
  });
}

class _RecordingWriter implements MaintainiacOrganizationBootstrapWriter {
  final documents = <String, Map<String, Object?>>{};

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {
    documents[path] = data;
  }
}
