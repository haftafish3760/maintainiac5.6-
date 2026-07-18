part of 'dashboard_trip_tracking_summary.dart';

bool _isBatteryLimitedStatus(String? status) {
  return switch (status) {
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
