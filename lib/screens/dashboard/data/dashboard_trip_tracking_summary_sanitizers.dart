part of 'dashboard_trip_tracking_summary.dart';

String _safeWorkStyle(String value) {
  return switch (value.trim()) {
    'general_road' => 'general_road',
    'rideshare' => 'rideshare',
    'delivery' => 'delivery',
    'contractor' => 'contractor',
    'equipment' => 'equipment',
    _ => 'general_road',
  };
}

String _safeStopDetectionMode(String value) {
  return switch (value.trim()) {
    'walking_assisted' => 'walking_assisted',
    'strong_debounce' => 'strong_debounce',
    'walking_ignored' => 'walking_ignored',
    _ => 'walking_assisted',
  };
}

String _safeStopReviewReasonCode(String value) {
  return switch (value.trim()) {
    'road_vehicle_stop_walk_review' => 'road_vehicle_stop_walk_review',
    'rideshare_stop_requires_extra_evidence' =>
      'rideshare_stop_requires_extra_evidence',
    'delivery_stop_walk_review' => 'delivery_stop_walk_review',
    'contractor_stop_walk_review' => 'contractor_stop_walk_review',
    'equipment_ignores_walking_stop_evidence' =>
      'equipment_ignores_walking_stop_evidence',
    _ => 'road_vehicle_stop_walk_review',
  };
}

String _safeStopSignal(String value) {
  return switch (value.trim()) {
    'no_stop' => 'no_stop',
    'stop_candidate' => 'stop_candidate',
    'review_only_stop' => 'review_only_stop',
    'likely_traffic_control' => 'likely_traffic_control',
    'equipment_ignored' => 'equipment_ignored',
    'unsafe_evidence' => 'unsafe_evidence',
    _ => 'no_stop',
  };
}

String _safeStopActionToken(String value) {
  return switch (value.trim()) {
    'keep_tracking' => 'keep_tracking',
    'continue_monitoring' => 'continue_monitoring',
    'review_delivery_stop' => 'review_delivery_stop',
    'review_jobsite_stop' => 'review_jobsite_stop',
    'review_shift_stop' => 'review_shift_stop',
    'review_trip_stop' => 'review_trip_stop',
    _ => 'keep_tracking',
  };
}

String _safeStopClassificationReason(String value) {
  return switch (value.trim()) {
    'no_stop_review_needed' => 'no_stop_review_needed',
    'unsafe_stop_evidence_rejected' => 'unsafe_stop_evidence_rejected',
    'equipment_walking_evidence_ignored' =>
      'equipment_walking_evidence_ignored',
    'road_vehicle_stop_walk_review' => 'road_vehicle_stop_walk_review',
    'rideshare_stop_requires_extra_evidence' =>
      'rideshare_stop_requires_extra_evidence',
    'delivery_stop_walk_review' => 'delivery_stop_walk_review',
    'contractor_stop_walk_review' => 'contractor_stop_walk_review',
    'stop_candidate_waiting_for_stronger_evidence' =>
      'stop_candidate_waiting_for_stronger_evidence',
    'stop_candidate_waiting_for_confirmation' =>
      'stop_candidate_waiting_for_confirmation',
    'traffic_control_or_stationary_jitter' =>
      'traffic_control_or_stationary_jitter',
    _ => 'no_stop_review_needed',
  };
}

String _safeGpsSignalQuality(String value) {
  return switch (value.trim()) {
    'no_samples' => 'no_samples',
    'healthy' => 'healthy',
    'reduced' => 'reduced',
    'poor' => 'poor',
    'interrupted' => 'interrupted',
    'unsafe' => 'unsafe',
    _ => 'no_samples',
  };
}

String _safeGpsSignalReason(String value) {
  return switch (value.trim()) {
    'gps_signal_waiting_for_samples' => 'gps_signal_waiting_for_samples',
    'gps_signal_healthy' => 'gps_signal_healthy',
    'gps_signal_reduced_but_usable' => 'gps_signal_reduced_but_usable',
    'gps_signal_poor_measurement_quality' =>
      'gps_signal_poor_measurement_quality',
    'gps_signal_interrupted_by_gap' => 'gps_signal_interrupted_by_gap',
    'gps_signal_unsafe_provider_evidence' =>
      'gps_signal_unsafe_provider_evidence',
    _ => 'gps_signal_waiting_for_samples',
  };
}

String _safeMapboxAssistState(String value) {
  return switch (value.trim()) {
    'disabled' => 'disabled',
    'unavailable' => 'unavailable',
    'rate_limited' => 'rate_limited',
    'rejected' => 'rejected',
    'visual_only' => 'visual_only',
    'distance_review' => 'distance_review',
    _ => 'disabled',
  };
}

String _safeMapboxAssistReason(String value) {
  return switch (value.trim()) {
    'mapbox_assist_disabled' => 'mapbox_assist_disabled',
    'mapbox_route_unavailable' => 'mapbox_route_unavailable',
    'mapbox_rate_limited' => 'mapbox_rate_limited',
    'mapbox_http_failure' => 'mapbox_http_failure',
    'mapbox_response_not_object' => 'mapbox_response_not_object',
    'mapbox_service_code_not_ok' => 'mapbox_service_code_not_ok',
    'mapbox_routes_missing' => 'mapbox_routes_missing',
    'mapbox_routes_invalid' => 'mapbox_routes_invalid',
    'invalid_map_assist_threshold' => 'invalid_map_assist_threshold',
    'mapbox_visual_only_no_trusted_mileage' =>
      'mapbox_visual_only_no_trusted_mileage',
    'mapbox_visual_assist_only' => 'mapbox_visual_assist_only',
    'mapbox_distance_review_only' => 'mapbox_distance_review_only',
    _ => 'mapbox_route_unavailable',
  };
}

