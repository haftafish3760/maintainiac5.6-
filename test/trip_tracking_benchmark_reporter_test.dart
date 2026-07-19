import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  SimulatedTripResult result(double meters, {required bool stopReview}) =>
      SimulatedTripResult(
        acceptedMeters: meters,
        dispositions: const [TripSampleDisposition.acceptedAnchor],
        needsWalkingReview: stopReview,
        motionState: TripMotionState.moving,
      );

  test('synthetic reporter separates mileage, drift, and stop metrics', () {
    final report = TripTrackingBenchmarkReporter.evaluate([
      TripTrackingBenchmarkCase(
        id: 'stationary_drift',
        category: TripTrackingBenchmarkCategory.urban,
        expectedDistanceMeters: 0,
        expectedStopReview: false,
        run: () => result(3, stopReview: false),
      ),
      TripTrackingBenchmarkCase(
        id: 'confirmed_delivery_stop',
        category: TripTrackingBenchmarkCategory.normalOpenSky,
        expectedDistanceMeters: 100,
        expectedStopReview: true,
        run: () => result(101, stopReview: true),
      ),
      TripTrackingBenchmarkCase(
        id: 'traffic_light_false_positive',
        category: TripTrackingBenchmarkCategory.urban,
        expectedStopReview: false,
        run: () => result(0, stopReview: true),
      ),
    ]);

    expect(report.distanceCaseCount, 2);
    expect(report.eventCaseCount, 3);
    expect(report.categoryCaseCounts, {
      'normalOpenSky': 1,
      'urban': 2,
      'rural': 0,
      'degraded': 0,
      'severeInterruption': 0,
    });
    expect(report.meanDistanceAbsoluteErrorMeters, 2);
    expect(report.medianDistancePercentageError, .01);
    expect(report.p95DistancePercentageError, .01);
    expect(report.maximumStationaryDriftMeters, 3);
    expect(report.truePositives, 1);
    expect(report.falsePositives, 1);
    expect(report.falseNegatives, 0);
    expect(report.stopDetectionPrecision, .5);
    expect(report.stopDetectionRecall, 1);

    final summary = report.toSafeSummary();
    expect(summary['syntheticFixtureMetricsOnly'], isTrue);
    expect(summary['realDeviceAccuracyProven'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
  });

  test('benchmark reports reject duplicate fixture ids', () {
    final duplicate = TripTrackingBenchmarkCase(
      id: 'duplicate',
      category: TripTrackingBenchmarkCategory.degraded,
      run: () => result(0, stopReview: false),
    );

    expect(
      () => TripTrackingBenchmarkReporter.evaluate([duplicate, duplicate]),
      throwsArgumentError,
    );
  });
}
