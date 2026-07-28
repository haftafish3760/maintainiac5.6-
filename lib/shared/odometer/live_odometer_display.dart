class LiveOdometerDisplaySnapshot {
  const LiveOdometerDisplaySnapshot({
    required this.confirmedReading,
    required this.displayReading,
    this.displayTenths,
    required this.isLive,
    this.liveUpdatedAt,
    this.projectionRevision = 0,
  });

  final int confirmedReading;
  final int displayReading;
  final int? displayTenths;
  final bool isLive;
  final DateTime? liveUpdatedAt;
  final int projectionRevision;

  int get deltaMiles {
    final delta = displayReading - confirmedReading;
    return isLive && delta > 0 ? delta : 0;
  }

  int get deltaTenths {
    final delta = safeDisplayTenths - confirmedReading * 10;
    return isLive && delta > 0 ? delta : 0;
  }

  String get label => isLive ? 'Live GPS odometer' : 'Odometer';

  String get truthLabel => isLive
      ? 'Confirmed odometer remains the mileage truth until trip review.'
      : 'Confirmed odometer';

  bool get manualEntryBlocked => isLive;

  bool get hasAdvisoryDelta => isLive && deltaTenths > 0;

  bool get confirmedReadingIsCanonical => true;

  bool get rawGpsIncluded => false;

  bool get routeGeometryIncluded => false;

  bool get mapboxMayOverrideOdometer => false;

  int get safeDisplayReading => isLive && displayReading < confirmedReading
      ? confirmedReading
      : displayReading;

  int get safeDisplayTenths {
    final fallback = safeDisplayReading * 10;
    final value = displayTenths;
    if (!isLive || value == null || value < confirmedReading * 10) {
      return fallback;
    }
    return value;
  }

  bool get hasLiveTenths => isLive && displayTenths != null;

  String get displayValue => hasLiveTenths
      ? _formatTenths(safeDisplayTenths)
      : _safeReading(safeDisplayReading).toString();

  String get confirmedDisplayValue => _safeReading(confirmedReading).toString();

  String? get deltaLabel {
    if (!isLive) return null;
    if (deltaTenths <= 0) return 'GPS live';
    return hasLiveTenths
        ? '+${_formatTenths(deltaTenths)} mi live'
        : '+$deltaMiles mi live';
  }

  String? get advisoryLabel {
    if (!isLive) return null;
    if (hasAdvisoryDelta) {
      final delta = hasLiveTenths
          ? _formatTenths(deltaTenths)
          : deltaMiles.toString();
      return 'GPS-assisted estimate is $delta mi ahead of confirmed odometer.';
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
    'projectionRevision': projectionRevision < 0 ? 0 : projectionRevision,
    'reviewRequired': isStaleAt(now),
    'manualEntryBlocked': manualEntryBlocked,
    'truthLabel': truthLabel,
    'confirmedReadingIsCanonical': confirmedReadingIsCanonical,
    'advisoryOnly': true,
    'dashboardLiveUpdateReady': true,
    'liveUiMustRefreshOnProjectionChange': true,
    'displayCanUpdateBeforeReview': isLive,
    'displayOnlyMileageSource': isLive
        ? 'gps_assisted_projection'
        : 'confirmed_odometer',
    'externalDistanceValidatedBeforeDisplay': true,
    'liveDisplayTrustedAfterValidationOnly': true,
    'remoteProjectionRequiresMatchingTripId': true,
    'staleProjectionCanCommitMileage': false,
    'remoteDisplayCanOverrideLocalTrip': false,
    'firestoreCanOverrideLiveDisplay': false,
    'mapboxCanOverrideLiveDisplay': false,
    'malformedDisplayPayloadFailsSafe': true,
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

String _formatTenths(int value) {
  final safe = value < 0 ? 0 : value;
  return '${safe ~/ 10}.${safe % 10}';
}
