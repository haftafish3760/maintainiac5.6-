// Regression coverage for the shared durable vehicle-profile snapshot bridge.
//
// Owns round-trip, revision, active-selection, and fail-closed validation.
// It does not test AppStateController, vehicle UI, odometers, or cloud backup.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/state/vehicle_profile_durable_record_bridge.dart';

void main() {
  test('round-trips complete confirmed vehicle snapshot', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final bridge = VehicleProfileDurableRecordBridge(records);
    final snapshot = VehicleProfileDurableSnapshot(
      vehicles: [
        _vehicle('vehicle-1', 'Work Truck'),
        _vehicle('vehicle-2', 'Delivery Van'),
      ],
      activeVehicleId: 'vehicle-2',
    );

    await bridge.save(snapshot, now: DateTime.utc(2026, 7, 29, 1));
    final restored = bridge.load();

    expect(restored?.vehicles, hasLength(2));
    expect(restored?.activeVehicleId, 'vehicle-2');
    expect(restored?.vehicles.last['usage'], 'businessPersonal');
    expect(restored?.vehicles.last['tireConfigurationRevision'], 3);
  });

  test('repeated save advances one shared record revision', () async {
    final records = MaintainiacDurableRecordStore.memory();
    final bridge = VehicleProfileDurableRecordBridge(records);
    final first = VehicleProfileDurableSnapshot(
      vehicles: [_vehicle('vehicle-1', 'Work Truck')],
      activeVehicleId: 'vehicle-1',
    );
    await bridge.save(first, now: DateTime.utc(2026, 7, 29, 1));
    await bridge.save(
      VehicleProfileDurableSnapshot(
        vehicles: [_vehicle('vehicle-1', 'Renamed Truck')],
        activeVehicleId: 'vehicle-1',
      ),
      now: DateTime.utc(2026, 7, 29, 2),
    );

    expect(
      records
          .recordFor(
            VehicleProfileDurableRecordBridge.recordModule,
            VehicleProfileDurableRecordBridge.recordId,
          )
          ?.lifecycle
          .revision,
      2,
    );
    expect(bridge.load()?.vehicles.single['nickname'], 'Renamed Truck');
  });

  test('rejects duplicate IDs and archived active selection', () async {
    final bridge = VehicleProfileDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );
    final duplicate = VehicleProfileDurableSnapshot(
      vehicles: [
        _vehicle('vehicle-1', 'Truck'),
        _vehicle('vehicle-1', 'Duplicate'),
      ],
      activeVehicleId: 'vehicle-1',
    );
    final archivedActive = VehicleProfileDurableSnapshot(
      vehicles: [
        {..._vehicle('vehicle-1', 'Truck'), 'archivedAt': '2026-07-29T01:00:00Z'},
      ],
      activeVehicleId: 'vehicle-1',
    );

    expect(() => bridge.save(duplicate), throwsArgumentError);
    expect(() => bridge.save(archivedActive), throwsArgumentError);
  });

  test('corrupt durable payload fails closed', () async {
    final records = MaintainiacDurableRecordStore.memory();
    await records.save(
      module: VehicleProfileDurableRecordBridge.recordModule,
      id: VehicleProfileDurableRecordBridge.recordId,
      payload: {
        'schemaVersion': 1,
        'vehicles': [
          {'id': '../unsafe', 'nickname': 'Unsafe'},
        ],
        'activeVehicleId': '../unsafe',
      },
    );

    expect(VehicleProfileDurableRecordBridge(records).load(), isNull);
  });
}

Map<String, dynamic> _vehicle(String id, String nickname) => {
  'id': id,
  'nickname': nickname,
  'year': '2024',
  'make': 'Maintainiac',
  'model': 'Test',
  'usage': 'businessPersonal',
  'tireSizeStatus': 'factoryEquivalent',
  'speedometerCalibrationStatus': 'calibratedForCurrentTires',
  'tireConfigurationRevision': 3,
  'tireConfigurationUpdatedAt': '2026-07-29T00:00:00Z',
  'archivedAt': null,
};
