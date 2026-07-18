import '../maps/mapbox_response_validation.dart';
import '../maps/mapbox_trip_assist_policy.dart';
import 'trip_tracking_mapbox_assist_boundary.dart';

enum TripMapboxRequestBoundaryStatus {
  disabled,
  requestAllowed,
  responseAccepted,
  fallbackGpsOnly,
  rateLimited,
  rejected,
}

class TripMapboxRequestBoundaryDecision {
  const TripMapboxRequestBoundaryDecision({
    required this.status,
    required this.reasonCode,
    required this.canCallMapbox,
    required this.canRenderMapAssist,
    required this.shouldUseGpsOnlyFallback,
    required this.shouldRetryLater,
    required this.requestsRemainingInWindow,
  });

  final TripMapboxRequestBoundaryStatus status;
  final String reasonCode;
  final bool canCallMapbox;
  final bool canRenderMapAssist;
  final bool shouldUseGpsOnlyFallback;
  final bool shouldRetryLater;
  final int requestsRemainingInWindow;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canCallMapbox': canCallMapbox,
    'canRenderMapAssist': canRenderMapAssist,
    'shouldUseGpsOnlyFallback': shouldUseGpsOnlyFallback,
    'shouldRetryLater': shouldRetryLater,
    'requestsRemainingInWindow': requestsRemainingInWindow,
    'gpsTripTrackingContinuesWithoutMaps': true,
    'mapboxRequiresSeparateUserOptIn': true,
    'mapboxRequestRequiresLocalTripSource': true,
    'mapboxRequestRequiresNetworkBudget': true,
    'mapboxCallRequiresRequestBudget': true,
    'mapboxResponseValidatedBeforeUse': true,
    'mapboxDirectionsCanOnlyVisualize': true,
    'mapboxMatrixCanOnlyEstimate': true,
    'mapboxMapMatchingCanOnlyAssistReview': true,
    'mapboxOptimizationCanOnlySuggestOrder': true,
    'mapboxIsochroneCanOnlyVisualizeCoverage': true,
    'mapboxEvChargeFinderCanOnlySuggestStops': true,
    'mapboxCanModifyTripLog': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanCreateStop': false,
    'mapboxCanEndTrip': false,
    'mapboxCanReorderOfficialStops': false,
    'mapboxCanPersistRouteWithoutOptIn': false,
    'mapboxRateLimitCanStopGpsTracking': false,
    'mapboxTimeoutCanCorruptTripLog': false,
    'malformedMapboxResponseFailsGracefully': true,
    'rawMapboxResponseIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'publicTokenIncluded': false,
    'secretTokenIncluded': false,
    'tokensIncluded': false,
  };
}

