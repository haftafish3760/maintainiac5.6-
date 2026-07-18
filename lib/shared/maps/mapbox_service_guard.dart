enum MapboxOptionalServiceKind {
  maps,
  directions,
  matrix,
  mapMatching,
  isochrone,
  optimization,
  search,
  evChargeFinder,
}

enum MapboxServiceGuardStatus {
  disabled,
  ready,
  rateLimited,
  httpFailure,
  malformedResponse,
}

class MapboxServiceGuardDecision {
  const MapboxServiceGuardDecision({
    required this.kind,
    required this.status,
    required this.safeReason,
    required this.retryAfterSeconds,
  });

  final MapboxOptionalServiceKind kind;
  final MapboxServiceGuardStatus status;
  final String safeReason;
  final int? retryAfterSeconds;

  bool get canUseFeature => status == MapboxServiceGuardStatus.ready;
  bool get shouldFallbackToGpsOnly => status != MapboxServiceGuardStatus.ready;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'kind': kind.name,
    'status': status.name,
    'safeReason': safeReason,
    if (retryAfterSeconds != null) 'retryAfterSeconds': retryAfterSeconds,
    'featureOptional': true,
    'fallbackMode': shouldFallbackToGpsOnly ? 'gps_only' : 'map_assist',
    'externalServiceCanonical': false,
    'canModifyTripLog': false,
    'canModifyOdometer': false,
    'sensitiveWriteAllowed': false,
    'rawResponseIncluded': false,
    'rawGeometryIncluded': false,
    'tokensIncluded': false,
    'publicTokenIncluded': false,
    'secretTokenIncluded': false,
    'coordinatesIncluded': false,
  };
}

class MapboxServiceGuard {
  const MapboxServiceGuard._();

  static MapboxServiceGuardDecision evaluate({
    required MapboxOptionalServiceKind kind,
    required bool featureEnabled,
    required int? httpStatus,
    required Object? decodedBody,
    Object? retryAfterSeconds,
  }) {
    if (!featureEnabled) {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.disabled,
        safeReason: 'mapbox_${kind.name}_disabled',
        retryAfterSeconds: null,
      );
    }
    final status = httpStatus;
    if (status == 429) {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.rateLimited,
        safeReason: 'mapbox_${kind.name}_rate_limited',
        retryAfterSeconds: _safeRetryAfterSeconds(retryAfterSeconds),
      );
    }
    if (status == null || status < 200 || status > 299) {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.httpFailure,
        safeReason: 'mapbox_${kind.name}_http_failure',
        retryAfterSeconds: null,
      );
    }
    if (decodedBody is! Map || decodedBody.isEmpty) {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.malformedResponse,
        safeReason: 'mapbox_${kind.name}_malformed_response',
        retryAfterSeconds: null,
      );
    }
    final serviceCode = decodedBody['code'];
    if (serviceCode != null && serviceCode != 'Ok') {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.malformedResponse,
        safeReason: 'mapbox_${kind.name}_service_code_not_ok',
        retryAfterSeconds: null,
      );
    }
    if (!_hasExpectedShape(kind, decodedBody)) {
      return MapboxServiceGuardDecision(
        kind: kind,
        status: MapboxServiceGuardStatus.malformedResponse,
        safeReason: 'mapbox_${kind.name}_unexpected_shape',
        retryAfterSeconds: null,
      );
    }
    return MapboxServiceGuardDecision(
      kind: kind,
      status: MapboxServiceGuardStatus.ready,
      safeReason: 'mapbox_${kind.name}_ready',
      retryAfterSeconds: null,
    );
  }
}

bool _hasExpectedShape(MapboxOptionalServiceKind kind, Map body) {
  return switch (kind) {
    MapboxOptionalServiceKind.maps => true,
    MapboxOptionalServiceKind.directions => _hasUsableRouteList(body['routes']),
    MapboxOptionalServiceKind.matrix =>
      _hasUsableMatrix(body['durations'], maxCellValue: 60 * 60 * 24 * 14) ||
          _hasUsableMatrix(body['distances'], maxCellValue: 20000000),
    MapboxOptionalServiceKind.mapMatching =>
      _hasUsableRouteList(body['matchings']) ||
          _hasUsableRouteList(body['routes']),
    MapboxOptionalServiceKind.isochrone =>
      _hasFeatureCollection(body) || _hasUsableFeatureList(body['features']),
    MapboxOptionalServiceKind.optimization =>
      _hasUsableRouteList(body['trips']) || _hasUsableRouteList(body['routes']),
    MapboxOptionalServiceKind.search =>
      _hasUsableFeatureList(body['features']) ||
          _hasUsableFeatureList(body['suggestions']),
    MapboxOptionalServiceKind.evChargeFinder =>
      _hasFeatureCollection(body) || _hasUsableFeatureList(body['features']),
  };
}

bool _hasFeatureCollection(Map body) {
  return body['type'] == 'FeatureCollection' &&
      _hasUsableFeatureList(body['features']);
}

bool _hasUsableRouteList(Object? value) {
  if (value is! List || value.isEmpty || value.length > 25) return false;
  return value.any(_hasUsableRouteShape);
}

bool _hasUsableRouteShape(Object? value) {
  if (value is! Map) return false;
  final distance = _safeFiniteNumber(value['distance']);
  final duration = _safeFiniteNumber(value['duration']);
  final hasBoundedDistance =
      distance == null || (distance > 0 && distance <= 20000000);
  final hasBoundedDuration =
      duration == null || (duration > 0 && duration <= 60 * 60 * 24 * 14);
  if (!hasBoundedDistance || !hasBoundedDuration) return false;
  return value.containsKey('geometry') ||
      value.containsKey('legs') ||
      distance != null ||
      duration != null;
}

bool _hasUsableMatrix(Object? value, {required double maxCellValue}) {
  if (value is! List || value.isEmpty || value.length > 25) return false;
  var hasReachableCell = false;
  for (final row in value) {
    if (row is! List || row.isEmpty || row.length > 25) return false;
    for (final cell in row) {
      if (cell == null) continue;
      final number = _safeFiniteNumber(cell);
      if (number == null || number < 0 || number > maxCellValue) return false;
      hasReachableCell = true;
    }
  }
  return hasReachableCell;
}

bool _hasUsableFeatureList(Object? value) {
  if (value is! List || value.isEmpty || value.length > 100) return false;
  return value.any((feature) => feature is Map && feature.isNotEmpty);
}

int? _safeRetryAfterSeconds(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final seconds = value.round();
  if (seconds < 0) return null;
  return seconds > 86400 ? 86400 : seconds;
}

double? _safeFiniteNumber(Object? value) {
  if (value == null) return null;
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}
