// Regression tests for the deterministic, memory-bounded GPS stress runner.
//
// Owns smoke coverage, seed reproducibility, failure injection, distribution,
// and bounds checks. It does not access physical devices or production data.
// The complete trip QA gate consumes this suite.

import 'package:flutter_test/flutter_test.dart';

import 'support/trip_tracking_stress/trip_stress_evaluator.dart';
import 'support/trip_tracking_stress/trip_stress_runner.dart';
import 'support/trip_tracking_stress/trip_stress_scenario.dart';

void main() {
  const runner = TripStressRunner();

  test(
    'one thousand meaningful scenarios pass with all families represented',
    () async {
      final report = await runner.run(
        const TripStressRunConfiguration(
          scenarioCount: 1000,
          masterSeed: 7272026,
          batchSize: 64,
          gitRevision: 'test',
        ),
      );

      expect(report.passed, isTrue, reason: '${report.retainedFailures}');
      expect(report.failureCount, 0);
      expect(report.invalidScenarioCount, 0);
      expect(report.distributions['family']?.length, 8);
      expect(report.savedRegressionCount, 8);
      expect(report.controllerReplayCount, 4);
      expect(report.retainedFailures, isEmpty);
    },
  );

  test('same seed and configuration reproduce the same digest', () async {
    const configuration = TripStressRunConfiguration(
      scenarioCount: 1000,
      masterSeed: 99271,
      batchSize: 113,
    );
    final first = await runner.run(configuration);
    final second = await runner.run(configuration);

    expect(first.deterministicDigest, second.deterministicDigest);
    expect(first.distributions, second.distributions);
  });

  test('different seeds produce different deterministic digests', () async {
    final first = await runner.run(
      const TripStressRunConfiguration(scenarioCount: 1000, masterSeed: 10),
    );
    final second = await runner.run(
      const TripStressRunConfiguration(scenarioCount: 1000, masterSeed: 11),
    );

    expect(first.deterministicDigest, isNot(second.deterministicDigest));
  });

  test('untrusted Bluetooth observations cannot select a vehicle', () {
    final scenario = const TripStressScenarioGenerator(7272026)
        .generate(5)
        .copyWith(
          bluetoothState: TripStressBluetoothState.wrong,
          hasActiveSession: false,
          hasUnfinishedSession: false,
          bluetoothRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        );

    final result = const TripStressEvaluator().evaluate(scenario);

    expect(result.passed, isTrue, reason: '${result.evidence}');
    expect(result.evidence['trustedObservation'], isFalse);
    expect(result.evidence['canSwitchVehicle'], isFalse);
  });

  test('deliberate failure injection is bounded and reproducible', () async {
    const configuration = TripStressRunConfiguration(
      scenarioCount: 1000,
      masterSeed: 12345,
      injectFailureAt: 417,
      maximumRetainedFailures: 3,
    );
    final first = await runner.run(configuration);
    final second = await runner.run(configuration);

    expect(first.failureCount, 1, reason: '${first.retainedFailures}');
    expect(first.retainedFailures, hasLength(1));
    expect(first.retainedFailures.single['scenarioIndex'], 417);
    expect(first.retainedFailures.single, second.retainedFailures.single);
    expect(first.deterministicDigest, second.deterministicDigest);
  });

  test('configuration rejects unbounded runs and batches', () {
    expect(
      () => runner.run(
        const TripStressRunConfiguration(scenarioCount: 1000001, masterSeed: 1),
      ),
      throwsRangeError,
    );
    expect(
      () => runner.run(
        const TripStressRunConfiguration(
          scenarioCount: 1,
          masterSeed: 1,
          batchSize: 4097,
        ),
      ),
      throwsRangeError,
    );
  });
}
