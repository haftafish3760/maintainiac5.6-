import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final start = DateTime.utc(2026, 7, 17, 12);

  TripLocationSample point(
    double longitude,
    int seconds, {
    double accuracy = 5,
    double? speed,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speed,
  );

  TripActivityObservation walking(int seconds) => TripActivityObservation(
    activity: TripActivity.walking,
    confidence: 92,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  test('delivery parking-lot crawl does not turn into walking mileage', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 5)),
      SimulatedTripPoint(point(-79.9995, 15, speed: 5)),
      SimulatedTripPoint(point(-79.99945, 30, speed: .6)),
      SimulatedTripPoint(point(-79.9994, 45, speed: .5)),
      SimulatedTripPoint(point(-79.99935, 60, speed: .4)),
      SimulatedTripPoint(point(-79.9993, 75, speed: .5)),
      SimulatedTripPoint(point(-79.9987, 95, speed: 7)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedMeters, greaterThan(80));
    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(1));
  });

  test('highway delivery run accepts credible fast movement', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 27)),
      SimulatedTripPoint(point(-79.995, 20, speed: 27)),
      SimulatedTripPoint(point(-79.990, 40, speed: 27)),
      SimulatedTripPoint(point(-79.985, 60, speed: 27)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.acceptedMeters, greaterThan(1200));
    expect(result.count(TripSampleDisposition.rejectedImplausibleSpeed), 0);
    expect(result.count(TripSampleDisposition.rejectedSpeedConflict), 0);
  });

  test('contractor stop requires repeated fresh walking evidence', () {
    final singleWalk = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.99895, 35), activity: walking(35)),
      SimulatedTripPoint(point(-79.998, 75, speed: 8)),
    ], profile: TripTrackingProfile.contractorVehicle);
    final repeatedWalk = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.99895, 35), activity: walking(35)),
      SimulatedTripPoint(point(-79.99890, 50), activity: walking(50)),
      SimulatedTripPoint(point(-79.99885, 65), activity: walking(65)),
      SimulatedTripPoint(point(-79.99880, 80), activity: walking(80)),
    ], profile: TripTrackingProfile.contractorVehicle);

    expect(singleWalk.needsWalkingReview, isFalse);
    expect(repeatedWalk.needsWalkingReview, isTrue);
    expect(repeatedWalk.acceptedMeters, lessThan(singleWalk.acceptedMeters));
  });
}
