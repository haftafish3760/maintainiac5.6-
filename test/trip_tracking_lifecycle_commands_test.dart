import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);

  TripTrackingController controllerFor(
    TripTrackingSessionStore store,
    GlobalOdometerController odometer,
  ) => TripTrackingController(
    sessionStore: store,
    odometer: odometer,
    activeProfileId: () => 'profile_1',
    clockNow: () => started.add(const Duration(hours: 1)),
  );

  test(
    'manual pause is distinct and durable without a native adapter',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = controllerFor(
        store,
        GlobalOdometerController(vehicleId: 'vehicle_1', initialReading: 1000),
      );
      expect(
        await controller.start(
          tripId: 'trip_manual_pause',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: started,
        ),
        isTrue,
      );

      expect(await controller.pauseByUser(), isTrue);
      expect(
        store.activeSession?.lifecycleState,
        TripTrackingSessionLifecycleState.pausedByUser,
      );
      expect(
        store.transitionEventsFor('trip_manual_pause').last.reasonCode,
        'lifecycle_condition_changed',
      );
    },
  );

  test(
    'meaningful cancellation requires confirmation and preserves history',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = controllerFor(
        store,
        GlobalOdometerController(vehicleId: 'vehicle_1', initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_cancel_evidence',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: started,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: started,
          horizontalAccuracyMeters: 5,
        ),
        referenceTime: started,
      );

      expect(await controller.cancelSession(userConfirmed: false), isFalse);
      expect(store.activeSession, isNotNull);
      expect(
        await controller.cancelSession(
          userConfirmed: true,
          cancelledAt: started.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      expect(store.activeSession, isNull);
      expect(store.cancelledSessions, hasLength(1));
      expect(store.cancelledSessions.single.hasMeaningfulEvidence, isTrue);
      expect(
        store.transitionEventsFor('trip_cancel_evidence').last.newState,
        TripTrackingSessionLifecycleState.cancelled,
      );
    },
  );

  test(
    'completion pending survives recovery until odometer confirmation',
    () async {
      final store = TripTrackingSessionStore.memory();
      final ownerOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final owner = controllerFor(store, ownerOdometer);
      await owner.start(
        tripId: 'trip_completion_pending',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: started,
      );
      expect(
        await owner.finishForReview(
          finishedAt: started.add(const Duration(minutes: 10)),
        ),
        isNotNull,
      );
      expect(owner.isTracking, isFalse);
      expect(
        store.activeSession?.lifecycleState,
        TripTrackingSessionLifecycleState.completionPending,
      );

      final recoveredOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final recovered = controllerFor(store, recoveredOdometer);
      expect(await recovered.restore(), isTrue);
      expect(recovered.isTracking, isFalse);
      expect(recovered.platformStatus, 'completion_pending');
      expect(
        await recovered.confirmOdometerReview(
          reviewId: 'trip_completion_pending',
          confirmedEndingOdometer: 1000,
          confirmedAt: started.add(const Duration(minutes: 11)),
        ),
        isTrue,
      );
      expect(store.activeSession, isNull);
      expect(
        store.reviewForTrip('trip_completion_pending')?.isOdometerConfirmed,
        isTrue,
      );
      expect(
        store.transitionEventsFor('trip_completion_pending').last.newState,
        TripTrackingSessionLifecycleState.completed,
      );
    },
  );
}
