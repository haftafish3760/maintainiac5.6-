const metersPerMile = 1609.344;

/// Produces a display-only odometer estimate during an active GPS trip. The
/// confirmed odometer is intentionally not overwritten until trip review.
class TripLiveOdometerProjection {
  TripLiveOdometerProjection({
    required this.startingOdometer,
    int maxSupportedReading = 9999999,
  }) : maxSupportedReading = _safeMaxSupportedReading(maxSupportedReading),
       _lastProjectedReading = _safeInitialProjection(
         startingOdometer: startingOdometer,
         maxSupportedReading: maxSupportedReading,
       );

  final int startingOdometer;
  final int maxSupportedReading;
  int _lastProjectedReading;
  var _lastUpdateExceededMax = false;

  int get projectedReading => _lastProjectedReading;
  bool get lastUpdateExceededMax => _lastUpdateExceededMax;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'projectedReading': projectedReading,
    'startingOdometer': _safeStartingOdometer(startingOdometer),
    'maxSupportedReading': maxSupportedReading,
    'lastUpdateExceededMax': lastUpdateExceededMax,
    'projectionExceededSupportedRange': lastUpdateExceededMax,
    'projectionIsMonotonic': true,
    'advisoryOnly': true,
    'dashboardLiveUpdateReady': true,
    'liveUiMustRefreshOnProjectionChange': true,
    'globalOdometerScopeMustNotifyListeners': true,
    'dashboardActiveVehicleBlockUsesLiveProjection': true,
    'contractorDashboardUsesLiveProjection': true,
    'crossDashboardLiveOdometerReady': true,
    'displayCanUpdateBeforeReview': true,
    'displayOnlyMileageSource': 'gps_assisted_projection',
    'externalDistanceValidatedBeforeProjection': true,
    'projectionTrustedAfterValidationOnly': true,
    'remoteProjectionRequiresMatchingTripId': true,
    'staleProjectionCanCommitMileage': false,
    'remoteProjectionCanOverrideLocalTrip': false,
    'firestoreCanOverrideLiveProjection': false,
    'mapboxCanOverrideLiveProjection': false,
    'malformedProjectionPayloadFailsSafe': true,
    'writesConfirmedOdometer': false,
    'confirmedOdometerRemainsCanonical': true,
    'manualConfirmationRequired': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'mapsRequiredForTracking': false,
    'mapboxCanChangeProjection': false,
    'localTripLogProtected': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };

  int updateAcceptedMeters(
    double acceptedMeters, {
    double gpsAssistanceCalibrationMultiplier = 1,
  }) {
    _lastUpdateExceededMax = false;
    if (!acceptedMeters.isFinite || acceptedMeters < 0) {
      return _lastProjectedReading;
    }
    final safeStart = _safeStartingOdometer(startingOdometer);
    final multiplier = _safeCalibrationMultiplier(
      gpsAssistanceCalibrationMultiplier,
    );
    final acceptedMiles = (acceptedMeters / metersPerMile) * multiplier;
    if (!acceptedMiles.isFinite ||
        acceptedMiles > maxSupportedReading - safeStart) {
      _lastUpdateExceededMax = acceptedMiles.isFinite;
      return _lastProjectedReading;
    }
    final estimated = safeStart + acceptedMiles.round();
    if (estimated > maxSupportedReading) {
      _lastUpdateExceededMax = true;
      return _lastProjectedReading;
    }
    if (estimated > _lastProjectedReading) {
      _lastProjectedReading = estimated;
    }
    return _lastProjectedReading;
  }
}

/// Validates a dashboard-facing live odometer payload at the UI trust boundary.
///
/// This does not make the projection canonical. It only lets dashboard widgets
/// decide whether an incoming local/remote mirror is safe enough to render as an
/// advisory live value. Confirmed odometer writes still require trip review.
class TripLiveOdometerDashboardPayloadValidation {
  const TripLiveOdometerDashboardPayloadValidation._({
    required this.isRenderable,
    required this.projectedReading,
    required this.reasons,
  });

  factory TripLiveOdometerDashboardPayloadValidation.fromPayload(
    Map<String, Object?> payload,
  ) {
    final reasons = <String>[];
    final schemaVersion = payload['schemaVersion'];
    final projectedReading = payload['projectedReading'];
    final startingOdometer = payload['startingOdometer'];
    final maxSupportedReading = payload['maxSupportedReading'];

    if (schemaVersion != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (projectedReading is! int) {
      reasons.add('projected_reading_not_int');
    }
    if (startingOdometer is! int) {
      reasons.add('starting_odometer_not_int');
    }
    if (maxSupportedReading is! int) {
      reasons.add('max_supported_reading_not_int');
    }

    final int? safeProjected = projectedReading is int
        ? _safeStartingOdometer(projectedReading)
        : null;
    final int? safeStart = startingOdometer is int
        ? _safeStartingOdometer(startingOdometer)
        : null;
    final int? safeMax = maxSupportedReading is int
        ? _safeMaxSupportedReading(maxSupportedReading)
        : null;

    if (safeProjected != null &&
        safeStart != null &&
        safeProjected < safeStart) {
      reasons.add('projection_below_starting_odometer');
    }
    if (safeProjected != null && safeMax != null && safeProjected > safeMax) {
      reasons.add('projection_above_supported_odometer');
    }
    if (payload['writesConfirmedOdometer'] != false) {
      reasons.add('payload_can_write_confirmed_odometer');
    }
    if (payload['confirmedOdometerRemainsCanonical'] != true) {
      reasons.add('confirmed_odometer_not_marked_canonical');
    }
    if (payload['remoteProjectionCanOverrideLocalTrip'] != false) {
      reasons.add('remote_projection_can_override_local_trip');
    }
    if (payload['firestoreCanOverrideLiveProjection'] != false) {
      reasons.add('firestore_can_override_live_projection');
    }
    if (payload['mapboxCanOverrideLiveProjection'] != false) {
      reasons.add('mapbox_can_override_live_projection');
    }
    if (payload['rawGpsIncluded'] != false ||
        payload['preciseLocationIncluded'] != false ||
        payload['routeGeometryIncluded'] != false ||
        payload['tokensIncluded'] != false) {
      reasons.add('payload_contains_sensitive_trip_material');
    }
    if (payload['projectionIsMonotonic'] != true) {
      reasons.add('projection_not_marked_monotonic');
    }
    if (payload['advisoryOnly'] != true) {
      reasons.add('projection_not_marked_advisory');
    }
    if (payload['mapsRequiredForTracking'] != false) {
      reasons.add('maps_required_for_tracking');
    }

    return TripLiveOdometerDashboardPayloadValidation._(
      isRenderable: reasons.isEmpty,
      projectedReading: reasons.isEmpty ? safeProjected : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final int? projectedReading;
  final List<String> reasons;
}

int _safeStartingOdometer(int value) => value < 0 ? 0 : value;

int _safeMaxSupportedReading(int value) => value < 0 ? 0 : value;

double _safeCalibrationMultiplier(double value) {
  if (!value.isFinite || value <= 0) return 1;
  return value.clamp(0.8, 1.25).toDouble();
}

int _safeInitialProjection({
  required int startingOdometer,
  required int maxSupportedReading,
}) {
  final safeStart = _safeStartingOdometer(startingOdometer);
  final safeMax = _safeMaxSupportedReading(maxSupportedReading);
  return safeStart > safeMax ? safeMax : safeStart;
}
