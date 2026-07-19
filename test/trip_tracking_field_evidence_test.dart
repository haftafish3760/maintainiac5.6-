import 'package:flutter_test/flutter_test.dart';

import 'support/trip_tracking_qa/trip_tracking_field_evidence.dart';

void main() {
  test('field evidence compares only coordinate-minimized mileage', () {
    final evidence = TripTrackingFieldEvidence.fromMap({
      'platform': 'android',
      'odometerMiles': 10.0,
      'filteredGpsMiles': 9.8,
    });
    expect(evidence.absoluteDistanceErrorMiles, closeTo(.2, .0001));
    expect(evidence.toSafeSummary()['coordinatesIncluded'], isFalse);
  });

  test('field evidence rejects coordinates and invalid values', () {
    expect(
      () => TripTrackingFieldEvidence.fromMap({
        'platform': 'ios',
        'odometerMiles': 1.0,
        'filteredGpsMiles': 1.0,
        'latitude': 35.0,
      }),
      throwsFormatException,
    );
  });
}
