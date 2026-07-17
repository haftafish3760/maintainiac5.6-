import 'dart:math' as math;

enum MapboxExternalFailureCode {
  httpFailure,
  rateLimited,
  malformedResponse,
  missingRoutes,
  invalidRouteShape,
  invalidGeometry,
  invalidCoordinate,
  invalidDistance,
  invalidDuration,
}

class MapboxExternalValidationFailure {
  const MapboxExternalValidationFailure(this.code, this.safeReason);

  final MapboxExternalFailureCode code;
  final String safeReason;
}

class MapboxValidatedCoordinate {
  const MapboxValidatedCoordinate({
    required this.longitude,
    required this.latitude,
  });

  final double longitude;
  final double latitude;

  bool get isValid =>
      longitude.isFinite &&
      latitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180 &&
      latitude >= -90 &&
      latitude <= 90;
}

class MapboxValidatedRouteCandidate {
  const MapboxValidatedRouteCandidate({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.coordinates,
    required this.source,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<MapboxValidatedCoordinate> coordinates;
  final String source;

  double get distanceMiles => distanceMeters / 1609.344;

  /// Mapbox route output is external assistive data. It may visualize,
  /// compare, or explain a trip, but it must not replace confirmed odometer
  /// truth without explicit user review.
  bool get odometerAuthoritative => false;
}

class MapboxRouteValidationResult {
  const MapboxRouteValidationResult._({
    required this.candidates,
    required this.failures,
  });

  factory MapboxRouteValidationResult.accepted(
    List<MapboxValidatedRouteCandidate> candidates,
  ) => MapboxRouteValidationResult._(
    candidates: List.unmodifiable(candidates),
    failures: const [],
  );

  factory MapboxRouteValidationResult.rejected(
    MapboxExternalValidationFailure failure,
  ) => MapboxRouteValidationResult._(candidates: const [], failures: [failure]);

  final List<MapboxValidatedRouteCandidate> candidates;
  final List<MapboxExternalValidationFailure> failures;

  bool get isAccepted => candidates.isNotEmpty && failures.isEmpty;
}

class MapboxExternalRouteValidator {
  const MapboxExternalRouteValidator._();

  static const int minimumHttpStatus = 200;
  static const int maximumHttpStatus = 299;
  static const int rateLimitStatus = 429;
  static const double maximumReasonableRouteMeters = 20000000;
  static const double maximumReasonableRouteSeconds = 60 * 60 * 24 * 14;
  static const double maximumReasonableRouteMetersPerSecond = 90;
  static const int maximumRouteCoordinates = 25000;

  static MapboxRouteValidationResult validateDirectionsLikeResponse({
    required int httpStatus,
    required Object? decodedBody,
  }) {
    if (httpStatus == rateLimitStatus) {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.rateLimited,
          'mapbox_rate_limited',
        ),
      );
    }
    if (httpStatus < minimumHttpStatus || httpStatus > maximumHttpStatus) {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.httpFailure,
          'mapbox_http_failure',
        ),
      );
    }
    if (decodedBody is! Map) {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.malformedResponse,
          'mapbox_response_not_object',
        ),
      );
    }
    final serviceCode = decodedBody['code'];
    if (serviceCode != 'Ok') {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.malformedResponse,
          'mapbox_service_code_not_ok',
        ),
      );
    }
    final routes = decodedBody['routes'];
    if (routes is! List || routes.isEmpty) {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.missingRoutes,
          'mapbox_routes_missing',
        ),
      );
    }

    final accepted = <MapboxValidatedRouteCandidate>[];
    for (final route in routes.take(3)) {
      final candidate = _candidateFromRoute(route);
      if (candidate != null) accepted.add(candidate);
    }
    if (accepted.isEmpty) {
      return MapboxRouteValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.invalidRouteShape,
          'mapbox_routes_invalid',
        ),
      );
    }
    return MapboxRouteValidationResult.accepted(accepted);
  }

  static MapboxValidatedRouteCandidate? _candidateFromRoute(Object? route) {
    if (route is! Map) return null;
    final distance = _finiteNumber(route['distance']);
    final duration = _finiteNumber(route['duration']);
    if (distance == null ||
        distance <= 0 ||
        distance > maximumReasonableRouteMeters) {
      return null;
    }
    if (duration == null ||
        duration <= 0 ||
        duration > maximumReasonableRouteSeconds) {
      return null;
    }
    if (distance / duration > maximumReasonableRouteMetersPerSecond) {
      return null;
    }
    final coordinates = _coordinatesFromGeometry(route['geometry']);
    if (coordinates == null || coordinates.length < 2) return null;
    if (!_hasCoherentRouteDistance(
      reportedDistanceMeters: distance,
      coordinates: coordinates,
    )) {
      return null;
    }
    return MapboxValidatedRouteCandidate(
      distanceMeters: distance,
      durationSeconds: duration,
      coordinates: coordinates,
      source: 'mapbox',
    );
  }

  static List<MapboxValidatedCoordinate>? _coordinatesFromGeometry(
    Object? geometry,
  ) {
    if (geometry is! Map) return null;
    if (geometry['type'] != 'LineString') return null;
    final rawCoordinates = geometry['coordinates'];
    if (rawCoordinates is! List ||
        rawCoordinates.isEmpty ||
        rawCoordinates.length > maximumRouteCoordinates) {
      return null;
    }
    final coordinates = <MapboxValidatedCoordinate>[];
    for (final raw in rawCoordinates) {
      if (raw is! List || raw.length != 2) return null;
      final longitude = _finiteNumber(raw[0]);
      final latitude = _finiteNumber(raw[1]);
      if (longitude == null || latitude == null) return null;
      final coordinate = MapboxValidatedCoordinate(
        longitude: longitude,
        latitude: latitude,
      );
      if (!coordinate.isValid) return null;
      coordinates.add(coordinate);
    }
    return List.unmodifiable(coordinates);
  }

  static double? _finiteNumber(Object? value) {
    if (value is! num || !value.isFinite) return null;
    return value.toDouble();
  }

  static bool _hasCoherentRouteDistance({
    required double reportedDistanceMeters,
    required List<MapboxValidatedCoordinate> coordinates,
  }) {
    var geometryMeters = 0.0;
    for (var index = 1; index < coordinates.length; index++) {
      geometryMeters += _distanceMeters(
        coordinates[index - 1],
        coordinates[index],
      );
    }
    if (!geometryMeters.isFinite || geometryMeters <= 0) return false;
    final lowerBound = (geometryMeters / 5) - 1000;
    final upperBound = (geometryMeters * 3) + 1000;
    return reportedDistanceMeters >= lowerBound &&
        reportedDistanceMeters <= upperBound;
  }
}

double _distanceMeters(
  MapboxValidatedCoordinate left,
  MapboxValidatedCoordinate right,
) {
  const earthRadiusMeters = 6371008.8;
  final latitudeDelta = _radians(right.latitude - left.latitude);
  final longitudeDelta = _radians(right.longitude - left.longitude);
  final a =
      _square(_sin(latitudeDelta / 2)) +
      _cos(_radians(left.latitude)) *
          _cos(_radians(right.latitude)) *
          _square(_sin(longitudeDelta / 2));
  final boundedA = a.clamp(0.0, 1.0).toDouble();
  return earthRadiusMeters * 2 * _atan2(_sqrt(boundedA), _sqrt(1 - boundedA));
}

double _radians(double degrees) => degrees * 3.1415926535897932 / 180;
double _square(double value) => value * value;
double _sin(double value) => math.sin(value);
double _cos(double value) => math.cos(value);
double _sqrt(double value) => math.sqrt(value);
double _atan2(double y, double x) => math.atan2(y, x);
