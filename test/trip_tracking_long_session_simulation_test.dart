import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'ten-hour controller replay keeps recovery state bounded and odometer advisory',
    () async {
      const tripId = 'ten_hour_bounded_replay';
      final startedAt = DateTime.utc(2026, 7, 24);
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => startedAt.add(const Duration(hours: 11)),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      expect(
        await controller.start(
          tripId: tripId,
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
        ),
        isTrue,
      );

      Future<void> ingestPoint(int index) async {
        final recordedAt = startedAt.add(Duration(seconds: index * 10));
        final decision = await controller.ingest(
          TripLocationSample(
            latitude: 35,
            longitude: -80 + (index * .001),
            recordedAt: recordedAt,
            horizontalAccuracyMeters: 5,
          ),
          referenceTime: recordedAt,
        );
        expect(decision, isNotNull);
      }

      await ingestPoint(0);
      final initialCheckpointBytes = utf8
          .encode(jsonEncode(store.activeSession!.toMap()))
          .length;
      for (var index = 1; index <= 3600; index += 1) {
        await ingestPoint(index);
      }

      final finalCheckpoint = store.activeSession!;
      final finalCheckpointBytes = utf8
          .encode(jsonEncode(finalCheckpoint.toMap()))
          .length;
      expect(
        finalCheckpointBytes,
        lessThan(initialCheckpointBytes + 4096),
        reason:
            'Recovery state must not retain the entire raw location stream.',
      );
      expect(controller.diagnostics.receivedSamples, 3601);
      expect(controller.diagnostics.acceptedSamples, 3601);
      expect(
        controller.diagnostics.dispositionCounts[TripSampleDisposition
            .acceptedAnchor],
        1,
      );
      expect(
        controller.diagnostics.dispositionCounts[TripSampleDisposition
            .acceptedDistance],
        3600,
      );
      expect(store.pendingSampleFor(tripId), isNull);
      expect(store.pendingWriteState, TripTrackingPendingWriteState.none);
      expect(controller.acceptedMeters, greaterThan(300000));
      expect(odometer.reading, greaterThan(1200));
      expect(odometer.confirmedReading, 1000);

      final review = await controller.finishForReview(
        finishedAt: startedAt.add(const Duration(hours: 10)),
      );
      expect(review, isNotNull);
      expect(review!.confirmedEndingOdometer, isNull);
      expect(review.isOdometerConfirmed, isFalse);
      expect(odometer.confirmedReading, 1000);
      expect(odometer.hasLiveTripProjection, isFalse);
    },
  );
}
