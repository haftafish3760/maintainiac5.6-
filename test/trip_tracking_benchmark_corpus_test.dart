import 'package:flutter_test/flutter_test.dart';

import 'support/trip_tracking_qa/trip_tracking_benchmark_corpus.dart';
import 'support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart';

void main() {
  test('representative synthetic stop corpus has no false stop advisory', () {
    final report = TripTrackingBenchmarkReporter.evaluate(
      TripTrackingBenchmarkCorpus(start: DateTime.utc(2026, 7, 13, 12)).build(),
    );

    expect(report.distanceCaseCount, 1);
    expect(report.eventCaseCount, 8);
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
    expect(report.maximumStationaryDriftMeters, lessThanOrEqualTo(15));
    expect(report.toSafeSummary()['realDeviceAccuracyProven'], isFalse);
  });
}
