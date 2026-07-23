import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active workday vehicle selection synchronizes identity owners', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('onVehicleChanged: _handleVehicleChanged'));
    expect(source, contains('odometerVehicleIdForVehicleId('));
    expect(source, contains('await odometer.switchVehicleById('));
    expect(source, contains('await appState.selectVehicle(selectedVehicle)'));
    expect(source, contains('operationalContext.setActiveVehicle('));
  });

  test(
    'active workday and GPS projection block unsafe vehicle replacement',
    () {
      final source = File(
        'lib/screens/dashboard/active_workday_screen.dart',
      ).readAsStringSync();

      expect(source, contains('workday.vehicleId != targetOdometerVehicleId'));
      expect(source, contains('await _restoreAppStateVehicle('));
      expect(
        source,
        contains('End the current workday before switching vehicles.'),
      );
      expect(
        source,
        contains(
          'End or review the active GPS trip before switching vehicles.',
        ),
      );
    },
  );
}
