import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_projection.dart';

void main() {
  test(
    'live projection only advances after credible accepted trip distance',
    () {
      final projection = TripLiveOdometerProjection(startingOdometer: 1000);

      expect(projection.projectedReading, 1000);
      expect(projection.updateAcceptedMeters(700), 1000);
      expect(projection.updateAcceptedMeters(900), 1001);
      expect(projection.updateAcceptedMeters(100), 1001);
    },
  );

  test('never exposes a non-finite or negative live odometer estimate', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 120000);

    expect(projection.updateAcceptedMeters(double.nan), 120000);
    expect(projection.updateAcceptedMeters(double.infinity), 120000);
    expect(projection.updateAcceptedMeters(-1), 120000);
  });

  test('negative projection baselines recover to zero', () {
    final projection = TripLiveOdometerProjection(startingOdometer: -20);

    expect(projection.projectedReading, isZero);
    expect(projection.updateAcceptedMeters(1609.344), 1);
  });

  test('over-range live projection stays at last safe reading', () {
    final projection = TripLiveOdometerProjection(
      startingOdometer: 1999,
      maxSupportedReading: 2000,
    );

    expect(projection.updateAcceptedMeters(1609.344), 2000);
    expect(projection.updateAcceptedMeters(3218.688), 2000);
    expect(projection.projectedReading, 2000);
  });

  test('over-range starting baseline is bounded before display', () {
    final projection = TripLiveOdometerProjection(
      startingOdometer: 5000,
      maxSupportedReading: 4000,
    );

    expect(projection.projectedReading, 4000);
    expect(projection.updateAcceptedMeters(1609.344), 4000);
  });

  test('huge finite accepted distance is rejected before projection math', () {
    final projection = TripLiveOdometerProjection(
      startingOdometer: 9999990,
      maxSupportedReading: 9999999,
    );

    expect(projection.updateAcceptedMeters(9 * metersPerMile), 9999999);
    expect(projection.updateAcceptedMeters(double.maxFinite), 9999999);
    expect(projection.projectedReading, 9999999);
  });
}
