import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_benchmark_corpus.dart';
import 'support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart';

void main() {
  test('representative synthetic stop corpus has no false stop advisory', () {
    final report = TripTrackingBenchmarkReporter.evaluate(
      TripTrackingBenchmarkCorpus(start: DateTime.utc(2026, 7, 13, 12)).build(),
    );

    expect(report.distanceCaseCount, 6);
    expect(report.eventCaseCount, 27);
    expect(
      report.categoryCaseCounts.values.every((count) => count > 0),
      isTrue,
    );
    expect(
      report.falsePositives,
      0,
      reason: report.cases
          .where(
            (entry) =>
                entry.benchmarkCase.expectedStopReview == false &&
                entry.actualStopReview,
          )
          .map((entry) => entry.benchmarkCase.id)
          .join(','),
    );
    expect(report.falseNegatives, 0);
    expect(report.stopDetectionPrecision, 1);
    expect(report.stopDetectionRecall, 1);
    expect(report.p95DistancePercentageError, lessThanOrEqualTo(.05));
    expect(report.maximumStationaryDriftMeters, lessThanOrEqualTo(15));
    final safeSummary = report.toSafeSummary();
    expect(safeSummary['truePositiveStops'], greaterThan(0));
    expect(safeSummary['falsePositiveStops'], 0);
    expect(safeSummary['falseNegativeStops'], 0);
    expect(safeSummary['realDeviceAccuracyProven'], isFalse);

    final shortTrip = report.cases.singleWhere(
      (entry) => entry.benchmarkCase.id == 'short_trip_known_distance',
    );
    expect(shortTrip.actual.acceptedDistanceCount, 3);
    expect(shortTrip.actual.acceptedMeters, lessThan(400));
    expect(shortTrip.distancePercentageError, lessThanOrEqualTo(.05));

    final tunnel = report.cases.singleWhere(
      (entry) => entry.benchmarkCase.id == 'tunnel_signal_loss_recovery',
    );
    expect(tunnel.actual.count(TripSampleDisposition.rejectedGap), 1);
    expect(tunnel.actual.acceptedDistanceCount, greaterThanOrEqualTo(3));
    expect(tunnel.actual.acceptedMeters, lessThan(500));
    expect(tunnel.actualStopReview, isFalse);

    final buildingCanyon = report.cases.singleWhere(
      (entry) => entry.benchmarkCase.id == 'urban_building_canyon_recovery',
    );
    expect(
      buildingCanyon.actual.count(TripSampleDisposition.rejectedAccuracy),
      3,
    );
    expect(buildingCanyon.actual.acceptedDistanceCount, greaterThanOrEqualTo(4));
    expect(buildingCanyon.actualStopReview, isFalse);
    expect(buildingCanyon.actual.toSafeSummary()['simulationCanReplaceOdometer'], isFalse);

    final ruralRecovery = report.cases.singleWhere(
      (entry) =>
          entry.benchmarkCase.id == 'rural_intermittent_coverage_recovery',
    );
    expect(ruralRecovery.actual.count(TripSampleDisposition.rejectedGap), 2);
    expect(ruralRecovery.actual.acceptedDistanceCount, 3);
    expect(ruralRecovery.actual.acceptedMeters, greaterThan(450));
    expect(ruralRecovery.actual.acceptedMeters, lessThan(650));
    expect(ruralRecovery.actualStopReview, isFalse);
  });
}
