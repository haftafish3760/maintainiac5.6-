import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  test(
    'seeded hostile replays never convert unsafe movement into trip truth',
    () {
      final start = DateTime.utc(2026, 7, 19, 12);

      for (final seed in [7313, 19017, 48109, 99991]) {
        final random = Random(seed);
        final points = <SimulatedTripPoint>[
          SimulatedTripPoint(_sample(start, -80, 0, speed: 8)),
        ];
        for (var index = 1; index <= 80; index++) {
          final seconds = index * 5;
          final hostileKind = random.nextInt(8);
          final longitude = hostileKind == 0
              ? -79.2 // impossible jump
              : -80 + (index * .00002) + ((random.nextDouble() - .5) * .00002);
          final recordedSeconds = hostileKind == 1 ? seconds - 10 : seconds;
          points.add(
            SimulatedTripPoint(
              _sample(
                start,
                longitude,
                recordedSeconds,
                accuracy: hostileKind == 2 ? 250 : 6,
                speed: hostileKind == 3 ? 150 : 8,
                mocked: hostileKind == 4,
              ),
            ),
          );
        }

        final result = replayTrip(points);
        expect(result.acceptedMeters, greaterThanOrEqualTo(0), reason: '$seed');
        expect(result.acceptedMeters, lessThan(400), reason: '$seed');
        expect(result.rejectedUnsafeCount, greaterThan(0), reason: '$seed');
        expect(result.toSafeSummary()['simulationCanReplaceOdometer'], isFalse);
        expect(
          result.toSafeSummary()['simulationCanCreateOfficialStop'],
          isFalse,
        );
      }
    },
  );
}

TripLocationSample _sample(
  DateTime start,
  double longitude,
  int seconds, {
  required double speed,
  double accuracy = 6,
  bool mocked = false,
}) => TripLocationSample(
  latitude: 35,
  longitude: longitude,
  recordedAt: start.add(Duration(seconds: seconds)),
  horizontalAccuracyMeters: accuracy,
  speedMetersPerSecond: speed,
  mockedLocation: mocked,
);
