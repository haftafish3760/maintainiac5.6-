import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';

void main() {
  group('MapboxExternalRouteValidator', () {
    test('accepts a bounded directions-style GeoJSON route candidate', () {
      final result =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': 1609.344,
                  'duration': 480,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80.0, 35.0],
                      [-80.01, 35.01],
                    ],
                  },
                },
              ],
            },
          );

      expect(result.isAccepted, isTrue);
      expect(result.candidates.single.distanceMiles, closeTo(1, .001));
      expect(result.candidates.single.odometerAuthoritative, isFalse);
      expect(result.failures, isEmpty);
    });

    test('rejects non-Ok Mapbox service status bodies', () {
      final result =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'NoRoute',
              'routes': [
                {
                  'distance': 1609.344,
                  'duration': 480,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80.0, 35.0],
                      [-80.01, 35.01],
                    ],
                  },
                },
              ],
            },
          );

      expect(result.isAccepted, isFalse);
      expect(
        result.failures.single.code,
        MapboxExternalFailureCode.malformedResponse,
      );
      expect(result.failures.single.safeReason, 'mapbox_service_code_not_ok');
    });

    test('rejects missing Mapbox service status bodies', () {
      final result =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'routes': [
                {
                  'distance': 1609.344,
                  'duration': 480,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80.0, 35.0],
                      [-80.01, 35.01],
                    ],
                  },
                },
              ],
            },
          );

      expect(result.isAccepted, isFalse);
      expect(
        result.failures.single.code,
        MapboxExternalFailureCode.malformedResponse,
      );
      expect(result.failures.single.safeReason, 'mapbox_service_code_not_ok');
    });

    test('rejects non-success and rate-limited responses safely', () {
      final serverFailure =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 503,
            decodedBody: const {},
          );
      final rateLimited =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 429,
            decodedBody: const {},
          );

      expect(serverFailure.isAccepted, isFalse);
      expect(
        serverFailure.failures.single.code,
        MapboxExternalFailureCode.httpFailure,
      );
      expect(rateLimited.isAccepted, isFalse);
      expect(
        rateLimited.failures.single.code,
        MapboxExternalFailureCode.rateLimited,
      );
    });

    test('rejects malformed bodies and empty route lists', () {
      final malformed =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: 'not-json-object',
          );
      final emptyRoutes =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: const {'code': 'Ok', 'routes': []},
          );

      expect(
        malformed.failures.single.code,
        MapboxExternalFailureCode.malformedResponse,
      );
      expect(
        emptyRoutes.failures.single.code,
        MapboxExternalFailureCode.missingRoutes,
      );
    });

    test('rejects invalid coordinates and non-finite route values', () {
      final badCoordinate =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': 10,
                  'duration': 60,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-181, 35],
                      [-80, 35],
                    ],
                  },
                },
              ],
            },
          );
      final badDistance =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': double.nan,
                  'duration': 60,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80, 35],
                      [-80.01, 35.01],
                    ],
                  },
                },
              ],
            },
          );

      expect(badCoordinate.isAccepted, isFalse);
      expect(
        badCoordinate.failures.single.code,
        MapboxExternalFailureCode.invalidRouteShape,
      );
      expect(badDistance.isAccepted, isFalse);
      expect(
        badDistance.failures.single.code,
        MapboxExternalFailureCode.invalidRouteShape,
      );
    });

    test('rejects partial or overwide route geometry coordinates', () {
      final onePoint =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': 10,
                  'duration': 60,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80, 35],
                    ],
                  },
                },
              ],
            },
          );
      final overwideCoordinate =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': 10,
                  'duration': 60,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80, 35, 900],
                      [-80.01, 35.01, 901],
                    ],
                  },
                },
              ],
            },
          );

      expect(onePoint.isAccepted, isFalse);
      expect(overwideCoordinate.isAccepted, isFalse);
    });

    test('caps accepted alternatives and rejects oversized geometries', () {
      final manyRoutes =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': List.generate(
                5,
                (index) => {
                  'distance': 1000 + index,
                  'duration': 120,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-80, 35],
                      [-80.01, 35.01],
                    ],
                  },
                },
              ),
            },
          );
      final oversized =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                {
                  'distance': 1000,
                  'duration': 120,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': List.generate(
                      MapboxExternalRouteValidator.maximumRouteCoordinates + 1,
                      (index) => [-80.0, 35.0],
                    ),
                  },
                },
              ],
            },
          );

      expect(manyRoutes.candidates, hasLength(3));
      expect(oversized.isAccepted, isFalse);
    });
  });
}
