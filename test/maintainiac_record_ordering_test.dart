import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_lifecycle.dart';
import 'package:maintaniac/shared/records/maintainiac_record_ordering.dart';

void main() {
  test(
    'equal-time confirmed records recover in stable identifier order',
    () async {
      final store = MaintainiacDurableRecordStore.memory();
      final now = DateTime.utc(2026, 7, 22, 12);

      await store.save(
        module: 'expenses',
        id: 'record-b',
        payload: {},
        now: now,
      );
      await store.save(
        module: 'expenses',
        id: 'record-a',
        payload: {},
        now: now,
      );

      expect(store.recordsFor('expenses').map((record) => record.id), [
        'record-a',
        'record-b',
      ]);
    },
  );

  test('equal-time drafts recover in stable identifier order', () async {
    final store = MaintainiacRecordDraftStore.memory();
    final now = DateTime.utc(2026, 7, 22, 12);

    await store.save(module: 'invoices', id: 'draft-b', payload: {}, now: now);
    await store.save(module: 'invoices', id: 'draft-a', payload: {}, now: now);

    expect(store.draftsFor('invoices').map((draft) => draft.id), [
      'draft-a',
      'draft-b',
    ]);
  });

  test('revision is the deterministic tie-breaker before identifier', () {
    final now = DateTime.utc(2026, 7, 22, 12);

    expect(
      compareMaintainiacRecordsNewestFirst(
        leftUpdatedAt: now,
        leftRevision: 9,
        leftId: 'record-z',
        rightUpdatedAt: now,
        rightRevision: 8,
        rightId: 'record-a',
      ),
      lessThan(0),
    );
  });
}
