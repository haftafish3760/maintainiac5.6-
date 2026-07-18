class LiveOdometerDisplaySnapshot {
  const LiveOdometerDisplaySnapshot({
    required this.confirmedReading,
    required this.displayReading,
    required this.isLive,
    this.liveUpdatedAt,
  });

  final int confirmedReading;
  final int displayReading;
  final bool isLive;
  final DateTime? liveUpdatedAt;

  int get deltaMiles {
    final delta = displayReading - confirmedReading;
    return isLive && delta > 0 ? delta : 0;
  }

  String get label => isLive ? 'Live GPS odometer' : 'Odometer';

  String get truthLabel => isLive
      ? 'Confirmed odometer remains the mileage truth until trip review.'
      : 'Confirmed odometer';

  bool get manualEntryBlocked => isLive;

  bool get hasAdvisoryDelta => isLive && deltaMiles > 0;

  bool get confirmedReadingIsCanonical => true;

  bool get rawGpsIncluded => false;

  bool get routeGeometryIncluded => false;

  bool get mapboxMayOverrideOdometer => false;

  int get safeDisplayReading => isLive && displayReading < confirmedReading
      ? confirmedReading
      : displayReading;

  String get displayValue =>
      _safeReading(safeDisplayReading).toString().padLeft(7, '0');

  String get confirmedDisplayValue =>
      _safeReading(confirmedReading).toString().padLeft(7, '0');

  String? get deltaLabel {
    if (!isLive) return null;
    return hasAdvisoryDelta ? '+$deltaMiles mi live' : 'GPS live';
  }

  String? get advisoryLabel {
    if (!isLive) return null;
    if (hasAdvisoryDelta) {
      return 'GPS-assisted estimate is $deltaMiles mi ahead of confirmed odometer.';
    }
    return 'GPS-assisted odometer is live; confirmed mileage has not changed.';
  }

  bool isStaleAt(
    DateTime now, {
    Duration staleAfter = const Duration(minutes: 5),
  }) {
    final updatedAt = liveUpdatedAt;
    if (!isLive || updatedAt == null) return false;
    if (staleAfter <= Duration.zero) return false;
    return now.toUtc().difference(updatedAt.toUtc()) > staleAfter;
  }

  int? ageSecondsAt(DateTime now) {
    final updatedAt = liveUpdatedAt;
    if (!isLive || updatedAt == null) return null;
    final age = now.toUtc().difference(updatedAt.toUtc()).inSeconds;
    if (age < 0) return 0;
    return age > 86400 ? 86400 : age;
  }

  String freshnessAt(DateTime now) {
    if (!isLive) return 'inactive';
    return isStaleAt(now) ? 'stale' : 'fresh';
  }

  String? statusLabelAt(DateTime now) {
    if (!isLive) return null;
    if (isStaleAt(now)) return 'Live GPS paused';
    return deltaLabel;
  }

  String semanticsLabelAt(DateTime now) {
    final status = statusLabelAt(now);
    if (!isLive) return '$label $displayValue';
    return [
      label,
      displayValue,
      ?status,
      'confirmed $confirmedDisplayValue',
    ].join(', ');
  }

  Map<String, Object?> toSafeDashboardMap(DateTime now) => {
    'schemaVersion': 1,
    'label': label,
    'displayValue': displayValue,
    'confirmedDisplayValue': confirmedDisplayValue,
    'isLive': isLive,
    'deltaMiles': deltaMiles,
    'statusLabel': statusLabelAt(now),
    'advisoryLabel': advisoryLabel,
    'freshness': freshnessAt(now),
    'ageSeconds': ageSecondsAt(now),
    'reviewRequired': isStaleAt(now),
    'manualEntryBlocked': manualEntryBlocked,
    'truthLabel': truthLabel,
    'confirmedReadingIsCanonical': confirmedReadingIsCanonical,
    'advisoryOnly': true,
    'dashboardLiveUpdateReady': true,
    'displayCanUpdateBeforeReview': isLive,
    'writesConfirmedOdometer': false,
    'manualConfirmationRequired': isLive,
    'gpsCanReplaceOdometer': false,
    'mapsRequiredForTracking': false,
    'mapboxCanChangeDisplay': false,
    'localTripLogProtected': true,
    'preciseLocationIncluded': false,
    'rawGpsIncluded': rawGpsIncluded,
    'routeGeometryIncluded': routeGeometryIncluded,
    'mapboxMayOverrideOdometer': mapboxMayOverrideOdometer,
  };
}

int _safeReading(int value) => value < 0 ? 0 : value;
