import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/vehicle_tire_configuration_selector.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  testWidgets(
    'tire setup keeps explicit unknown choices and odometer warning',
    (tester) async {
      var tireStatus = VehicleTireSizeStatus.unknown;
      var calibrationStatus = VehicleSpeedometerCalibrationStatus.unknown;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleTireConfigurationSelector(
              tireSizeStatus: tireStatus,
              speedometerCalibrationStatus: calibrationStatus,
              onTireSizeChanged: (value) => tireStatus = value,
              onSpeedometerCalibrationChanged: (value) =>
                  calibrationStatus = value,
            ),
          ),
        ),
      );

      expect(find.text('Not sure'), findsNWidgets(2));
      expect(find.textContaining('never changes confirmed odometer'), findsOne);

      await tester.tap(find.byKey(const ValueKey('vehicle-tire-size-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Larger than recommended').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('vehicle-speedometer-calibration-status')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('No').last);
      await tester.pumpAndSettle();

      expect(tireStatus, VehicleTireSizeStatus.largerThanRecommended);
      expect(
        calibrationStatus,
        VehicleSpeedometerCalibrationStatus.notCalibratedForCurrentTires,
      );
    },
  );
}
