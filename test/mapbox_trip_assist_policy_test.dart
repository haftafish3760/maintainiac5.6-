import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';
import 'package:maintaniac/shared/maps/mapbox_trip_assist_policy.dart';

void main() {
  test(
    'rate limits fail gracefully without changing trip or odometer data',
    () {
      final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
        validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
          httpStatus: 429,
          decodedBody: const {},
        ),
        confirmedOdometerMiles: 12,
        gpsAcceptedMiles: 12,
      );

      expect(decision.status, MapboxTripAssistStatus.rateLimited);
      expect(decision.shouldShowRoute, isFalse);
      expect(decision.canModifyTripLog, isFalse);
      expect(decision.canModifyOdometer, isFalse);
      expect(decision.trustedMileageSource, MapboxTrustedMileageSource.none);
      expect(decision.toSafeSummary()['schemaVersion'], 1);
      expect(decision.toSafeSummary()['advisoryOnly'], isTrue);
      expect(decision.toSafeSummary()['officialMileageSource'], 'odometer');
      expect(decision.toSafeSummary()['canOverrideLocalTripLog'], isFalse);
      expect(decision.toSafeSummary()['localTripLogProtected'], isTrue);
      expect(decision.toSafeSummary()['rawGeometryIncluded'], isFalse);
    },
  );

  test('malformed route responses remain unavailable and advisory only', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
        httpStatus: 200,
        decodedBody: const {'code': 'Ok', 'routes': []},
      ),
    );

    expect(decision.status, MapboxTripAssistStatus.unavailable);
    expect(decision.safeReason, 'mapbox_routes_missing');
    expect(decision.routeDistanceMiles, isNull);
    expect(decision.canModifyTripLog, isFalse);
    expect(decision.canModifyOdometer, isFalse);
    expect(decision.toSafeSummary()['fallbackMode'], isNull);
    expect(decision.toSafeSummary()['trustedComparisonSource'], 'none');
  });

  test(
    'accepted routes visualize without replacing trusted odometer mileage',
    () {
      final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
        validation: _validRoute(distanceMeters: 1609.344),
        confirmedOdometerMiles: 1.03,
        gpsAcceptedMiles: 1,
      );

      expect(decision.status, MapboxTripAssistStatus.visualOnly);
      expect(decision.shouldShowRoute, isTrue);
      expect(decision.shouldPromptReview, isFalse);
      expect(decision.routeDistanceMiles, closeTo(1, .001));
      expect(decision.comparisonDeltaMiles, closeTo(.03, .001));
      expect(
        decision.trustedMileageSource,
        MapboxTrustedMileageSource.odometer,
      );
      expect(decision.canModifyOdometer, isFalse);
    },
  );

  test('GPS accepted mileage is only a fallback comparison source', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: _validRoute(distanceMeters: 1609.344 * 6.1),
      confirmedOdometerMiles: null,
      gpsAcceptedMiles: 6,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, MapboxTripAssistStatus.visualOnly);
    expect(
      decision.trustedMileageSource,
      MapboxTrustedMileageSource.gpsAccepted,
    );
    expect(summary['trustedComparisonSource'], 'gpsAccepted');
    expect(summary['officialMileageSource'], 'odometer');
    expect(summary['canModifyOdometer'], isFalse);
    expect(summary['canModifyTripLog'], isFalse);
    expect(summary['canConfirmStop'], isFalse);
    expect(summary['canReplaceGpsDistance'], isFalse);
    expect(summary['odometerRequiresUserConfirmation'], isTrue);
  });

  test(
    'large Mapbox mismatch prompts review without becoming authoritative',
    () {
      final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
        validation: _validRoute(distanceMeters: 1609.344 * 14),
        confirmedOdometerMiles: 10,
        gpsAcceptedMiles: 10,
      );

      expect(decision.status, MapboxTripAssistStatus.distanceReview);
      expect(decision.shouldPromptReview, isTrue);
      expect(decision.safeReason, 'mapbox_distance_review_only');
      expect(decision.comparisonDeltaMiles, closeTo(4, .001));
      expect(decision.canModifyTripLog, isFalse);
      expect(decision.canModifyOdometer, isFalse);
      expect(decision.toSafeSummary()['shouldPromptReview'], isTrue);
    },
  );

  test('invalid odometer comparison keeps Mapbox visual-only', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: _validRoute(distanceMeters: 1609.344),
      confirmedOdometerMiles: double.nan,
      gpsAcceptedMiles: -1,
    );

    expect(decision.status, MapboxTripAssistStatus.visualOnly);
    expect(decision.safeReason, 'mapbox_visual_only_no_trusted_mileage');
    expect(decision.comparisonDeltaMiles, isNull);
    expect(decision.trustedMileageSource, MapboxTrustedMileageSource.none);
  });

  test('safe summaries never expose raw route geometry or coordinates', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: _validRoute(distanceMeters: 1609.344),
      confirmedOdometerMiles: 1,
    );
    final summary = decision.toSafeSummary();

    expect(summary.keys, isNot(contains('coordinates')));
    expect(summary.keys, isNot(contains('geometry')));
    expect(summary.keys, isNot(contains('polyline')));
    expect(summary['rawResponseIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
    expect(summary['publicTokenIncluded'], isFalse);
    expect(summary['secretTokenIncluded'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['rawGeometryIncluded'], isFalse);
  });

  test('safe summaries round route assist miles for dashboard storage', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: _validRoute(distanceMeters: 1609.344 * 7.12349),
      confirmedOdometerMiles: 7.12301,
    );
    final summary = decision.toSafeSummary();

    expect(summary['routeDistanceMiles'], 7.123);
    expect(summary['comparisonDeltaMiles'], 0.0);
    expect(summary['advisoryOnly'], isTrue);
  });

  test('invalid review thresholds fail closed before using Mapbox mileage', () {
    final decision = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: _validRoute(distanceMeters: 1609.344),
      confirmedOdometerMiles: 1,
      reviewDifferenceMiles: double.nan,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, MapboxTripAssistStatus.rejected);
    expect(decision.safeReason, 'invalid_map_assist_threshold');
    expect(summary['shouldShowRoute'], isFalse);
    expect(summary['shouldPromptReview'], isFalse);
    expect(summary['routeDistanceMiles'], isNull);
    expect(summary['canPersistRawRoute'], isFalse);
    expect(summary['canPersistCoordinates'], isFalse);
  });

  test('safe summaries sanitize direct malformed Mapbox reason text', () {
    const decision = MapboxTripAssistDecision(
      status: MapboxTripAssistStatus.visualOnly,
      safeReason: 'lat=-80.1 lon=35.1 token=pk.secret',
      routeDistanceMiles: 5,
      comparisonDeltaMiles: 1,
      trustedMileageSource: MapboxTrustedMileageSource.gpsAccepted,
    );
    final summary = decision.toSafeSummary();

    expect(summary['safeReason'], 'mapbox_route_unavailable');
    expect(summary['canOverrideLocalTripLog'], isFalse);
    expect(summary['localTripLogProtected'], isTrue);
    expect(summary.toString(), isNot(contains('35.1')));
    expect(summary.toString(), isNot(contains('pk.secret')));
  });
}

MapboxRouteValidationResult _validRoute({required double distanceMeters}) {
  final longitudeDelta =
      distanceMeters / (111320 * math.cos(35 * math.pi / 180));
  return MapboxExternalRouteValidator.validateDirectionsLikeResponse(
    httpStatus: 200,
    decodedBody: {
      'code': 'Ok',
      'routes': [
        {
          'distance': distanceMeters,
          'duration': 900,
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [-80.0, 35.0],
              [-80.0 + longitudeDelta, 35.0],
            ],
          },
        },
      ],
    },
  );
}
