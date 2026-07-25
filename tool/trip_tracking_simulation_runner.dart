import 'dart:convert';
import 'dart:io';

import '../test/support/trip_tracking_qa/trip_tracking_benchmark_corpus.dart';
import '../test/support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart';

const int _defaultIterations = 25;
const int _maximumIterations = 1000;
const double _maximumStationaryDriftMeters = 15;
const double _maximumP95DistanceError = .05;
const int _minimumDistanceCases = 5;

final class TripTrackingSimulationResult {
  const TripTrackingSimulationResult({
    required this.iterations,
    required this.casesPerIteration,
    required this.summary,
    required this.failures,
  });

  final int iterations;
  final int casesPerIteration;
  final Map<String, Object?> summary;
  final List<String> failures;

  bool get passed => failures.isEmpty;

  Map<String, Object?> toJson() => {
    'passed': passed,
    'iterations': iterations,
    'casesPerIteration': casesPerIteration,
    'totalCaseRuns': iterations * casesPerIteration,
    'failures': failures,
    'metrics': summary,
  };
}

TripTrackingSimulationResult runTripTrackingSimulations({
  int iterations = _defaultIterations,
}) {
  if (iterations < 1 || iterations > _maximumIterations) {
    throw RangeError.range(iterations, 1, _maximumIterations, 'iterations');
  }

  Map<String, Object?>? baseline;
  var casesPerIteration = 0;
  final failures = <String>[];

  for (var iteration = 0; iteration < iterations; iteration++) {
    final cases = TripTrackingBenchmarkCorpus(
      start: DateTime.utc(2026),
    ).build();
    casesPerIteration = cases.length;
    final report = TripTrackingBenchmarkReporter.evaluate(cases);
    final summary = report.toSafeSummary();

    baseline ??= summary;
    if (!_deepEqual(baseline, summary)) {
      failures.add('iteration_${iteration + 1}_was_nondeterministic');
      break;
    }
  }

  final summary = baseline ?? const <String, Object?>{};
  final precision = summary['stopDetectionPrecision'] as num?;
  final recall = summary['stopDetectionRecall'] as num?;
  final drift = summary['maximumStationaryDriftMeters'] as num?;
  final distanceCases = summary['distanceCaseCount'] as int?;
  final p95DistanceError = summary['p95DistancePercentageError'] as num?;

  if (distanceCases == null || distanceCases < _minimumDistanceCases) {
    failures.add('insufficient_distance_fixture_coverage');
  }
  if (p95DistanceError == null || p95DistanceError > _maximumP95DistanceError) {
    failures.add('p95_distance_error_above_5_percent');
  }
  if (precision == null || precision < 1) {
    failures.add('stop_detection_precision_below_1');
  }
  if (recall == null || recall < 1) {
    failures.add('stop_detection_recall_below_1');
  }
  if (drift == null || drift > _maximumStationaryDriftMeters) {
    failures.add('stationary_drift_above_15_meters');
  }
  if (summary['realDeviceAccuracyProven'] != false) {
    failures.add('synthetic_run_claimed_real_device_accuracy');
  }
  if (summary['coordinatesIncluded'] != false ||
      summary['routeGeometryIncluded'] != false) {
    failures.add('safe_summary_exposed_route_data');
  }

  return TripTrackingSimulationResult(
    iterations: iterations,
    casesPerIteration: casesPerIteration,
    summary: summary,
    failures: List.unmodifiable(failures),
  );
}

Future<void> main(List<String> arguments) async {
  try {
    final options = _SimulationOptions.parse(arguments);
    final result = runTripTrackingSimulations(iterations: options.iterations);
    final output = const JsonEncoder.withIndent('  ').convert(result.toJson());

    if (options.outputPath == null) {
      stdout.writeln(output);
    } else {
      final file = File(options.outputPath!);
      await file.parent.create(recursive: true);
      await file.writeAsString('$output\n', flush: true);
      stdout.writeln(file.path);
    }
    if (!result.passed) exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on RangeError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}

final class _SimulationOptions {
  const _SimulationOptions({required this.iterations, this.outputPath});

  final int iterations;
  final String? outputPath;

  static _SimulationOptions parse(List<String> arguments) {
    var iterations = _defaultIterations;
    String? outputPath;
    for (final argument in arguments) {
      if (argument == '--help') {
        throw const FormatException(
          'Usage: dart run tool/trip_tracking_simulation_runner.dart '
          '[--iterations=1..1000] [--output=path]',
        );
      }
      if (argument.startsWith('--iterations=')) {
        iterations =
            int.tryParse(argument.substring('--iterations='.length)) ??
            (throw const FormatException('iterations must be an integer'));
        continue;
      }
      if (argument.startsWith('--output=')) {
        outputPath = argument.substring('--output='.length);
        if (outputPath.isEmpty) {
          throw const FormatException('output path must not be empty');
        }
        continue;
      }
      throw FormatException('unknown argument: $argument');
    }
    return _SimulationOptions(iterations: iterations, outputPath: outputPath);
  }
}

bool _deepEqual(Object? left, Object? right) =>
    jsonEncode(left) == jsonEncode(right);
