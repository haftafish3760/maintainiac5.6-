/// Keeps active-workday GPS warnings separate from mileage confirmation.
/// Location data remains advisory until TripLog and the physical odometer are
/// reviewed.
class TripTrackingDashboardLiveStatusPolicy {
  const TripTrackingDashboardLiveStatusPolicy._();

  /// Dashboard health messages are advisory; the confirmed physical odometer
  /// remains the app-wide mileage authority.
  static const bool odometerIsGlobalTruth = true;

  static const _staleSignalFallback =
      'GPS has not produced a location fix recently. Keep your trip open; '
      'review the gap before confirming mileage.';
  static const _awaitingInitialFixFallback =
      'Waiting for a current GPS fix. Your true trip start time is preserved, '
      'and the confirmed odometer remains official.';

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
          'GPS assistance is paused by you. The trip and its explicit gap are preserved until you resume or complete it.';
    }
    final initialFixFallback = switch (platformStatus) {
      'initial_fix_stale' =>
        'GPS returned an old cached location. The original trip start time is preserved while a current fix is requested.',
      'initial_fix_approximate' =>
        'Only approximate location is available. GPS assistance remains degraded; the confirmed odometer stays official.',
      'initial_fix_unavailable' || 'initial_fix_rejected' =>
        'A reliable starting location is not available yet. The trip can continue with degraded GPS assistance.',
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
}
