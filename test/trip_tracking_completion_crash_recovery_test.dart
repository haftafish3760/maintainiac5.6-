import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('stopping checkpoint rebuilds completion-pending review', () async {
    final store = TripTrackingSessionStore.memory();
    final startedAt = DateTime.utc(2026, 7, 21, 12);
    final stoppedAt = startedAt.add(const Duration(minutes: 30));
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_stop_crash_window',
        vehicleId: 'vehicle_1',
        startingOdometer: 9000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
        updatedAt: stoppedAt,
        lifecycleState: TripTrackingSessionLifecycleState.stopping,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 4200,
          walkingReviewSuggested: false,
        ),
        transitionAudits: [
          TripTrackingSessionTransitionAudit(
            id: 'trip_stop_crash_window:2',
            sessionId: 'trip_stop_crash_window',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.roadVehicle,
            profileId: 'roadVehicle',
            fromState: TripTrackingSessionLifecycleState.active,
            toState: TripTrackingSessionLifecycleState.stopping,
            eventTimestamp: stoppedAt,
            sequenceNumber: 2,
            reasonCode: 'trip_review_requested',
            initiatingSource: 'user_finish_for_review',
            revision: 2,
            permissionState: 'permission_granted',
            confidenceState: 'healthy',
            trackingQualityMode: 'high_quality',
          ),
        ],
      ),
    );
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 9000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );
    addTearDown(controller.dispose);

    expect(await controller.restore(), isFalse);
    final review = store.reviewForTrip('trip_stop_crash_window');
    expect(review, isNotNull);
    expect(review!.finishedAt, stoppedAt);
    expect(review.confirmedEndingOdometer, isNull);
    expect(review.engineSnapshot.totalAcceptedMeters, 4200);
    expect(store.activeSession, isNull);
    expect(odometer.confirmedReading, 9000);
    expect(controller.platformStatus, 'completion_review_recovered');
  });
}