class TripMapboxRequestBoundarySummaryValidation {
  const TripMapboxRequestBoundarySummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reasonCode,
    required this.reasons,
  });

  factory TripMapboxRequestBoundarySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    final reasonCode = _safeReasonObject(summary['reasonCode']);
    final remaining = summary['requestsRemainingInWindow'];

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_mapbox_boundary_status');
    if (reasonCode == null) reasons.add('invalid_mapbox_boundary_reason');
    if (remaining is! int || remaining < 0 || remaining > 100000) {
      reasons.add('invalid_request_window_remaining');
    }
    if (summary['canCallMapbox'] == true &&
        (status != TripMapboxRequestBoundaryStatus.requestAllowed ||
            summary['mapboxRequiresSeparateUserOptIn'] != true ||
            summary['mapboxRequestRequiresLocalTripSource'] != true ||
            summary['mapboxCallRequiresRequestBudget'] != true)) {
      reasons.add('unsafe_mapbox_call_claim');
    }
    if (summary['canRenderMapAssist'] == true &&
        status != TripMapboxRequestBoundaryStatus.responseAccepted) {
      reasons.add('unsafe_map_assist_render_claim');
    }
    if (summary['gpsTripTrackingContinuesWithoutMaps'] != true ||
        summary['mapboxRateLimitCanStopGpsTracking'] != false ||
        summary['mapboxTimeoutCanCorruptTripLog'] != false ||
        summary['malformedMapboxResponseFailsGracefully'] != true) {
      reasons.add('gps_fallback_boundary_missing');
    }
    if (summary['mapboxResponseValidatedBeforeUse'] != true ||
        summary['mapboxDirectionsCanOnlyVisualize'] != true ||
        summary['mapboxMatrixCanOnlyEstimate'] != true ||
        summary['mapboxMapMatchingCanOnlyAssistReview'] != true ||
        summary['mapboxOptimizationCanOnlySuggestOrder'] != true ||
        summary['mapboxIsochroneCanOnlyVisualizeCoverage'] != true ||
        summary['mapboxEvChargeFinderCanOnlySuggestStops'] != true) {
      reasons.add('mapbox_service_boundary_missing');
    }
    if (summary['mapboxCanModifyTripLog'] != false ||
        summary['mapboxCanReplaceOdometer'] != false ||
        summary['mapboxCanCreateStop'] != false ||
        summary['mapboxCanEndTrip'] != false ||
        summary['mapboxCanReorderOfficialStops'] != false ||
        summary['mapboxCanPersistRouteWithoutOptIn'] != false) {
      reasons.add('mapbox_can_mutate_trip_truth');
    }
    if (summary['rawMapboxResponseIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['publicTokenIncluded'] != false ||
        summary['secretTokenIncluded'] != false ||
        summary['tokensIncluded'] != false) {
      reasons.add('summary_contains_sensitive_mapbox_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripMapboxRequestBoundarySummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reasonCode: reasons.isEmpty ? reasonCode : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripMapboxRequestBoundaryStatus? status;
  final String? reasonCode;
  final List<String> reasons;
}

class TripMapboxRequestBoundaryPolicy {
  const TripMapboxRequestBoundaryPolicy._();

  static TripMapboxRequestBoundaryDecision beforeRequest({
    required bool mapPreviewOptIn,
    required bool mapboxRuntimeConfigured,
    required bool networkAvailable,
    required bool localTripSourceValidated,
    required int requestsUsedInWindow,
    int maxRequestsPerWindow = 100,
  }) {
    if (!mapPreviewOptIn) {
      return _decision(
        status: TripMapboxRequestBoundaryStatus.disabled,
        reasonCode: 'map_preview_not_enabled',
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: false,
        requestsRemainingInWindow: _remainingRequests(
          requestsUsedInWindow,
          maxRequestsPerWindow,
        ),
      );
    }
    if (!mapboxRuntimeConfigured ||
        !networkAvailable ||
        !localTripSourceValidated) {
      return _decision(
        status: TripMapboxRequestBoundaryStatus.fallbackGpsOnly,
        reasonCode: !mapboxRuntimeConfigured
            ? 'mapbox_runtime_not_configured'
            : !networkAvailable
            ? 'mapbox_network_unavailable'
            : 'validated_local_trip_source_required',
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: networkAvailable == false,
        requestsRemainingInWindow: _remainingRequests(
          requestsUsedInWindow,
          maxRequestsPerWindow,
        ),
      );
    }
    if (!_withinRequestBudget(requestsUsedInWindow, maxRequestsPerWindow)) {
      return _decision(
        status: TripMapboxRequestBoundaryStatus.rateLimited,
        reasonCode: 'mapbox_local_request_budget_exhausted',
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: true,
        requestsRemainingInWindow: 0,
      );
    }
    return _decision(
      status: TripMapboxRequestBoundaryStatus.requestAllowed,
      reasonCode: 'mapbox_request_allowed',
      canCallMapbox: true,
      canRenderMapAssist: false,
      shouldUseGpsOnlyFallback: false,
      shouldRetryLater: false,
      requestsRemainingInWindow: _remainingRequests(
        requestsUsedInWindow,
        maxRequestsPerWindow,
      ),
    );
  }

  static TripMapboxRequestBoundaryDecision afterDirectionsResponse({
    required int httpStatus,
    required Object? decodedBody,
    required double? confirmedOdometerMiles,
    required double? gpsAcceptedMiles,
  }) {
    final validation =
        MapboxExternalRouteValidator.validateDirectionsLikeResponse(
          httpStatus: httpStatus,
          decodedBody: decodedBody,
        );
    final assist = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: validation,
      confirmedOdometerMiles: confirmedOdometerMiles,
      gpsAcceptedMiles: gpsAcceptedMiles,
    );
    if (assist.status == MapboxTripAssistStatus.rateLimited) {
      return _decision(
        status: TripMapboxRequestBoundaryStatus.rateLimited,
        reasonCode: assist.safeReason,
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: true,
        requestsRemainingInWindow: 0,
      );
    }
    if (!assist.shouldShowRoute) {
      return _decision(
        status: validation.isAccepted
            ? TripMapboxRequestBoundaryStatus.fallbackGpsOnly
            : TripMapboxRequestBoundaryStatus.rejected,
        reasonCode: assist.safeReason,
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: false,
        requestsRemainingInWindow: 0,
      );
    }
    return _decision(
      status: TripMapboxRequestBoundaryStatus.responseAccepted,
      reasonCode: assist.safeReason,
      canCallMapbox: false,
      canRenderMapAssist: true,
      shouldUseGpsOnlyFallback: false,
      shouldRetryLater: false,
      requestsRemainingInWindow: 0,
    );
  }

  static TripMapboxRequestBoundaryDecision fromAssistBoundary(
    TripTrackingMapboxAssistBoundaryDecision boundary,
  ) {
    if (!boundary.canRenderMapAssist) {
      return _decision(
        status: TripMapboxRequestBoundaryStatus.fallbackGpsOnly,
        reasonCode: boundary.safeReason,
        canCallMapbox: false,
        canRenderMapAssist: false,
        shouldUseGpsOnlyFallback: true,
        shouldRetryLater: boundary.safeReason == 'mapbox_rate_limited',
        requestsRemainingInWindow: 0,
      );
    }
    return _decision(
      status: TripMapboxRequestBoundaryStatus.responseAccepted,
      reasonCode: boundary.safeReason,
      canCallMapbox: false,
      canRenderMapAssist: true,
      shouldUseGpsOnlyFallback: false,
      shouldRetryLater: false,
      requestsRemainingInWindow: 0,
    );
  }
}

TripMapboxRequestBoundaryDecision _decision({
  required TripMapboxRequestBoundaryStatus status,
  required String reasonCode,
  required bool canCallMapbox,
  required bool canRenderMapAssist,
  required bool shouldUseGpsOnlyFallback,
  required bool shouldRetryLater,
  required int requestsRemainingInWindow,
}) {
  return TripMapboxRequestBoundaryDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canCallMapbox: canCallMapbox,
    canRenderMapAssist: canRenderMapAssist,
    shouldUseGpsOnlyFallback: shouldUseGpsOnlyFallback,
    shouldRetryLater: shouldRetryLater,
    requestsRemainingInWindow: requestsRemainingInWindow < 0
        ? 0
        : requestsRemainingInWindow,
  );
}

