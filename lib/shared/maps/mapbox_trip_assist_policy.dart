import 'mapbox_response_validation.dart';

enum MapboxTripAssistStatus {
  unavailable,
  rateLimited,
  rejected,
  visualOnly,
  distanceReview,
}

enum MapboxTrustedMileageSource { none, odometer, gpsAccepted }

class MapboxTripAssistDecision {
  const MapboxTripAssistDecision({
    required this.status,
    required this.safeReason,
    required this.routeDistanceMiles,
    required this.comparisonDeltaMiles,
    required this.trustedMileageSource,
  });

  final MapboxTripAssistStatus status;
  final String safeReason;
  final double? routeDistanceMiles;
  final double? comparisonDeltaMiles;
  final MapboxTrustedMileageSource trustedMileageSource;

  bool get canModifyTripLog => false;
  bool get canModifyOdometer => false;
  bool get shouldShowRoute =>
      status == MapboxTripAssistStatus.visualOnly ||
      status == MapboxTripAssistStatus.distanceReview;
  bool get shouldPromptReview =>
      status == MapboxTripAssistStatus.distanceReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'safeReason': _safeMapboxAssistReason(safeReason),
    'advisoryOnly': true,
    'officialMileageSource': 'odometer',
    'trustedComparisonSource': trustedMileageSource.name,
    'shouldShowRoute': shouldShowRoute,
    'shouldPromptReview': shouldPromptReview,
    if (_safeMiles(routeDistanceMiles) != null)
      'routeDistanceMiles': _safeMiles(routeDistanceMiles),
    if (comparisonDeltaMiles != null)
      'comparisonDeltaMiles': _safeMiles(comparisonDeltaMiles),
    'canModifyTripLog': false,
    'canModifyOdometer': false,
    'canConfirmStop': false,
    'canReplaceGpsDistance': false,
    'canOverrideLocalTripLog': false,
    'localTripLogProtected': true,
    'odometerRequiresUserConfirmation': true,
    'canPersistRawRoute': false,
    'canPersistCoordinates': false,
    'rawResponseIncluded': false,
    'tokensIncluded': false,
    'publicTokenIncluded': false,
    'secretTokenIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'rawGeometryIncluded': false,
  };
}

class MapboxTripAssistPolicy {
  const MapboxTripAssistPolicy._();

  static MapboxTripAssistDecision evaluateRouteAssist({
    required MapboxRouteValidationResult validation,
    double? confirmedOdometerMiles,
    double? gpsAcceptedMiles,
    double reviewDifferenceMiles = 1,
    double reviewDifferencePercent = 8,
  }) {
    if (!reviewDifferenceMiles.isFinite ||
        reviewDifferenceMiles < 0 ||
        !reviewDifferencePercent.isFinite ||
        reviewDifferencePercent < 0) {
      return const MapboxTripAssistDecision(
        status: MapboxTripAssistStatus.rejected,
        safeReason: 'invalid_map_assist_threshold',
        routeDistanceMiles: null,
        comparisonDeltaMiles: null,
        trustedMileageSource: MapboxTrustedMileageSource.none,
      );
    }
    if (!validation.isAccepted) {
      final reason = validation.failures.isEmpty
          ? 'mapbox_route_unavailable'
          : validation.failures.first.safeReason;
      return MapboxTripAssistDecision(
        status:
            validation.failures.any(
              (failure) =>
                  failure.code == MapboxExternalFailureCode.rateLimited,
            )
            ? MapboxTripAssistStatus.rateLimited
            : MapboxTripAssistStatus.unavailable,
        safeReason: reason,
        routeDistanceMiles: null,
        comparisonDeltaMiles: null,
        trustedMileageSource: MapboxTrustedMileageSource.none,
      );
    }
    final candidate = validation.candidates.first;
    final routeMiles = candidate.distanceMiles;
    final comparison = _trustedComparisonMiles(
      confirmedOdometerMiles: confirmedOdometerMiles,
      gpsAcceptedMiles: gpsAcceptedMiles,
    );
    if (comparison.miles == null || comparison.miles! <= 0) {
      return MapboxTripAssistDecision(
        status: MapboxTripAssistStatus.visualOnly,
        safeReason: 'mapbox_visual_only_no_trusted_mileage',
        routeDistanceMiles: routeMiles,
        comparisonDeltaMiles: null,
        trustedMileageSource: MapboxTrustedMileageSource.none,
      );
    }
    final comparisonMiles = comparison.miles!;
    final deltaMiles = (routeMiles - comparisonMiles).abs();
    final percent = comparisonMiles == 0
        ? 0
        : (deltaMiles / comparisonMiles) * 100;
    final needsReview =
        deltaMiles >= reviewDifferenceMiles &&
        percent >= reviewDifferencePercent;
    return MapboxTripAssistDecision(
      status: needsReview
          ? MapboxTripAssistStatus.distanceReview
          : MapboxTripAssistStatus.visualOnly,
      safeReason: needsReview
          ? 'mapbox_distance_review_only'
          : 'mapbox_visual_assist_only',
      routeDistanceMiles: routeMiles,
      comparisonDeltaMiles: deltaMiles,
      trustedMileageSource: comparison.source,
    );
  }
}

class _TrustedMileageComparison {
  const _TrustedMileageComparison(this.miles, this.source);

  final double? miles;
  final MapboxTrustedMileageSource source;
}

_TrustedMileageComparison _trustedComparisonMiles({
  required double? confirmedOdometerMiles,
  required double? gpsAcceptedMiles,
}) {
  if (confirmedOdometerMiles != null &&
      confirmedOdometerMiles.isFinite &&
      confirmedOdometerMiles > 0) {
    return _TrustedMileageComparison(
      confirmedOdometerMiles,
      MapboxTrustedMileageSource.odometer,
    );
  }
  if (gpsAcceptedMiles != null &&
      gpsAcceptedMiles.isFinite &&
      gpsAcceptedMiles > 0) {
    return _TrustedMileageComparison(
      gpsAcceptedMiles,
      MapboxTrustedMileageSource.gpsAccepted,
    );
  }
  return const _TrustedMileageComparison(null, MapboxTrustedMileageSource.none);
}

double? _safeMiles(double? value) {
  if (value == null || !value.isFinite || value < 0) return null;
  if (value > 12500) return null;
  return (value * 1000).roundToDouble() / 1000;
}

String _safeMapboxAssistReason(String value) {
  return switch (value.trim()) {
    'mapbox_route_unavailable' => 'mapbox_route_unavailable',
    'mapbox_rate_limited' => 'mapbox_rate_limited',
    'mapbox_http_failure' => 'mapbox_http_failure',
    'mapbox_response_not_object' => 'mapbox_response_not_object',
    'mapbox_service_code_not_ok' => 'mapbox_service_code_not_ok',
    'mapbox_routes_missing' => 'mapbox_routes_missing',
    'mapbox_routes_invalid' => 'mapbox_routes_invalid',
    'invalid_map_assist_threshold' => 'invalid_map_assist_threshold',
    'mapbox_visual_only_no_trusted_mileage' =>
      'mapbox_visual_only_no_trusted_mileage',
    'mapbox_visual_assist_only' => 'mapbox_visual_assist_only',
    'mapbox_distance_review_only' => 'mapbox_distance_review_only',
    _ => 'mapbox_route_unavailable',
  };
}
