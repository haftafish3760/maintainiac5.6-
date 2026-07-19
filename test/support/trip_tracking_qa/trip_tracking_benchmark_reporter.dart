import 'trip_tracking_simulator.dart';

enum TripTrackingBenchmarkCategory {
  normalOpenSky,
  urban,
  rural,
  degraded,
  severeInterruption,
}

/// Deterministic aggregate metrics for synthetic GPS replay fixtures.
///
/// This deliberately measures only the expectations supplied by a fixture.
/// It is not a claim about field accuracy, battery use, or real-device GPS
/// performance. Real route evidence is collected separately before those
/// claims can be made.
class TripTrackingBenchmarkReporter {
  const TripTrackingBenchmarkReporter._();

  static TripTrackingBenchmarkReport evaluate(
    Iterable<TripTrackingBenchmarkCase> cases,
  ) {
    final results = cases
        .map(
          (benchmarkCase) => TripTrackingBenchmarkCaseResult(
            benchmarkCase: benchmarkCase,
            actual: benchmarkCase.run(),
          ),
        )
        .toList(growable: false);
    return TripTrackingBenchmarkReport(results);
  }
}

class TripTrackingBenchmarkCase {
  const TripTrackingBenchmarkCase({
    required this.id,
    required this.run,
    required this.category,
    this.expectedDistanceMeters,
    this.expectedStopReview,
    this.stopReviewDetector = _defaultStopReviewDetector,
  }) : assert(id != '');

  final String id;
  final SimulatedTripResult Function() run;
  final TripTrackingBenchmarkCategory category;

  /// Null means the fixture is event-only and contributes no distance metric.
  final double? expectedDistanceMeters;

  /// Null means the fixture is distance-only and contributes no event metric.
  final bool? expectedStopReview;
  final bool Function(SimulatedTripResult result) stopReviewDetector;
}

class TripTrackingBenchmarkCaseResult {
  const TripTrackingBenchmarkCaseResult({
    required this.benchmarkCase,
    required this.actual,
  });

  final TripTrackingBenchmarkCase benchmarkCase;
  final SimulatedTripResult actual;

  bool get actualStopReview => benchmarkCase.stopReviewDetector(actual);

  double? get distanceAbsoluteErrorMeters {
    final expected = benchmarkCase.expectedDistanceMeters;
    if (expected == null || !expected.isFinite) return null;
    return (actual.acceptedMeters - expected).abs();
  }

  double? get distancePercentageError {
    final expected = benchmarkCase.expectedDistanceMeters;
    final absoluteError = distanceAbsoluteErrorMeters;
    if (expected == null || absoluteError == null || expected <= 0) return null;
    return absoluteError / expected;
  }

  bool? get stopDetectionCorrect {
    final expected = benchmarkCase.expectedStopReview;
    return expected == null ? null : actualStopReview == expected;
  }
}

class TripTrackingBenchmarkReport {
  TripTrackingBenchmarkReport(Iterable<TripTrackingBenchmarkCaseResult> input)
    : cases = List.unmodifiable(input) {
    final ids = <String>{};
    for (final entry in cases) {
      if (!ids.add(entry.benchmarkCase.id)) {
        throw ArgumentError.value(
          entry.benchmarkCase.id,
          'cases',
          'benchmark case ids must be unique',
        );
      }
    }
  }

  final List<TripTrackingBenchmarkCaseResult> cases;

  int get distanceCaseCount =>
      cases.where((entry) => entry.distanceAbsoluteErrorMeters != null).length;

  int get eventCaseCount =>
      cases.where((entry) => entry.stopDetectionCorrect != null).length;

  Map<String, int> get categoryCaseCounts => Map.unmodifiable({
    for (final category in TripTrackingBenchmarkCategory.values)
      category.name: cases
          .where((entry) => entry.benchmarkCase.category == category)
          .length,
  });

  double? get meanDistanceAbsoluteErrorMeters =>
      _mean(cases.map((entry) => entry.distanceAbsoluteErrorMeters));

  double? get medianDistancePercentageError =>
      _percentile(cases.map((entry) => entry.distancePercentageError), .5);

  double? get p95DistancePercentageError =>
      _percentile(cases.map((entry) => entry.distancePercentageError), .95);

  /// Synthetic stationary-drift measurement. Only explicit zero-distance
  /// fixtures are included, so normal short routes never dilute this metric.
  double? get maximumStationaryDriftMeters {
    final values = cases
        .where((entry) => entry.benchmarkCase.expectedDistanceMeters == 0)
        .map((entry) => entry.actual.acceptedMeters)
        .where((value) => value.isFinite)
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((left, right) => left > right ? left : right);
  }

  int get truePositives => cases
      .where(
        (entry) =>
            entry.benchmarkCase.expectedStopReview == true &&
            entry.actualStopReview,
      )
      .length;

  int get falsePositives => cases
      .where(
        (entry) =>
            entry.benchmarkCase.expectedStopReview == false &&
            entry.actualStopReview,
      )
      .length;

  int get falseNegatives => cases
      .where(
        (entry) =>
            entry.benchmarkCase.expectedStopReview == true &&
            !entry.actualStopReview,
      )
      .length;

  double? get stopDetectionPrecision {
    final denominator = truePositives + falsePositives;
    return denominator == 0 ? null : truePositives / denominator;
  }

  double? get stopDetectionRecall {
    final denominator = truePositives + falseNegatives;
    return denominator == 0 ? null : truePositives / denominator;
  }

  Map<String, Object?> toSafeSummary() => {
    'distanceCaseCount': distanceCaseCount,
    'eventCaseCount': eventCaseCount,
    'categoryCaseCounts': categoryCaseCounts,
    'meanDistanceAbsoluteErrorMeters': _rounded(
      meanDistanceAbsoluteErrorMeters,
    ),
    'medianDistancePercentageError': _rounded(medianDistancePercentageError),
    'p95DistancePercentageError': _rounded(p95DistancePercentageError),
    'maximumStationaryDriftMeters': _rounded(maximumStationaryDriftMeters),
    'stopDetectionPrecision': _rounded(stopDetectionPrecision),
    'stopDetectionRecall': _rounded(stopDetectionRecall),
    'syntheticFixtureMetricsOnly': true,
    'realDeviceAccuracyProven': false,
    'routeGeometryIncluded': false,
    'coordinatesIncluded': false,
  };
}

double? _mean(Iterable<double?> source) {
  final values = source.whereType<double>().where((value) => value.isFinite);
  var count = 0;
  var total = 0.0;
  for (final value in values) {
    count++;
    total += value;
  }
  return count == 0 ? null : total / count;
}

double? _percentile(Iterable<double?> source, double percentile) {
  final values =
      source.whereType<double>().where((value) => value.isFinite).toList()
        ..sort();
  if (values.isEmpty || !percentile.isFinite) return null;
  final index = ((values.length - 1) * percentile.clamp(0.0, 1.0)).round();
  return values[index];
}

double? _rounded(double? value) =>
    value == null ? null : double.parse(value.toStringAsFixed(4));

bool _defaultStopReviewDetector(SimulatedTripResult result) =>
    result.needsWalkingReview;
