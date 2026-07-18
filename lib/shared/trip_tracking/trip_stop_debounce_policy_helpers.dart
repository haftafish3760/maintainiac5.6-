part of 'trip_stop_debounce_policy.dart';

bool _unsafeObservation(TripStopDebounceObservation value) {
  if (!value.speedMps.isFinite || !value.horizontalAccuracyMeters.isFinite) {
    return true;
  }
  if (value.speedMps < 0 || value.speedMps > 90) return true;
  if (value.horizontalAccuracyMeters <= 0 ||
      value.horizontalAccuracyMeters > 250) {
    return true;
  }
  return value.stationaryDuration < Duration.zero ||
      value.walkingEvidenceSpan < Duration.zero;
}

bool _looksLikeTrafficControl({
  required TripTrackingProfileStrategy strategy,
  required TripStopDebounceObservation observation,
  required Duration stationaryDuration,
  required int rejectedDriftCount,
  required int walkingCount,
}) {
  if (walkingCount > 0) return false;
  if (observation.motionState == TripMotionState.stopped) return false;
  if (stationaryDuration > _trafficControlCeilingFor(strategy)) return false;
  if (rejectedDriftCount < 4) return false;
  return observation.speedMps <= 1.2;
}

bool _looksLikeWalkingBurst({
  required TripTrackingProfileStrategy strategy,
  required int walkingCount,
  required Duration walkingSpan,
}) {
  if (!strategy.usesWalkingStopEvidence) return false;
  if (walkingCount < strategy.walkingConfirmationCount) return false;
  return walkingSpan < strategy.minimumWalkingEvidenceSpacing;
}

bool _speedAllowsStopReview(double speedMps) =>
    speedMps.isFinite && speedMps >= 0 && speedMps <= 1.4;

Duration _minimumStationaryFor(TripTrackingProfileStrategy strategy) {
  if (strategy.workStyle == TripTrackingWorkStyle.rideshare) {
    return const Duration(seconds: 45);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.contractor) {
    return const Duration(seconds: 25);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.delivery) {
    return const Duration(seconds: 20);
  }
  return const Duration(seconds: 35);
}

Duration _trafficControlCeilingFor(TripTrackingProfileStrategy strategy) {
  if (strategy.workStyle == TripTrackingWorkStyle.rideshare) {
    return const Duration(minutes: 5);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.delivery) {
    return const Duration(minutes: 4);
  }
  return const Duration(minutes: 3);
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

Duration _safeDuration(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > const Duration(hours: 24) ? const Duration(hours: 24) : value;
}

bool _signalQualityUnsafe(TripTrackingSignalQuality quality) =>
    quality == TripTrackingSignalQuality.unsafe;

bool _signalQualityBlocksStopReview(TripTrackingSignalQuality quality) {
  return switch (quality) {
    TripTrackingSignalQuality.noSamples ||
    TripTrackingSignalQuality.poor ||
    TripTrackingSignalQuality.interrupted ||
    TripTrackingSignalQuality.unsafe => true,
    TripTrackingSignalQuality.healthy ||
    TripTrackingSignalQuality.reduced => false,
  };
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'unsafe_stop_debounce_evidence' => 'unsafe_stop_debounce_evidence',
    'unsafe_gps_blocks_stop_review' => 'unsafe_gps_blocks_stop_review',
    'gps_dependability_blocks_stop_review' =>
      'gps_dependability_blocks_stop_review',
    'gps_dependability_waiting_for_projection_grade_signal' =>
      'gps_dependability_waiting_for_projection_grade_signal',
    'gps_signal_quality_blocks_stop_review' =>
      'gps_signal_quality_blocks_stop_review',
    'vehicle_movement_required_before_stop_review' =>
      'vehicle_movement_required_before_stop_review',
    'traffic_control_debounce_protected' =>
      'traffic_control_debounce_protected',
    'vehicle_only_dwell_traffic_control_protected' =>
      'vehicle_only_dwell_traffic_control_protected',
    'vehicle_only_dwell_manual_fallback' =>
      'vehicle_only_dwell_manual_fallback',
    'walking_burst_debounce_protected' => 'walking_burst_debounce_protected',
    'vehicle_speed_blocks_stop_review' => 'vehicle_speed_blocks_stop_review',
    'future_walking_evidence_rejected' => 'future_walking_evidence_rejected',
    'stale_walking_evidence_rejected' => 'stale_walking_evidence_rejected',
    'undated_walking_evidence_rejected' => 'undated_walking_evidence_rejected',
    'walking_stop_debounce_ready' => 'walking_stop_debounce_ready',
    'stop_debounce_waiting_for_confirmation' =>
      'stop_debounce_waiting_for_confirmation',
    'stop_debounce_keep_tracking' => 'stop_debounce_keep_tracking',
    _ => 'unsafe_stop_debounce_evidence',
  };
}
