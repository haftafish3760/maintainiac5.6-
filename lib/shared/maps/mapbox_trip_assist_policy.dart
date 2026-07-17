import 'mapbox_response_validation.dart';

enum MapboxTripAssistStatus {
  unavailable,
  rateLimited,
  rejected,
  visualOnly,
  distanceReview,
}

class MapboxTripAssistDecision {
  const MapboxTripAssistDecision({
    required this.status,
    required this.safeReason,
    required this.routeDistanceMiles,
    required this.comparisonDeltaMiles,
  });

  final MapboxTripAssistStatus status;
  final String safeReason;
  final double? routeDistanceMiles;
  final double? comparisonDeltaMiles;

  bool get canModifyTripLog => false;
  bool get canModifyOdometer => false;
  bool get shouldShowRoute =>
      status == MapboxTripAssistStatus.visualOnly ||
      status == MapboxTripAssistStatus.distanceReview;
  bool get shouldPromptReview =>
      status == MapboxTripAssistStatus.distanceReview;

  Map<String, Object?> toSafeSummary() => {
    'status': status.name,
    'safeReason': safeReason,
    if (routeDistanceMiles != null) 'routeDistanceMiles': routeDistanceMiles,
    if (comparisonDeltaMiles != null)
      'comparisonDeltaMiles': comparisonDeltaMiles,
    'canModifyTripLog': false,
    'canModifyOdometer': false,
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
      );
    }
    final candidate = validation.candidates.first;
    final routeMiles = candidate.distanceMiles;
    final comparisonMiles = _trustedComparisonMiles(
      confirmedOdometerMiles: confirmedOdometerMiles,
      gpsAcceptedMiles: gpsAcceptedMiles,
    );
    if (comparisonMiles == null || comparisonMiles <= 0) {
      return MapboxTripAssistDecision(
        status: MapboxTripAssistStatus.visualOnly,
        safeReason: 'mapbox_visual_only_no_trusted_mileage',
        routeDistanceMiles: routeMiles,
        comparisonDeltaMiles: null,
      );
    }
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
    );
  }
}

double? _trustedComparisonMiles({
  required double? confirmedOdometerMiles,
  required double? gpsAcceptedMiles,
}) {
  if (confirmedOdometerMiles != null &&
      confirmedOdometerMiles.isFinite &&
      confirmedOdometerMiles > 0) {
    return confirmedOdometerMiles;
  }
  if (gpsAcceptedMiles != null &&
      gpsAcceptedMiles.isFinite &&
      gpsAcceptedMiles > 0) {
    return gpsAcceptedMiles;
  }
  return null;
}
