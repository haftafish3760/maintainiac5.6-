import 'trip_tracking_map_storage_policy.dart';

class TripTrackingMapRoutePointPayloadDecision {
  const TripTrackingMapRoutePointPayloadDecision({
    required this.accepted,
    required this.reasonCode,
    required this.source,
    required this.schemaVersion,
    required this.sequence,
    required this.hasSafeTripId,
    required this.hasValidCoordinate,
    required this.hasValidTimestamp,
    required this.hasValidAccuracy,
    required this.orderedAfterLastPoint,
  });

  final bool accepted;
  final String reasonCode;
  final String source;
  final int schemaVersion;
  final int sequence;
  final bool hasSafeTripId;
  final bool hasValidCoordinate;
  final bool hasValidTimestamp;
  final bool hasValidAccuracy;
  final bool orderedAfterLastPoint;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': schemaVersion == 1 ? 1 : 1,
    'accepted': accepted && _safeRoutePointPayloadReason(reasonCode) == 'valid',
    'reasonCode': _safeRoutePointPayloadReason(reasonCode),
    'source': _safeRoutePointSource(source),
    'sequenceBucket': _sequenceBucket(sequence),
    'hasSafeTripId': hasSafeTripId,
    'hasValidCoordinate': hasValidCoordinate,
    'hasValidTimestamp': hasValidTimestamp,
    'hasValidAccuracy': hasValidAccuracy,
    'orderedAfterLastPoint': orderedAfterLastPoint,
    'gpsTrackingCanContinueWithoutMaps': true,
    'odometerIsGlobalTruth': true,
    'officialMileageSource': 'confirmed_odometer',
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesRoutePointMileage': true,
    'routePointMileageCanOnlyAdviseReview': true,
    'routePointCanSetGlobalTruth': false,
    'routePointCanConfirmOfficialMileage': false,
    'routePointCanChangeOfficialMileage': false,
    'routePointCanConfirmOfficialStop': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'routePointCanCreateCalibration': false,
    'routePointCanApplyCalibration': false,
    'routePointCanReplaceOdometer': false,
    'routePointCanCreateOfficialTripLog': false,
    'mapboxRouteCanReplaceGpsDistance': false,
    'mapboxCanOverrideRouteBudget': false,
    'mapboxFailureCanCorruptTripLog': false,
    'malformedRouteStoragePayloadFailsSafe': true,
    'routeStorageTrustedAfterValidationOnly': true,
    'preciseLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingMapRoutePointPayloadPolicy {
  const TripTrackingMapRoutePointPayloadPolicy._();

  static TripTrackingMapRoutePointPayloadDecision validate({
    required Map<dynamic, dynamic> payload,
    required String expectedTripId,
    required DateTime nowUtc,
    int? lastPersistedSequence,
  }) {
    final schemaVersion = payload['schemaVersion'];
    final tripId = payload['tripId'];
    final source = _safeRoutePointSource('${payload['source'] ?? ''}');
    final recordedAt = DateTime.tryParse('${payload['recordedAt'] ?? ''}');
    final sequence = payload['sequence'];
    final latitude = payload['latitude'];
    final longitude = payload['longitude'];
    final horizontalAccuracyMeters = payload['horizontalAccuracyMeters'];
    final hasSafeTripId =
        _isSafeRoutePointId(tripId) && tripId == expectedTripId;
    final hasValidSchema = schemaVersion is int && schemaVersion == 1;
    final hasValidCoordinate =
        latitude is num &&
        longitude is num &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
    final hasValidTimestamp =
        recordedAt != null &&
        !recordedAt.isBefore(nowUtc.subtract(const Duration(days: 2))) &&
        !recordedAt.isAfter(nowUtc.add(const Duration(minutes: 5)));
    final hasValidSequence =
        sequence is int &&
        sequence >= 0 &&
        sequence <= TripTrackingMapStoragePolicy.maxSafeRoutePointsPerDay;
    final orderedAfterLastPoint =
        lastPersistedSequence == null ||
        (hasValidSequence && sequence > lastPersistedSequence);
    final hasValidAccuracy =
        horizontalAccuracyMeters is num &&
        horizontalAccuracyMeters.isFinite &&
        horizontalAccuracyMeters >= 0 &&
        horizontalAccuracyMeters <= 250;
    final hasRawMapPayload =
        payload.containsKey('mapboxGeometry') ||
        payload.containsKey('routeGeometry') ||
        payload.containsKey('polyline') ||
        payload.containsKey('token') ||
        payload.containsKey('accessToken');
    final reasonCode = !hasValidSchema
        ? 'unsupported_schema'
        : !hasSafeTripId
        ? 'unsafe_trip_binding'
        : source == 'unknown'
        ? 'unsupported_source'
        : !hasValidCoordinate
        ? 'invalid_coordinate'
        : !hasValidTimestamp
        ? 'invalid_timestamp'
        : !hasValidSequence
        ? 'invalid_sequence'
        : !orderedAfterLastPoint
        ? 'route_point_replay_or_duplicate'
        : !hasValidAccuracy
        ? 'invalid_accuracy'
        : hasRawMapPayload
        ? 'raw_map_payload_not_allowed'
        : 'valid';
    return TripTrackingMapRoutePointPayloadDecision(
      accepted: reasonCode == 'valid',
      reasonCode: reasonCode,
      source: source,
      schemaVersion: schemaVersion is int ? schemaVersion : 1,
      sequence: sequence is int ? sequence : -1,
      hasSafeTripId: hasSafeTripId,
      hasValidCoordinate: hasValidCoordinate,
      hasValidTimestamp: hasValidTimestamp,
      hasValidAccuracy: hasValidAccuracy,
      orderedAfterLastPoint: orderedAfterLastPoint,
    );
  }
}

String _safeRoutePointSource(String value) {
  return switch (value.trim()) {
    'gps' => 'gps',
    'mapMatchedGps' => 'mapMatchedGps',
    'userReviewed' => 'userReviewed',
    _ => 'unknown',
  };
}

String _safeRoutePointPayloadReason(String value) {
  return switch (value.trim()) {
    'valid' => 'valid',
    'unsupported_schema' => 'unsupported_schema',
    'unsafe_trip_binding' => 'unsafe_trip_binding',
    'unsupported_source' => 'unsupported_source',
    'invalid_coordinate' => 'invalid_coordinate',
    'invalid_timestamp' => 'invalid_timestamp',
    'invalid_sequence' => 'invalid_sequence',
    'route_point_replay_or_duplicate' => 'route_point_replay_or_duplicate',
    'invalid_accuracy' => 'invalid_accuracy',
    'raw_map_payload_not_allowed' => 'raw_map_payload_not_allowed',
    _ => 'unsupported_schema',
  };
}

bool _isSafeRoutePointId(Object? value) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty || clean.length > 160) return false;
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean);
}

String _sequenceBucket(int value) {
  if (value < 0) return 'invalid';
  if (value == 0) return 'first';
  if (value < 1000) return 'under_1k';
  if (value < 10000) return '1k_10k';
  if (value <= TripTrackingMapStoragePolicy.maxSafeRoutePointsPerDay) {
    return '10k_plus';
  }
  return 'invalid';
}
