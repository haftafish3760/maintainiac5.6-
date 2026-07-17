import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final start = DateTime.utc(2026, 7, 13, 12);

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
    confidence: 90,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  test('stationary urban GPS jitter does not accumulate a phantom trip', () {
    final random = Random(7313);
    final samples = List.generate(120, (index) {
      final jitter = (random.nextDouble() - .5) * .000035;
      return SimulatedTripPoint(point(-80 + jitter, index * 5));
    });

    final result = replayTrip(samples);

    expect(result.acceptedMeters, lessThan(15));
    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(80));
  });

  test('a low-speed mower route remains measurable without precision mode', () {
    final points = List.generate(
      80,
      (index) => SimulatedTripPoint(
        point(-80 + (index * .00016), index * 5, speed: 3.6),
      ),
    );

    final result = replayTrip(
      points,
      profile: TripTrackingProfile.lowSpeedEquipment,
    );

    expect(result.acceptedMeters, greaterThan(1000));
    expect(
      result.count(TripSampleDisposition.acceptedDistance),
      greaterThan(70),
    );
  });

  test(
    'poor urban-canyon samples and an outage never bridge false distance',
    () {
      final result = replayTrip([
        SimulatedTripPoint(point(-80, 0)),
        SimulatedTripPoint(point(-79.9998, 10)),
        SimulatedTripPoint(point(-79.995, 15, accuracy: 120)),
        SimulatedTripPoint(point(-79.99, 160)),
        SimulatedTripPoint(point(-79.9898, 170)),
      ]);

      expect(result.count(TripSampleDisposition.rejectedAccuracy), 1);
      expect(result.count(TripSampleDisposition.rejectedGap), 1);
      expect(result.acceptedMeters, lessThan(60));
    },
  );

  test('long tunnel-style GPS outage reanchors before resuming mileage', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 9)),
      SimulatedTripPoint(point(-79.999, 20, speed: 9)),
      SimulatedTripPoint(point(-79.95, 600, speed: 9)),
      SimulatedTripPoint(point(-79.949, 620, speed: 9)),
    ]);

    expect(result.count(TripSampleDisposition.rejectedGap), 1);
    expect(result.acceptedMeters, greaterThan(80));
    expect(result.acceptedMeters, lessThan(250));
  });

  test('single walking blip at a light does not become a stop review', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 9)),
      SimulatedTripPoint(point(-79.999, 20, speed: 9)),
      SimulatedTripPoint(point(-79.999, 45, speed: 0), activity: walking(45)),
      SimulatedTripPoint(point(-79.998, 70, speed: 9)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedMeters, greaterThan(150));
  });

  test('leaving a vehicle and walking excludes confirmed on-foot movement', () {
    final points = <SimulatedTripPoint>[SimulatedTripPoint(point(-80, 0))];
    for (var index = 1; index <= 7; index++) {
      final seconds = index * 15;
      points.add(
        SimulatedTripPoint(
          point(-80 + (index * .00012), seconds),
          activity: walking(seconds),
        ),
      );
    }

    final result = replayTrip(points);

    expect(result.needsWalkingReview, isTrue);
    expect(
      result.count(TripSampleDisposition.excludedWalking),
      greaterThanOrEqualTo(4),
    );
  });

  test(
    'a stop-and-walk delivery replay excludes walking then resumes driving',
    () {
      final result = replayTrip([
        SimulatedTripPoint(point(-80, 0, speed: 8)),
        SimulatedTripPoint(point(-79.999, 20, speed: 8)),
        SimulatedTripPoint(point(-79.998, 40, speed: 8)),
        SimulatedTripPoint(point(-79.9979, 55), activity: walking(55)),
        SimulatedTripPoint(point(-79.99785, 70), activity: walking(70)),
        SimulatedTripPoint(point(-79.9978, 85), activity: walking(85)),
        SimulatedTripPoint(point(-79.99775, 100), activity: walking(100)),
        SimulatedTripPoint(point(-79.9968, 130, speed: 8)),
        SimulatedTripPoint(point(-79.9958, 150, speed: 8)),
      ], profile: TripTrackingProfile.deliveryVehicle);

      expect(result.needsWalkingReview, isTrue);
      expect(
        result.count(TripSampleDisposition.excludedWalking),
        greaterThanOrEqualTo(2),
      );
      expect(
        result.count(TripSampleDisposition.acceptedDistance),
        greaterThanOrEqualTo(3),
      );
      expect(result.acceptedMeters, greaterThan(250));
      expect(result.acceptedMeters, lessThan(450));
    },
  );

  test(
    'a multi-stop delivery route distinguishes walking stops from traffic lights',
    () {
      final points = <SimulatedTripPoint>[
        SimulatedTripPoint(point(-80, 0, speed: 9)),
        SimulatedTripPoint(point(-79.999, 20, speed: 9)),
        SimulatedTripPoint(point(-79.998, 40, speed: 9)),
        SimulatedTripPoint(point(-79.99795, 55), activity: walking(55)),
        SimulatedTripPoint(point(-79.99788, 70), activity: walking(70)),
        SimulatedTripPoint(point(-79.99782, 85), activity: walking(85)),
        SimulatedTripPoint(point(-79.9968, 120, speed: 9)),
      ];
      for (var index = 0; index < 8; index++) {
        points.add(
          SimulatedTripPoint(
            point(
              -79.9968 + ((index.isEven ? 1 : -1) * .000008),
              140 + (index * 10),
              speed: 0,
            ),
          ),
        );
      }
      points.addAll([
        SimulatedTripPoint(point(-79.9958, 230, speed: 9)),
        SimulatedTripPoint(point(-79.9948, 250, speed: 9)),
        SimulatedTripPoint(point(-79.99475, 270), activity: walking(270)),
        SimulatedTripPoint(point(-79.99468, 285), activity: walking(285)),
        SimulatedTripPoint(point(-79.99462, 300), activity: walking(300)),
        SimulatedTripPoint(point(-79.9938, 340, speed: 9)),
      ]);

      final result = replayTrip(
        points,
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.needsWalkingReview, isTrue);
      expect(
        result.count(TripSampleDisposition.excludedWalking),
        greaterThanOrEqualTo(4),
      );
      expect(
        result.count(TripSampleDisposition.rejectedDrift),
        greaterThanOrEqualTo(6),
      );
      expect(result.motionState, TripMotionState.moving);
      expect(result.acceptedMeters, greaterThan(400));
      expect(result.acceptedMeters, lessThan(700));
    },
  );

  test(
    'a rideshare-style long traffic light does not become a delivery stop',
    () {
      final points = <SimulatedTripPoint>[
        SimulatedTripPoint(point(-80, 0, speed: 9)),
        SimulatedTripPoint(point(-79.999, 20, speed: 9)),
        SimulatedTripPoint(point(-79.998, 40, speed: 9)),
      ];
      for (var index = 0; index < 10; index++) {
        points.add(
          SimulatedTripPoint(
            point(
              -79.998 + ((index.isEven ? 1 : -1) * .00001),
              55 + (index * 10),
              speed: 0,
            ),
          ),
        );
      }
      points.addAll([
        SimulatedTripPoint(point(-79.997, 170, speed: 9)),
        SimulatedTripPoint(point(-79.996, 190, speed: 9)),
      ]);

      final result = replayTrip(points);

      expect(result.needsWalkingReview, isFalse);
      expect(result.motionState, TripMotionState.moving);
      expect(result.count(TripSampleDisposition.excludedWalking), isZero);
      expect(
        result.count(TripSampleDisposition.rejectedDrift),
        greaterThanOrEqualTo(8),
      );
      expect(result.acceptedMeters, greaterThan(250));
      expect(result.acceptedMeters, lessThan(450));
    },
  );

  test('stale walking sensor state does not strip later vehicle mileage', () {
    final staleWalking = TripActivityObservation(
      activity: TripActivity.walking,
      confidence: 95,
      recordedAt: start.add(const Duration(seconds: 10)),
    );
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.998, 95, speed: 8), activity: staleWalking),
      SimulatedTripPoint(point(-79.997, 115, speed: 8)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.needsWalkingReview, isFalse);
    expect(result.motionState, TripMotionState.moving);
    expect(result.count(TripSampleDisposition.excludedWalking), isZero);
    expect(
      result.count(TripSampleDisposition.acceptedDistance),
      greaterThanOrEqualTo(3),
    );
    expect(result.acceptedMeters, greaterThan(250));
  });

  test(
    'a passenger delivery with the tracked phone parked stays vehicle-only',
    () {
      final points = <SimulatedTripPoint>[
        SimulatedTripPoint(point(-80, 0, speed: 8)),
        SimulatedTripPoint(point(-79.999, 20, speed: 8)),
        SimulatedTripPoint(point(-79.998, 40, speed: 8)),
      ];
      for (var index = 0; index < 8; index++) {
        points.add(
          SimulatedTripPoint(
            point(
              -79.998 + ((index.isEven ? 1 : -1) * .000008),
              60 + (index * 20),
              speed: 0,
            ),
          ),
        );
      }
      points.addAll([
        SimulatedTripPoint(point(-79.9972, 235, speed: 8)),
        SimulatedTripPoint(point(-79.9962, 255, speed: 8)),
      ]);

      final result = replayTrip(points);

      expect(result.needsWalkingReview, isFalse);
      expect(result.motionState, TripMotionState.moving);
      expect(result.count(TripSampleDisposition.excludedWalking), isZero);
      expect(
        result.count(TripSampleDisposition.rejectedDrift),
        greaterThanOrEqualTo(6),
      );
      expect(result.acceptedMeters, greaterThan(250));
      expect(result.acceptedMeters, lessThan(500));
    },
  );

  test(
    'a contractor jobsite stop excludes walking work before the next drive',
    () {
      final result = replayTrip([
        SimulatedTripPoint(point(-80, 0, speed: 10)),
        SimulatedTripPoint(point(-79.999, 20, speed: 10)),
        SimulatedTripPoint(point(-79.998, 40, speed: 10)),
        SimulatedTripPoint(point(-79.99795, 60), activity: walking(60)),
        SimulatedTripPoint(point(-79.99785, 80), activity: walking(80)),
        SimulatedTripPoint(point(-79.9977, 100), activity: walking(100)),
        SimulatedTripPoint(point(-79.99755, 120), activity: walking(120)),
        SimulatedTripPoint(point(-79.9968, 170, speed: 10)),
        SimulatedTripPoint(point(-79.9958, 190, speed: 10)),
      ], profile: TripTrackingProfile.contractorVehicle);

      expect(result.needsWalkingReview, isTrue);
      expect(result.motionState, TripMotionState.moving);
      expect(
        result.count(TripSampleDisposition.excludedWalking),
        greaterThanOrEqualTo(4),
      );
      expect(
        result.count(TripSampleDisposition.acceptedDistance),
        greaterThanOrEqualTo(3),
      );
      expect(result.acceptedMeters, greaterThan(250));
      expect(result.acceptedMeters, lessThan(450));
    },
  );

  test(
    'spoof-like jumps, timestamp reversals, and malformed points fail closed',
    () {
      final result = replayTrip([
        SimulatedTripPoint(point(-80, 0)),
        SimulatedTripPoint(point(-79.99, 2)),
        SimulatedTripPoint(point(-79.9898, 30)),
        SimulatedTripPoint(point(-79.9896, 20)),
        SimulatedTripPoint(
          TripLocationSample(
            latitude: double.nan,
            longitude: -79.9894,
            recordedAt: start.add(const Duration(seconds: 35)),
            horizontalAccuracyMeters: 5,
          ),
        ),
      ]);

      expect(result.count(TripSampleDisposition.rejectedImplausibleSpeed), 1);
      expect(result.count(TripSampleDisposition.rejectedOutOfOrder), 1);
      expect(result.count(TripSampleDisposition.rejectedInvalid), 1);
      expect(result.acceptedMeters, lessThan(30));
    },
  );

  test('a mocked location cannot be replayed into a vehicle route', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0)),
      SimulatedTripPoint(
        TripLocationSample(
          latitude: 35,
          longitude: -79.9,
          recordedAt: start.add(const Duration(seconds: 20)),
          horizontalAccuracyMeters: 3,
          mockedLocation: true,
        ),
      ),
      SimulatedTripPoint(point(-79.9998, 40)),
    ]);

    expect(result.count(TripSampleDisposition.rejectedMockLocation), 1);
    expect(result.acceptedMeters, lessThan(40));
  });

  test('provider speed conflicts re-anchor without inflating mileage', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.99, 40, speed: 0)),
      SimulatedTripPoint(point(-79.9898, 60, speed: 8)),
      SimulatedTripPoint(point(-79.9888, 80, speed: 8)),
    ]);

    expect(result.count(TripSampleDisposition.rejectedSpeedConflict), 1);
    expect(result.acceptedMeters, greaterThan(150));
    expect(result.acceptedMeters, lessThan(300));
  });

  test(
    'a mixed hostile sensor replay never turns stale or degraded fixes into miles',
    () {
      final result = replayTrip([
        SimulatedTripPoint(point(-80, 0)),
        SimulatedTripPoint(point(-79.999, 20, speed: 8)),
        SimulatedTripPoint(point(-79.9989, 20, speed: 8)),
        SimulatedTripPoint(point(-79.99, 21, accuracy: 120, speed: 8)),
        SimulatedTripPoint(point(-79.9988, 19, speed: 8)),
        SimulatedTripPoint(point(-79.98, 180, speed: 8)),
        SimulatedTripPoint(point(-79.9799, 190, accuracy: 120, speed: 8)),
        SimulatedTripPoint(point(-79.9798, 185, speed: 8)),
        SimulatedTripPoint(
          TripLocationSample(
            latitude: double.nan,
            longitude: -79.9798,
            recordedAt: start.add(const Duration(seconds: 195)),
            horizontalAccuracyMeters: 5,
          ),
        ),
        SimulatedTripPoint(point(-79.9796, 220, speed: 8)),
      ]);

      expect(result.acceptedMeters.isFinite, isTrue);
      expect(result.acceptedMeters, greaterThan(50));
      expect(result.acceptedMeters, lessThan(160));
      expect(result.count(TripSampleDisposition.rejectedAccuracy), 2);
      expect(result.count(TripSampleDisposition.rejectedOutOfOrder), 3);
      expect(result.count(TripSampleDisposition.rejectedGap), 1);
      expect(result.count(TripSampleDisposition.rejectedInvalid), 1);
    },
  );

  test('antimeridian and near-pole routes remain finite and measurable', () {
    final antimeridian = replayTrip([
      SimulatedTripPoint(point(179.9999, 0)),
      SimulatedTripPoint(point(-179.9998, 5)),
    ]);
    final nearPole = replayTrip([
      SimulatedTripPoint(
        TripLocationSample(
          latitude: 89.999,
          longitude: 20,
          recordedAt: start,
          horizontalAccuracyMeters: 3,
        ),
      ),
      SimulatedTripPoint(
        TripLocationSample(
          latitude: 89.999,
          longitude: 30,
          recordedAt: start.add(const Duration(seconds: 5)),
          horizontalAccuracyMeters: 3,
        ),
      ),
    ]);

    expect(antimeridian.acceptedMeters, greaterThan(10));
    expect(antimeridian.acceptedMeters, lessThan(100));
    expect(nearPole.acceptedMeters, greaterThan(5));
    expect(nearPole.acceptedMeters.isFinite, isTrue);
  });
}
