import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final start = DateTime.utc(2026, 7, 13, 12);

  test('seeded hostile samples preserve distance accounting invariants', () {
    for (final seed in List<int>.generate(24, (index) => 9000 + index)) {
      final random = Random(seed);
      final engine = TripTrackingEngine();
      var longitude = -80.0;
      var seconds = 0;
      var previousTotal = 0.0;

      for (var index = 0; index < 240; index++) {
        seconds += 1 + random.nextInt(20);
        final kind = random.nextInt(8);
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
        );

        final decision = engine.ingest(sample);
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
}
