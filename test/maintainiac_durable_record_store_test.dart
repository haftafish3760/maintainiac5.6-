import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  test('shared confirmed records save, delete, and restore locally', () async {
    final store = MaintainiacDurableRecordStore.memory();
    final created = DateTime.utc(2026, 7, 15, 12);
    final saved = await store.save(
      module: 'maintenance',
      id: 'record-1',
      payload: const {'title': 'Oil'},
      now: created,
    );
    final deleted = await store.delete(
      'maintenance',
      'record-1',
      now: created.add(const Duration(minutes: 1)),
    );
    final restored = await store.restore(
      'maintenance',
      'record-1',
      now: created.add(const Duration(minutes: 2)),
    );
    expect(saved.lifecycle.revision, 1);
    expect(deleted?.lifecycle.isDeleted, isTrue);
    expect(restored?.lifecycle.isActive, isTrue);
    expect(store.recordsFor('maintenance'), hasLength(1));
  });

  test(
    'shared confirmed records never claim a write when storage is full',
    () async {
      final store = MaintainiacDurableRecordStore.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: 1,
          requiredBytes: 2,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      await expectLater(
        () => store.save(
          module: 'maintenance',
          id: 'record-1',
          payload: const {},
        ),
        throwsStateError,
      );
      expect(store.recordFor('maintenance', 'record-1'), isNull);
    },
  );

  test('shared confirmed records isolate nested payloads from callers', () {
    final nested = <String, dynamic>{'amount': 10};
    final record = MaintainiacDurableRecord(
      module: 'expenses',
      id: 'record-1',
      payload: {'line': nested},
      lifecycle: MaintainiacRecordLifecycle(
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );

    nested['amount'] = 20;

    expect((record.payload['line'] as Map)['amount'], 10);
    expect(
      () => (record.payload['line'] as Map)['amount'] = 30,
      throwsUnsupportedError,
    );
  });

  test('corrupt durable lifecycle dates are rejected during recovery', () {
    expect(
      () => MaintainiacDurableRecord.fromMap({
        'module': 'expenses',
        'id': 'record-1',
        'payload': const {},
        'lifecycle': {'updatedAt': '2026-07-15T00:00:00.000Z', 'revision': 1},
      }),
      throwsFormatException,
    );
  });

  test(
    'confirmed records acknowledge only the matching draft checkpoint',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      final drafts = MaintainiacRecordDraftStore.memory();
      final checkpoint = await drafts.save(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Local draft'},
        now: DateTime.utc(2026, 7, 15),
      );

      final saved = await records.saveAndAcknowledgeDraft(
        module: 'expenses',
        id: 'receipt-1',
        payload: const {'merchant': 'Confirmed receipt'},
        draftStore: drafts,
        expectedDraftUpdatedAt: checkpoint.lifecycle.updatedAt,
        now: DateTime.utc(2026, 7, 15, 1),
      );

      expect(saved.payload['merchant'], 'Confirmed receipt');
      expect(drafts.draftFor('expenses', 'receipt-1'), isNull);
    },
  );
}
