// Active Day Bluetooth-status regression coverage.
//
// Owns truthful status classification checks. It does not test native
// Bluetooth observation, vehicle selection, or trip creation.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_bluetooth_status_line.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';

void main() {
  test(
    'Bluetooth status never treats an unapproved suggestion as confirmed',
    () {
      const decision = BluetoothVehicleMatchDecision(
        disposition: BluetoothVehicleMatchDisposition.requiresUserConfirmation,
        vehicleId: 'vehicle_2',
        safeReason: 'test',
      );
      final status = ActiveWorkdayBluetoothStatus.forSnapshot(
        recognitionEnabled: true,
        observationAvailable: true,
        isListening: true,
        lastDecision: decision,
      );

      expect(status.label, contains('review required'));
      expect(status.label, isNot(contains('active vehicle')));
    },
  );

  test('Bluetooth status distinguishes off, unavailable, and ready', () {
    expect(
      ActiveWorkdayBluetoothStatus.forSnapshot(
        recognitionEnabled: false,
        observationAvailable: false,
        isListening: false,
        lastDecision: null,
      ).label,
      contains('off'),
    );
    expect(
      ActiveWorkdayBluetoothStatus.forSnapshot(
        recognitionEnabled: true,
        observationAvailable: false,
        isListening: false,
        lastDecision: null,
      ).label,
      contains('unavailable'),
    );
    expect(
      ActiveWorkdayBluetoothStatus.forSnapshot(
        recognitionEnabled: true,
        observationAvailable: true,
        isListening: true,
        lastDecision: null,
      ).label,
      contains('ready'),
    );
  });
}
