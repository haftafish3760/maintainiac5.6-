/// Keeps active-workday GPS warnings separate from mileage confirmation.
/// Location data remains advisory until TripLog and the physical odometer are
/// reviewed.
class TripTrackingDashboardLiveStatusPolicy {
  const TripTrackingDashboardLiveStatusPolicy._();

  static const _staleSignalFallback =
      'GPS has not produced a location fix recently. Keep your trip open; '
      'review the gap before confirming mileage.';

  static String? warning({
    required bool tracking,
    String? platformStatus,
    String? platformError,
  }) {
    if (!tracking) return null;
    final safeError = _nonBlank(platformError);
    if (platformStatus == 'gps_signal_stale') {
      return safeError ?? _staleSignalFallback;
    }
    return safeError;
  }

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
