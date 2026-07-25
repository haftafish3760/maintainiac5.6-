import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_trip_log_proposal.dart';

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

  test(
    'startup proposal retry cannot crash on unreadable review storage',
    () async {
      final controller = TripTrackingController(
        sessionStore: _UnavailableReviewStore(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        ),
        tripLogProposalSink: _NoopProposalSink(),
      );
      addTearDown(controller.dispose);

      expect(await controller.retryPendingTripLogProposals(), 0);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        'Could not read locally saved trip reviews.',
      );
    },
  );

  test('successful review reads clear only their matching storage error', () {
    final store = _RecoveringReviewStore();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle-1',
        initialReading: 12000,
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.latestReview, isNull);
    expect(controller.platformStatus, 'storage_failed');
    store.failPendingReviews = false;
    expect(controller.latestReview, isNull);
    expect(controller.platformStatus, isNull);

    expect(
      controller.evaluateOdometerEndReview(
        reviewId: 'trip-1',
        endingOdometer: 12001,
      ),
      isNull,
    );
    expect(controller.platformStatus, 'storage_failed');
    store.failReview = false;
    expect(
      controller.evaluateOdometerEndReview(
        reviewId: 'trip-1',
        endingOdometer: 12001,
      ),
      isNull,
    );
    expect(controller.platformStatus, isNull);
    expect(controller.platformError, isNull);
  });

  test(
    'starting a trip cannot erase an unrelated review-storage warning',
    () async {
      final store = _RecoveringReviewStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 12000,
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.latestReview, isNull);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        await controller.start(
          tripId: 'trip-1',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
        ),
        isTrue,
      );
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        'Could not read locally saved trip reviews.',
      );

      store.failPendingReviews = false;
      expect(controller.latestReview, isNull);
      expect(controller.platformStatus, isNull);
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

class _RecoveringReviewStore extends TripTrackingSessionStore {
  _RecoveringReviewStore() : super.memory();

  var failPendingReviews = true;
  var failReview = true;

  @override
  List<TripTrackingReviewRecord> get pendingReviews {
    if (failPendingReviews) throw StateError('review storage unavailable');
    return super.pendingReviews;
  }

  @override
  TripTrackingReviewRecord? reviewForTrip(String tripId) {
    if (failReview) throw StateError('review storage unavailable');
    return super.reviewForTrip(tripId);
  }
}

class _NoopProposalSink implements TripTrackingTripLogProposalSink {
  @override
  Future<void> propose(TripTrackingTripLogProposal proposal) async {}
}
