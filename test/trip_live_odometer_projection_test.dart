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
    expect(projection.updateAcceptedMeters(-1), 120000);
  });
}
