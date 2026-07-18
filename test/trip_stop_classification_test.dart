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

  test('rideshare creeping pickup traffic stays out of stop review', () {
    final result = replayTrip(
      scenarios.ridesharePickupQueueCreepingTraffic(),
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final classification = classifyScenario(
      scenarios.ridesharePickupQueueCreepingTraffic(),
      TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(classification.requiresUserReview, isFalse);
    expect(classification.canSuggestStop, isFalse);
    expect(
      classification.signal,
      isNot(anyOf(TripStopSignal.reviewOnlyStop, TripStopSignal.stopCandidate)),
    );
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

  test('delivery multi-stop walking proof stays review-only and bounded', () {
    final result = replayTrip(
      scenarios.deliveryMultiStopRouteWithWalkingProof(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final classification = classifyScenario(
      scenarios.deliveryMultiStopRouteWithWalkingProof(),
      TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.count(TripSampleDisposition.excludedWalking), greaterThan(0));
    expect(result.acceptedMiles, greaterThan(0));
    expect(result.acceptedMiles, lessThan(1.0));
    expect(classification.signal, TripStopSignal.reviewOnlyStop);
    expect(classification.actionToken, 'review_delivery_stop');
    expect(summary['stopSignal'], 'review_only_stop');
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
  });

  test('two-person delivery stop without phone walking stays vehicle-only', () {
    final result = replayTrip(
      scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final classification = classifyScenario(
      scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
      TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(classification.canSuggestStop, isFalse);
    expect(classification.requiresUserReview, isFalse);
    expect(classification.signal, isNot(TripStopSignal.reviewOnlyStop));
  });

  test('weak walking false positives while driving do not create stops', () {
    final result = replayTrip(
      scenarios.weakWalkingFalsePositiveWhileDriving(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final classification = classifyScenario(
      scenarios.weakWalkingFalsePositiveWhileDriving(),
      TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.count(TripSampleDisposition.excludedWalking), 0);
    expect(result.acceptedDistanceCount, greaterThan(1));
    expect(classification.signal, TripStopSignal.noStop);
    expect(classification.canSuggestStop, isFalse);
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

  test('walking evidence without accepted vehicle movement fails closed', () {
    final classification = TripStopClassifier.classify(
      profile: TripTrackingProfile.deliveryVehicle,
      motionState: TripMotionState.stopped,
      needsWalkingReview: true,
      excludedWalkingCount: 3,
      rejectedDriftCount: 0,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 0,
    );

    expect(classification.signal, TripStopSignal.unsafeEvidence);
    expect(classification.reasonCode, 'walking_stop_without_vehicle_movement');
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

    expect(summary['schemaVersion'], 1);
    expect(summary['signal'], 'reviewOnlyStop');
    expect(summary['reviewOnly'], isTrue);
    expect(summary['advisoryOnly'], isTrue);
    expect(summary['gpsAssistedOnly'], isTrue);
    expect(summary['manualStopFallbackAvailable'], isTrue);
    expect(summary['vehicleOnlyStopFallbackAvailable'], isTrue);
    expect(summary['longTrafficLightProtected'], isTrue);
    expect(summary['walkingEvidenceCanOnlySuggestReview'], isTrue);
    expect(summary['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(summary['officialStopSource'], 'user_review');
    expect(summary['officialMileageSource'], 'odometer');
    expect(summary['canCreateOfficialStop'], isFalse);
    expect(summary['canReplaceOdometer'], isFalse);
    expect(summary['canEndTripAutomatically'], isFalse);
    expect(summary['stopRequiresAcceptedVehicleMovement'], isTrue);
    expect(summary['mapsRequiredForStopReview'], isFalse);
    expect(summary['mapboxCanCreateStop'], isFalse);
    expect(summary['mapboxCanEndTrip'], isFalse);
    expect(summary['rawSamplesIncluded'], isFalse);
    expect(summary['rawMotionPayloadIncluded'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['mapboxGeometryIncluded'], isFalse);
  });

  test('safe summary sanitizes direct malformed public fields', () {
    const classification = TripStopClassification(
      signal: TripStopSignal.reviewOnlyStop,
      reasonCode: 'token=pk.secret lat=35.1',
      requiresUserReview: true,
      canSuggestStop: true,
      actionToken: 'open_private_map',
      dashboardMessage: 'driver at 35.1,-80.1 token=sk.secret',
    );
    final summary = classification.toSafeSummary();

    expect(summary['reasonCode'], 'unsafe_stop_evidence_rejected');
    expect(summary['actionToken'], 'keep_tracking');
    expect(
      summary['dashboardMessage'],
      'Stop evidence is unavailable. Keep tracking and review mileage later.',
    );
    expect(summary.toString(), isNot(contains('35.1')));
    expect(summary.toString(), isNot(contains('sk.secret')));
    expect(summary['coordinatesIncluded'], isFalse);
  });

  test('traffic and vehicle-only summaries stay manual review only', () {
    final traffic = TripStopClassifier.classify(
      profile: TripTrackingProfile.deliveryVehicle,
      motionState: TripMotionState.moving,
      needsWalkingReview: false,
      excludedWalkingCount: 0,
      rejectedDriftCount: 6,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 5,
    ).toSafeSummary();
    final vehicleOnly = TripStopClassifier.classify(
      profile: TripTrackingProfile.rideshareVehicle,
      motionState: TripMotionState.stopCandidate,
      needsWalkingReview: false,
      excludedWalkingCount: 0,
      rejectedDriftCount: 0,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 4,
    ).toSafeSummary();

    expect(traffic['signal'], 'likelyTrafficControl');
    expect(traffic['longTrafficLightProtected'], isTrue);
    expect(traffic['canCreateOfficialStop'], isFalse);
    expect(traffic['canEndTripAutomatically'], isFalse);
    expect(vehicleOnly['signal'], 'stopCandidate');
    expect(vehicleOnly['vehicleOnlyStopFallbackAvailable'], isTrue);
    expect(vehicleOnly['walkingEvidenceCanOnlySuggestReview'], isTrue);
    expect(vehicleOnly['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(vehicleOnly['mapboxCanEndTrip'], isFalse);
  });
}
