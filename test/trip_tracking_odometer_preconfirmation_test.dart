import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_end_review_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'meaningful discrepancy requires explicit pre-confirm acknowledgement',
    () async {
      final startedAt = DateTime.utc(2026, 7, 21, 12);
      final finishedAt = startedAt.add(const Duration(hours: 1));
      final confirmedAt = finishedAt.add(const Duration(minutes: 1));
      final store = TripTrackingSessionStore.memory();
      await store.saveReview(
        TripTrackingReviewRecord(
          id: 'trip_preconfirm',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1025,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
          finishedAt: finishedAt,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 25 * 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => confirmedAt,
      );
      addTearDown(controller.dispose);

      final decision = controller.evaluateOdometerEndReview(
        reviewId: 'trip_preconfirm',
        endingOdometer: 1001,
        nowUtc: confirmedAt,
      );
      expect(decision, isNotNull);
      expect(decision!.status, TripOdometerEndReviewStatus.reviewRecommended);
      expect(decision.canConfirmOdometer, isTrue);
      expect(decision.shouldShowReviewBeforeConfirm, isTrue);

      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_preconfirm',
          confirmedEndingOdometer: 1001,
          confirmedAt: confirmedAt,
        ),
        isFalse,
      );
      expect(odometer.confirmedReading, 1000);
      expect(
        controller.platformStatus,
        'odometer_review_acknowledgement_required',
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_preconfirm',
          confirmedEndingOdometer: 1001,
          confirmedAt: confirmedAt,
          userAcknowledgedReviewPrompt: true,
        ),
        isTrue,
      );
      expect(odometer.confirmedReading, 1001);
    },
  );
}
