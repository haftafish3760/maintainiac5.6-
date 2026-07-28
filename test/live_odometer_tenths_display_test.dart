// Regression coverage for the advisory live GPS odometer tenths display.
//
// Owns conservative tenth-mile formatting and monotonic live-projection
// behavior. It does not alter confirmed odometer history or trip review data.
// The global odometer controller and dashboard surfaces consume this contract.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_projection.dart';

void main() {
  test('accepted GPS evidence is displayed conservatively to one tenth', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000);
    projection.updateAcceptedMeters(metersPerMile * .79);

    expect(projection.projectedReading, 1001);
    expect(projection.projectedTenths, 10007);
    const snapshot = LiveOdometerDisplaySnapshot(
      confirmedReading: 1000,
      displayReading: 1001,
      displayTenths: 10007,
      isLive: true,
    );
    expect(snapshot.displayValue, '1000.7');
    expect(snapshot.deltaLabel, '+0.7 mi live');
    expect(snapshot.advisoryLabel, contains('0.7 mi ahead'));
    expect(snapshot.confirmedDisplayValue, '1000');
  });

  test('live tenths advance without changing confirmed odometer truth', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_tenths',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_tenths',
        estimatedOdometer: 1001,
        estimatedOdometerTenths: 10007,
      ),
      isTrue,
    );

    expect(controller.displayValue, '1000.7');
    expect(controller.confirmedReading, 1000);
    expect(controller.reading, 1001);
  });
}