bool _withinRequestBudget(int used, int max) {
  if (used < 0 || max <= 0 || max > 100000) return false;
  return used < max;
}

int _remainingRequests(int used, int max) {
  if (used < 0 || max <= 0 || max > 100000) return 0;
  final remaining = max - used;
  if (remaining <= 0) return 0;
  return remaining > 100000 ? 100000 : remaining;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'map_preview_not_enabled' => 'map_preview_not_enabled',
    'mapbox_runtime_not_configured' => 'mapbox_runtime_not_configured',
    'mapbox_network_unavailable' => 'mapbox_network_unavailable',
    'validated_local_trip_source_required' =>
      'validated_local_trip_source_required',
    'mapbox_local_request_budget_exhausted' =>
      'mapbox_local_request_budget_exhausted',
    'mapbox_request_allowed' => 'mapbox_request_allowed',
    'mapbox_rate_limited' => 'mapbox_rate_limited',
    'mapbox_http_failure' => 'mapbox_http_failure',
    'mapbox_response_not_object' => 'mapbox_response_not_object',
    'mapbox_service_code_not_ok' => 'mapbox_service_code_not_ok',
    'mapbox_routes_missing' => 'mapbox_routes_missing',
    'mapbox_routes_invalid' => 'mapbox_routes_invalid',
    'mapbox_visual_only_no_trusted_mileage' =>
      'mapbox_visual_only_no_trusted_mileage',
    'invalid_mapbox_route_distance' => 'invalid_mapbox_route_distance',
    'mapbox_visual_assist_only' => 'mapbox_visual_assist_only',
    'mapbox_distance_review_only' => 'mapbox_distance_review_only',
    _ => 'mapbox_http_failure',
  };
}

TripMapboxRequestBoundaryStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripMapboxRequestBoundaryStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _safeReasonObject(Object? value) {
  if (value is! String) return null;
  return _safeReason(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
