import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('generic cloud record round trips with account-bound hash', () {
    final record = MaintainiacDurableRecord(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark', 'weekStartsOn': 1},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22, 1),
        revision: 2,
      ),
    );
    final draft = MaintainiacFirestoreDurableRecordCodec.encode(
      organizationId: 'org-a',
      uid: 'user-a',
      accountScopeId: 'org-a.user-a',
      schemaVersion: 1,
      record: record,
    );
    final documentId = draft.path.split('/').last;
    final restored = MaintainiacFirestoreDurableRecordCodec.decode(
      expectedOrganizationId: 'org-a',
      expectedUid: 'user-a',
      expectedAccountScopeId: 'org-a.user-a',
      documentId: documentId,
      data: draft.data,
    );
    expect(restored.record.payload, record.payload);
    expect(restored.record.lifecycle.revision, 2);
    expect(
      MaintainiacRestoreApplier.contentSha256For(
        restored.record,
        accountScopeId: restored.accountScopeId,
      ),
      restored.contentSha256,
    );
  });

  test('generic codec rejects private or device-only payload fields', () {
    final record = MaintainiacDurableRecord(
      module: 'settings',
      id: 'settings-1',
      payload: const {'LoCaLpAtH': '/private/device/file'},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22),
      ),
    );
    expect(
      () => MaintainiacFirestoreDurableRecordCodec.encode(
        organizationId: 'org-a',
        uid: 'user-a',
        accountScopeId: 'org-a.user-a',
        schemaVersion: 1,
        record: record,
      ),
      throwsArgumentError,
    );
  });

  test('generic codec rejects a mismatched authenticated account scope', () {
    final record = MaintainiacDurableRecord(
      module: 'settings',
      id: 'settings-1',
      payload: const {'theme': 'dark'},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 22),
        updatedAt: DateTime.utc(2026, 7, 22),
      ),
    );

    expect(
      () => MaintainiacFirestoreDurableRecordCodec.encode(
        organizationId: 'org-a',
        uid: 'user-a',
        accountScopeId: 'org-a.user-b',
        schemaVersion: 1,
        record: record,
      ),
      throwsArgumentError,
    );
  });

  test('decode rejects account and document identity substitution', () {
    final draft = MaintainiacFirestoreDurableRecordCodec.encode(
      organizationId: 'org-a',
      uid: 'user-a',
      accountScopeId: 'org-a.user-a',
      schemaVersion: 1,
      record: MaintainiacDurableRecord(
        module: 'profiles',
        id: 'profile-1',
        payload: const {'nickname': 'Default'},
        lifecycle: MaintainiacRecordLifecycle(
          createdAt: DateTime.utc(2026, 7, 22),
          updatedAt: DateTime.utc(2026, 7, 22),
        ),
      ),
    );
    expect(
      () => MaintainiacFirestoreDurableRecordCodec.decode(
        expectedOrganizationId: 'org-a',
        expectedUid: 'user-b',
        expectedAccountScopeId: 'org-a.user-b',
        documentId: draft.path.split('/').last,
        data: draft.data,
      ),
      throwsFormatException,
    );
  });

  test('decode rejects cloud boundary drift before restore', () {
    final draft = MaintainiacFirestoreDurableRecordCodec.encode(
      organizationId: 'org-a',
      uid: 'user-a',
      accountScopeId: 'org-a.user-a',
      schemaVersion: 1,
      record: MaintainiacDurableRecord(
        module: 'settings',
        id: 'settings-1',
        payload: const {'theme': 'dark'},
        lifecycle: MaintainiacRecordLifecycle(
          createdAt: DateTime.utc(2026, 7, 22),
          updatedAt: DateTime.utc(2026, 7, 22),
        ),
      ),
    );
    final documentId = draft.path.split('/').last;
    final unsafe = <Map<String, Object?>>[
      {...draft.data, 'updatedByUid': 'user-b'},
      {...draft.data, 'privateToOwner': false},
      {...draft.data, 'recordSchemaVersion': 0},
      {...draft.data, 'contentSha256': 'f' * 64},
      {...draft.data, 'unexpectedField': true},
      {...draft.data}..remove('auditEvents'),
    ];
    for (final data in unsafe) {
      expect(
        () => MaintainiacFirestoreDurableRecordCodec.decode(
          expectedOrganizationId: 'org-a',
          expectedUid: 'user-a',
          expectedAccountScopeId: 'org-a.user-a',
          documentId: documentId,
          data: data,
        ),
        throwsFormatException,
      );
    }
  });
}
