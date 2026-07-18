import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_response_validation.dart';

void main() {
  group('MapboxExternalMatrixValidator', () {
    test('accepts bounded matrix responses with partial unreachable cells', () {
      final result = MapboxExternalMatrixValidator.validateMatrixLikeResponse(
        httpStatus: 200,
        decodedBody: const {
          'code': 'Ok',
          'durations': [
            [0, 120, null],
            [125, 0, 300],
          ],
          'distances': [
            [0, 1600, null],
            [1625, 0, 3200],
          ],
        },
      );
      final summary = result.toSafeDashboardMap();

      expect(result.isAccepted, isTrue);
      expect(result.cells, hasLength(6));
      expect(result.reachableCellCount, 5);
      expect(result.cells[2].isReachable, isFalse);
      expect(summary['coordinatesIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
      expect(summary['odometerAuthoritative'], isFalse);
    });

    test('rejects malformed envelope and rate limits safely', () {
      final malformed =
          MapboxExternalMatrixValidator.validateMatrixLikeResponse(
            httpStatus: 200,
            decodedBody: const {'durations': []},
          );
      final limited = MapboxExternalMatrixValidator.validateMatrixLikeResponse(
        httpStatus: 429,
        decodedBody: const {},
      );

      expect(malformed.isAccepted, isFalse);
      expect(
        malformed.failures.single.safeReason,
        'mapbox_service_code_not_ok',
      );
      expect(limited.isAccepted, isFalse);
      expect(
        limited.failures.single.code,
        MapboxExternalFailureCode.rateLimited,
      );
    });

    test('rejects invalid matrix shape and values before use', () {
      final ragged = MapboxExternalMatrixValidator.validateMatrixLikeResponse(
        httpStatus: 200,
        decodedBody: const {
          'code': 'Ok',
          'durations': [
            [0, 120],
            [125],
          ],
        },
      );
      final impossible =
          MapboxExternalMatrixValidator.validateMatrixLikeResponse(
            httpStatus: 200,
            decodedBody: const {
              'code': 'Ok',
              'durations': [
                [0, double.infinity],
              ],
            },
          );

      expect(ragged.isAccepted, isFalse);
      expect(
        ragged.failures.single.code,
        MapboxExternalFailureCode.invalidMatrixShape,
      );
      expect(impossible.isAccepted, isFalse);
      expect(
        impossible.failures.single.code,
        MapboxExternalFailureCode.invalidDuration,
      );
    });

    test('rejects fully unreachable matrices as optional map failures', () {
      final result = MapboxExternalMatrixValidator.validateMatrixLikeResponse(
        httpStatus: 200,
        decodedBody: const {
          'code': 'Ok',
          'durations': [
            [null, null],
            [null, null],
          ],
        },
      );

      expect(result.isAccepted, isFalse);
      expect(
        result.failures.single.code,
        MapboxExternalFailureCode.noReachableMatrixCells,
      );
      expect(
        result.failures.single.safeReason,
        'mapbox_matrix_no_reachable_cells',
      );
    });
  });
}
