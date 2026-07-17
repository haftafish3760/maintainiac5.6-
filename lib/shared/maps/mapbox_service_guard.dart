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
    'kind': kind.name,
    'status': status.name,
    'safeReason': safeReason,
    if (retryAfterSeconds != null) 'retryAfterSeconds': retryAfterSeconds,
    'rawResponseIncluded': false,
    'tokensIncluded': false,
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
    return MapboxServiceGuardDecision(
      kind: kind,
      status: MapboxServiceGuardStatus.ready,
      safeReason: 'mapbox_${kind.name}_ready',
      retryAfterSeconds: null,
    );
  }
}

int? _safeRetryAfterSeconds(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final seconds = value.round();
  if (seconds < 0) return null;
  return seconds > 86400 ? 86400 : seconds;
}
