import 'package:flutter_test/flutter_test.dart';

import '../tool/trip_tracking_simulation_runner.dart';

void main() {
  test('bounded deterministic corpus passes without field accuracy claims', () {
    final result = runTripTrackingSimulations(iterations: 3);

    expect(result.passed, isTrue);
    expect(result.casesPerIteration, greaterThanOrEqualTo(23));
    expect(result.toJson()['totalCaseRuns'], result.casesPerIteration * 3);
    expect(result.summary['distanceCaseCount'], greaterThanOrEqualTo(5));
    expect(
      result.summary['p95DistancePercentageError'],
      lessThanOrEqualTo(.05),
    );
    expect(result.summary['stopDetectionPrecision'], 1);
    expect(result.summary['stopDetectionRecall'], 1);
    expect(result.summary['realDeviceAccuracyProven'], isFalse);
    expect(result.summary['coordinatesIncluded'], isFalse);
    expect(result.summary['routeGeometryIncluded'], isFalse);
  });

  test('repeated runs produce identical safe summaries', () {
    final first = runTripTrackingSimulations(iterations: 5);
    final second = runTripTrackingSimulations(iterations: 5);

    expect(second.toJson(), first.toJson());
  });

  test('iteration count is strictly bounded', () {
    expect(() => runTripTrackingSimulations(iterations: 0), throwsRangeError);
    expect(
      () => runTripTrackingSimulations(iterations: 1001),
      throwsRangeError,
    );
  });
}
