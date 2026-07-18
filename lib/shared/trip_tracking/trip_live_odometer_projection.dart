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
    'activeVehicleBlockMustNotCacheProjection': true,
    'allDashboardSurfacesUseSameProjectionRevision': true,
    'contractorDashboardUsesLiveProjection': true,
    'crossDashboardLiveOdometerReady': true,
    'displayCanUpdateBeforeReview': true,
    'displayProjectionIsNotOfficialMileage': true,
    'liveProjectionCanSetGlobalTruth': false,
    'liveProjectionCanChangeGlobalTruth': false,
    'liveProjectionCanConfirmOfficialMileage': false,
    'displayOnlyMileageSource': 'gps_assisted_projection',
    'externalDistanceValidatedBeforeProjection': true,
    'projectionTrustedAfterValidationOnly': true,
    'remoteProjectionRequiresMatchingTripId': true,
    'matchingActiveTripRequired': true,
    'matchingVehicleProfileRequired': true,
    'projectionRevisionMustIncrease': true,
    'liveProjectionRequiresOwnershipValidation': true,
    'liveProjectionRequiresDeviceLocalSource': true,
    'projectionCannotOutliveActiveDay': true,
    'authenticationDoesNotGrantDisplayAuthority': true,
    'staleProjectionCanCommitMileage': false,
    'staleProjectionCanNotifyAsFresh': false,
    'remoteProjectionCanReviveEndedTrip': false,
    'remoteProjectionCanOverrideLocalTrip': false,
    'firestoreCanOverrideLiveProjection': false,
    'firestoreCanOverrideLiveDisplay': false,
    'remoteDisplayCanOverrideLocalTrip': false,
    'importedDisplayCanOverrideLocalTrip': false,
    'dashboardCacheCanOverrideLocalTrip': false,
    'mapboxCanOverrideLiveProjection': false,
    'mapboxCanIncreaseLiveMileage': false,
    'malformedProjectionPayloadFailsSafe': true,
    'writesConfirmedOdometer': false,
    'confirmedOdometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'manualConfirmationRequired': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'mapsRequiredForTracking': false,
    'mapboxCanChangeProjection': false,
    'calibrationCanCommitWithoutReview': false,
    'calibrationCanDecreaseLiveProjection': false,
    'localTripLogProtected': true,
    'futureProjectionCanRender': false,
    'impossibleProjectionCanRender': false,
    'activeTripIdIncluded': false,
    'ownerUserIdIncluded': false,
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
    if (payload['displayOnlyMileageSource'] != 'gps_assisted_projection') {
      reasons.add('invalid_display_only_mileage_source');
    }
    if (payload['externalDistanceValidatedBeforeProjection'] != true ||
        payload['projectionTrustedAfterValidationOnly'] != true) {
      reasons.add('external_distance_validation_contract_missing');
    }
    if (payload['confirmedOdometerRemainsCanonical'] != true ||
        payload['odometerIsGlobalTruth'] != true ||
        payload['physicalOdometerRequiredForOfficialMileage'] != true ||
        payload['confirmedOdometerOverridesExternalMileage'] != true ||
        payload['externalMileageCannotBecomeGlobalTruth'] != true ||
        payload['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        payload['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        payload['optimizationCannotChangeOfficialMileage'] != true) {
      reasons.add('confirmed_odometer_not_marked_canonical');
    }
    if (payload['displayProjectionIsNotOfficialMileage'] != true ||
        payload['liveProjectionCanSetGlobalTruth'] != false ||
        payload['liveProjectionCanChangeGlobalTruth'] != false ||
        payload['liveProjectionCanConfirmOfficialMileage'] != false) {
      reasons.add('live_projection_claims_global_truth');
    }
    if (payload['manualConfirmationRequired'] != true) {
      reasons.add('manual_confirmation_not_required');
    }
    if (payload['matchingActiveTripRequired'] != true ||
        payload['remoteProjectionRequiresMatchingTripId'] != true ||
        payload['liveProjectionRequiresOwnershipValidation'] != true ||
        payload['liveProjectionRequiresDeviceLocalSource'] != true ||
        payload['projectionCannotOutliveActiveDay'] != true ||
        payload['matchingVehicleProfileRequired'] != true ||
        payload['projectionRevisionMustIncrease'] != true ||
        payload['localTripLogProtected'] != true ||
        payload['authenticationDoesNotGrantDisplayAuthority'] != true) {
      reasons.add('live_projection_local_authorization_contract_missing');
    }
    if (payload['remoteProjectionCanReviveEndedTrip'] != false) {
      reasons.add('remote_projection_can_revive_ended_trip');
    }
    if (payload['remoteProjectionCanOverrideLocalTrip'] != false) {
      reasons.add('remote_projection_can_override_local_trip');
    }
    if (payload['firestoreCanOverrideLiveProjection'] != false) {
      reasons.add('firestore_can_override_live_projection');
    }
    if (payload['firestoreCanOverrideLiveDisplay'] != false ||
        payload['remoteDisplayCanOverrideLocalTrip'] != false ||
        payload['importedDisplayCanOverrideLocalTrip'] != false ||
        payload['dashboardCacheCanOverrideLocalTrip'] != false) {
      reasons.add('remote_display_can_override_local_trip');
    }
    if (payload['mapboxCanOverrideLiveProjection'] != false ||
        payload['mapboxCanIncreaseLiveMileage'] != false) {
      reasons.add('mapbox_can_override_live_projection');
    }
    if (payload['staleProjectionCanNotifyAsFresh'] != false) {
      reasons.add('remote_projection_can_override_local_trip');
    }
    if (payload['calibrationCanCommitWithoutReview'] != false ||
        payload['calibrationCanDecreaseLiveProjection'] != false) {
      reasons.add('payload_can_write_confirmed_odometer');
    }
    if (payload['futureProjectionCanRender'] != false ||
        payload['impossibleProjectionCanRender'] != false) {
      reasons.add('unsafe_projection_can_render');
    }
    if (payload['activeTripIdIncluded'] != false ||
        payload['ownerUserIdIncluded'] != false) {
      reasons.add('payload_contains_trip_owner_identifiers');
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
    if (payload['activeVehicleBlockMustNotCacheProjection'] != true ||
        payload['allDashboardSurfacesUseSameProjectionRevision'] != true) {
      reasons.add('live_projection_surface_contract_missing');
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
