import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';
import 'package:maintaniac/shared/maps/mapbox_trip_assist_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('Mapbox route assist remains advisory in dashboard summary', () {
    final mapboxAssist = MapboxTripAssistPolicy.evaluateRouteAssist(
      validation: MapboxExternalRouteValidator.validateDirectionsLikeResponse(
        httpStatus: 200,
        decodedBody: const {
          'code': 'Ok',
          'routes': [
            {
              'distance': 16093.44,
              'duration': 1200,
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [-80.0, 35.0],
                  [-79.85, 35.0],
                ],
              },
            },
          ],
        },
      ),
      confirmedOdometerMiles: 8,
      gpsAcceptedMiles: 10,
    );

    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      mapboxRouteAssist: mapboxAssist,
    );

    expect(summary.mapboxAssistState, 'distance_review');
    expect(summary.mapboxAssistReason, 'mapbox_distance_review_only');
    expect(summary.mapboxAssistReviewRequired, isTrue);
    expect(summary.mapboxTrustedMileageSource, 'odometer');
    expect(summary.mapboxRouteDistanceMiles, closeTo(10, .001));
    expect(summary.mapboxRouteDeltaMiles, closeTo(2, .001));
    expect(summary.reviewRequired, isTrue);
  });

  test(
    'malformed Mapbox fallback tokens are sanitized before dashboard use',
    () {
      final summary = DashboardTripTrackingSummary.fromSettings(
        settings: const TripTrackingSettings(),
        mapboxAssistState: 'raw_polyline',
        mapboxAssistReason: 'lat=-80.1 lon=35.1 token=pk.secret',
        mapboxAssistReviewRequired: true,
        mapboxTrustedMileageSource: 'route_geometry',
        mapboxRouteDistanceMiles: double.nan,
        mapboxRouteDeltaMiles: -1,
      );

      expect(summary.mapboxAssistState, 'disabled');
      expect(summary.mapboxAssistReason, 'mapbox_route_unavailable');
      expect(summary.mapboxAssistReviewRequired, isTrue);
      expect(summary.mapboxTrustedMileageSource, 'none');
      expect(summary.mapboxRouteDistanceMiles, isNull);
      expect(summary.mapboxRouteDeltaMiles, isNull);
      expect(summary.reviewRequired, isTrue);
    },
  );
}
