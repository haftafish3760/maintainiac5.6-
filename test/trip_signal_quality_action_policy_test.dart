import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_signal_quality_action_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  test(
    'healthy and reduced signals keep tracking without changing mileage',
    () {
      final healthy = TripSignalQualityActionPolicy.evaluate(
        signal: signal(TripTrackingSignalQuality.healthy),
        activeTripHasLocalCheckpoint: true,
        userCanReviewNow: true,
      );
      final reduced = TripSignalQualityActionPolicy.evaluate(
        signal: signal(TripTrackingSignalQuality.reduced),
        activeTripHasLocalCheckpoint: true,
        userCanReviewNow: true,
      );

      expect(healthy.action, TripSignalQualityAction.keepTracking);
      expect(healthy.canContinueGps, isTrue);
      expect(reduced.action, TripSignalQualityAction.reduceSamplingCost);
      expect(reduced.canContinueGps, isTrue);
    },
  );

  test('poor and interrupted signals prompt review without ending trip', () {
    final poor = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.poor),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: true,
    );
    final interrupted = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.interrupted),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: false,
    );

    expect(poor.action, TripSignalQualityAction.promptSignalReview);
    expect(poor.shouldOpenReview, isTrue);
    expect(interrupted.action, TripSignalQualityAction.promptSignalReview);
    expect(interrupted.canContinueGps, isTrue);
    expect(interrupted.shouldOpenReview, isFalse);
  });

  test('unsafe signal pauses GPS assistance until user review', () {
    final decision = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.unsafe),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: true,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.action, TripSignalQualityAction.pauseGpsUntilReview);
    expect(decision.canContinueGps, isFalse);
    expect(decision.shouldOpenReview, isTrue);
    expect(safe['signalActionCanEndTrip'], isFalse);
    expect(safe['signalActionCanConfirmMileage'], isFalse);
  });

  test(
    'no samples waits safely and requires a local checkpoint to continue',
    () {
      final noCheckpoint = TripSignalQualityActionPolicy.evaluate(
        signal: signal(TripTrackingSignalQuality.noSamples),
        activeTripHasLocalCheckpoint: false,
        userCanReviewNow: false,
      );
      final checkpoint = TripSignalQualityActionPolicy.evaluate(
        signal: signal(TripTrackingSignalQuality.noSamples),
        activeTripHasLocalCheckpoint: true,
        userCanReviewNow: false,
      );

      expect(noCheckpoint.action, TripSignalQualityAction.waitForSamples);
      expect(noCheckpoint.canContinueGps, isFalse);
      expect(checkpoint.canContinueGps, isTrue);
    },
  );

  test('safe action summary keeps remote and Mapbox boundaries closed', () {
    final safe = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.unsafe),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: true,
    ).toSafeDashboardMap();

    expect(safe['signalActionCanCreateOfficialStop'], isFalse);
    expect(safe['signalActionCanDeleteLocalData'], isFalse);
    expect(safe['localTripLogProtected'], isTrue);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['mapboxCanOverrideSignalAction'], isFalse);
    expect(safe['remoteDiagnosticsCanOverrideSignalAction'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['signalActionCanCreateCalibration'], isFalse);
    expect(safe['signalActionCanApplyCalibration'], isFalse);
    expect(safe['signalActionCanOverrideCalibration'], isFalse);
    expect(safe['mapsRequiredForSignalRecovery'], isFalse);
    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('dependability gate can pause action before raw signal fallback', () {
    final decision = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.healthy),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: true,
      dependability: dependability(
        status: TripGpsDependabilityStatus.unsafeBlocked,
        reasonCode: 'gps_dependability_unsafe_evidence',
        signalQuality: TripTrackingSignalQuality.unsafe,
        shouldContinueSampling: true,
        requiresUserReview: true,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.action, TripSignalQualityAction.pauseGpsUntilReview);
    expect(decision.reasonCode, 'dependability_unsafe_paused_until_review');
    expect(decision.canContinueGps, isFalse);
    expect(decision.shouldOpenReview, isTrue);
    expect(safe['signalActionCanConfirmMileage'], isFalse);
    expect(safe['signalActionCanCreateOfficialStop'], isFalse);
  });

  test('projection-paused dependability preserves sampling when safe', () {
    final decision = TripSignalQualityActionPolicy.evaluate(
      signal: signal(TripTrackingSignalQuality.healthy),
      activeTripHasLocalCheckpoint: true,
      userCanReviewNow: false,
      dependability: dependability(
        status: TripGpsDependabilityStatus.projectionPaused,
        reasonCode: 'gps_poor_signal_pauses_projection',
        signalQuality: TripTrackingSignalQuality.poor,
        shouldContinueSampling: true,
        requiresUserReview: true,
      ),
    );

    expect(decision.action, TripSignalQualityAction.promptSignalReview);
    expect(
      decision.reasonCode,
      'dependability_projection_paused_continue_sampling',
    );
    expect(decision.canContinueGps, isTrue);
    expect(decision.shouldShowBanner, isTrue);
    expect(decision.shouldOpenReview, isFalse);
  });
}

TripGpsDependabilityDecision dependability({
  required TripGpsDependabilityStatus status,
  required String reasonCode,
  required TripTrackingSignalQuality signalQuality,
  required bool shouldContinueSampling,
  required bool requiresUserReview,
}) {
  return TripGpsDependabilityDecision(
    status: status,
    reasonCode: reasonCode,
    profile: TripTrackingProfile.deliveryVehicle,
    confidence: TripTrackingConfidence.low,
    signalQuality: signalQuality,
    canFeedLiveOdometerProjection: false,
    canPersistCompactRoutePoint: false,
    canOpenStopReview: false,
    canContributeToCalibration: false,
    shouldContinueSampling: shouldContinueSampling,
    requiresUserReview: requiresUserReview,
  );
}

TripTrackingSignalQualitySummary signal(TripTrackingSignalQuality quality) {
  return TripTrackingSignalQualitySummary(
    quality: quality,
    reasonCode: switch (quality) {
      TripTrackingSignalQuality.noSamples => 'gps_signal_waiting_for_samples',
      TripTrackingSignalQuality.healthy => 'gps_signal_healthy',
      TripTrackingSignalQuality.reduced => 'gps_signal_reduced_but_usable',
      TripTrackingSignalQuality.poor => 'gps_signal_poor_measurement_quality',
      TripTrackingSignalQuality.interrupted => 'gps_signal_interrupted_by_gap',
      TripTrackingSignalQuality.unsafe => 'gps_signal_unsafe_provider_evidence',
    },
    receivedSamples: quality == TripTrackingSignalQuality.noSamples ? 0 : 10,
    acceptedSamples: quality == TripTrackingSignalQuality.healthy ? 10 : 3,
    rejectedSamples: quality == TripTrackingSignalQuality.healthy ? 0 : 7,
    acceptanceRate: quality == TripTrackingSignalQuality.healthy ? 1 : .3,
    requiresUserReview:
        quality == TripTrackingSignalQuality.poor ||
        quality == TripTrackingSignalQuality.interrupted ||
        quality == TripTrackingSignalQuality.unsafe,
  );
}
