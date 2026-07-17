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
      expect(decision.canModifyOdometer, isFalse);
    },
  );

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
    expect(summary['rawGeometryIncluded'], isFalse);
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
