import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
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
}
