/// Keeps active-workday GPS warnings separate from mileage confirmation.
/// Location data remains advisory until TripLog and the physical odometer are
/// reviewed.
class TripTrackingDashboardLiveStatusPolicy {
  const TripTrackingDashboardLiveStatusPolicy._();

  /// Dashboard health messages are advisory; the confirmed physical odometer
  /// remains the app-wide mileage authority.
  static const bool odometerIsGlobalTruth = true;

  static const _staleSignalFallback =
      'Your phone has not reported a recent location. Keep the trip open and '
      'review the mileage before ending your day.';
  static const _awaitingInitialFixFallback =
      'Waiting for your current location. Your start time and confirmed '
      'odometer are saved.';

  static String vehicleStatus({
    required bool activeTrip,
    required bool nativeTracking,
    required bool hasLiveProjection,
    String? platformStatus,
    bool awaitingInitialFix = false,
    bool signalReviewRequired = false,
  }) {
    if (nativeTracking) {
      if (awaitingInitialFix) return 'GPS ACQUIRING';
      if (platformStatus == 'gps_signal_stale' || signalReviewRequired) {
        return 'GPS DEGRADED';
      }
      return 'LIVE GPS';
    }
    if (activeTrip || hasLiveProjection) {
      if (_isExplicitPause(platformStatus)) return 'GPS PAUSED';
      return 'GPS RECOVERY';
    }
    return 'Active';
  }

  static String? warning({
    required bool tracking,
    String? platformStatus,
    String? platformError,
    bool awaitingInitialFix = false,
  }) {
    if (!tracking) return null;
    final safeError = _nonBlank(platformError);
    if (platformStatus == 'gps_signal_stale') {
      return safeError ?? _staleSignalFallback;
    }
    if (platformStatus == 'paused' ||
        platformStatus == 'recovery_paused_by_user') {
      return safeError ??
          'Location tracking is paused. Your trip is saved until you resume or finish it.';
    }
    final initialFixFallback = switch (platformStatus) {
      'initial_fix_stale' =>
        'Your phone has not provided a current location yet. Your original start time is saved.',
      'initial_fix_approximate' =>
        'Only an approximate location is available. Your confirmed odometer stays official.',
      'initial_fix_unavailable' || 'initial_fix_rejected' =>
        'A reliable starting location is not available yet. You can continue and enter the odometer manually.',
      _ => null,
    };
    if (initialFixFallback != null) return safeError ?? initialFixFallback;
    if (awaitingInitialFix) return safeError ?? _awaitingInitialFixFallback;
    return safeError;
  }

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool _isExplicitPause(String? status) =>
      status == 'paused' ||
      status == 'recovery_paused_by_user' ||
      status == 'battery_critical_gps_blocked' ||
      status == 'low_battery_requires_user_choice' ||
      status == 'gps_signal_review_required';
}
