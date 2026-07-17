import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/maps/mapbox_service_guard.dart';

void main() {
  test('disabled optional Mapbox services fail gracefully to GPS-only', () {
    for (final kind in MapboxOptionalServiceKind.values) {
      final decision = MapboxServiceGuard.evaluate(
        kind: kind,
        featureEnabled: false,
        httpStatus: 200,
        decodedBody: const {'code': 'Ok'},
      );

      expect(decision.status, MapboxServiceGuardStatus.disabled);
      expect(decision.canUseFeature, isFalse);
      expect(decision.shouldFallbackToGpsOnly, isTrue);
      expect(decision.safeReason, 'mapbox_${kind.name}_disabled');
    }
  });

  test('successful optional Mapbox services become ready without raw data', () {
    for (final kind in MapboxOptionalServiceKind.values) {
      final decision = MapboxServiceGuard.evaluate(
        kind: kind,
        featureEnabled: true,
        httpStatus: 200,
        decodedBody: _validBodyFor(kind),
      );
      final summary = decision.toSafeSummary();

      expect(decision.status, MapboxServiceGuardStatus.ready);
      expect(decision.canUseFeature, isTrue);
      expect(summary['rawResponseIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
      expect(summary['coordinatesIncluded'], isFalse);
      expect(summary.toString(), isNot(contains('private')));
      expect(summary.toString(), isNot(contains('35.1')));
    }
  });

  test('rate limits preserve a bounded retry hint and no location payload', () {
    final decision = MapboxServiceGuard.evaluate(
      kind: MapboxOptionalServiceKind.optimization,
      featureEnabled: true,
      httpStatus: 429,
      decodedBody: const {'message': 'token=pk.secret lat=35.1 lon=-80.1'},
      retryAfterSeconds: 999999,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, MapboxServiceGuardStatus.rateLimited);
    expect(decision.retryAfterSeconds, 86400);
    expect(decision.shouldFallbackToGpsOnly, isTrue);
    expect(summary.toString(), isNot(contains('pk.secret')));
    expect(summary.toString(), isNot(contains('35.1')));
    expect(summary.toString(), isNot(contains('-80.1')));
  });

  test('HTTP failures and missing statuses do not enable Mapbox features', () {
    for (final status in const [null, 400, 500]) {
      final decision = MapboxServiceGuard.evaluate(
        kind: MapboxOptionalServiceKind.directions,
        featureEnabled: true,
        httpStatus: status,
        decodedBody: const {'code': 'Ok'},
      );

      expect(decision.status, MapboxServiceGuardStatus.httpFailure);
      expect(decision.canUseFeature, isFalse);
      expect(decision.safeReason, 'mapbox_directions_http_failure');
    }
  });

  test('malformed bodies and non-Ok service codes fail closed', () {
    final malformed = MapboxServiceGuard.evaluate(
      kind: MapboxOptionalServiceKind.matrix,
      featureEnabled: true,
      httpStatus: 200,
      decodedBody: 'not-a-json-object',
    );
    final nonOk = MapboxServiceGuard.evaluate(
      kind: MapboxOptionalServiceKind.mapMatching,
      featureEnabled: true,
      httpStatus: 200,
      decodedBody: const {'code': 'NoSegment'},
    );

    expect(malformed.status, MapboxServiceGuardStatus.malformedResponse);
    expect(malformed.safeReason, 'mapbox_matrix_malformed_response');
    expect(nonOk.status, MapboxServiceGuardStatus.malformedResponse);
    expect(nonOk.safeReason, 'mapbox_mapMatching_service_code_not_ok');
  });

  test('enabled optional services require service-specific response shape', () {
    for (final kind in MapboxOptionalServiceKind.values) {
      if (kind == MapboxOptionalServiceKind.maps) continue;
      final decision = MapboxServiceGuard.evaluate(
        kind: kind,
        featureEnabled: true,
        httpStatus: 200,
        decodedBody: const {'code': 'Ok', 'message': 'not enough shape'},
      );

      expect(decision.status, MapboxServiceGuardStatus.malformedResponse);
      expect(decision.safeReason, 'mapbox_${kind.name}_unexpected_shape');
      expect(decision.canUseFeature, isFalse);
      expect(decision.shouldFallbackToGpsOnly, isTrue);
    }
  });

  test('retry-after values are type checked and bounded', () {
    int? retry(Object? raw) => MapboxServiceGuard.evaluate(
      kind: MapboxOptionalServiceKind.search,
      featureEnabled: true,
      httpStatus: 429,
      decodedBody: const {},
      retryAfterSeconds: raw,
    ).retryAfterSeconds;

    expect(retry('60'), isNull);
    expect(retry(double.nan), isNull);
    expect(retry(-1), isNull);
    expect(retry(30.4), 30);
    expect(retry(999999), 86400);
  });
}

Map<String, Object?> _validBodyFor(MapboxOptionalServiceKind kind) {
  return switch (kind) {
    MapboxOptionalServiceKind.maps => const {
      'code': 'Ok',
      'tilejson': 'private-style',
    },
    MapboxOptionalServiceKind.directions => const {
      'code': 'Ok',
      'routes': [
        {'geometry': 'private', 'distance': 1000},
      ],
    },
    MapboxOptionalServiceKind.matrix => const {
      'code': 'Ok',
      'durations': [
        [0, 60],
      ],
    },
    MapboxOptionalServiceKind.mapMatching => const {
      'code': 'Ok',
      'matchings': [
        {'geometry': 'private'},
      ],
    },
    MapboxOptionalServiceKind.isochrone => const {
      'code': 'Ok',
      'type': 'FeatureCollection',
      'features': [
        {'geometry': 'private'},
      ],
    },
    MapboxOptionalServiceKind.optimization => const {
      'code': 'Ok',
      'trips': [
        {'geometry': 'private'},
      ],
    },
    MapboxOptionalServiceKind.search => const {
      'code': 'Ok',
      'features': [
        {
          'center': [35.1, -80.1],
        },
      ],
    },
    MapboxOptionalServiceKind.evChargeFinder => const {
      'code': 'Ok',
      'type': 'FeatureCollection',
      'features': [
        {'geometry': 'private'},
      ],
    },
  };
}
