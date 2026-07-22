import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'vehicle_tire_configuration_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test('vehicle tire context persists across an app restart', () async {
    final first = await AppStateController.create();
    final vehicle = VehicleProfile(
      id: 'vehicle-tire-context',
      nickname: 'Cargo van',
      tireSizeStatus: VehicleTireSizeStatus.largerThanRecommended,
      speedometerCalibrationStatus:
          VehicleSpeedometerCalibrationStatus.notCalibratedForCurrentTires,
      tireConfigurationRevision: 3,
      tireConfigurationUpdatedAt: DateTime.utc(2026, 7, 20, 12),
    );
    await first.addVehicle(vehicle);
    await first.selectVehicle(vehicle);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = await AppStateController.create();

    expect(
      restored.activeVehicle?.tireSizeStatus,
      VehicleTireSizeStatus.largerThanRecommended,
    );
    expect(
      restored.activeVehicle?.speedometerCalibrationStatus,
      VehicleSpeedometerCalibrationStatus.notCalibratedForCurrentTires,
    );
    expect(restored.activeVehicle?.tireConfigurationRevision, 3);
    expect(
      restored.activeVehicle?.tireConfigurationUpdatedAt,
      DateTime.utc(2026, 7, 20, 12),
    );
  });

  test('legacy vehicle maps fail safely to unknown tire context', () {
    final restored = VehicleProfile.fromMap({
      'id': 'legacy-vehicle',
      'nickname': 'Legacy truck',
      'tireConfigurationRevision': -4,
    });

    expect(restored.tireSizeStatus, VehicleTireSizeStatus.unknown);
    expect(
      restored.speedometerCalibrationStatus,
      VehicleSpeedometerCalibrationStatus.unknown,
    );
    expect(restored.tireConfigurationRevision, 0);
    expect(restored.tireConfigurationUpdatedAt, isNull);
  });
}
