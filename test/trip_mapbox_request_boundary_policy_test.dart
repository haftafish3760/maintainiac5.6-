import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_mapbox_request_boundary_policy.dart';

void main() {
  Map<String, Object?> validRoute({double distance = 1609.344}) => {
    'code': 'Ok',
    'routes': [
      {
        'distance': distance,
        'duration': 300,
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [-80.0000, 35.0000],
            [-80.0000, 35.0145],
          ],
        },
      },
    ],
  };

  test('preflight blocks Mapbox when maps are not opted in', () {
    final decision = TripMapboxRequestBoundaryPolicy.beforeRequest(
      mapPreviewOptIn: false,
      mapboxRuntimeConfigured: true,
      networkAvailable: true,
      localTripSourceValidated: true,
      requestsUsedInWindow: 0,
    );

    expect(decision.status, TripMapboxRequestBoundaryStatus.disabled);
    expect(decision.canCallMapbox, isFalse);
    expect(decision.shouldUseGpsOnlyFallback, isTrue);
  });

  test(
    'preflight requires runtime, network, local source, and request budget',
    () {
      final missingRuntime = TripMapboxRequestBoundaryPolicy.beforeRequest(
        mapPreviewOptIn: true,
        mapboxRuntimeConfigured: false,
        networkAvailable: true,
        localTripSourceValidated: true,
        requestsUsedInWindow: 0,
      );
      final exhausted = TripMapboxRequestBoundaryPolicy.beforeRequest(
        mapPreviewOptIn: true,
        mapboxRuntimeConfigured: true,
        networkAvailable: true,
        localTripSourceValidated: true,
        requestsUsedInWindow: 100,
        maxRequestsPerWindow: 100,
      );

      expect(
        missingRuntime.status,
        TripMapboxRequestBoundaryStatus.fallbackGpsOnly,
      );
      expect(exhausted.status, TripMapboxRequestBoundaryStatus.rateLimited);
      expect(exhausted.shouldRetryLater, isTrue);
    },
  );

  test('valid preflight allows one optional Mapbox call', () {
    final decision = TripMapboxRequestBoundaryPolicy.beforeRequest(
      mapPreviewOptIn: true,
      mapboxRuntimeConfigured: true,
      networkAvailable: true,
      localTripSourceValidated: true,
      requestsUsedInWindow: 3,
    );

    expect(decision.status, TripMapboxRequestBoundaryStatus.requestAllowed);
    expect(decision.canCallMapbox, isTrue);
    expect(decision.requestsRemainingInWindow, 97);
    expect(decision.toSafeDashboardMap()['requestsRemainingInWindow'], 97);
  });

  test(
    'malformed request budgets fail closed without tokens or coordinates',
    () {
      final decision = TripMapboxRequestBoundaryPolicy.beforeRequest(
        mapPreviewOptIn: true,
        mapboxRuntimeConfigured: true,
        networkAvailable: true,
        localTripSourceValidated: true,
        requestsUsedInWindow: -1,
        maxRequestsPerWindow: 100,
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripMapboxRequestBoundaryStatus.rateLimited);
      expect(decision.canCallMapbox, isFalse);
      expect(decision.requestsRemainingInWindow, 0);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
    },
  );

  test('valid directions response may render visual assist only', () {
    final decision = TripMapboxRequestBoundaryPolicy.afterDirectionsResponse(
      httpStatus: 200,
      decodedBody: validRoute(),
      confirmedOdometerMiles: 1.0,
      gpsAcceptedMiles: null,
    );

    expect(decision.status, TripMapboxRequestBoundaryStatus.responseAccepted);
    expect(decision.canRenderMapAssist, isTrue);
    expect(decision.shouldUseGpsOnlyFallback, isFalse);
  });

  test('Mapbox rate limits and HTTP failures fall back to GPS only', () {
    final limited = TripMapboxRequestBoundaryPolicy.afterDirectionsResponse(
      httpStatus: 429,
      decodedBody: validRoute(),
      confirmedOdometerMiles: 1.0,
      gpsAcceptedMiles: null,
    );
    final failed = TripMapboxRequestBoundaryPolicy.afterDirectionsResponse(
      httpStatus: 500,
      decodedBody: {'code': 'Ok'},
      confirmedOdometerMiles: 1.0,
      gpsAcceptedMiles: null,
    );

    expect(limited.status, TripMapboxRequestBoundaryStatus.rateLimited);
    expect(limited.shouldRetryLater, isTrue);
    expect(failed.status, TripMapboxRequestBoundaryStatus.rejected);
    expect(failed.shouldUseGpsOnlyFallback, isTrue);
  });

  test('malformed geometry cannot render or corrupt trip tracking', () {
    final decision = TripMapboxRequestBoundaryPolicy.afterDirectionsResponse(
      httpStatus: 200,
      decodedBody: {
        'code': 'Ok',
        'routes': [
          {
            'distance': 1609.344,
            'duration': 300,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-80.0, 35.0],
              ],
            },
          },
        ],
      },
      confirmedOdometerMiles: 1.0,
      gpsAcceptedMiles: null,
    );

    expect(decision.status, TripMapboxRequestBoundaryStatus.rejected);
    expect(decision.canRenderMapAssist, isFalse);
    expect(decision.shouldUseGpsOnlyFallback, isTrue);
  });

  test('safe summary keeps Mapbox optional and token free', () {
    final safe = TripMapboxRequestBoundaryPolicy.beforeRequest(
      mapPreviewOptIn: true,
      mapboxRuntimeConfigured: true,
      networkAvailable: true,
      localTripSourceValidated: true,
      requestsUsedInWindow: 0,
    ).toSafeDashboardMap();

    expect(safe['gpsTripTrackingContinuesWithoutMaps'], isTrue);
    expect(safe['mapboxRequestRequiresOwnershipValidation'], isTrue);
    expect(safe['mapboxRequestRequiresDeviceLocalSource'], isTrue);
    expect(safe['authenticationAloneAuthorizesMapboxRequest'], isFalse);
    expect(safe['mapboxCallRequiresRequestBudget'], isTrue);
    expect(safe['mapboxResponseValidatedBeforeUse'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
    expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
    expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
    expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
    expect(safe['mapboxDirectionsCanOnlyVisualize'], isTrue);
    expect(safe['mapboxMatrixCanOnlyEstimate'], isTrue);
    expect(safe['mapboxMapMatchingCanOnlyAssistReview'], isTrue);
    expect(safe['mapboxOptimizationCanOnlySuggestOrder'], isTrue);
    expect(safe['mapboxIsochroneCanOnlyVisualizeCoverage'], isTrue);
    expect(safe['mapboxEvChargeFinderCanOnlySuggestStops'], isTrue);
    expect(safe['mapboxCanModifyTripLog'], isFalse);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
    expect(safe['mapboxCanCreateStop'], isFalse);
    expect(safe['mapboxCanReorderOfficialStops'], isFalse);
    expect(safe['mapboxCanPersistRouteWithoutOptIn'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['publicTokenIncluded'], isFalse);
    expect(safe['secretTokenIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('safe summary validates as renderable request boundary', () {
    final validation = TripMapboxRequestBoundarySummaryValidation.fromSummary(
      TripMapboxRequestBoundaryPolicy.beforeRequest(
        mapPreviewOptIn: true,
        mapboxRuntimeConfigured: true,
        networkAvailable: true,
        localTripSourceValidated: true,
        requestsUsedInWindow: 2,
      ).toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripMapboxRequestBoundaryStatus.requestAllowed);
    expect(validation.reasonCode, 'mapbox_request_allowed');
    expect(validation.reasons, isEmpty);
  });

  test(
    'summary validation rejects Mapbox authority and sensitive material',
    () {
      final validation = TripMapboxRequestBoundarySummaryValidation.fromSummary(
        TripMapboxRequestBoundaryPolicy.beforeRequest(
          mapPreviewOptIn: true,
          mapboxRuntimeConfigured: true,
          networkAvailable: true,
          localTripSourceValidated: true,
          requestsUsedInWindow: 0,
        ).toSafeDashboardMap()..addAll({
          'mapboxResponseValidatedBeforeUse': false,
          'odometerIsGlobalTruth': false,
          'physicalOdometerRequiredForOfficialMileage': false,
          'confirmedOdometerOverridesExternalMileage': false,
          'externalMileageCannotBecomeGlobalTruth': false,
          'gpsDistanceCanOnlyAdviseMileageReview': false,
          'mapMatchingCanOnlyAdviseMileageReview': false,
          'optimizationCannotChangeOfficialMileage': false,
          'mapboxRequestRequiresOwnershipValidation': false,
          'mapboxRequestRequiresDeviceLocalSource': false,
          'authenticationAloneAuthorizesMapboxRequest': true,
          'mapboxDirectionsCanOnlyVisualize': false,
          'mapboxMatrixCanOnlyEstimate': false,
          'mapboxMapMatchingCanOnlyAssistReview': false,
          'mapboxOptimizationCanOnlySuggestOrder': false,
          'mapboxIsochroneCanOnlyVisualizeCoverage': false,
          'mapboxEvChargeFinderCanOnlySuggestStops': false,
          'mapboxCanModifyTripLog': true,
          'mapboxCanReplaceOdometer': true,
          'mapboxCanCreateStop': true,
          'mapboxCanEndTrip': true,
          'mapboxCanReorderOfficialStops': true,
          'mapboxCanPersistRouteWithoutOptIn': true,
          'rawMapboxResponseIncluded': true,
          'routeGeometryIncluded': true,
          'publicTokenIncluded': true,
          'secretTokenIncluded': true,
          'debugPoint': '35.123456,-80.123456',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('mapbox_service_boundary_missing'));
      expect(
        validation.reasons,
        contains('mapbox_request_authorization_boundary_missing'),
      );
      expect(validation.reasons, contains('mapbox_can_mutate_trip_truth'));
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_mapbox_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );

  test('summary validation catches unsafe call and render claims', () {
    final validation = TripMapboxRequestBoundarySummaryValidation.fromSummary({
      'schemaVersion': 2,
      'status': 'forceMap',
      'reasonCode': 'private_reason',
      'canCallMapbox': true,
      'canRenderMapAssist': true,
      'requestsRemainingInWindow': -1,
      'gpsTripTrackingContinuesWithoutMaps': false,
      'mapboxRateLimitCanStopGpsTracking': true,
      'mapboxTimeoutCanCorruptTripLog': true,
      'malformedMapboxResponseFailsGracefully': false,
    });

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema_version',
        'invalid_mapbox_boundary_status',
        'invalid_request_window_remaining',
        'unsafe_mapbox_call_claim',
        'unsafe_map_assist_render_claim',
        'gps_fallback_boundary_missing',
      ]),
    );
  });

  test('summary validation rejects auth-only Mapbox request authority', () {
    final validation = TripMapboxRequestBoundarySummaryValidation.fromSummary(
      TripMapboxRequestBoundaryPolicy.beforeRequest(
        mapPreviewOptIn: true,
        mapboxRuntimeConfigured: true,
        networkAvailable: true,
        localTripSourceValidated: true,
        requestsUsedInWindow: 1,
      ).toSafeDashboardMap()..addAll({
        'mapboxRequestRequiresOwnershipValidation': false,
        'mapboxRequestRequiresDeviceLocalSource': false,
        'authenticationAloneAuthorizesMapboxRequest': true,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('unsafe_mapbox_call_claim'));
    expect(
      validation.reasons,
      contains('mapbox_request_authorization_boundary_missing'),
    );
  });
}
