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
  });

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
    expect(safe['mapboxCanModifyTripLog'], isFalse);
    expect(safe['mapboxCanReplaceOdometer'], isFalse);
    expect(safe['mapboxCanCreateStop'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['publicTokenIncluded'], isFalse);
    expect(safe['secretTokenIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}
