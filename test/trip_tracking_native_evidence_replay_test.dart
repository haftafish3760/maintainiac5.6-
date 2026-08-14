// Deterministic native-callback replays for automatic trip evidence.
//
// Owns field-shaped GPS and activity regression cases. Does not prove device
// hardware behavior or create confirmed TripLog records; the controller UI
// tests own proposal presentation and user review.
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary(
    start: DateTime.utc(2026, 8, 6, 12),
  );

  void expectReviewOnly(SimulatedTripResult result) {
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopCanReplaceOdometer'], isFalse);
    expect(summary['simulationCanCreateOfficialStop'], isFalse);
  }

  test('drive, park, exit, and walk produces review-only stop evidence', () {
    final result = replayNativeEvidence(
      scenarios.deliveryStopWithWellSpacedWalkingEvidence(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.sawReviewableStopEvidence, isTrue);
    expectReviewOnly(result);
  });

  test('short delivery stop then return to vehicle remains review-only', () {
    final result = replayNativeEvidence(
      scenarios.contractorLongJobsiteWalkThenDriveAway(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.sawReviewableStopEvidence, isTrue);
    expect(result.motionState, TripMotionState.moving);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(3));
    expectReviewOnly(result);
  });

  test('traffic light does not become a stop proposal', () {
    final result = replayNativeEvidence(
      scenarios.longTrafficLightWithUrbanJitter(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.sawReviewableStopEvidence, isFalse);
    expect(result.motionState, TripMotionState.moving);
  });

  test('parking-lot crawl does not become a stop proposal', () {
    final result = replayNativeEvidence(
      scenarios.ridesharePickupQueueCreepingTraffic(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.sawReviewableStopEvidence, isFalse);
    expect(result.motionState, TripMotionState.moving);
  });

  test('fragmented GPS cannot bridge distance or create a stop proposal', () {
    final result = replayNativeEvidence(
      scenarios.gpsJumpAndGapMasqueradingAsStop(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.sawReviewableStopEvidence, isFalse);
    expect(result.rejectedUnsafeCount, greaterThanOrEqualTo(1));
    expect(
      result.count(TripSampleDisposition.rejectedGap),
      greaterThanOrEqualTo(1),
    );
  });

  test('late walking evidence never rewrites accepted GPS distance', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final startedAt = DateTime.utc(2026, 8, 6, 12);
    TripLocationSample sample(double longitude, int seconds) =>
        TripLocationSample(
          latitude: 35,
          longitude: longitude,
          recordedAt: startedAt.add(Duration(seconds: seconds)),
          horizontalAccuracyMeters: 5,
        );

    engine.ingest(sample(-82, 0));
    final accepted = engine.ingest(sample(-81.999, 20));
    expect(accepted.disposition, TripSampleDisposition.acceptedDistance);
    final metersBeforeWalking = engine.totalAcceptedMeters;
    final diagnosticsBeforeWalking = engine.snapshot.diagnostics;

    engine.recordActivityEvidence(
      TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 95,
        recordedAt: startedAt.add(const Duration(seconds: 20)),
      ),
      observedAt: startedAt.add(const Duration(seconds: 20)),
    );

    expect(engine.totalAcceptedMeters, metersBeforeWalking);
    expect(engine.snapshot.diagnostics, diagnosticsBeforeWalking);
    expect(engine.motionState, isNot(TripMotionState.stopCandidate));
  });

  test(
    'Android-style location callback gap reanchors before resumed driving',
    () {
      final result = replayNativeEvidence(
        scenarios.tunnelSignalLossAndRecovery(),
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.needsWalkingReview, isFalse);
      expect(result.sawReviewableStopEvidence, isFalse);
      expect(result.count(TripSampleDisposition.rejectedGap), 1);
      expect(result.acceptedDistanceCount, greaterThanOrEqualTo(2));
    },
  );

  test(
    'delayed or misclassified motion does not convert driving into a stop',
    () {
      final result = replayNativeEvidence(
        scenarios.walkingSensorMisclassifiedAtVehicleSpeed(),
        profile: TripTrackingProfile.deliveryVehicle,
      );

      expect(result.needsWalkingReview, isFalse);
      expect(result.sawReviewableStopEvidence, isFalse);
      expect(result.motionState, TripMotionState.moving);
    },
  );

  test('stale walking evidence after driving resumes cannot reopen a stop', () {
    final result = replayNativeEvidence(
      scenarios.staleWalkingAfterDriveResumes(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.motionState, TripMotionState.moving);
  });
}
