import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final start = DateTime.utc(2026, 7, 13, 12);

  test('seeded hostile samples preserve distance accounting invariants', () {
    for (final seed in List<int>.generate(128, (index) => 9000 + index)) {
      final random = Random(seed);
      final engine = TripTrackingEngine();
      var longitude = -80.0;
      var seconds = 0;
      var previousTotal = 0.0;
      var mockedRejections = 0;

      for (var index = 0; index < 240; index++) {
        seconds += 1 + random.nextInt(20);
        final kind = random.nextInt(9);
        final timestampSeconds = kind == 0
            ? seconds - (1 + random.nextInt(30))
            : seconds;
        final accuracy = kind == 1
            ? 100 + random.nextDouble() * 200
            : 3 + random.nextDouble() * 20;
        longitude += kind == 2
            ? (random.nextBool() ? 1 : -1) * .02
            : (random.nextDouble() - .5) * .00022;
        final sample = TripLocationSample(
          latitude: kind == 3 ? double.nan : 35,
          longitude: longitude,
          recordedAt: start.add(Duration(seconds: timestampSeconds)),
          horizontalAccuracyMeters: accuracy,
          speedMetersPerSecond: kind == 4
              ? double.infinity
              : random.nextDouble() * 12,
          mockedLocation: kind == 5,
        );

        final decision = engine.ingest(sample);
        if (decision.disposition ==
            TripSampleDisposition.rejectedMockLocation) {
          mockedRejections += 1;
        }
        expect(
          decision.totalAcceptedMeters.isFinite,
          isTrue,
          reason: 'seed $seed',
        );
        expect(decision.totalAcceptedMeters, greaterThanOrEqualTo(0));
        if (decision.accepted) {
          expect(
            decision.totalAcceptedMeters,
            closeTo(previousTotal + decision.addedMeters, .000001),
          );
        } else {
          expect(decision.totalAcceptedMeters, previousTotal);
        }
        previousTotal = decision.totalAcceptedMeters;
      }
      expect(mockedRejections, greaterThan(0), reason: 'seed $seed');
    }
  });

  test(
    'a twelve-hour low-speed route remains finite and does not leak drift',
    () {
      final engine = TripTrackingEngine();
      var longitude = -80.0;
      for (var index = 0; index <= 1440; index++) {
        final decision = engine.ingest(
          TripLocationSample(
            latitude: 35,
            longitude: longitude,
            recordedAt: start.add(Duration(seconds: index * 30)),
            horizontalAccuracyMeters: 4,
            speedMetersPerSecond: .5,
          ),
        );
        if (index > 0) {
          expect(decision.addedMeters, greaterThan(0));
        }
        longitude += .000165;
      }

      expect(engine.totalAcceptedMeters.isFinite, isTrue);
      expect(engine.totalAcceptedMeters, greaterThan(18000));
      expect(engine.totalAcceptedMeters, lessThan(30000));
    },
  );

  test('seeded mixed motion never creates review before vehicle evidence', () {
    for (final seed in List<int>.generate(64, (index) => 12000 + index)) {
      final random = Random(seed);
      final engine = TripTrackingEngine(
        profile: TripTrackingProfile.deliveryVehicle,
      );
      var longitude = -80.0;
      var seconds = 0;
      var acceptedDistanceSeen = false;

      for (var index = 0; index < 180; index += 1) {
        seconds += 5 + random.nextInt(25);
        final kind = random.nextInt(12);
        final activityKind = random.nextInt(7);
        longitude += kind == 0
            ? (random.nextBool() ? .015 : -.015)
            : (random.nextDouble() - .35) * .00035;
        final sample = TripLocationSample(
          latitude: kind == 1 ? double.nan : 35,
          longitude: longitude,
          recordedAt: start.add(
            Duration(seconds: kind == 2 ? seconds - 90 : seconds),
          ),
          horizontalAccuracyMeters: kind == 3
              ? 120 + random.nextDouble() * 80
              : 3 + random.nextDouble() * 16,
          speedMetersPerSecond: kind == 4
              ? 0
              : kind == 5
              ? double.infinity
              : random.nextDouble() * 14,
          mockedLocation: kind == 6,
        );
        final activity = activityKind == 0 || activityKind == 1
            ? TripActivityObservation(
                activity: activityKind == 0
                    ? TripActivity.walking
                    : TripActivity.automotive,
                confidence: activityKind == 0 ? 90 : 95,
                recordedAt: start.add(Duration(seconds: seconds)),
              )
            : null;

        final decision = engine.ingest(sample, activity: activity);
        acceptedDistanceSeen =
            acceptedDistanceSeen ||
            decision.disposition == TripSampleDisposition.acceptedDistance;

        expect(decision.totalAcceptedMeters.isFinite, isTrue, reason: '$seed');
        expect(decision.totalAcceptedMeters, greaterThanOrEqualTo(0));
        if (decision.walkingReviewSuggested) {
          expect(acceptedDistanceSeen, isTrue, reason: '$seed');
        }
        if (decision.disposition ==
            TripSampleDisposition.rejectedMockLocation) {
          expect(decision.addedMeters, 0);
        }
      }
    }
  });
}
