import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_recovery_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'completion draft preserves lower reading and reasoned adjustments',
    () async {
      final now = DateTime.utc(2026, 7, 21, 12);
      final store = TripTrackingSessionStore.memory();
      await store.saveReview(
        TripTrackingReviewRecord(
          id: 'draft_trip',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1010,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
          finishedAt: now.add(const Duration(hours: 1)),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 16000,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      final adjustment = TripManualMileageAdjustment(
        id: 'adjustment_1',
        deltaMiles: 2.5,
        reason: TripManualMileageAdjustmentReason.gpsGap,
        createdAt: now.add(const Duration(hours: 1)),
        userConfirmed: true,
        note: 'Route reviewed by driver',
      );

      expect(
        await controller.saveCompletionDraft(
          tripId: 'draft_trip',
          endingOdometerDraft: 995,
          manualAdjustments: [adjustment],
        ),
        isTrue,
      );
      final saved = store.reviewForTrip('draft_trip')!;
      final restored = TripTrackingReviewRecord.fromMap(saved.toMap());

      expect(restored.endingOdometerDraft, 995);
      expect(restored.isOdometerConfirmed, isFalse);
      expect(restored.manualAdjustments, hasLength(1));
      expect(
        restored.manualAdjustments.single.reason,
        TripManualMileageAdjustmentReason.gpsGap,
      );
      expect(
        restored.manualAdjustments.single.canRewriteConfirmedOdometer,
        isFalse,
      );
      expect(restored.toMap().toString(), isNot(contains('latitude')));
    },
  );

  test(
    'successful completion-draft retry clears its storage warning',
    () async {
      final now = DateTime.utc(2026, 7, 21, 12);
      final store = _FailingReviewSaveStore();
      await store.saveReview(
        TripTrackingReviewRecord(
          id: 'draft_retry',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1010,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
          finishedAt: now.add(const Duration(hours: 1)),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 16000,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      addTearDown(controller.dispose);

      store.failNextReviewSave = true;
      expect(
        await controller.saveCompletionDraft(
          tripId: 'draft_retry',
          endingOdometerDraft: 1010,
        ),
        isFalse,
      );
      expect(controller.platformStatus, 'storage_failed');

      expect(
        await controller.saveCompletionDraft(
          tripId: 'draft_retry',
          endingOdometerDraft: 1010,
        ),
        isTrue,
      );
      expect(controller.platformStatus, isNull);
      expect(controller.platformError, isNull);
    },
  );

  test('duplicate or private manual adjustments fail closed', () async {
    final now = DateTime.utc(2026, 7, 21, 12);
    final adjustment = TripManualMileageAdjustment(
      id: 'adjustment_duplicate',
      deltaMiles: 2.5,
      reason: TripManualMileageAdjustmentReason.gpsGap,
      createdAt: now.add(const Duration(days: 2)),
      userConfirmed: true,
      note: 'token=sk.private at 35.12345,-80.98765',
    );
    final review = TripTrackingReviewRecord(
      id: 'draft_private_adjustment',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1010,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: now,
      finishedAt: now.add(const Duration(hours: 1)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 16000,
        walkingReviewSuggested: false,
      ),
      manualAdjustments: [adjustment, adjustment],
    );

    await expectLater(
      TripTrackingSessionStore.memory().saveReview(review),
      throwsArgumentError,
    );
    final validation = TripTrackingSessionRecoveryValidation.review(
      review,
      recoveredAt: now.add(const Duration(days: 1)),
    );
    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('invalid_manual_adjustment_in_review'));
  });
}

class _FailingReviewSaveStore extends TripTrackingSessionStore {
  _FailingReviewSaveStore() : super.memory();

  var failNextReviewSave = false;

  @override
  Future<void> saveReview(TripTrackingReviewRecord review) {
    if (failNextReviewSave) {
      failNextReviewSave = false;
      return Future<void>.error(StateError('review storage unavailable'));
    }
    return super.saveReview(review);
  }
}
