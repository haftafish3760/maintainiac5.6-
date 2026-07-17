import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';

void main() {
  group('MapboxExternalRouteValidator alternative limits', () {
    test(
      'caps accepted alternatives after skipping invalid route candidates',
      () {
        final result =
            MapboxExternalRouteValidator.validateDirectionsLikeResponse(
              httpStatus: 200,
              decodedBody: {
                'code': 'Ok',
                'routes': [
                  {
                    'distance': 0,
                    'duration': 120,
                    'geometry': {
                      'type': 'LineString',
                      'coordinates': [
                        [-80, 35],
                        [-80.01, 35.01],
                      ],
                    },
                  },
                  'not-a-route-object',
                  for (var index = 0; index < 4; index++)
                    {
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
                ],
              },
            );

        expect(result.isAccepted, isTrue);
        expect(result.candidates, hasLength(3));
        expect(result.candidates.map((candidate) => candidate.distanceMeters), [
          1000,
          1001,
          1002,
        ]);
      },
    );

    test('bounds how many route alternatives are scanned', () {
      final result =
          MapboxExternalRouteValidator.validateDirectionsLikeResponse(
            httpStatus: 200,
            decodedBody: {
              'code': 'Ok',
              'routes': [
                for (
                  var index = 0;
                  index <
                      MapboxExternalRouteValidator
                          .maximumRouteCandidatesScanned;
                  index++
                )
                  {
                    'distance': 0,
                    'duration': 120,
                    'geometry': {
                      'type': 'LineString',
                      'coordinates': [
                        [-80, 35],
                        [-80.01, 35.01],
                      ],
                    },
                  },
                {
                  'distance': 1000,
                  'duration': 120,
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

      expect(result.isAccepted, isFalse);
      expect(
        result.failures.single.code,
        MapboxExternalFailureCode.invalidRouteShape,
      );
    });
  });
}
