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

  test('corrupt shared draft maps are rejected instead of recreated', () {
    expect(
      () => MaintainiacRecordDraft.fromMap({
        'module': 'expenses',
        'id': 'corrupt-draft',
        'payload': const {},
        'lifecycle': {
          'createdAt': '2026-07-15T12:00:00.000Z',
          'updatedAt': '2026-07-15T12:00:00.000Z',
          'revision': 1,
          'state': 'deleted',
        },
      }),
      throwsFormatException,
    );
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

  test('shared draft snapshots deep-copy nested form values', () {
    final line = <String, dynamic>{'total': 18.75};
    final lines = <Map<String, dynamic>>[line];
    final draft = MaintainiacRecordDraft(
      module: 'expenses',
      id: 'draft-nested-immutable',
      payload: {'lines': lines},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 15, 12),
        updatedAt: DateTime.utc(2026, 7, 15, 12),
      ),
    );

    line['total'] = 99.99;
    lines.add({'total': 4.50});
    final frozenLines = draft.payload['lines'] as List<dynamic>;
    final frozenLine = frozenLines.single as Map<dynamic, dynamic>;

    expect(frozenLine['total'], 18.75);
    expect(frozenLines, hasLength(1));
    expect(() => frozenLines.add({}), throwsUnsupportedError);
    expect(() => frozenLine['total'] = 99.99, throwsUnsupportedError);
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

  test(
    'shared draft store retains the newer checkpoint on delayed writes',
    () async {
      final store = MaintainiacRecordDraftStore.memory();
      final time = DateTime.utc(2026, 7, 15, 12);
      await Future.wait([
        store.save(
          module: 'expenses',
          id: 'draft-order',
          payload: const {'merchant': 'Newest'},
          now: time.add(const Duration(seconds: 1)),
        ),
        store.save(
          module: 'expenses',
          id: 'draft-order',
          payload: const {'merchant': 'Stale'},
          now: time,
        ),
      ]);

      expect(
        store.draftFor('expenses', 'draft-order')?.payload['merchant'],
        'Newest',
      );
    },
  );

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

  test('confirmed save cannot remove a newer draft checkpoint', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final created = DateTime.utc(2026, 7, 15, 12);
    final confirmedCheckpoint = await store.save(
      module: 'expenses',
      id: 'draft-confirmed-save',
      payload: const {'merchant': 'Before confirmation'},
      now: created,
    );
    await store.save(
      module: 'expenses',
      id: 'draft-confirmed-save',
      payload: const {'merchant': 'Newer local edit'},
      now: created.add(const Duration(seconds: 1)),
    );

    final deleted = await store.removeIfUnchanged(
      module: 'expenses',
      id: 'draft-confirmed-save',
      expectedUpdatedAt: confirmedCheckpoint.lifecycle.updatedAt,
    );

    expect(deleted, isFalse);
    expect(
      store.draftFor('expenses', 'draft-confirmed-save')?.payload['merchant'],
      'Newer local edit',
    );
  });

  test('shared draft store rejects ambiguous durable keys', () async {
    final store = MaintainiacRecordDraftStore.memory();
    await store.save(module: 'expenses', id: 'draft-safe', payload: const {});

    await expectLater(
      () => store.save(module: '', id: 'draft', payload: const {}),
      throwsArgumentError,
    );
    await expectLater(
      () => store.save(module: 'expenses', id: 'draft:1', payload: const {}),
      throwsArgumentError,
    );
    await expectLater(
      () => store.save(module: ' expenses', id: 'draft-1', payload: const {}),
      throwsArgumentError,
    );
    await store.remove('expenses:other', 'draft-safe');
    expect(store.draftFor('expenses', 'draft-safe'), isNotNull);
    expect(store.draftFor('expenses:other', 'draft-safe'), isNull);
    expect(store.draftsFor('expenses:other'), isEmpty);
  });
}
