import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_initial_fix_classifier.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'twelve-hour trip survives process recovery without duplicate distance',
    () async {
      final start = DateTime.utc(2026, 7, 23, 8);
      final store = TripTrackingSessionStore.memory();
      final firstOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final first = _controller(
        store: store,
        odometer: firstOdometer,
        now: () => start.add(const Duration(hours: 6)),
      );

      expect(
        await first.start(
          tripId: 'trip_twelve_hour_recovery',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      for (var index = 0; index <= 720; index += 1) {
        await first.ingest(
          _sample(start, index),
          referenceTime: start.add(Duration(seconds: index * 30)),
        );
      }
      final beforeRecoveryMeters = first.acceptedMeters;
      final beforeRecoveryRevision = first.activeSession!.revision;
      expect(beforeRecoveryMeters, greaterThan(10000));
      first.dispose();

      final recoveredOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final recovered = _controller(
        store: store,
        odometer: recoveredOdometer,
        now: () => start.add(const Duration(hours: 12)),
      );
      addTearDown(recovered.dispose);
      expect(await recovered.restore(), isTrue);
      expect(recovered.acceptedMeters, closeTo(beforeRecoveryMeters, .000001));
      expect(
        recovered.activeSession!.revision,
        greaterThan(beforeRecoveryRevision),
      );

      for (var index = 721; index <= 1440; index += 1) {
        await recovered.ingest(
          _sample(start, index),
          referenceTime: start.add(Duration(seconds: index * 30)),
        );
      }

      expect(recovered.acceptedMeters, greaterThan(beforeRecoveryMeters));
      expect(recovered.acceptedMeters, greaterThan(20000));
      expect(recovered.acceptedMeters, lessThan(30000));
      expect(recoveredOdometer.confirmedReading, 1000);
      expect(recoveredOdometer.reading, greaterThan(1000));
      expect(store.pendingSampleFor('trip_twelve_hour_recovery'), isNull);
      expect(
        utf8
            .encode(jsonEncode(recovered.activeSession!.engineSnapshot.toMap()))
            .length,
        lessThan(12000),
      );
    },
  );
}

TripTrackingController _controller({
  required TripTrackingSessionStore store,
  required GlobalOdometerController odometer,
  required DateTime Function() now,
}) => TripTrackingController(
  sessionStore: store,
  odometer: odometer,
  clockNow: now,
  initialFixClassifier: const TripInitialFixClassifier(
    maximumFreshAge: Duration(days: 3650),
  ),
);

TripLocationSample _sample(DateTime start, int index) => TripLocationSample(
  latitude: 35,
  longitude: -80 + (index * .0002),
  recordedAt: start.add(Duration(seconds: index * 30)),
  horizontalAccuracyMeters: 4,
  speedMetersPerSecond: .6,
  speedAccuracyMetersPerSecond: .5,
  monotonicElapsedNanos: index * 30000000000,
);
