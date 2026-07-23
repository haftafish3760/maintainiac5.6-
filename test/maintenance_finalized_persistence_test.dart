import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/maintenance/maintenance_local_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'maintenance_finalized_persistence_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('finalized setup and service history survive app restart', () async {
    final first = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    final vehicle = first.activeVehicle!;

    await first.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 7500,
        milesSinceService: 1200,
        intervalMonths: 6,
        monthsSinceService: 2,
        importance: 100,
        detailA: 'Full Synthetic',
        detailB: '5W-30',
        setupComplete: true,
      ),
    ]);
    await first.logMaintenanceService(
      MaintenanceServiceEvent(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        serviceDate: DateTime.utc(2026, 7, 23),
        odometer: 101250,
        provider: 'Owner',
        totalCost: 51.34,
        receiptProofCount: 1,
      ),
    );
    final recordId = first.maintenance.single.recordId;
    final eventId = first.maintenanceEvents.single.eventId;
    expect(recordId, isNotEmpty);
    expect(eventId, isNotEmpty);
    first.dispose();

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );

    expect(restored.maintenance, hasLength(1));
    expect(restored.maintenanceEvents, hasLength(1));
    final record = restored.maintenance.single;
    final event = restored.maintenanceEvents.single;
    expect(record.recordId, recordId);
    expect(record.vehicleId, vehicle.id);
    expect(record.detailA, 'Full Synthetic');
    expect(record.detailB, '5W-30');
    expect(record.lastServiceDate, DateTime.utc(2026, 7, 23));
    expect(record.lastServiceOdometer, 101250);
    expect(event.eventId, eventId);
    expect(event.vehicleId, vehicle.id);
    expect(event.totalCost, 51.34);
    expect(event.receiptProofCount, 1);
    restored.dispose();
  });

  test('duplicate service event id is idempotent', () async {
    final state = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    final vehicle = state.activeVehicle!;
    final event = MaintenanceServiceEvent(
      eventId: 'confirmed_service_1',
      itemName: 'Tire Rotation',
      vehicleId: vehicle.id,
      vehicleName: vehicle.nickname,
      serviceDate: DateTime.utc(2026, 7, 23),
      odometer: 101250,
    );

    await state.logMaintenanceService(event);
    await state.logMaintenanceService(event);

    expect(state.maintenanceEvents, hasLength(1));
    state.dispose();
  });

  test('legacy nickname record migrates to the stable vehicle id', () async {
    final box = await Hive.openBox<dynamic>(MaintenanceLocalStore.boxName);
    await box.put(MaintenanceLocalStore.primaryKey, {
      'schemaVersion': 1,
      'records': [
        {
          'itemName': 'Engine Oil',
          'vehicleName': 'Work Truck 1',
          'intervalMiles': 5000,
          'milesSinceService': 1000,
          'intervalMonths': 6,
          'monthsSinceService': 2,
          'importance': 100,
          'setupComplete': true,
        },
      ],
      'events': <Object?>[],
      'updatedAt': DateTime.utc(2026, 7, 23).toIso8601String(),
    });

    final restored = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );

    expect(restored.maintenance.single.vehicleId, 'vehicle_work_truck_1');
    expect(restored.maintenance.single.recordId, isNotEmpty);
    expect(
      restored.maintenance.single.belongsToVehicle(restored.activeVehicle!),
      isTrue,
    );
    restored.dispose();
  });

  test('failed durable write does not mutate in-memory maintenance', () async {
    final state = await AppStateController.create(
      maintenanceStorageCheck: _blockedStorage,
    );
    final vehicle = state.activeVehicle!;

    await expectLater(
      state.addMaintenanceRecords([
        MaintenanceRecord(
          itemName: 'Battery',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          intervalMiles: 0,
          milesSinceService: 0,
          intervalMonths: 48,
          monthsSinceService: 0,
          importance: 86,
          timeOnly: true,
        ),
      ]),
      throwsA(isA<StateError>()),
    );

    expect(state.maintenance, isEmpty);
    state.dispose();
  });

  test('app state reports and repairs backup recovery', () async {
    final first = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    final vehicle = first.activeVehicle!;
    await first.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 5000,
        milesSinceService: 0,
        intervalMonths: 6,
        monthsSinceService: 0,
        importance: 100,
      ),
    ]);
    await first.updateMaintenanceRecord(
      first.maintenance.single.copyWith(intervalMiles: 7500),
    );
    first.dispose();

    final box = Hive.box<dynamic>(MaintenanceLocalStore.boxName);
    await box.put(MaintenanceLocalStore.primaryKey, {
      'schemaVersion': 999,
      'records': 'corrupt',
    });
    await Hive.close();
    Hive.init(hiveDirectory.path);

    final recovered = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    expect(recovered.maintenanceRecoveredFromBackup, isTrue);
    expect(recovered.maintenancePrimaryWasInvalid, isTrue);
    expect(recovered.maintenance.single.intervalMiles, 5000);

    final repairedBox = Hive.box<dynamic>(MaintenanceLocalStore.boxName);
    expect(
      (repairedBox.get(MaintenanceLocalStore.primaryKey)
          as Map)['schemaVersion'],
      1,
    );
    recovered.dispose();
  });

  test('archive and restore survive restart without losing history', () async {
    final first = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    final vehicle = first.activeVehicle!;
    await first.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 5000,
        milesSinceService: 0,
        intervalMonths: 6,
        monthsSinceService: 0,
        importance: 100,
      ),
    ]);
    final recordId = first.maintenance.single.recordId;
    await first.logMaintenanceService(
      MaintenanceServiceEvent(
        eventId: 'archive_history_event',
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        serviceDate: DateTime.utc(2026, 7, 23),
        odometer: 101250,
      ),
    );
    expect(first.maintenanceEvents, hasLength(1));

    await first.archiveMaintenanceRecord(recordId);
    expect(first.maintenance, isEmpty);
    expect(first.allMaintenanceRecords.single.isArchived, isTrue);
    expect(first.maintenanceEvents, hasLength(1));
    first.dispose();

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final archived = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    expect(archived.maintenance, isEmpty);
    expect(archived.allMaintenanceRecords.single.recordId, recordId);
    expect(archived.allMaintenanceRecords.single.isArchived, isTrue);
    expect(archived.maintenanceEvents.single.eventId, 'archive_history_event');

    await archived.restoreMaintenanceRecord(recordId);
    expect(archived.maintenance.single.recordId, recordId);
    expect(archived.maintenance.single.isArchived, isFalse);
    archived.dispose();

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = await AppStateController.create(
      maintenanceStorageCheck: _enoughStorage,
    );
    expect(restored.maintenance.single.recordId, recordId);
    expect(restored.maintenanceEvents, hasLength(1));
    restored.dispose();
  });

  test(
    'adding an archived item restores its identity instead of duplicating',
    () async {
      final state = await AppStateController.create(
        maintenanceStorageCheck: _enoughStorage,
      );
      final vehicle = state.activeVehicle!;
      MaintenanceRecord oil() => MaintenanceRecord(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 5000,
        milesSinceService: 0,
        intervalMonths: 6,
        monthsSinceService: 0,
        importance: 100,
      );

      await state.addMaintenanceRecords([oil()]);
      final recordId = state.maintenance.single.recordId;
      await state.archiveMaintenanceRecord(recordId);
      await state.addMaintenanceRecords([oil()]);

      expect(state.allMaintenanceRecords, hasLength(1));
      expect(state.maintenance.single.recordId, recordId);
      expect(state.maintenance.single.isArchived, isFalse);
      state.dispose();
    },
  );

  test(
    'stable vehicle identity survives a vehicle rename and restart',
    () async {
      final first = await AppStateController.create(
        maintenanceStorageCheck: _enoughStorage,
      );
      final vehicle = first.activeVehicle!;
      await first.addMaintenanceRecords([
        MaintenanceRecord(
          itemName: 'Engine Oil',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          intervalMiles: 5000,
          milesSinceService: 1000,
          intervalMonths: 6,
          monthsSinceService: 2,
          importance: 100,
        ),
      ]);
      await first.logMaintenanceService(
        MaintenanceServiceEvent(
          eventId: 'rename_history_event',
          itemName: 'Engine Oil',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          serviceDate: DateTime.utc(2026, 7, 23),
          odometer: 101250,
        ),
      );

      const renamed = 'Primary Service Truck';
      await first.updateVehicle(vehicle.copyWith(nickname: renamed));
      expect(
        first.maintenanceVehicleName(
          vehicleId: vehicle.id,
          fallback: vehicle.nickname,
        ),
        renamed,
      );
      expect(first.maintenance.single.vehicleId, vehicle.id);
      expect(first.maintenanceEvents.single.vehicleId, vehicle.id);
      first.dispose();

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await AppStateController.create(
        maintenanceStorageCheck: _enoughStorage,
      );
      expect(restored.activeVehicle!.nickname, renamed);
      expect(restored.maintenance.single.vehicleId, vehicle.id);
      expect(restored.maintenance.single.vehicleName, renamed);
      expect(restored.maintenanceEvents.single.vehicleId, vehicle.id);
      expect(restored.maintenanceEvents.single.vehicleName, renamed);
      restored.dispose();
    },
  );
}

Future<AppStorageCheck> _enoughStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);

Future<AppStorageCheck> _blockedStorage() async => const AppStorageCheck(
  availableBytes: 1,
  operationBytes: 1024 * 1024,
  requiredBytes: 26 * 1024 * 1024,
  purpose: AppStoragePurpose.smallRecordWrite,
);
