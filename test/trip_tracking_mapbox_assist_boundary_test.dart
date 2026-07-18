import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';
import 'package:maintaniac/shared/maps/mapbox_trip_assist_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_mapbox_assist_boundary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 14, 8);

  TripTrackingSessionRecord activeSession() => TripTrackingSessionRecord(
    id: 'trip_mapbox_active',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    updatedAt: startedAt.add(const Duration(minutes: 30)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
  );

  TripTrackingReviewRecord reviewRecord() => TripTrackingReviewRecord(
    id: 'trip_mapbox_review',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1010,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(minutes: 45)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344 * 10,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
    confirmedEndingOdometer: 1010,
    odometerConfirmedAt: startedAt.add(const Duration(minutes: 50)),
  );

  test('map preview opt-in is required before rendering map assist', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 1, gpsMiles: 1),
      activeSession: activeSession(),
      mapPreviewOptIn: false,
      routeHistoryOptIn: true,
    );

    expect(decision.status, TripTrackingMapboxAssistBoundaryStatus.disabled);
    expect(decision.canRenderMapAssist, isFalse);
    expect(decision.toSafeDashboardMap()['fallbackMode'], 'gps_only');
  });

  test('validated local trip source is required for any Mapbox assist', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 1, gpsMiles: 1),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );

    expect(
      decision.status,
      TripTrackingMapboxAssistBoundaryStatus.gpsOnlyFallback,
    );
    expect(decision.safeReason, 'validated_local_trip_source_required');
    expect(decision.canRenderMapAssist, isFalse);
  });

  test('valid active session can render visual-only map assist', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 1.12349, gpsMiles: 1.12),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: false,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripTrackingMapboxAssistBoundaryStatus.visualOnly);
    expect(decision.canRenderMapAssist, isTrue);
    expect(decision.canPromptMileageReview, isFalse);
    expect(decision.canPersistRouteHistory, isFalse);
    expect(safe['routeDistanceMiles'], 1.123);
    expect(safe['routeHistoryRequiresSeparateOptIn'], isTrue);
    expect(safe['mapboxAssistRequiresOwnershipValidation'], isTrue);
    expect(safe['mapboxAssistRequiresDeviceLocalSource'], isTrue);
    expect(safe['authenticationAloneAuthorizesMapAssist'], isFalse);
    expect(safe['mapboxAssistCannotPersistWithoutRouteHistoryOptIn'], isTrue);
    expect(safe['mapboxResponseValidatedBeforeAssist'], isTrue);
    expect(safe['mapboxCanModifyTripLog'], isFalse);
    expect(safe['mapboxCanModifyOdometer'], isFalse);
  });

  test('Mapbox mileage mismatch is review-only and requires review record', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 14, confirmedMiles: 10),
      reviewRecord: reviewRecord(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );
    final safe = decision.toSafeDashboardMap();

    expect(
      decision.status,
      TripTrackingMapboxAssistBoundaryStatus.mileageReviewOnly,
    );
    expect(decision.canPromptMileageReview, isTrue);
    expect(decision.canPersistRouteHistory, isTrue);
    expect(safe['advisoryOnly'], isTrue);
    expect(safe['officialMileageSource'], 'odometer');
    expect(safe['remoteRouteCanBecomeCanonical'], isFalse);
    expect(safe['mapboxCanConfirmMileage'], isFalse);
    expect(safe['mapboxCanConfirmStop'], isFalse);
    expect(safe['mapboxMileageReviewRequiresLocalReviewRecord'], isTrue);
  });

  test('mileage mismatch cannot prompt review without local review record', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 14, confirmedMiles: 10),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripTrackingMapboxAssistBoundaryStatus.visualOnly);
    expect(decision.canPromptMileageReview, isFalse);
    expect(decision.canPersistRouteHistory, isTrue);
    expect(safe['mapboxMileageReviewRequiresLocalReviewRecord'], isTrue);
    expect(safe['mapboxCanConfirmMileage'], isFalse);
    expect(safe['officialMileageSource'], 'odometer');
  });

  test('invalid route distance falls back without rendering map assist', () {
    final decision = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: const MapboxTripAssistDecision(
        status: MapboxTripAssistStatus.visualOnly,
        safeReason: 'mapbox_visual_assist_only',
        routeDistanceMiles: double.infinity,
        comparisonDeltaMiles: null,
        trustedMileageSource: MapboxTrustedMileageSource.none,
      ),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );

    expect(
      decision.status,
      TripTrackingMapboxAssistBoundaryStatus.gpsOnlyFallback,
    );
    expect(decision.safeReason, 'invalid_mapbox_route_distance');
    expect(decision.canRenderMapAssist, isFalse);
    expect(decision.canPersistRouteHistory, isFalse);
  });

  test('rate limits and malformed routes fall back to GPS-only safely', () {
    final rateLimited = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: MapboxTripAssistPolicy.evaluateRouteAssist(
        validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
          httpStatus: 429,
          decodedBody: const {},
        ),
      ),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );
    final malformed = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: MapboxTripAssistPolicy.evaluateRouteAssist(
        validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
          httpStatus: 200,
          decodedBody: const {'code': 'Ok', 'routes': []},
        ),
      ),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    );

    expect(rateLimited.canRenderMapAssist, isFalse);
    expect(rateLimited.safeReason, 'mapbox_rate_limited');
    expect(malformed.canRenderMapAssist, isFalse);
    expect(malformed.safeReason, 'mapbox_routes_missing');
    expect(
      rateLimited.toSafeDashboardMap()['rawMapboxResponseIncluded'],
      isFalse,
    );
  });

  test(
    'safe summary never includes route geometry, coordinates, or tokens',
    () {
      final safe = TripTrackingMapboxAssistBoundaryDecision.evaluate(
        mapboxDecision: _routeDecision(routeMiles: 1, gpsMiles: 1),
        activeSession: activeSession(),
        mapPreviewOptIn: true,
        routeHistoryOptIn: true,
      ).toSafeDashboardMap();

      expect(safe['rawMapboxResponseIncluded'], isFalse);
      expect(safe['rawGpsIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe.toString(), isNot(contains('pk.')));
      expect(safe.toString(), isNot(contains('sk.')));
      expect(safe.toString(), isNot(contains('35.')));
    },
  );

  test('safe Mapbox assist summary validates as advisory only', () {
    final summary = TripTrackingMapboxAssistBoundaryDecision.evaluate(
      mapboxDecision: _routeDecision(routeMiles: 1, gpsMiles: 1),
      activeSession: activeSession(),
      mapPreviewOptIn: true,
      routeHistoryOptIn: true,
    ).toSafeDashboardMap();

    final validation =
        TripTrackingMapboxAssistBoundarySummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isTrue);
    expect(
      validation.status,
      TripTrackingMapboxAssistBoundaryStatus.visualOnly,
    );
    expect(validation.reasons, isEmpty);
  });

  test('Mapbox assist summary rejects auth-only source authority', () {
    final summary =
        TripTrackingMapboxAssistBoundaryDecision.evaluate(
          mapboxDecision: _routeDecision(routeMiles: 1, gpsMiles: 1),
          activeSession: activeSession(),
          mapPreviewOptIn: true,
          routeHistoryOptIn: true,
        ).toSafeDashboardMap()..addAll({
          'mapboxAssistRequiresOwnershipValidation': false,
          'mapboxAssistRequiresDeviceLocalSource': false,
          'authenticationAloneAuthorizesMapAssist': true,
        });

    final validation =
        TripTrackingMapboxAssistBoundarySummaryValidation.fromSummary(summary);

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('mapbox_assist_authorization_boundary_missing'),
    );
  });

  test(
    'Mapbox assist summary rejects route authority and sensitive material',
    () {
      final summary =
          TripTrackingMapboxAssistBoundaryDecision.evaluate(
            mapboxDecision: _routeDecision(routeMiles: 14, confirmedMiles: 10),
            reviewRecord: reviewRecord(),
            mapPreviewOptIn: true,
            routeHistoryOptIn: true,
          ).toSafeDashboardMap()..addAll({
            'mapboxCanModifyTripLog': true,
            'mapboxCanModifyOdometer': true,
            'mapboxCanCreateStop': true,
            'mapboxCanEndTrip': true,
            'mapboxCanOverrideLocalTrip': true,
            'mapboxCanReorderOfficialStops': true,
            'mapboxCanPersistRouteWithoutOptIn': true,
            'mapboxCanConfirmMileage': true,
            'mapboxCanConfirmStop': true,
            'firestoreCanOverrideMapAssistBoundary': true,
            'remoteRouteCanBecomeCanonical': true,
            'rawMapboxResponseIncluded': true,
            'rawGpsIncluded': true,
            'preciseLocationIncluded': true,
            'routeGeometryIncluded': true,
            'tokensIncluded': true,
            'debug': 'sk.secret 35.123456,-80.123456',
          });

      final validation =
          TripTrackingMapboxAssistBoundarySummaryValidation.fromSummary(
            summary,
          );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('mapbox_assist_claims_trip_authority'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_mapbox_assist_material'),
      );
    },
  );
}

MapboxTripAssistDecision _routeDecision({
  required double routeMiles,
  double? confirmedMiles,
  double? gpsMiles,
}) {
  final distanceMeters = routeMiles * 1609.344;
  final longitudeDelta =
      distanceMeters / (111320 * math.cos(35 * math.pi / 180));
  return MapboxTripAssistPolicy.evaluateRouteAssist(
    validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
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
    ),
    confirmedOdometerMiles: confirmedMiles,
    gpsAcceptedMiles: gpsMiles,
  );
}
