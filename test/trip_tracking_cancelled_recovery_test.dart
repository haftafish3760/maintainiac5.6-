import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'cancelled checkpoint deterministically rebuilds preserved review',
    () async {
      final store = TripTrackingSessionStore.memory();
      final startedAt = DateTime.utc(2026, 7, 21, 18);
      final cancelledAt = startedAt.add(const Duration(minutes: 20));
      await store.save(
        TripTrackingSessionRecord(
          id: 'trip_cancel_crash_window',
          vehicleId: 'vehicle_1',
          startingOdometer: 5000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
          updatedAt: cancelledAt,
          lifecycleState: TripTrackingSessionLifecycleState.cancelled,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 3200,
            walkingReviewSuggested: false,
          ),
          revision: 2,
          transitionAudits: [
            TripTrackingSessionTransitionAudit(
              id: 'trip_cancel_crash_window:2',
              sessionId: 'trip_cancel_crash_window',
              vehicleId: 'vehicle_1',
              profile: TripTrackingProfile.roadVehicle,
              profileId: 'roadVehicle',
              fromState: TripTrackingSessionLifecycleState.active,
              toState: TripTrackingSessionLifecycleState.cancelled,
              eventTimestamp: cancelledAt,
              sequenceNumber: 2,
              reasonCode: 'trip_cancelled',
              initiatingSource: 'user_cancel',
              revision: 2,
              permissionState: 'permission_granted',
              confidenceState: 'healthy',
              trackingQualityMode: 'high_quality',
            ),
          ],
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 5000,
        ),
      );
      addTearDown(controller.dispose);

      expect(await controller.restore(), isFalse);
      final review = store.reviewForTrip('trip_cancel_crash_window');
      expect(review, isNotNull);
      expect(review!.finishedAt, cancelledAt);
      expect(review.estimatedEndingOdometerTenths, 50019);
      expect(review.estimatedEndingOdometer, 5001);
      expect(
        review.transitionAudits.last.toState,
        TripTrackingSessionLifecycleState.cancelled,
      );
      expect(review.confirmedEndingOdometer, isNull);
      expect(store.activeSession, isNull);
      expect(controller.platformStatus, 'cancelled_review_recovered');
    },
  );

  test('new start cannot erase a cancelled checkpoint', () async {
    final store = TripTrackingSessionStore.memory();
    final at = DateTime.utc(2026, 7, 21, 20);
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_cancel_preserved',
        vehicleId: 'vehicle_1',
        startingOdometer: 5000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
        updatedAt: at.add(const Duration(minutes: 1)),
        lifecycleState: TripTrackingSessionLifecycleState.cancelled,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 100,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 5000,
      ),
    );
    addTearDown(controller.dispose);

    expect(
      await controller.start(
        tripId: 'replacement_trip',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
      ),
      isFalse,
    );
    expect(store.activeSession?.id, 'trip_cancel_preserved');
    expect(controller.platformStatus, 'cancelled_review_pending');
  });

  test(
    'restore quarantines terminal trip evidence without erasing it',
    () async {
      final store = TripTrackingSessionStore.memory();
      final at = DateTime.utc(2026, 7, 21, 21);
      await store.save(
        TripTrackingSessionRecord(
          id: 'trip_terminal_preserved',
          vehicleId: 'vehicle_1',
          startingOdometer: 5000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: at,
          updatedAt: at.add(const Duration(minutes: 1)),
          lifecycleState: TripTrackingSessionLifecycleState.failedTerminal,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 100,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 5000,
        ),
      );
      addTearDown(controller.dispose);

      expect(await controller.restore(), isFalse);
      expect(store.activeSession, isNull);
      expect(store.quarantinedSessions, hasLength(1));
      expect(
        store.quarantinedSessions.single.sessionId,
        'trip_terminal_preserved',
      );
      expect(
        store.quarantinedSessions.single.sessionPayload['lifecycleState'],
        TripTrackingSessionLifecycleState.failedTerminal.name,
      );
      expect(controller.platformStatus, 'session_quarantined');
    },
  );
}
