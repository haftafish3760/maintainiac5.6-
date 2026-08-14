import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test('manual time-only service preserves an unknown odometer', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final vehicle = state.activeVehicle!;
    await state.addMaintenanceRecords([
      MaintenanceRecord(
        itemName: 'Registration',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        intervalMiles: 0,
        milesSinceService: 0,
        intervalMonths: 12,
        monthsSinceService: 0,
        importance: 98,
        timeOnly: true,
      ),
    ]);

    await state.logMaintenanceService(
      MaintenanceServiceEvent(
        itemName: 'Registration',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        serviceDate: DateTime(2026, 8, 13),
        odometer: 0,
      ),
    );

    final record = state.maintenance.single;
    expect(record.lastServiceOdometer, 0);
    expect(record.lastOdometerEstimated, isTrue);
    expect(record.lastServiceEstimated, isFalse);
  });

  test('atomic time-only service preserves an unknown odometer', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final vehicle = state.activeVehicle!;

    await state.applyMaintenanceTransaction(
      records: [
        MaintenanceRecord(
          itemName: 'Inspection',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          intervalMiles: 0,
          milesSinceService: 0,
          intervalMonths: 12,
          monthsSinceService: 0,
          importance: 97,
          timeOnly: true,
        ),
      ],
      events: [
        MaintenanceServiceEvent(
          itemName: 'Inspection',
          vehicleId: vehicle.id,
          vehicleName: vehicle.nickname,
          serviceDate: DateTime(2026, 8, 13),
          odometer: 0,
        ),
      ],
    );

    final record = state.maintenance.single;
    expect(record.lastServiceOdometer, 0);
    expect(record.lastOdometerEstimated, isTrue);
    expect(record.lastServiceEstimated, isFalse);
  });

  test('recorded service odometer remains confirmed', () async {
    final state = AppStateController();
    addTearDown(state.dispose);
    final vehicle = state.activeVehicle!;
    await state.addMaintenanceRecords([
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

    await state.logMaintenanceService(
      MaintenanceServiceEvent(
        itemName: 'Engine Oil',
        vehicleId: vehicle.id,
        vehicleName: vehicle.nickname,
        serviceDate: DateTime(2026, 8, 13),
        odometer: 101250,
      ),
    );

    final record = state.maintenance.single;
    expect(record.lastServiceOdometer, 101250);
    expect(record.lastOdometerEstimated, isFalse);
  });
}
