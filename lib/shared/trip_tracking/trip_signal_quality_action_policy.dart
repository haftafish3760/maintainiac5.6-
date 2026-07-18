import 'trip_gps_dependability_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_signal_quality.dart';

enum TripSignalQualityAction {
  waitForSamples,
  keepTracking,
  reduceSamplingCost,
  promptSignalReview,
  pauseGpsUntilReview,
}

class TripSignalQualityActionDecision {
  const TripSignalQualityActionDecision({
    required this.action,
    required this.reasonCode,
    required this.targetHealthState,
    required this.canContinueGps,
    required this.shouldShowBanner,
    required this.shouldOpenReview,
  });

  final TripSignalQualityAction action;
  final String reasonCode;
  final TripTrackingHealthState targetHealthState;
  final bool canContinueGps;
  final bool shouldShowBanner;
  final bool shouldOpenReview;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'action': action.name,
    'reasonCode': _safeReason(reasonCode),
    'targetHealthState': targetHealthState.name,
    'canContinueGps': canContinueGps,
    'shouldShowBanner': shouldShowBanner,
    'shouldOpenReview': shouldOpenReview,
    'advisoryOnly': true,
    'signalActionCanEndTrip': false,
    'signalActionCanConfirmMileage': false,
    'signalActionCanCreateOfficialStop': false,
    'signalActionCanDeleteLocalData': false,
    'localTripLogProtected': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxCanOverrideSignalAction': false,
    'remoteDiagnosticsCanOverrideSignalAction': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'signalActionCanCreateCalibration': false,
    'signalActionCanApplyCalibration': false,
    'signalActionCanOverrideCalibration': false,
    'mapsRequiredForSignalRecovery': false,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSignalQualityActionPolicy {
  const TripSignalQualityActionPolicy._();

  static TripSignalQualityActionDecision evaluate({
    required TripTrackingSignalQualitySummary signal,
    required bool activeTripHasLocalCheckpoint,
    required bool userCanReviewNow,
    TripGpsDependabilityDecision? dependability,
  }) {
    final dependabilityDecision = _dependabilityAction(
      dependability,
      userCanReviewNow: userCanReviewNow,
    );
    if (dependabilityDecision != null) return dependabilityDecision;

    return switch (signal.quality) {
      TripTrackingSignalQuality.noSamples => _decision(
        TripSignalQualityAction.waitForSamples,
        'waiting_for_first_safe_gps_sample',
        signal.healthState,
        canContinueGps: activeTripHasLocalCheckpoint,
        shouldShowBanner: false,
      ),
      TripTrackingSignalQuality.healthy => _decision(
        TripSignalQualityAction.keepTracking,
        'signal_healthy_keep_tracking',
        signal.healthState,
      ),
      TripTrackingSignalQuality.reduced => _decision(
        TripSignalQualityAction.reduceSamplingCost,
        'signal_reduced_continue_with_guardrails',
        signal.healthState,
        shouldShowBanner: signal.requiresUserReview,
      ),
      TripTrackingSignalQuality.poor => _decision(
        TripSignalQualityAction.promptSignalReview,
        'signal_poor_review_recommended',
        signal.healthState,
        shouldShowBanner: true,
        shouldOpenReview: userCanReviewNow,
      ),
      TripTrackingSignalQuality.interrupted => _decision(
        TripSignalQualityAction.promptSignalReview,
        'signal_interrupted_recovery_review',
        signal.healthState,
        canContinueGps: activeTripHasLocalCheckpoint,
        shouldShowBanner: true,
        shouldOpenReview: userCanReviewNow,
      ),
      TripTrackingSignalQuality.unsafe => _decision(
        TripSignalQualityAction.pauseGpsUntilReview,
        'unsafe_signal_paused_until_review',
        signal.healthState,
        canContinueGps: false,
        shouldShowBanner: true,
        shouldOpenReview: userCanReviewNow,
      ),
    };
  }
}

TripSignalQualityActionDecision? _dependabilityAction(
  TripGpsDependabilityDecision? dependability, {
  required bool userCanReviewNow,
}) {
  if (dependability == null) return null;
  return switch (dependability.status) {
    TripGpsDependabilityStatus.readyForAssist ||
    TripGpsDependabilityStatus.reviewOnly => null,
    TripGpsDependabilityStatus.unsafeBlocked => _decision(
      TripSignalQualityAction.pauseGpsUntilReview,
      'dependability_unsafe_paused_until_review',
      TripTrackingHealthState.unavailable,
      canContinueGps: false,
      shouldShowBanner: true,
      shouldOpenReview: userCanReviewNow,
    ),
    TripGpsDependabilityStatus.projectionPaused => _decision(
      dependability.shouldContinueSampling
          ? TripSignalQualityAction.promptSignalReview
          : TripSignalQualityAction.pauseGpsUntilReview,
      dependability.shouldContinueSampling
          ? 'dependability_projection_paused_continue_sampling'
          : 'dependability_device_policy_paused',
      _healthStateFor(dependability.signalQuality),
      canContinueGps: dependability.shouldContinueSampling,
      shouldShowBanner: dependability.requiresUserReview,
      shouldOpenReview: dependability.requiresUserReview && userCanReviewNow,
    ),
  };
}

TripTrackingHealthState _healthStateFor(TripTrackingSignalQuality quality) {
  return switch (quality) {
    TripTrackingSignalQuality.noSamples => TripTrackingHealthState.reduced,
    TripTrackingSignalQuality.healthy => TripTrackingHealthState.healthy,
    TripTrackingSignalQuality.reduced => TripTrackingHealthState.reduced,
    TripTrackingSignalQuality.poor => TripTrackingHealthState.poor,
    TripTrackingSignalQuality.interrupted =>
      TripTrackingHealthState.interrupted,
    TripTrackingSignalQuality.unsafe => TripTrackingHealthState.unavailable,
  };
}

TripSignalQualityActionDecision _decision(
  TripSignalQualityAction action,
  String reasonCode,
  TripTrackingHealthState healthState, {
  bool canContinueGps = true,
  bool shouldShowBanner = false,
  bool shouldOpenReview = false,
}) {
  return TripSignalQualityActionDecision(
    action: action,
    reasonCode: reasonCode,
    targetHealthState: healthState,
    canContinueGps: canContinueGps,
    shouldShowBanner: shouldShowBanner,
    shouldOpenReview: shouldOpenReview,
  );
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'waiting_for_first_safe_gps_sample' ||
    'signal_healthy_keep_tracking' ||
    'signal_reduced_continue_with_guardrails' ||
    'signal_poor_review_recommended' ||
    'signal_interrupted_recovery_review' ||
    'unsafe_signal_paused_until_review' ||
    'dependability_projection_paused_continue_sampling' ||
    'dependability_device_policy_paused' ||
    'dependability_unsafe_paused_until_review' => clean,
    _ => 'unsafe_signal_paused_until_review',
  };
}
