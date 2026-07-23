import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  for (final testCase
      in <({TripTrackingSessionLifecycleState state, String expectedStatus})>[
        (
          state: TripTrackingSessionLifecycleState.cancelled,
          expectedStatus: 'cancelled_review_invalid',
        ),
        (
          state: TripTrackingSessionLifecycleState.stopping,
          expectedStatus: 'completion_review_invalid',
        ),
      ]) {
    test('${testCase.state.name} recovery preserves a mismatched review and '
        'checkpoint for repair', () async {
      final store = TripTrackingSessionStore.memory();
      final startedAt = DateTime.utc(2026, 7, 23, 9);
      final finishedAt = startedAt.add(const Duration(minutes: 20));
      final session = TripTrackingSessionRecord(
        id: 'trip_${testCase.state.name}_review_mismatch',
        vehicleId: 'vehicle_1',
        startingOdometer: 5000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
        updatedAt: finishedAt,
        lifecycleState: testCase.state,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 3200,
          walkingReviewSuggested: false,
        ),
        revision: 2,
      );
      await store.save(session);
      final mismatchedReview = TripTrackingReviewRecord(
        id: session.id,
        vehicleId: session.vehicleId,
        startingOdometer: 4999,
        estimatedEndingOdometer: 5001,
        profile: session.profile,
        startedAt: startedAt,
        finishedAt: finishedAt,
        engineSnapshot: session.engineSnapshot,
        revision: session.revision,
      );
      await store.saveReview(mismatchedReview);
      final odometer = GlobalOdometerController(
        vehicleId: session.vehicleId,
        initialReading: session.startingOdometer,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      addTearDown(controller.dispose);

      expect(await controller.restore(), isFalse);

      expect(controller.platformStatus, testCase.expectedStatus);
      expect(store.activeSession?.id, session.id);
      expect(
        store.recoveryReviewForTrip(session.id)?.startingOdometer,
        mismatchedReview.startingOdometer,
      );
      expect(odometer.confirmedReading, session.startingOdometer);
    });
  }
}
