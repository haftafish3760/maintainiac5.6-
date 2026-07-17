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
    'sensitiveWriteAllowed': false,
    'rawResponseIncluded': false,
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
    MapboxOptionalServiceKind.directions => _hasNonEmptyList(body['routes']),
    MapboxOptionalServiceKind.matrix =>
      _hasNonEmptyList(body['durations']) ||
          _hasNonEmptyList(body['distances']),
    MapboxOptionalServiceKind.mapMatching =>
      _hasNonEmptyList(body['matchings']) || _hasNonEmptyList(body['routes']),
    MapboxOptionalServiceKind.isochrone =>
      _hasFeatureCollection(body) || _hasNonEmptyList(body['features']),
    MapboxOptionalServiceKind.optimization =>
      _hasNonEmptyList(body['trips']) || _hasNonEmptyList(body['routes']),
    MapboxOptionalServiceKind.search =>
      _hasNonEmptyList(body['features']) ||
          _hasNonEmptyList(body['suggestions']),
    MapboxOptionalServiceKind.evChargeFinder =>
      _hasFeatureCollection(body) || _hasNonEmptyList(body['features']),
  };
}

bool _hasFeatureCollection(Map body) {
  return body['type'] == 'FeatureCollection' &&
      _hasNonEmptyList(body['features']);
}

bool _hasNonEmptyList(Object? value) => value is List && value.isNotEmpty;

int? _safeRetryAfterSeconds(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final seconds = value.round();
  if (seconds < 0) return null;
  return seconds > 86400 ? 86400 : seconds;
}
