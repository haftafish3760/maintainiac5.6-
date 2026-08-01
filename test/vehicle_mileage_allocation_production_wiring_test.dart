// Source-contract regression for allocation durable-sync production wiring.
//
// Owns proof that app bootstrap consumes the published durable bucket and both
// confirmed odometer evidence and opt-in changes request a sync. It does not
// test the bucket, Expense, GPS, or actual Firebase network behavior.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bootstrap wires opt-in allocation sync to confirmed odometer history',
    () {
      final source = File('lib/main.dart').readAsStringSync();

      expect(source, contains('VehicleMileageAllocationDurableStore('));
      expect(source, contains('VehicleMileageAllocationDurableSync('));
      expect(source, contains('VehicleMileageAllocationDashboardScope('));
      expect(
        source,
        contains('vehicleMileageAllocationDashboard.refreshProjection()'),
      );
      expect(source, contains('syncVehicleMileageAllocation();'));
      expect(
        source,
        contains('globalOdometer.addListener(syncVehicleMileageAllocation)'),
      );
      expect(
        source,
        contains(
          'tripTrackingSettings.addListener(syncVehicleMileageAllocation)',
        ),
      );
      expect(source, contains('history: globalOdometer.history'));
    },
  );
}
