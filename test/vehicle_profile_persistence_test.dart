import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'vehicle_profile_persistence_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test(
    'vehicle IDs and selected vehicle persist across an app restart',
    () async {
      final first = await AppStateController.create();
      final vehicle = VehicleProfile(
        id: 'vehicle-keep',
        nickname: 'Cargo van',
        year: '2024',
        make: 'Ford',
        model: 'Transit',
      );
      await first.addVehicle(vehicle);
      await first.selectVehicle(vehicle);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await AppStateController.create();

      expect(
        restored.vehicles.any((item) => item.id == 'vehicle-keep'),
        isTrue,
      );
      expect(restored.activeVehicle?.id, 'vehicle-keep');
    },
  );

  test(
    'cannot select an unknown or archived vehicle as the active context',
    () async {
      final appState = await AppStateController.create();
      final originalId = appState.activeVehicle!.id;

      await appState.selectVehicle(
        VehicleProfile(id: 'unknown', nickname: 'Unknown vehicle'),
      );
      expect(appState.activeVehicle?.id, originalId);

      final vehicle = VehicleProfile(id: 'archived', nickname: 'Old van');
      await appState.addVehicle(vehicle);
      await appState.deleteVehicle(vehicle.id);
      await appState.selectVehicle(vehicle);

      expect(appState.activeVehicle?.id, originalId);
    },
  );

  test('all-vehicles scope persists across an app restart', () async {
    final first = await AppStateController.create();
    await first.selectCompanyScope();
    expect(first.activeVehicle, isNull);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = await AppStateController.create();

    expect(restored.activeVehicle, isNull);
    expect(restored.vehicles, isNotEmpty);
  });

  test('queued vehicle selections retain the last requested context', () async {
    final appState = await AppStateController.create();
    final first = VehicleProfile(id: 'queued-first', nickname: 'First van');
    final second = VehicleProfile(id: 'queued-second', nickname: 'Second van');
    await appState.addVehicle(first);
    await appState.addVehicle(second);

    await Future.wait([
      appState.selectVehicle(first),
      appState.selectVehicle(second),
    ]);

    expect(appState.activeVehicle?.id, second.id);
  });

  test(
    'an archived-only vehicle snapshot restores without an active vehicle',
    () async {
      final box = await Hive.openBox<dynamic>(
        AppStateController.vehicleBoxName,
      );
      await box.put('snapshot', {
        'vehicles': [
          VehicleProfile(
            id: 'archived-only',
            nickname: 'Retired van',
            archivedAt: DateTime.utc(2026, 7, 15),
          ).toMap(),
        ],
        'activeVehicleId': 'archived-only',
      });

      final restored = await AppStateController.create();

      expect(restored.vehicles, isEmpty);
      expect(restored.activeVehicle, isNull);
      expect(restored.vehicleById('archived-only')?.isArchived, isTrue);
    },
  );

  test('rejects duplicate stable vehicle IDs', () async {
    final appState = await AppStateController.create();
    final vehicle = VehicleProfile(id: 'vehicle-duplicate', nickname: 'Van');
    await appState.addVehicle(vehicle);

    await expectLater(
      () => appState.addVehicle(
        VehicleProfile(id: vehicle.id, nickname: 'Different label'),
      ),
      throwsArgumentError,
    );
    expect(
      appState.allVehicles.where((item) => item.id == vehicle.id),
      hasLength(1),
    );
  });

  test(
    'does not claim a vehicle profile was saved when storage is full',
    () async {
      var canWrite = true;
      final appState = await AppStateController.create(
        storageCheck: () async => AppStorageCheck(
          availableBytes: canWrite
              ? AppStorageGuard.smallRecordWriteBytes * 2
              : 0,
          operationBytes: AppStorageGuard.smallRecordWriteBytes,
          requiredBytes: AppStorageGuard.smallRecordWriteBytes,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      canWrite = false;

      await expectLater(
        () => appState.addVehicle(
          VehicleProfile(id: 'no-space', nickname: 'No-space van'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(appState.vehicleById('no-space'), isNull);
    },
  );

  test(
    'deleting the active vehicle archives its historical identity',
    () async {
      final first = await AppStateController.create();
      final vehicle = VehicleProfile(
        id: 'vehicle-delete',
        nickname: 'Old van',
        year: '2016',
        make: 'Ford',
        model: 'Transit',
      );
      await first.addVehicle(vehicle);
      await first.selectVehicle(vehicle);

      await first.deleteVehicle(vehicle.id);
      final remainingId = first.activeVehicle!.id;
      expect(first.vehicles.any((item) => item.id == vehicle.id), isFalse);
      expect(first.vehicleById(vehicle.id)?.isArchived, isTrue);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await AppStateController.create();

      expect(restored.vehicles.any((item) => item.id == vehicle.id), isFalse);
      expect(restored.vehicleById(vehicle.id)?.isArchived, isTrue);
      expect(restored.activeVehicle?.id, remainingId);
    },
  );

  test('a historical receipt retains its archived vehicle identity', () async {
    final appState = await AppStateController.create();
    final vehicle = VehicleProfile(
      id: 'vehicle-history',
      nickname: 'Old van',
      year: '2016',
      make: 'Ford',
      model: 'Transit',
    );
    await appState.addVehicle(vehicle);
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'vehicle-history-receipt',
        receiptDate: DateTime.utc(2026, 7, 15),
        vehicleId: vehicle.id,
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'vehicle-history-line',
            description: 'Parking',
            category: 'Parking',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
    );
    await appState.deleteVehicle(vehicle.id);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restoredAppState = await AppStateController.create();
    final restoredLedger = await ExpenseLedgerController.create();

    expect(
      restoredLedger.receiptById('vehicle-history-receipt')?.vehicleId,
      vehicle.id,
    );
    expect(restoredAppState.vehicleById(vehicle.id)?.isArchived, isTrue);
  });
}
