import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary();

  TripStopClassification classifyScenario(
    List<SimulatedTripPoint> points,
    TripTrackingProfile profile,
  ) {
    final result = replayTrip(points, profile: profile);
    return TripStopClassifier.classify(
      profile: profile,
      motionState: result.motionState,
      needsWalkingReview: result.needsWalkingReview,
      excludedWalkingCount: result.count(TripSampleDisposition.excludedWalking),
      rejectedDriftCount: result.count(TripSampleDisposition.rejectedDrift),
      rejectedUnsafeCount:
          result.count(TripSampleDisposition.rejectedInvalid) +
          result.count(TripSampleDisposition.rejectedMockLocation) +
          result.count(TripSampleDisposition.rejectedAccuracy) +
          result.count(TripSampleDisposition.rejectedOutOfOrder),
      acceptedDistanceCount: result.acceptedDistanceCount,
    );
  }

  test('delivery walking stop becomes review-only dashboard guidance', () {
    final classification = classifyScenario(
      scenarios.deliveryDriverLeavesVehicle(),
      TripTrackingProfile.deliveryVehicle,
    );

    expect(classification.signal, TripStopSignal.reviewOnlyStop);
    expect(classification.requiresUserReview, isTrue);
    expect(classification.canSuggestStop, isTrue);
    expect(classification.actionToken, 'review_delivery_stop');
    expect(classification.reasonCode, 'delivery_stop_walk_review');
  });

  test('contractor walking stop points to jobsite review', () {
    final classification = classifyScenario(
      scenarios.contractorJobsiteWalkAround(),
      TripTrackingProfile.contractorVehicle,
    );

    expect(classification.signal, TripStopSignal.reviewOnlyStop);
    expect(classification.actionToken, 'review_jobsite_stop');
    expect(classification.dashboardMessage, contains('job-site'));
  });

  test('rideshare vehicle-only waiting does not create a stop', () {
    final classification = classifyScenario(
      scenarios.rideshareDriverStaysInVehicle(),
      TripTrackingProfile.rideshareVehicle,
    );

    expect(classification.signal, TripStopSignal.likelyTrafficControl);
    expect(classification.requiresUserReview, isFalse);
    expect(classification.canSuggestStop, isFalse);
  });

  test('sustained rideshare walking becomes a shift-stop review', () {
    final classification = classifyScenario(
      scenarios.rideshareDriverWalksAfterShiftStop(),
      TripTrackingProfile.rideshareVehicle,
    );

    expect(classification.signal, TripStopSignal.reviewOnlyStop);
    expect(classification.actionToken, 'review_shift_stop');
    expect(classification.reasonCode, contains('rideshare'));
  });

  test('long traffic light jitter stays out of stop review workflow', () {
    final classification = classifyScenario(
      scenarios.longTrafficLightWithUrbanJitter(),
      TripTrackingProfile.deliveryVehicle,
    );

    expect(classification.signal, TripStopSignal.likelyTrafficControl);
    expect(classification.actionToken, 'keep_tracking');
    expect(classification.dashboardMessage, contains('traffic light'));
  });

  test('unsafe provider evidence fails closed without a stop suggestion', () {
    final classification = classifyScenario(
      scenarios.hostileProviderReplay(),
      TripTrackingProfile.deliveryVehicle,
    );

    expect(classification.signal, TripStopSignal.noStop);
    expect(classification.canSuggestStop, isFalse);
    expect(classification.requiresUserReview, isFalse);
  });

  test('safe summary never exposes route samples or geometry', () {
    final summary = TripStopClassifier.classify(
      profile: TripTrackingProfile.contractorVehicle,
      motionState: TripMotionState.stopped,
      needsWalkingReview: true,
      excludedWalkingCount: 3,
      rejectedDriftCount: 0,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 2,
    ).toSafeSummary();

    expect(summary['signal'], 'reviewOnlyStop');
    expect(summary['rawSamplesIncluded'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
  });
}
