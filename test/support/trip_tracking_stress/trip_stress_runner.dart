// Memory-bounded runner and report model for GPS stress scenarios.
//
// Owns batching, deterministic digests, bounded failure retention, scenario
// distributions, and memory observations. It does not access physical devices
// or persist production data. Tests and the command-line gate consume it.

import 'dart:io';

import 'trip_stress_evaluator.dart';
import 'trip_stress_controller_replay.dart';
import 'trip_stress_regression_corpus.dart';
import 'trip_stress_scenario.dart';

const tripStressHarnessVersion = 'gps-stress-v2';

final class TripStressRunConfiguration {
  const TripStressRunConfiguration({
    required this.scenarioCount,
    required this.masterSeed,
    this.batchSize = 256,
    this.maximumRetainedFailures = 20,
    this.injectFailureAt,
    this.controllerReplayStride = 250,
    this.gitRevision = 'unknown',
  });

  final int scenarioCount;
  final int masterSeed;
  final int batchSize;
  final int maximumRetainedFailures;
  final int? injectFailureAt;
  final int controllerReplayStride;
  final String gitRevision;

  void validate() {
    if (scenarioCount < 1 || scenarioCount > 1000000) {
      throw RangeError.range(scenarioCount, 1, 1000000, 'scenarioCount');
    }
    if (batchSize < 1 || batchSize > 4096) {
      throw RangeError.range(batchSize, 1, 4096, 'batchSize');
    }
    if (maximumRetainedFailures < 1 || maximumRetainedFailures > 100) {
      throw RangeError.range(
        maximumRetainedFailures,
        1,
        100,
        'maximumRetainedFailures',
      );
    }
    if (controllerReplayStride < 1 || controllerReplayStride > 1000000) {
      throw RangeError.range(
        controllerReplayStride,
        1,
        1000000,
        'controllerReplayStride',
      );
    }
  }
}

final class TripStressRunReport {
  const TripStressRunReport({
    required this.configuration,
    required this.elapsed,
    required this.invalidScenarioCount,
    required this.skippedCount,
    required this.failureCount,
    required this.retainedFailures,
    required this.distributions,
    required this.deterministicDigest,
    required this.startRssBytes,
    required this.peakRssBytes,
    required this.endRssBytes,
    required this.savedRegressionCount,
    required this.controllerReplayCount,
  });

  final TripStressRunConfiguration configuration;
  final Duration elapsed;
  final int invalidScenarioCount;
  final int skippedCount;
  final int failureCount;
  final List<Map<String, Object?>> retainedFailures;
  final Map<String, Map<String, int>> distributions;
  final String deterministicDigest;
  final int startRssBytes;
  final int peakRssBytes;
  final int endRssBytes;
  final int savedRegressionCount;
  final int controllerReplayCount;

  bool get passed => failureCount == 0 && invalidScenarioCount == 0;
  double get scenariosPerSecond => elapsed.inMicroseconds == 0
      ? 0
      : configuration.scenarioCount * 1000000 / elapsed.inMicroseconds;

  Map<String, Object?> toMap() => {
    'harnessVersion': tripStressHarnessVersion,
    'gitRevision': configuration.gitRevision,
    'masterSeed': configuration.masterSeed,
    'scenarioCount': configuration.scenarioCount,
    'batchSize': configuration.batchSize,
    'familyWeights': {
      for (final family in TripStressFamily.values) family.name: 1,
    },
    'elapsedMilliseconds': elapsed.inMilliseconds,
    'scenariosPerSecond': scenariosPerSecond,
    'invalidScenarioCount': invalidScenarioCount,
    'skippedCount': skippedCount,
    'failureCount': failureCount,
    'retainedFailureCount': retainedFailures.length,
    'savedRegressionCount': savedRegressionCount,
    'controllerReplayStride': configuration.controllerReplayStride,
    'controllerReplayCount': controllerReplayCount,
    'deterministicDigest': deterministicDigest,
    'memory': {
      'startRssBytes': startRssBytes,
      'peakRssBytes': peakRssBytes,
      'endRssBytes': endRssBytes,
    },
    'distributions': distributions,
    'failures': retainedFailures,
  };
}

final class TripStressRunner {
  const TripStressRunner({
    this.evaluator = const TripStressEvaluator(),
    this.controllerReplay = const TripStressControllerReplay(),
  });

  final TripStressEvaluator evaluator;
  final TripStressControllerReplay controllerReplay;

