import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/app_state.dart';

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
    'deleting the active vehicle persists a remaining active vehicle',
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

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await AppStateController.create();

      expect(restored.vehicles.any((item) => item.id == vehicle.id), isFalse);
      expect(restored.activeVehicle?.id, remainingId);

    },
  );
}
