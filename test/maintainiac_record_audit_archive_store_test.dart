import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/records/maintainiac_record_audit_archive_store.dart';

void main() {
  test(
    'durable saves preserve append-only local audit evidence first',
    () async {
      final archive = MaintainiacRecordAuditArchiveStore.memory();
      final records = MaintainiacDurableRecordStore.memory(
        auditArchive: archive,
      );

      await records.save(
        module: 'expenses',
        id: 'expense-1',
        payload: const {'totalCents': 1200},
        now: DateTime.utc(2026, 8, 1),
      );
      await records.save(
        module: 'expenses',
        id: 'expense-1',
        payload: const {'totalCents': 1300},
        now: DateTime.utc(2026, 8, 1, 0, 1),
      );

      final entries = archive.entriesFor('expenses', 'expense-1');
      expect(entries, hasLength(2));
      expect(entries.map((entry) => entry.ordinal), [1, 2]);
      expect(entries.last.previousEntrySha256, entries.first.entrySha256);
    },
  );

  test('conflicting preserved audit evidence fails without deletion', () async {
    final archive = MaintainiacRecordAuditArchiveStore.memory();
    await archive.preserveLifecycle(
      module: 'expenses',
      id: 'expense-1',
      lifecycle: (await MaintainiacDurableRecordStore.memory().save(
        module: 'expenses',
        id: 'expense-1',
        payload: const {'totalCents': 1200},
        now: DateTime.utc(2026, 8, 1),
      )).lifecycle,
    );

    await expectLater(
      archive.preserveLifecycle(
        module: 'expenses',
        id: 'expense-1',
        lifecycle: (await MaintainiacDurableRecordStore.memory().save(
          module: 'expenses',
          id: 'expense-1',
          payload: const {'totalCents': 1300},
          now: DateTime.utc(2026, 8, 1, 0, 1),
        )).lifecycle,
      ),
      throwsStateError,
    );
    expect(archive.entriesFor('expenses', 'expense-1'), hasLength(1));
  });
}
