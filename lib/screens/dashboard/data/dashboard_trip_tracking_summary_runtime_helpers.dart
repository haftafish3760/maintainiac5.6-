part of 'dashboard_trip_tracking_summary.dart';

bool _isBatteryLimitedStatus(String? status) {
  return switch (status) {
    'battery_critical_gps_blocked' ||
    'low_battery_requires_user_choice' ||
    'low_power_mode_requires_user_choice' ||
    'low_battery_gps_blocked_by_saved_choice' ||
    'low_power_mode_gps_blocked_by_saved_choice' => true,
    _ => false,
  };
}

String _recoveryStateFor(TripTrackingRecoveryDecision? decision) {
  return switch (decision?.status) {
    TripTrackingRecoveryStatus.ready => 'ready',
    TripTrackingRecoveryStatus.pendingReplayReady => 'pending_replay',
    TripTrackingRecoveryStatus.completedReviewPresent => 'completed_review',
    TripTrackingRecoveryStatus.invalidSession => 'invalid_session',
    TripTrackingRecoveryStatus.invalidReviewPresent => 'invalid_review',
    TripTrackingRecoveryStatus.vehicleMismatch => 'vehicle_mismatch',
    TripTrackingRecoveryStatus.odometerMismatch => 'odometer_mismatch',
    TripTrackingRecoveryStatus.odometerProjectionInvalid =>
      'projection_invalid',
    TripTrackingRecoveryStatus.noRecoverableTrip || null => 'none',
  };
}

String _recoveryReasonFor(TripTrackingRecoveryDecision? decision) {
  return _safeRecoveryReason(decision?.safeReason ?? 'trip_recovery_none');
}

TripStopClassification? _stopClassificationFor({
  required TripTrackingSettings settings,
  required TripTrackingController? tripTracking,
}) {
  if (tripTracking == null || !tripTracking.isTracking) return null;
  final counts = tripTracking.diagnostics.dispositionCounts;
  return TripStopClassifier.classify(
    profile: settings.defaultProfile,
    motionState: tripTracking.motionState,
    needsWalkingReview: tripTracking.needsWalkingReview,
    excludedWalkingCount: counts[TripSampleDisposition.excludedWalking] ?? 0,
    rejectedDriftCount: counts[TripSampleDisposition.rejectedDrift] ?? 0,
    rejectedUnsafeCount:
        (counts[TripSampleDisposition.rejectedInvalid] ?? 0) +
        (counts[TripSampleDisposition.rejectedMockLocation] ?? 0) +
        (counts[TripSampleDisposition.rejectedAccuracy] ?? 0) +
        (counts[TripSampleDisposition.rejectedOutOfOrder] ?? 0),
    acceptedDistanceCount: counts[TripSampleDisposition.acceptedDistance] ?? 0,
  );
}

String _dashboardStopSignalFor(TripStopClassification? classification) {
  return switch (classification?.signal) {
    TripStopSignal.stopCandidate => 'stop_candidate',
    TripStopSignal.reviewOnlyStop => 'review_only_stop',
    TripStopSignal.likelyTrafficControl => 'likely_traffic_control',
    TripStopSignal.equipmentIgnored => 'equipment_ignored',
    TripStopSignal.unsafeEvidence => 'unsafe_evidence',
    _ => 'no_stop',
  };
}

String _dashboardGpsSignalQualityFor(
  TripTrackingSignalQualitySummary? summary,
) {
  return switch (summary?.quality) {
    TripTrackingSignalQuality.healthy => 'healthy',
    TripTrackingSignalQuality.reduced => 'reduced',
    TripTrackingSignalQuality.poor => 'poor',
    TripTrackingSignalQuality.interrupted => 'interrupted',
    TripTrackingSignalQuality.unsafe => 'unsafe',
    _ => 'no_samples',
  };
}

String _deviceCapabilityStateFor(
  TripTrackingCapabilityGuidance? capabilityGuidance,
) {
  if (capabilityGuidance == null) return 'unknown';
  return switch (capabilityGuidance.readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'unavailable',
    TripTrackingCapabilityReadiness.locationOnly => 'location_only',
    TripTrackingCapabilityReadiness.foregroundReady => 'foreground_ready',
    TripTrackingCapabilityReadiness.backgroundReady => 'background_ready',
    TripTrackingCapabilityReadiness.motionReady => 'motion_ready',
    TripTrackingCapabilityReadiness.fullSafetyAssist => 'full_safety_assist',
  };
}

String _sensorAssistStateFor(
  TripTrackingCapabilityGuidance? capabilityGuidance,
) {
  if (capabilityGuidance == null) return 'unknown';
  final motion = capabilityGuidance.canUseActivityRecognition;
  final battery =
      capabilityGuidance.canUseBatteryGuard ||
      capabilityGuidance.canUseLowPowerGuard;
  if (motion && battery) return 'motion_battery_available';
  if (motion) return 'motion_available';
  if (battery) return 'battery_available';
  return 'no_assist';
}

String _durableRecordBackupStateFor(TripTrackingController? tripTracking) {
  if (tripTracking == null || !tripTracking.hasDurableRecordBridge) {
    return 'not_configured';
  }
  if (tripTracking.durableRecordError != null) return 'pending_retry';
  return 'available';
}
