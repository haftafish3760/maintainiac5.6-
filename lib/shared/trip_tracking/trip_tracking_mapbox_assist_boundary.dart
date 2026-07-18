import '../maps/mapbox_trip_assist_policy.dart';
import 'trip_tracking_session_recovery_validation.dart';
import 'trip_tracking_session_store.dart';

enum TripTrackingMapboxAssistBoundaryStatus {
  disabled,
  gpsOnlyFallback,
  visualOnly,
  mileageReviewOnly,
}

class TripTrackingMapboxAssistBoundaryDecision {
  const TripTrackingMapboxAssistBoundaryDecision._({
    required this.status,
    required this.safeReason,
    required this.canRenderMapAssist,
    required this.canPromptMileageReview,
    required this.canPersistRouteHistory,
    required this.routeDistanceMiles,
    required this.comparisonDeltaMiles,
  });

  factory TripTrackingMapboxAssistBoundaryDecision.evaluate({
    required MapboxTripAssistDecision mapboxDecision,
    TripTrackingSessionRecord? activeSession,
    TripTrackingReviewRecord? reviewRecord,
    required bool mapPreviewOptIn,
    required bool routeHistoryOptIn,
  }) {
    if (!mapPreviewOptIn) {
      return const TripTrackingMapboxAssistBoundaryDecision._(
        status: TripTrackingMapboxAssistBoundaryStatus.disabled,
        safeReason: 'map_preview_not_enabled',
        canRenderMapAssist: false,
        canPromptMileageReview: false,
        canPersistRouteHistory: false,
        routeDistanceMiles: null,
        comparisonDeltaMiles: null,
      );
    }

    final hasSafeLocalSource = _hasSafeLocalSource(
      activeSession: activeSession,
      reviewRecord: reviewRecord,
    );
    if (!hasSafeLocalSource) {
      return const TripTrackingMapboxAssistBoundaryDecision._(
        status: TripTrackingMapboxAssistBoundaryStatus.gpsOnlyFallback,
        safeReason: 'validated_local_trip_source_required',
        canRenderMapAssist: false,
        canPromptMileageReview: false,
        canPersistRouteHistory: false,
        routeDistanceMiles: null,
        comparisonDeltaMiles: null,
      );
    }

    if (!mapboxDecision.shouldShowRoute) {
      return TripTrackingMapboxAssistBoundaryDecision._(
        status: TripTrackingMapboxAssistBoundaryStatus.gpsOnlyFallback,
        safeReason: _safeReason(mapboxDecision.safeReason),
        canRenderMapAssist: false,
        canPromptMileageReview: false,
        canPersistRouteHistory: false,
        routeDistanceMiles: null,
        comparisonDeltaMiles: null,
      );
    }

    final reviewReady =
        mapboxDecision.shouldPromptReview && reviewRecord != null;
    return TripTrackingMapboxAssistBoundaryDecision._(
      status: reviewReady
          ? TripTrackingMapboxAssistBoundaryStatus.mileageReviewOnly
          : TripTrackingMapboxAssistBoundaryStatus.visualOnly,
      safeReason: _safeReason(mapboxDecision.safeReason),
      canRenderMapAssist: true,
      canPromptMileageReview: reviewReady,
      canPersistRouteHistory: routeHistoryOptIn,
      routeDistanceMiles: mapboxDecision.routeDistanceMiles,
      comparisonDeltaMiles: mapboxDecision.comparisonDeltaMiles,
    );
  }

  final TripTrackingMapboxAssistBoundaryStatus status;
  final String safeReason;
  final bool canRenderMapAssist;
  final bool canPromptMileageReview;
  final bool canPersistRouteHistory;
  final double? routeDistanceMiles;
  final double? comparisonDeltaMiles;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'safeReason': safeReason,
    'canRenderMapAssist': canRenderMapAssist,
    'canPromptMileageReview': canPromptMileageReview,
    'canPersistRouteHistory': canPersistRouteHistory,
    'mapPreviewRequiresSeparateOptIn': true,
    'routeHistoryRequiresSeparateOptIn': true,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'fallbackMode': canRenderMapAssist ? 'map_assist' : 'gps_only',
    if (_safeMiles(routeDistanceMiles) != null)
      'routeDistanceMiles': _safeMiles(routeDistanceMiles),
    if (_safeMiles(comparisonDeltaMiles) != null)
      'comparisonDeltaMiles': _safeMiles(comparisonDeltaMiles),
    'advisoryOnly': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'localTripLogProtected': true,
    'officialMileageSource': 'odometer',
    'mapboxCanModifyTripLog': false,
    'mapboxCanModifyOdometer': false,
    'mapboxCanCreateStop': false,
    'mapboxCanEndTrip': false,
    'mapboxCanOverrideLocalTrip': false,
    'firestoreCanOverrideMapAssistBoundary': false,
    'remoteRouteCanBecomeCanonical': false,
    'rawMapboxResponseIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

bool _hasSafeLocalSource({
  required TripTrackingSessionRecord? activeSession,
  required TripTrackingReviewRecord? reviewRecord,
}) {
  if (activeSession != null) {
    return TripTrackingSessionRecoveryValidation.activeSession(
      activeSession,
    ).isRecoverable;
  }
  if (reviewRecord != null) {
    return TripTrackingSessionRecoveryValidation.review(
      reviewRecord,
    ).isRecoverable;
  }
  return false;
}

double? _safeMiles(double? value) {
  if (value == null || !value.isFinite || value < 0 || value > 12500) {
    return null;
  }
  return (value * 1000).roundToDouble() / 1000;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'map_preview_not_enabled' => 'map_preview_not_enabled',
    'validated_local_trip_source_required' =>
      'validated_local_trip_source_required',
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
