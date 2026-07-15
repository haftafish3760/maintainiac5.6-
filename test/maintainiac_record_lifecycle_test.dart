import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('shared lifecycle preserves delete and restore history', () {
    final created = DateTime.utc(2026, 7, 15, 12);
    final deleted = created.add(const Duration(minutes: 1));
    final restored = deleted.add(const Duration(minutes: 1));
    final lifecycle =
        MaintainiacRecordLifecycle(createdAt: created, updatedAt: created)
            .deleted(deleted, event: 'removed record')
            .restored(restored, event: 'restored record');

    expect(lifecycle.state, MaintainiacRecordState.active);
    expect(lifecycle.deletedAt, isNull);
    expect(lifecycle.revision, 3);
    expect(lifecycle.auditEvents, hasLength(2));
  });

  test('shared lifecycle and draft snapshots cannot be mutated after save', () {
    final events = <String>['created'];
    final payload = <String, dynamic>{'merchant': 'Store'};
    final lifecycle = MaintainiacRecordLifecycle(
      createdAt: DateTime.utc(2026, 7, 15, 12),
      updatedAt: DateTime.utc(2026, 7, 15, 12),
      auditEvents: events,
    );
    final draft = MaintainiacRecordDraft(
      module: 'expenses',
      id: 'draft-immutable',
      payload: payload,
      lifecycle: lifecycle,
    );

    events.add('outside change');
    payload['total'] = 18.75;

    expect(lifecycle.auditEvents, ['created']);
    expect(draft.payload, {'merchant': 'Store'});
    expect(() => lifecycle.auditEvents.add('tamper'), throwsUnsupportedError);
    expect(() => draft.payload['total'] = 18.75, throwsUnsupportedError);
  });

  test('shared draft checkpoint saves every update locally', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final created = DateTime.utc(2026, 7, 15, 12);
    await store.save(
      module: 'expenses',
      id: 'draft-1',
      payload: const {'merchant': 'Store'},
      now: created,
    );
    final saved = await store.save(
      module: 'expenses',
      id: 'draft-1',
      payload: const {'merchant': 'Store', 'total': 18.75},
      now: created.add(const Duration(seconds: 1)),
    );

    expect(saved.lifecycle.revision, 2);
    expect(store.draftFor('expenses', 'draft-1')?.payload['total'], 18.75);
    expect(store.draftsFor('expenses'), hasLength(1));
  });

  test('shared draft store refuses an unsafe local write', () async {
    final store = MaintainiacRecordDraftStore.memory(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes: AppStorageGuard.smallRecordWriteBytes + 1,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(
      () => store.save(
        module: 'expenses',
        id: 'draft-no-space',
        payload: const {'merchant': 'Store'},
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.draftFor('expenses', 'draft-no-space'), isNull);
  });
}
