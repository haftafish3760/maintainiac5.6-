import 'trip_sample_window_quality_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_signal_quality.dart';

enum TripGpsDependabilityStatus {
  readyForAssist,
  reviewOnly,
  projectionPaused,
  unsafeBlocked,
}

class TripGpsDependabilityDecision {
  const TripGpsDependabilityDecision({
    required this.status,
    required this.reasonCode,
    required this.profile,
    required this.confidence,
    required this.signalQuality,
    required this.canFeedLiveOdometerProjection,
    required this.canPersistCompactRoutePoint,
    required this.canOpenStopReview,
    required this.canContributeToCalibration,
    required this.shouldContinueSampling,
    required this.requiresUserReview,
  });

  final TripGpsDependabilityStatus status;
  final String reasonCode;
  final TripTrackingProfile profile;
  final TripTrackingConfidence confidence;
  final TripTrackingSignalQuality signalQuality;
  final bool canFeedLiveOdometerProjection;
  final bool canPersistCompactRoutePoint;
  final bool canOpenStopReview;
  final bool canContributeToCalibration;
  final bool shouldContinueSampling;
  final bool requiresUserReview;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'profile': profile.name,
    'confidence': confidence.name,
    'signalQuality': signalQuality.name,
    'canFeedLiveOdometerProjection': canFeedLiveOdometerProjection,
    'canPersistCompactRoutePoint': canPersistCompactRoutePoint,
    'canOpenStopReview': canOpenStopReview,
    'canContributeToCalibration': canContributeToCalibration,
    'shouldContinueSampling': shouldContinueSampling,
    'requiresUserReview': requiresUserReview,
    'gpsAssistedTrackingWorksWithoutMaps': true,
    'mapsRequiredForGpsDependability': false,
    'gpsDependabilityRequiresIntakeGuard': true,
    'gpsDependabilityRequiresSampleWindowPolicy': true,
    'gpsDependabilityRequiresSignalQualityPolicy': true,
    'gpsDependabilityRequiresDeviceCapabilityContext': true,
    'gpsDependabilityRequiresPermissionContinuity': true,
    'gpsDependabilityRequiresBatteryAllowance': true,
    'reducedGpsIsReviewOnly': true,
    'poorGpsPausesProjection': true,
    'interruptedGpsPausesProjection': true,
    'unsafeGpsBlocksAllAssistance': true,
    'stopReviewRequiresTrustedGpsAndDebounce': true,
    'calibrationRequiresTrustedGpsAndOdometerReview': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'gpsCanReplaceOdometer': false,
    'gpsCanConfirmOfficialMileage': false,
    'gpsCanCreateOfficialStop': false,
    'mapboxCanOverrideGpsDependability': false,
    'firestoreCanOverrideGpsDependability': false,
    'cloudFunctionCanOverrideGpsDependability': false,
    'remoteTotalsCanBecomeCanonical': false,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripGpsDependabilityPolicy {
  const TripGpsDependabilityPolicy._();

  static TripGpsDependabilityDecision evaluate({
    required TripTrackingProfile profile,
    required TripTrackingSignalQualitySummary signalSummary,
    required TripSampleWindowQualityDecision sampleWindow,
    bool permissionContinuityTrusted = true,
    bool deviceCapabilityTrusted = true,
    bool batteryAllowsGps = true,
  }) {
    final safeSignal = signalSummary.toSafeDashboardMap();
    final signalQuality = _safeSignal(signalSummary.quality);
    final signalCalibrationEligible =
        safeSignal['signalQualityEligibleForCalibration'] == true;
    final sampleCanProject = sampleWindow.canFeedLiveOdometerProjection;
    final sampleCanPersist = sampleWindow.canPersistCompactRoutePoint;
    final sampleUnsafe =
        sampleWindow.status == TripSampleWindowQualityStatus.unsafeRejected;

    if (!permissionContinuityTrusted) {
      return _decision(
        status: TripGpsDependabilityStatus.projectionPaused,
        reasonCode: 'gps_permission_continuity_required',
        profile: profile,
        confidence: TripTrackingConfidence.low,
        signalQuality: signalQuality,
        shouldContinueSampling: false,
        requiresUserReview: true,
      );
    }
    if (!deviceCapabilityTrusted) {
      return _decision(
        status: TripGpsDependabilityStatus.projectionPaused,
        reasonCode: 'gps_device_capability_required',
        profile: profile,
        confidence: TripTrackingConfidence.low,
        signalQuality: signalQuality,
        shouldContinueSampling: false,
        requiresUserReview: true,
      );
    }
    if (!batteryAllowsGps) {
      return _decision(
        status: TripGpsDependabilityStatus.projectionPaused,
        reasonCode: 'gps_battery_policy_paused',
        profile: profile,
        confidence: TripTrackingConfidence.low,
        signalQuality: signalQuality,
        shouldContinueSampling: false,
        requiresUserReview: false,
      );
    }
    if (sampleUnsafe || signalQuality == TripTrackingSignalQuality.unsafe) {
      return _decision(
        status: TripGpsDependabilityStatus.unsafeBlocked,
        reasonCode: 'gps_dependability_unsafe_evidence',
        profile: profile,
        confidence: TripTrackingConfidence.low,
        signalQuality: signalQuality,
        shouldContinueSampling: true,
        requiresUserReview: true,
      );
    }
    if (signalQuality == TripTrackingSignalQuality.noSamples ||
        signalQuality == TripTrackingSignalQuality.poor ||
        signalQuality == TripTrackingSignalQuality.interrupted ||
        !sampleCanProject) {
      return _decision(
        status: TripGpsDependabilityStatus.projectionPaused,
        reasonCode: _projectionPauseReason(signalQuality, sampleWindow),
        profile: profile,
        confidence: TripTrackingConfidence.low,
        signalQuality: signalQuality,
        shouldContinueSampling: true,
        requiresUserReview:
            signalSummary.requiresUserReview ||
            signalQuality == TripTrackingSignalQuality.poor ||
            signalQuality == TripTrackingSignalQuality.interrupted,
      );
    }
    if (signalQuality == TripTrackingSignalQuality.reduced) {
      return _decision(
        status: TripGpsDependabilityStatus.reviewOnly,
        reasonCode: 'gps_reduced_review_only_assist',
        profile: profile,
        confidence: TripTrackingConfidence.medium,
        signalQuality: signalQuality,
        canFeedLiveOdometerProjection: true,
        canPersistCompactRoutePoint: sampleCanPersist,
        canOpenStopReview: false,
        canContributeToCalibration: signalCalibrationEligible,
        shouldContinueSampling: true,
        requiresUserReview: signalSummary.requiresUserReview,
      );
    }

    return _decision(
      status: TripGpsDependabilityStatus.readyForAssist,
      reasonCode: 'gps_dependability_ready',
      profile: profile,
      confidence: TripTrackingConfidence.high,
      signalQuality: signalQuality,
      canFeedLiveOdometerProjection: true,
      canPersistCompactRoutePoint: sampleCanPersist,
      canOpenStopReview: true,
      canContributeToCalibration: signalCalibrationEligible,
      shouldContinueSampling: true,
      requiresUserReview: false,
    );
  }
}

TripGpsDependabilityDecision _decision({
  required TripGpsDependabilityStatus status,
  required String reasonCode,
  required TripTrackingProfile profile,
  required TripTrackingConfidence confidence,
  required TripTrackingSignalQuality signalQuality,
  bool canFeedLiveOdometerProjection = false,
  bool canPersistCompactRoutePoint = false,
  bool canOpenStopReview = false,
  bool canContributeToCalibration = false,
  required bool shouldContinueSampling,
  required bool requiresUserReview,
}) {
  return TripGpsDependabilityDecision(
    status: status,
    reasonCode: reasonCode,
    profile: profile,
    confidence: confidence,
    signalQuality: signalQuality,
    canFeedLiveOdometerProjection: canFeedLiveOdometerProjection,
    canPersistCompactRoutePoint: canPersistCompactRoutePoint,
    canOpenStopReview: canOpenStopReview,
    canContributeToCalibration: canContributeToCalibration,
    shouldContinueSampling: shouldContinueSampling,
    requiresUserReview: requiresUserReview,
  );
}

TripTrackingSignalQuality _safeSignal(TripTrackingSignalQuality quality) {
  return TripTrackingSignalQuality.values.contains(quality)
      ? quality
      : TripTrackingSignalQuality.unsafe;
}

String _projectionPauseReason(
  TripTrackingSignalQuality signalQuality,
  TripSampleWindowQualityDecision sampleWindow,
) {
  if (signalQuality == TripTrackingSignalQuality.noSamples) {
    return 'gps_waiting_for_samples';
  }
  if (signalQuality == TripTrackingSignalQuality.poor) {
    return 'gps_poor_signal_pauses_projection';
  }
  if (signalQuality == TripTrackingSignalQuality.interrupted) {
    return 'gps_interrupted_signal_pauses_projection';
  }
  if (sampleWindow.status == TripSampleWindowQualityStatus.noSamples) {
    return 'gps_sample_window_waiting';
  }
  return 'gps_sample_window_not_projection_grade';
}

String _safeReason(String reasonCode) {
  return switch (reasonCode.trim()) {
    'gps_dependability_ready' => 'gps_dependability_ready',
    'gps_reduced_review_only_assist' => 'gps_reduced_review_only_assist',
    'gps_waiting_for_samples' => 'gps_waiting_for_samples',
    'gps_poor_signal_pauses_projection' => 'gps_poor_signal_pauses_projection',
    'gps_interrupted_signal_pauses_projection' =>
      'gps_interrupted_signal_pauses_projection',
    'gps_sample_window_waiting' => 'gps_sample_window_waiting',
    'gps_sample_window_not_projection_grade' =>
      'gps_sample_window_not_projection_grade',
    'gps_permission_continuity_required' =>
      'gps_permission_continuity_required',
    'gps_device_capability_required' => 'gps_device_capability_required',
    'gps_battery_policy_paused' => 'gps_battery_policy_paused',
    'gps_dependability_unsafe_evidence' => 'gps_dependability_unsafe_evidence',
    _ => 'gps_dependability_unsafe_evidence',
  };
}