  Future<TripStressRunReport> run(
    TripStressRunConfiguration configuration,
  ) async {
    configuration.validate();
    final stopwatch = Stopwatch()..start();
    final generator = TripStressScenarioGenerator(configuration.masterSeed);
    final failures = <Map<String, Object?>>[];
    final distributions = <String, Map<String, int>>{};
    var failureCount = 0;
    var invalidCount = 0;
    var controllerReplayCount = 0;
    var digest = 0xcbf29ce484222325;
    final startRss = ProcessInfo.currentRss;
    var peakRss = startRss;
    final corpus = buildTripStressRegressionCorpus();

    for (final saved in corpus) {
      final evaluation = evaluator.evaluate(saved);
      digest = _digest(digest, saved.scenarioSeed, evaluation.passed);
      if (!evaluation.passed) {
        failureCount += 1;
        _retain(failures, configuration, saved, evaluation.evidence, true);
      }
    }

    for (
      var batchStart = 0;
      batchStart < configuration.scenarioCount;
      batchStart += configuration.batchSize
    ) {
      final batchEnd = (batchStart + configuration.batchSize).clamp(
        0,
        configuration.scenarioCount,
      );
      for (var index = batchStart; index < batchEnd; index += 1) {
        try {
          final scenario = generator.generate(index);
          _count(distributions, 'family', scenario.family.name);
          _count(distributions, 'providerState', scenario.providerState.name);
          _count(
            distributions,
            'permissionState',
            scenario.permissionState.name,
          );
          _count(distributions, 'batteryState', scenario.batteryState.name);
          _count(distributions, 'bluetoothState', scenario.bluetoothState.name);
          _count(distributions, 'lifecycleEvent', scenario.lifecycleEvent.name);
          _count(distributions, 'distanceClass', scenario.distanceClass.name);
          _count(distributions, 'stopClass', scenario.stopClass.name);
          _count(distributions, 'recoveryPath', scenario.recoveryPath.name);
          _count(
            distributions,
            'stateTransition',
            '${scenario.initialLifecycleIndex}->${scenario.targetLifecycleIndex}',
          );
          final evaluation = evaluator.evaluate(scenario);
          final replay = index % configuration.controllerReplayStride == 0
              ? await controllerReplay.replay(scenario)
              : null;
          if (replay != null) controllerReplayCount += 1;
          final injected = configuration.injectFailureAt == index;
          final passed =
              evaluation.passed && replay?['passed'] != false && !injected;
          digest = _digest(digest, scenario.scenarioSeed, passed);
          if (!passed) {
            failureCount += 1;
            _retain(failures, configuration, scenario, {
              ...evaluation.evidence,
              ...?(replay == null ? null : {'controllerReplay': replay}),
              if (injected) 'injectedFailure': true,
            }, false);
          }
        } on Object catch (error) {
          invalidCount += 1;
          digest = _digest(digest, index, false);
          if (failures.length < configuration.maximumRetainedFailures) {
            failures.add({
              'scenarioIndex': index,
              'invalidScenario': true,
              'errorType': error.runtimeType.toString(),
            });
          }
        }
      }
      final rss = ProcessInfo.currentRss;
      if (rss > peakRss) peakRss = rss;
    }
    stopwatch.stop();
    return TripStressRunReport(
      configuration: configuration,
      elapsed: stopwatch.elapsed,
      invalidScenarioCount: invalidCount,
      skippedCount: 0,
      failureCount: failureCount,
      retainedFailures: List.unmodifiable(failures),
      distributions: {
        for (final entry in distributions.entries)
          entry.key: Map.unmodifiable(entry.value),
      },
      deterministicDigest: digest.toRadixString(16).padLeft(16, '0'),
      startRssBytes: startRss,
      peakRssBytes: peakRss,
      endRssBytes: ProcessInfo.currentRss,
      savedRegressionCount: corpus.length,
      controllerReplayCount: controllerReplayCount,
    );
  }
}

void _count(
  Map<String, Map<String, int>> distributions,
  String dimension,
  String value,
) {
  final values = distributions.putIfAbsent(dimension, () => <String, int>{});
  values[value] = (values[value] ?? 0) + 1;
}

void _retain(
  List<Map<String, Object?>> failures,
  TripStressRunConfiguration configuration,
  TripStressScenario scenario,
  Map<String, Object?> evidence,
  bool savedRegression,
) {
  if (failures.length >= configuration.maximumRetainedFailures) return;
  failures.add({
    ...scenario.toFailureMap(),
    'savedRegression': savedRegression,
    'actual': evidence,
  });
}

int _digest(int current, int scenarioSeed, bool passed) {
  var value = current ^ scenarioSeed ^ (passed ? 1 : 0);
  value = (value * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF;
  return value;
}
