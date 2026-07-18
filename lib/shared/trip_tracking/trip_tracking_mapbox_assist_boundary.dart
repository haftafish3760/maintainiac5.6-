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
    final routeDistanceMiles = _safeMiles(mapboxDecision.routeDistanceMiles);
    if (routeDistanceMiles == null) {
      return const TripTrackingMapboxAssistBoundaryDecision._(
        status: TripTrackingMapboxAssistBoundaryStatus.gpsOnlyFallback,
        safeReason: 'invalid_mapbox_route_distance',
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
      routeDistanceMiles: routeDistanceMiles,
      comparisonDeltaMiles: _safeMiles(mapboxDecision.comparisonDeltaMiles),
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
    'mapboxAssistRequiresOwnershipValidation': true,
    'mapboxAssistRequiresDeviceLocalSource': true,
    'authenticationAloneAuthorizesMapAssist': false,
    'mapboxAssistCannotPersistWithoutRouteHistoryOptIn': true,
    'mapboxMileageReviewRequiresLocalReviewRecord': true,
    'mapboxResponseValidatedBeforeAssist': true,
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
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'mapboxCanModifyTripLog': false,
    'mapboxCanModifyOdometer': false,
    'mapboxCanCreateStop': false,
    'mapboxCanEndTrip': false,
    'mapboxCanOverrideLocalTrip': false,
    'mapboxDirectionsCanOnlyVisualize': true,
    'mapboxMatrixCanOnlyEstimate': true,
    'mapboxMapMatchingCanOnlyAssistReview': true,
    'mapboxOptimizationCanOnlySuggestOrder': true,
    'mapboxIsochroneCanOnlyVisualizeCoverage': true,
    'mapboxEvChargeFinderCanOnlySuggestStops': true,
    'mapboxSearchCanOnlySuggestAddress': true,
    'mapboxSearchCannotConfirmStopAddress': true,
    'mapboxNavigationCanOnlyGuideUser': true,
    'mapboxNavigationCannotEndTrip': true,
    'mapboxMapMatchingCannotRewriteGpsTrace': true,
    'mapboxOptimizationCannotPersistStopOrderWithoutReview': true,
    'mapboxCanReorderOfficialStops': false,
    'mapboxCanPersistRouteWithoutOptIn': false,
    'mapboxCanConfirmMileage': false,
    'mapboxCanConfirmStop': false,
    'firestoreCanOverrideMapAssistBoundary': false,
    'remoteRouteCanBecomeCanonical': false,
    'rawMapboxResponseIncluded': false,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingMapboxAssistBoundarySummaryValidation {
  const TripTrackingMapboxAssistBoundarySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasons,
  });

  factory TripTrackingMapboxAssistBoundarySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    final fallbackMode = summary['fallbackMode'];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_mapbox_assist_status');
    if (_safeReason(summary['safeReason']?.toString() ?? '') !=
        summary['safeReason']) {
      reasons.add('invalid_mapbox_assist_reason');
    }
    if (fallbackMode != 'map_assist' && fallbackMode != 'gps_only') {
      reasons.add('invalid_fallback_mode');
    }
    if (summary['canRenderMapAssist'] is! bool ||
        summary['canPromptMileageReview'] is! bool ||
        summary['canPersistRouteHistory'] is! bool) {
      reasons.add('invalid_mapbox_assist_flags');
    }
    if (summary['canPromptMileageReview'] == true &&
        status != TripTrackingMapboxAssistBoundaryStatus.mileageReviewOnly) {
      reasons.add('unsafe_mileage_review_claim');
    }
    if (summary['canPersistRouteHistory'] == true &&
        summary['routeHistoryRequiresSeparateOptIn'] != true) {
      reasons.add('route_history_opt_in_boundary_missing');
    }
    if (summary['mapPreviewRequiresSeparateOptIn'] != true ||
        summary['mapboxAssistRequiresOwnershipValidation'] != true ||
        summary['mapboxAssistRequiresDeviceLocalSource'] != true ||
        summary['authenticationAloneAuthorizesMapAssist'] != false ||
        summary['mapboxMileageReviewRequiresLocalReviewRecord'] != true ||
        summary['mapboxResponseValidatedBeforeAssist'] != true) {
      reasons.add('mapbox_assist_authorization_boundary_missing');
    }
    if (summary['gpsAssistedTrackingAvailableWithoutMaps'] != true ||
        summary['advisoryOnly'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['localTripLogProtected'] != true ||
        summary['officialMileageSource'] != 'odometer' ||
        summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true) {
      reasons.add('mapbox_assist_truth_boundary_missing');
    }
    if (summary['mapboxCanModifyTripLog'] != false ||
        summary['mapboxCanModifyOdometer'] != false ||
        summary['mapboxCanCreateStop'] != false ||
        summary['mapboxCanEndTrip'] != false ||
        summary['mapboxCanOverrideLocalTrip'] != false ||
        summary['mapboxCanReorderOfficialStops'] != false ||
        summary['mapboxCanPersistRouteWithoutOptIn'] != false ||
        summary['mapboxCanConfirmMileage'] != false ||
        summary['mapboxCanConfirmStop'] != false ||
        summary['firestoreCanOverrideMapAssistBoundary'] != false ||
        summary['remoteRouteCanBecomeCanonical'] != false) {
      reasons.add('mapbox_assist_claims_trip_authority');
    }
    if (summary['mapboxDirectionsCanOnlyVisualize'] != true ||
        summary['mapboxMatrixCanOnlyEstimate'] != true ||
        summary['mapboxMapMatchingCanOnlyAssistReview'] != true ||
        summary['mapboxOptimizationCanOnlySuggestOrder'] != true ||
        summary['mapboxIsochroneCanOnlyVisualizeCoverage'] != true ||
        summary['mapboxEvChargeFinderCanOnlySuggestStops'] != true ||
        summary['mapboxSearchCanOnlySuggestAddress'] != true ||
        summary['mapboxSearchCannotConfirmStopAddress'] != true ||
        summary['mapboxNavigationCanOnlyGuideUser'] != true ||
        summary['mapboxNavigationCannotEndTrip'] != true ||
        summary['mapboxMapMatchingCannotRewriteGpsTrace'] != true ||
        summary['mapboxOptimizationCannotPersistStopOrderWithoutReview'] !=
            true) {
      reasons.add('mapbox_service_boundary_missing');
    }
    if (summary['rawMapboxResponseIncluded'] != false ||
        summary['rawGpsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_mapbox_assist_material');
    }
    return TripTrackingMapboxAssistBoundarySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripTrackingMapboxAssistBoundaryStatus? status;
  final List<String> reasons;
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

TripTrackingMapboxAssistBoundaryStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripTrackingMapboxAssistBoundaryStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
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
    'invalid_mapbox_route_distance' => 'invalid_mapbox_route_distance',
    'mapbox_visual_only_no_trusted_mileage' =>
      'mapbox_visual_only_no_trusted_mileage',
    'mapbox_visual_assist_only' => 'mapbox_visual_assist_only',
    'mapbox_distance_review_only' => 'mapbox_distance_review_only',
    _ => 'mapbox_route_unavailable',
  };
}
