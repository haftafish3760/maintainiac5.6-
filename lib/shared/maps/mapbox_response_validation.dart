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
  invalidMatrixShape,
  noReachableMatrixCells,
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

class MapboxValidatedMatrixCell {
  const MapboxValidatedMatrixCell({
    required this.row,
    required this.column,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  final int row;
  final int column;
  final double? durationSeconds;
  final double? distanceMeters;

  bool get isReachable => durationSeconds != null;
}

class MapboxMatrixValidationResult {
  const MapboxMatrixValidationResult._({
    required this.cells,
    required this.failures,
  });

  factory MapboxMatrixValidationResult.accepted(
    List<MapboxValidatedMatrixCell> cells,
  ) => MapboxMatrixValidationResult._(
    cells: List.unmodifiable(cells),
    failures: const [],
  );

  factory MapboxMatrixValidationResult.rejected(
    MapboxExternalValidationFailure failure,
  ) => MapboxMatrixValidationResult._(cells: const [], failures: [failure]);

  final List<MapboxValidatedMatrixCell> cells;
  final List<MapboxExternalValidationFailure> failures;

  bool get isAccepted => cells.isNotEmpty && failures.isEmpty;
  int get reachableCellCount => cells.where((cell) => cell.isReachable).length;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'accepted': isAccepted,
    'reachableCellCount': reachableCellCount,
    'cellCount': cells.length,
    'coordinatesIncluded': false,
    'tokensIncluded': false,
    'odometerAuthoritative': false,
  };
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
  static const int maximumAcceptedRouteCandidates = 3;
  static const int maximumRouteCandidatesScanned = 25;

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
    for (final route in routes.take(maximumRouteCandidatesScanned)) {
      final candidate = _candidateFromRoute(route);
      if (candidate != null) accepted.add(candidate);
      if (accepted.length == maximumAcceptedRouteCandidates) break;
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

class MapboxExternalMatrixValidator {
  const MapboxExternalMatrixValidator._();

  static const int maximumMatrixRows = 25;
  static const int maximumMatrixColumns = 25;

  static MapboxMatrixValidationResult validateMatrixLikeResponse({
    required int httpStatus,
    required Object? decodedBody,
  }) {
    final commonFailure = _validateCommonMapboxEnvelope(
      httpStatus: httpStatus,
      decodedBody: decodedBody,
    );
    if (commonFailure != null) {
      return MapboxMatrixValidationResult.rejected(commonFailure);
    }
    final body = decodedBody as Map;
    final durations = body['durations'];
    if (durations is! List || durations.isEmpty) {
      return MapboxMatrixValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.invalidMatrixShape,
          'mapbox_matrix_durations_missing',
        ),
      );
    }
    if (durations.length > maximumMatrixRows) {
      return MapboxMatrixValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.invalidMatrixShape,
          'mapbox_matrix_rows_exceeded',
        ),
      );
    }
    final distances = body['distances'];
    if (distances != null &&
        (distances is! List || distances.length != durations.length)) {
      return MapboxMatrixValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.invalidMatrixShape,
          'mapbox_matrix_distance_shape_invalid',
        ),
      );
    }
    final cells = <MapboxValidatedMatrixCell>[];
    int? expectedColumns;
    var reachableCells = 0;
    for (var rowIndex = 0; rowIndex < durations.length; rowIndex += 1) {
      final durationRow = durations[rowIndex];
      if (durationRow is! List || durationRow.isEmpty) {
        return MapboxMatrixValidationResult.rejected(
          const MapboxExternalValidationFailure(
            MapboxExternalFailureCode.invalidMatrixShape,
            'mapbox_matrix_duration_row_invalid',
          ),
        );
      }
      expectedColumns ??= durationRow.length;
      if (durationRow.length != expectedColumns ||
          durationRow.length > maximumMatrixColumns) {
        return MapboxMatrixValidationResult.rejected(
          const MapboxExternalValidationFailure(
            MapboxExternalFailureCode.invalidMatrixShape,
            'mapbox_matrix_columns_invalid',
          ),
        );
      }
      final distanceRow = distances == null ? null : distances[rowIndex];
      if (distanceRow != null &&
          (distanceRow is! List || distanceRow.length != durationRow.length)) {
        return MapboxMatrixValidationResult.rejected(
          const MapboxExternalValidationFailure(
            MapboxExternalFailureCode.invalidMatrixShape,
            'mapbox_matrix_distance_row_invalid',
          ),
        );
      }
      for (
        var columnIndex = 0;
        columnIndex < durationRow.length;
        columnIndex += 1
      ) {
        final duration = _nullableBoundedNumber(
          durationRow[columnIndex],
          maximum: MapboxExternalRouteValidator.maximumReasonableRouteSeconds,
        );
        if (duration == _invalidNullableNumber) {
          return MapboxMatrixValidationResult.rejected(
            const MapboxExternalValidationFailure(
              MapboxExternalFailureCode.invalidDuration,
              'mapbox_matrix_duration_invalid',
            ),
          );
        }
        final distance = distanceRow == null
            ? null
            : _nullableBoundedNumber(
                distanceRow[columnIndex],
                maximum:
                    MapboxExternalRouteValidator.maximumReasonableRouteMeters,
              );
        if (distance == _invalidNullableNumber) {
          return MapboxMatrixValidationResult.rejected(
            const MapboxExternalValidationFailure(
              MapboxExternalFailureCode.invalidDistance,
              'mapbox_matrix_distance_invalid',
            ),
          );
        }
        if (duration != null) reachableCells += 1;
        cells.add(
          MapboxValidatedMatrixCell(
            row: rowIndex,
            column: columnIndex,
            durationSeconds: duration,
            distanceMeters: distance,
          ),
        );
      }
    }
    if (reachableCells == 0) {
      return MapboxMatrixValidationResult.rejected(
        const MapboxExternalValidationFailure(
          MapboxExternalFailureCode.noReachableMatrixCells,
          'mapbox_matrix_no_reachable_cells',
        ),
      );
    }
    return MapboxMatrixValidationResult.accepted(cells);
  }
}

MapboxExternalValidationFailure? _validateCommonMapboxEnvelope({
  required int httpStatus,
  required Object? decodedBody,
}) {
  if (httpStatus == MapboxExternalRouteValidator.rateLimitStatus) {
    return const MapboxExternalValidationFailure(
      MapboxExternalFailureCode.rateLimited,
      'mapbox_rate_limited',
    );
  }
  if (httpStatus < MapboxExternalRouteValidator.minimumHttpStatus ||
      httpStatus > MapboxExternalRouteValidator.maximumHttpStatus) {
    return const MapboxExternalValidationFailure(
      MapboxExternalFailureCode.httpFailure,
      'mapbox_http_failure',
    );
  }
  if (decodedBody is! Map) {
    return const MapboxExternalValidationFailure(
      MapboxExternalFailureCode.malformedResponse,
      'mapbox_response_not_object',
    );
  }
  if (decodedBody['code'] != 'Ok') {
    return const MapboxExternalValidationFailure(
      MapboxExternalFailureCode.malformedResponse,
      'mapbox_service_code_not_ok',
    );
  }
  return null;
}

const _invalidNullableNumber = -1.0;

double? _nullableBoundedNumber(Object? value, {required double maximum}) {
  if (value == null) return null;
  if (value is! num || !value.isFinite || value < 0 || value > maximum) {
    return _invalidNullableNumber;
  }
  return value.toDouble();
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
