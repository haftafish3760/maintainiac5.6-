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