String _safeMapboxTrustedMileageSource(String value) {
  return switch (value.trim()) {
    'none' => 'none',
    'odometer' => 'odometer',
    'gps_accepted' => 'gps_accepted',
    _ => 'none',
  };
}

double? _safeMapboxMiles(double? value) {
  if (value == null || !value.isFinite || value < 0 || value > 12500) {
    return null;
  }
  return double.parse(value.toStringAsFixed(3));
}

double _safeMapRouteHistoryBudget(double value) {
  if (!value.isFinite || value <= 0) return 0;
  if (value > 2) return 2;
  return double.parse(value.toStringAsFixed(2));
}

int _safeMapRouteHistoryInterval(int value) => value.clamp(15, 300);

String _mapRouteHistoryState(TripTrackingMapStorageEstimate estimate) {
  if (!estimate.enabled) return 'disabled';
  if (!estimate.allowedToPersistRoute && estimate.dailyBudgetMb <= 0) {
    return 'budget_missing';
  }
  if (estimate.exceedsDailyBudget) return 'budget_exceeded';
  return 'within_budget';
}

String _safeRecoveryState(String value) {
  return switch (value.trim()) {
    'none' => 'none',
    'ready' => 'ready',
    'pending_replay' => 'pending_replay',
    'completed_review' => 'completed_review',
    'invalid_session' => 'invalid_session',
    'invalid_review' => 'invalid_review',
    'vehicle_mismatch' => 'vehicle_mismatch',
    'odometer_mismatch' => 'odometer_mismatch',
    'projection_invalid' => 'projection_invalid',
    _ => 'none',
  };
}

String _safeRecoveryReason(String value) {
  return switch (value.trim()) {
    'trip_recovery_none' => 'trip_recovery_none',
    'trip_recovery_ready' => 'trip_recovery_ready',
    'trip_recovery_pending_replay_ready' =>
      'trip_recovery_pending_replay_ready',
    'trip_recovery_completed_review_present' =>
      'trip_recovery_completed_review_present',
    'trip_recovery_invalid_session' => 'trip_recovery_invalid_session',
    'trip_recovery_invalid_review_present' =>
      'trip_recovery_invalid_review_present',
    'trip_recovery_vehicle_mismatch' => 'trip_recovery_vehicle_mismatch',
    'trip_recovery_odometer_mismatch' => 'trip_recovery_odometer_mismatch',
    'trip_recovery_odometer_projection_invalid' =>
      'trip_recovery_odometer_projection_invalid',
    _ => 'trip_recovery_none',
  };
}

String _safeStorageState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'text_record_safe' => 'text_record_safe',
    'low_storage' => 'low_storage',
    'blocked' => 'blocked',
    _ => 'unknown',
  };
}

String _safeDeviceCapabilityState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'unavailable' => 'unavailable',
    'location_only' => 'location_only',
    'foreground_ready' => 'foreground_ready',
    'background_ready' => 'background_ready',
    'motion_ready' => 'motion_ready',
    'full_safety_assist' => 'full_safety_assist',
    _ => 'unknown',
  };
}

String _safeSensorAssistState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'no_assist' => 'no_assist',
    'battery_available' => 'battery_available',
    'motion_available' => 'motion_available',
    'motion_battery_available' => 'motion_battery_available',
    _ => 'unknown',
  };
}

String _safeOdometerCalibrationState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'disabled' => 'disabled',
    'insufficient_history' => 'insufficient_history',
    'stable' => 'stable',
    'review_recommended' => 'review_recommended',
    'invalid' => 'invalid',
    _ => 'unknown',
  };
}

String _safeOdometerUsageState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'disabled' => 'disabled',
    'insufficient_history' => 'insufficient_history',
    'normal' => 'normal',
    'review_recommended' => 'review_recommended',
    'invalid' => 'invalid',
    _ => 'unknown',
  };
}

int? _safeCalibrationSamples(int? value) {
  if (value == null || value < 0) return null;
  return value > 999 ? 999 : value;
}

double? _safeCalibrationMultiplier(double? value) {
  if (value == null || !value.isFinite) return null;
  if (value < .8 || value > 1.25) return null;
  return double.parse(value.toStringAsFixed(4));
}

double? _safeUsageMiles(double? value) {
  if (value == null || !value.isFinite || value < 0 || value > 12500) {
    return null;
  }
  return double.parse(value.toStringAsFixed(1));
}

List<String> _safeDashboardWidgetTokens(Iterable<String> tokens) {
  const allowed = {
    'start_day',
    'live_odometer',
    'stops',
    'pay',
    'profit',
    'miles',
    'hours',
    'expenses',
    'jobs',
    'materials',
    'payments',
    'maintenance',
  };
  return tokens.where(allowed.contains).take(12).toList(growable: false);
}

List<String> _safeQuickActionTokens(Iterable<String> tokens) {
  const allowed = {
    'start_trip',
    'end_trip',
    'add_stop',
    'add_pickup',
    'add_dropoff',
    'add_job',
    'add_expense',
    'add_pay',
    'record_payment',
    'maintenance_log',
    'review_mileage',
  };
  return tokens.where(allowed.contains).take(12).toList(growable: false);
}
