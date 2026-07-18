import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_summary_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 18, 14);

  TripStopDebounceObservation observation({
    TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
    TripGpsDependabilityDecision? gpsDependability,
  }) {
    return TripStopDebounceObservation(
      motionState: TripMotionState.stopCandidate,
      stationaryDuration: const Duration(seconds: 45),
      walkingEvidenceCount: 3,
      walkingEvidenceSpan: const Duration(seconds: 24),
      rejectedDriftCount: 0,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 8,
      acceptedVehicleMovementObserved: true,
      speedMps: 0.2,
      horizontalAccuracyMeters: 12,
      signalQuality: signalQuality,
      gpsDependability: gpsDependability,
      latestWalkingEvidenceAt: observedAt.subtract(const Duration(seconds: 30)),
      observedAt: observedAt,
    );
  }

  test('poor or interrupted GPS blocks otherwise valid stop review', () {
    for (final quality in const [
      TripTrackingSignalQuality.noSamples,
      TripTrackingSignalQuality.poor,
      TripTrackingSignalQuality.interrupted,
    ]) {
      final decision = TripStopDebouncePolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        observation: observation(signalQuality: quality),
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
      expect(decision.canOpenReview, isFalse);
      expect(decision.reasonCode, 'gps_signal_quality_blocks_stop_review');
      expect(safe['poorGpsCannotOpenStopReview'], isTrue);
      expect(safe['interruptedGpsCannotOpenStopReview'], isTrue);
      expect(safe['missingGpsCannotOpenStopReview'], isTrue);
      expect(
        TripStopDebounceSummaryValidation.fromDashboardMap(safe).isRenderable,
        isTrue,
      );
    }
  });

  test('unsafe GPS fails closed before stop review can open', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(signalQuality: TripTrackingSignalQuality.unsafe),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.unsafeEvidence);
    expect(decision.canOpenReview, isFalse);
    expect(decision.reasonCode, 'unsafe_gps_blocks_stop_review');
    expect(safe['unsafeGpsCannotOpenStopReview'], isTrue);
    expect(
      TripStopDebounceSummaryValidation.fromDashboardMap(safe).isRenderable,
      isTrue,
    );
  });

  test('unsafe GPS dependability gate blocks otherwise valid stop review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        gpsDependability: dependability(
          TripGpsDependabilityStatus.unsafeBlocked,
          TripTrackingSignalQuality.unsafe,
          shouldContinueSampling: true,
          requiresUserReview: true,
        ),
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.unsafeEvidence);
    expect(decision.reasonCode, 'gps_dependability_blocks_stop_review');
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.canSuggestStop, isFalse);
    expect(safe['stopReviewRequiredForOfficialStop'], isTrue);
    expect(
      TripStopDebounceSummaryValidation.fromDashboardMap(safe).isRenderable,
      isTrue,
    );
  });

  test('projection-paused GPS dependability waits for better signal', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: observation(
        gpsDependability: dependability(
          TripGpsDependabilityStatus.projectionPaused,
          TripTrackingSignalQuality.poor,
          shouldContinueSampling: true,
          requiresUserReview: true,
        ),
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(
      decision.reasonCode,
      'gps_dependability_waiting_for_projection_grade_signal',
    );
    expect(decision.canOpenReview, isFalse);
    expect(decision.shouldContinueSampling, isTrue);
    expect(safe['poorGpsCannotOpenStopReview'], isTrue);
    expect(
      TripStopDebounceSummaryValidation.fromDashboardMap(safe).isRenderable,
      isTrue,
    );
  });

  test(
    'review-only GPS dependability cannot be bypassed by walking evidence',
    () {
      final decision = TripStopDebouncePolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        observation: observation(
          gpsDependability: dependability(
            TripGpsDependabilityStatus.reviewOnly,
            TripTrackingSignalQuality.reduced,
            shouldContinueSampling: true,
            requiresUserReview: true,
          ),
        ),
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
      expect(
        decision.reasonCode,
        'gps_dependability_blocks_stop_review_authority',
      );
      expect(decision.canOpenReview, isFalse);
      expect(decision.needsWalkingReview, isFalse);
      expect(safe['reducedGpsCanOnlyOpenReviewWithCorroboration'], isTrue);
      expect(safe['stopReviewRequiredForOfficialStop'], isTrue);
      expect(
        TripStopDebounceSummaryValidation.fromDashboardMap(safe).isRenderable,
        isTrue,
      );
    },
  );
}

TripGpsDependabilityDecision dependability(
  TripGpsDependabilityStatus status,
  TripTrackingSignalQuality signalQuality, {
  required bool shouldContinueSampling,
  required bool requiresUserReview,
}) {
  return TripGpsDependabilityDecision(
    status: status,
    reasonCode: status == TripGpsDependabilityStatus.unsafeBlocked
        ? 'gps_dependability_unsafe_evidence'
        : 'gps_poor_signal_pauses_projection',
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
