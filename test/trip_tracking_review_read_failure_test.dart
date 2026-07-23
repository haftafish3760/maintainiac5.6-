import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('review-facing reads fail safely when local storage is unavailable', () {
    final controller = TripTrackingController(
      sessionStore: _UnavailableReviewStore(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle-1',
        initialReading: 12000,
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.latestReview, isNull);
    expect(controller.latestReviewForVehicle('vehicle-1'), isNull);
    expect(controller.latestUnconfirmedReview, isNull);
    expect(() => controller.odometerCalibrationSignal(), returnsNormally);
    expect(
      () => controller.odometerUsageAnomalySignal(currentOdometerMiles: 10),
      returnsNormally,
    );
    expect(
      () => controller.odometerUsageAnomalySignalForCurrentDay(),
      returnsNormally,
    );
    expect(
      () => controller.refreshGpsAssistanceCalibration(enabled: true),
      returnsNormally,
    );
    expect(
      () => controller.driverPatternDecision(profileId: 'profile-1'),
      returnsNormally,
    );
    expect(controller.platformStatus, 'storage_failed');
    expect(
      controller.platformError,
      'Could not read locally saved trip reviews.',
    );
    expect(controller.activeSession, isNull);
  });

  test(
    'review actions return controlled results when storage is unavailable',
    () async {
      final controller = TripTrackingController(
        sessionStore: _UnavailableReviewStore(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        ),
      );
      addTearDown(controller.dispose);

      expect(
        controller.evaluateOdometerEndReview(
          reviewId: 'trip-1',
          endingOdometer: 12001,
        ),
        isNull,
      );
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip-1',
          confirmedEndingOdometer: 12001,
        ),
        isFalse,
      );
      expect(
        await controller.saveCompletionDraft(
          tripId: 'trip-1',
          endingOdometerDraft: 12001,
        ),
        isFalse,
      );
      expect(await controller.retryTripLogProposal('trip-1'), isFalse);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        'Could not read the locally saved trip review.',
      );
      expect(controller.activeSession, isNull);
    },
  );
}

class _UnavailableReviewStore extends TripTrackingSessionStore {
  _UnavailableReviewStore() : super.memory();

  @override
  List<TripTrackingReviewRecord> get pendingReviews =>
      throw StateError('review storage unavailable');

  @override
  TripTrackingReviewRecord? reviewForTrip(String tripId) =>
      throw StateError('review storage unavailable');
}
