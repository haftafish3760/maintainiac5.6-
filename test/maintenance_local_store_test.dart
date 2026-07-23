import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/maintenance/maintenance_local_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;
  late Box<dynamic> box;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_local_store_test_',
    );
    Hive.init(hiveDirectory.path);
    box = await Hive.openBox<dynamic>(MaintenanceLocalStore.boxName);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('writes and restores a versioned finalized snapshot', () async {
    final store = MaintenanceLocalStore(box: box, storageCheck: _enoughStorage);
    final snapshot = MaintenanceLocalSnapshot(
      schemaVersion: MaintenanceLocalSnapshot.currentSchemaVersion,
      records: const [
        {
          'recordId': 'maintenance_record_1',
          'vehicleId': 'vehicle_1',
          'itemName': 'Engine Oil',
        },
      ],
      events: const [
        {
          'eventId': 'maintenance_event_1',
          'vehicleId': 'vehicle_1',
          'itemName': 'Engine Oil',
        },
      ],
      updatedAt: DateTime.utc(2026, 7, 23),
    );

    await store.write(snapshot);
    await Hive.close();
    Hive.init(hiveDirectory.path);
    box = await Hive.openBox<dynamic>(MaintenanceLocalStore.boxName);

    final restored = await MaintenanceLocalStore(
      box: box,
      storageCheck: _enoughStorage,
    ).read();

    expect(restored.snapshot.schemaVersion, 1);
    expect(restored.snapshot.records.single['vehicleId'], 'vehicle_1');
    expect(restored.snapshot.events.single['eventId'], 'maintenance_event_1');
    expect(restored.recoveredFromBackup, isFalse);
  });

  test(
    'recovers the last-known-good snapshot from a corrupt primary',
    () async {
      final store = MaintenanceLocalStore(
        box: box,
        storageCheck: _enoughStorage,
      );
      await store.write(_snapshot('first'));
      await store.write(_snapshot('second'));
      await box.put(MaintenanceLocalStore.primaryKey, {
        'schemaVersion': 999,
        'records': 'invalid',
      });

      final restored = await store.read();

      expect(restored.recoveredFromBackup, isTrue);
      expect(restored.primaryWasInvalid, isTrue);
      expect(restored.snapshot.records.single['recordId'], 'first');
    },
  );

  test('serializes racing writes and preserves the newest snapshot', () async {
    final store = MaintenanceLocalStore(box: box, storageCheck: _enoughStorage);

    await Future.wait([
      store.write(_snapshot('first')),
      store.write(_snapshot('second')),
      store.write(_snapshot('third')),
    ]);

    final restored = await store.read();
    expect(restored.snapshot.records.single['recordId'], 'third');
  });

  test(
    'does not replace local truth when storage cannot safely write',
    () async {
      final store = MaintenanceLocalStore(
        box: box,
        storageCheck: _enoughStorage,
      );
      await store.write(_snapshot('saved'));
      final blocked = MaintenanceLocalStore(
        box: box,
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 1,
          operationBytes: 1024 * 1024,
          requiredBytes: 26 * 1024 * 1024,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );

      await expectLater(
        blocked.write(_snapshot('not-saved')),
        throwsA(isA<StateError>()),
      );

      final restored = await store.read();
      expect(restored.snapshot.records.single['recordId'], 'saved');
    },
  );

  test('rejects unsupported write schema versions', () async {
    final store = MaintenanceLocalStore(box: box, storageCheck: _enoughStorage);

    expect(
      () => store.write(
        MaintenanceLocalSnapshot(
          schemaVersion: 2,
          records: const [],
          events: const [],
          updatedAt: DateTime.utc(2026, 7, 23),
        ),
      ),
      throwsArgumentError,
    );
  });
}

MaintenanceLocalSnapshot _snapshot(String id) => MaintenanceLocalSnapshot(
  schemaVersion: MaintenanceLocalSnapshot.currentSchemaVersion,
  records: [
    {'recordId': id, 'vehicleId': 'vehicle_1', 'itemName': 'Engine Oil'},
  ],
  events: const [],
  updatedAt: DateTime.utc(2026, 7, 23),
);

Future<AppStorageCheck> _enoughStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);
