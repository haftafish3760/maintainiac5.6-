import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sample_window_quality_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

import 'support/trip_tracking_qa/trip_tracking_commercial_edge_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final start = DateTime.utc(2026, 7, 17, 12);
  final scenarios = TripTrackingScenarioLibrary(start: start);
  final commercialScenarios = TripTrackingCommercialEdgeScenarios(start: start);

  TripLocationSample point(
    double longitude,
    int seconds, {
    double accuracy = 5,
    double? speed,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speed,
  );

  TripActivityObservation walking(int seconds) => TripActivityObservation(
    activity: TripActivity.walking,
    confidence: 92,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  TripRouteHistoryCaptureDecision routeDecision({
    bool optedIntoMaps = true,
    bool optedIntoHistory = true,
    double budgetMb = 1,
  }) {
    return TripRouteHistoryCapturePolicy.evaluate(
      accountTier: TripRouteHistoryAccountTier.free,
      gpsAssistedTrackingEnabled: true,
      userOptedIntoMaps: optedIntoMaps,
      userOptedIntoRouteHistory: optedIntoHistory,
      mapboxRuntimeAvailable: optedIntoMaps,
      requestedDailyBudgetMb: budgetMb,
      availableStorageMb: 2000,
      requestedSampleIntervalSeconds: 15,
    );
  }

  test('delivery parking-lot crawl does not turn into walking mileage', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 5)),
      SimulatedTripPoint(point(-79.9995, 15, speed: 5)),
      SimulatedTripPoint(point(-79.99945, 30, speed: .6)),
      SimulatedTripPoint(point(-79.9994, 45, speed: .5)),
      SimulatedTripPoint(point(-79.99935, 60, speed: .4)),
      SimulatedTripPoint(point(-79.9993, 75, speed: .5)),
      SimulatedTripPoint(point(-79.9987, 95, speed: 7)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedMeters, greaterThan(80));
    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(1));
  });

  test('highway delivery run accepts credible fast movement', () {
    final result = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 27)),
      SimulatedTripPoint(point(-79.995, 20, speed: 27)),
      SimulatedTripPoint(point(-79.990, 40, speed: 27)),
      SimulatedTripPoint(point(-79.985, 60, speed: 27)),
    ], profile: TripTrackingProfile.deliveryVehicle);

    expect(result.acceptedMeters, greaterThan(1200));
    expect(result.count(TripSampleDisposition.rejectedImplausibleSpeed), 0);
    expect(result.count(TripSampleDisposition.rejectedSpeedConflict), 0);
  });

  test('contractor stop requires repeated fresh walking evidence', () {
    final singleWalk = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.99895, 35), activity: walking(35)),
      SimulatedTripPoint(point(-79.998, 75, speed: 8)),
    ], profile: TripTrackingProfile.contractorVehicle);
    final repeatedWalk = replayTrip([
      SimulatedTripPoint(point(-80, 0, speed: 8)),
      SimulatedTripPoint(point(-79.999, 20, speed: 8)),
      SimulatedTripPoint(point(-79.99895, 35), activity: walking(35)),
      SimulatedTripPoint(point(-79.99890, 50), activity: walking(50)),
      SimulatedTripPoint(point(-79.99885, 65), activity: walking(65)),
      SimulatedTripPoint(point(-79.99880, 80), activity: walking(80)),
    ], profile: TripTrackingProfile.contractorVehicle);

    expect(singleWalk.needsWalkingReview, isFalse);
    expect(repeatedWalk.needsWalkingReview, isTrue);
    expect(repeatedWalk.acceptedMeters, lessThan(singleWalk.acceptedMeters));
  });

  test('stop detection requires time-spaced evidence, not sensor bursts', () {
    final burst = replayTrip(
      scenarios.burstWalkingMisfireAtStoplight(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final spaced = replayTrip(
      scenarios.deliveryStopWithWellSpacedWalkingEvidence(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(burst.needsWalkingReview, isFalse);
    expect(burst.motionState, isNot(TripMotionState.stopped));
    expect(spaced.needsWalkingReview, isTrue);
    expect(spaced.motionState, TripMotionState.stopped);
  });

  test('stale walking evidence is discarded after movement continues', () {
    final result = replayTrip(
      scenarios.staleWalkingAfterDriveResumes(),
      profile: TripTrackingProfile.contractorVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.motionState, TripMotionState.moving);
    expect(result.acceptedDistanceCount, greaterThan(1));
  });

  test('two-person delivery with phone in vehicle remains vehicle-only', () {
    final result = replayTrip(
      scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(summary['stopSignal'], anyOf('likely_traffic_control', 'no_stop'));
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopCanReplaceOdometer'], isFalse);
    expect(summary['mapsRequiredForStopReview'], isFalse);
    expect(summary['simulationCanCreateOfficialStop'], isFalse);
    expect(summary['simulationCanReplaceOdometer'], isFalse);
  });

  test(
    'multi-stop delivery route stays review-only and never auto-commits',
    () {
      final result = replayTrip(
        scenarios.deliveryMultiStopRouteWithWalkingProof(),
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.needsWalkingReview, isTrue);
      expect(summary['stopSignal'], 'review_only_stop');
      expect(summary['stopReviewConfidence'], 'high');
      expect(summary['stopCanSuggestReview'], isTrue);
      expect(summary['stopRequiresUserReview'], isTrue);
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['stopReviewConfidenceCanCreateOfficialStop'], isFalse);
      expect(summary['stopReviewConfidenceCanEndTripAutomatically'], isFalse);
      expect(summary['officialStopSource'], 'user_review');
      expect(summary['officialMileageSource'], 'odometer');
    },
  );

  test(
    'rideshare pickup queue creeping traffic stays manual fallback only',
    () {
      final result = replayTrip(
        scenarios.ridesharePickupQueueCreepingTraffic(),
        profile: TripTrackingProfile.rideshareVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.rideshareVehicle,
      );

      expect(result.needsWalkingReview, isFalse);
      expect(summary['stopCanSuggestReview'], isFalse);
      expect(summary['stopRequiresUserReview'], isFalse);
      expect(summary['stopShouldSurfaceManualFallback'], isTrue);
      expect(summary['stopReviewConfidence'], 'low');
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['mapsRequiredForStopReview'], isFalse);
    },
  );

  test('weak walking false positives cannot surface a stop review', () {
    final result = replayTrip(
      scenarios.weakWalkingFalsePositiveWhileDriving(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedDistanceCount, greaterThan(2));
    expect(result.excludedWalkingCount, isZero);
    expect(summary['stopReviewConfidence'], 'none');
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
  });

  test('two-person delivery can surface manual fallback without auto stop', () {
    final result = replayTrip(
      scenarios.deliveryPhoneStaysInVehicleAtCustomerStop(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    if (summary['stopSignal'] == 'likely_traffic_control') {
      expect(summary['stopShouldSurfaceManualFallback'], isTrue);
    }
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['officialStopSource'], 'user_review');
  });

  test('hostile provider replay cannot become stop or mileage truth', () {
    final result = replayTrip(
      scenarios.hostileProviderReplay(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedMiles, lessThan(.1));
    expect(summary['stopSignal'], 'unsafe_evidence');
    expect(summary['stopReviewConfidence'], 'none');
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopShouldSurfaceManualFallback'], isFalse);
    expect(summary['simulationCanCreateOfficialStop'], isFalse);
    expect(summary['simulationCanReplaceOdometer'], isFalse);
    expect(summary['officialMileageSource'], 'odometer');
    expect(summary.toString(), isNot(contains('-79.')));
    expect(summary.toString(), isNot(contains('35.')));
  });

  test(
    'delivery acceleration spike is rejected before it can inflate miles',
    () {
      final result = replayTrip(
        scenarios.accelerationSpikeDuringDeliveryRoute(),
        profile: TripTrackingProfile.deliveryVehicle,
        policy: const TripTrackingPolicy(
          maximumPlausibleSpeedMetersPerSecond: 100,
          maximumReportedSpeedDisagreementMetersPerSecond: 100,
          maximumReportedAccelerationMetersPerSecondSquared: 5,
        ),
      );

      expect(result.count(TripSampleDisposition.rejectedSpeedConflict), 1);
      expect(result.needsWalkingReview, isFalse);
      expect(result.acceptedMeters, lessThan(30));
    },
  );

  test('rideshare airport queue long wait does not become auto stop', () {
    final result = replayTrip(
      commercialScenarios.rideshareAirportQueueLongWait(),
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopReviewConfidenceCanEndTripAutomatically'], isFalse);
    expect(summary['officialStopSource'], 'user_review');
  });

  test('delivery apartment multi-door walking stays review-only', () {
    final result = replayTrip(
      commercialScenarios.deliveryApartmentComplexMultiDoorWalks(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(2));
    expect(summary['stopSignal'], 'review_only_stop');
    expect(summary['stopReviewConfidence'], 'high');
    expect(summary['stopCanSuggestReview'], isTrue);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopReviewConfidenceCanCreateOfficialStop'], isFalse);
    expect(summary['officialMileageSource'], 'odometer');
  });

  test('contractor supply and jobsite walking stays user-review gated', () {
    final result = replayTrip(
      commercialScenarios.contractorSupplyCounterThenJobsiteWalk(),
      profile: TripTrackingProfile.contractorVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.contractorVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(summary['stopSignal'], 'review_only_stop');
    expect(summary['stopReviewConfidence'], 'high');
    expect(summary['stopCanSuggestReview'], isTrue);
    expect(summary['stopRequiresUserReview'], isTrue);
    expect(summary['simulationCanCreateOfficialStop'], isFalse);
    expect(summary['simulationCanReplaceOdometer'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
  });

  test(
    'delivery stoplight followed by real door walk preserves both signals',
    () {
      final result = replayTrip(
        commercialScenarios.deliveryStoplightThenConfirmedDoorWalk(),
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.needsWalkingReview, isTrue);
      expect(
        result.count(TripSampleDisposition.rejectedDrift),
        greaterThanOrEqualTo(8),
      );
      expect(
        result.count(TripSampleDisposition.excludedWalking),
        greaterThanOrEqualTo(3),
      );
      expect(summary['stopSignal'], 'review_only_stop');
      expect(summary['stopCanSuggestReview'], isTrue);
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['officialMileageSource'], 'odometer');
      expect(summary['mapsRequiredForStopReview'], isFalse);
    },
  );

  test('rideshare brief pickup walk waits for stronger stop evidence', () {
    final result = replayTrip(
      commercialScenarios.rideshareBriefWalkAtPickupDoor(),
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['officialStopSource'], 'user_review');
  });

  test(
    'provider burst reanchors before recovery drive without odometer truth',
    () {
      final result = replayTrip(
        commercialScenarios.deliveryProviderBurstThenRecoveryDrive(),
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.rejectedGpsJumpCount, greaterThanOrEqualTo(1));
      expect(result.acceptedMeters, greaterThan(150));
      expect(result.acceptedMeters, lessThan(400));
      expect(summary['simulationCanReplaceOdometer'], isFalse);
      expect(summary['officialMileageSource'], 'odometer');
      expect(summary['stopCanCreateOfficialStop'], isFalse);
    },
  );

  test('delivery drive-thru queue waits for real door-walk review', () {
    final result = replayTrip(
      commercialScenarios.deliveryDriveThruQueueThenDoorWalk(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(3));
    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(5));
    expect(summary['stopSignal'], 'review_only_stop');
    expect(summary['stopCanSuggestReview'], isTrue);
    expect(summary['stopRequiresUserReview'], isTrue);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['officialMileageSource'], 'odometer');
    expect(summary['mapsRequiredForStopReview'], isFalse);
  });

  test('rideshare passenger swap without driver walk never auto-stops', () {
    final result = replayTrip(
      commercialScenarios.ridesharePassengerSwapNoDriverWalk(),
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.acceptedMeters, greaterThan(200));
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopReviewConfidenceCanEndTripAutomatically'], isFalse);
    expect(summary['officialStopSource'], 'user_review');
  });

  test('contractor back-to-back short jobs remain review-only', () {
    final result = replayTrip(
      commercialScenarios.contractorBackToBackShortJobs(),
      profile: TripTrackingProfile.contractorVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.contractorVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(2));
    expect(summary['stopSignal'], 'review_only_stop');
    expect(summary['stopReviewConfidence'], 'high');
    expect(summary['stopCanSuggestReview'], isTrue);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['simulationCanReplaceOdometer'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
  });

  test(
    'commercial replay quality rejects stale and future samples before maps',
    () {
      final sampleWindow = [
        point(-80, 0, speed: 10),
        point(-79.999, 20, speed: 10),
        point(-79.998, 40, speed: 10),
        point(-79.997, 900, speed: 10),
        point(-79.996, 1000, speed: 10),
      ];
      final quality = TripSampleWindowQualityPolicy.evaluate(
        evaluationNow: start.add(const Duration(seconds: 60)),
        maximumSampleAge: const Duration(minutes: 5),
        maximumFutureSkew: const Duration(seconds: 30),
        samples: sampleWindow,
        routeHistoryDecision: routeDecision(),
      );
      final replay = replayTrip(
        sampleWindow.map(SimulatedTripPoint.new).toList(),
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final summary = replay.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      );
      final safeQuality = quality.toSafeDashboardMap();

      expect(
        quality.status,
        TripSampleWindowQualityStatus.degradedTrackingOnly,
      );
      expect(quality.rejectedSampleCount, 2);
      expect(quality.canFeedLiveOdometerProjection, isTrue);
      expect(safeQuality['futureSamplesRejected'], isTrue);
      expect(safeQuality['remoteWindowCanRepairInvalidSamples'], isFalse);
      expect(summary['simulationCanReplaceOdometer'], isFalse);
      expect(summary['officialMileageSource'], 'odometer');
      expect(summary['mapsRequiredForStopReview'], isFalse);
    },
  );

  test('commercial sample window pauses projection on poor GPS', () {
    final quality = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        point(-80, 0, speed: 10),
        point(-79.999, 20, speed: 10),
        point(-79.998, 40, speed: 10),
      ],
      routeHistoryDecision: routeDecision(),
      signalQuality: TripTrackingSignalQuality.poor,
    );
    final safeQuality = quality.toSafeDashboardMap();

    expect(quality.status, TripSampleWindowQualityStatus.usableForTracking);
    expect(quality.canFeedLiveOdometerProjection, isFalse);
    expect(quality.canPersistCompactRoutePoint, isFalse);
    expect(safeQuality['poorGpsPausesLiveProjection'], isTrue);
    expect(safeQuality['sampleWindowRequiresTrustedGpsSignal'], isTrue);
    expect(safeQuality['odometerIsGlobalTruth'], isTrue);
  });
}
