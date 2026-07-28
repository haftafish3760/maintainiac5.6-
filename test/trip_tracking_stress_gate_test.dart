// Configurable Flutter test entry point for large GPS stress runs.
//
// Owns environment-driven execution and a bounded JSON artifact. It does not
// access devices or production storage. The shell gate supplies count, seed,
// batch size, revision, and artifact path without duplicating stress suites.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/trip_tracking_stress/trip_stress_runner.dart';

void main() {
  test('configured deterministic GPS stress gate', () {
    const countText = String.fromEnvironment(
      'TRIP_STRESS_SCENARIOS',
      defaultValue: '1000',
    );
    const seedText = String.fromEnvironment(
      'TRIP_STRESS_SEED',
      defaultValue: '7272026',
    );
    const batchText = String.fromEnvironment(
      'TRIP_STRESS_BATCH_SIZE',
      defaultValue: '256',
    );
    const revision = String.fromEnvironment(
      'TRIP_STRESS_GIT_REVISION',
      defaultValue: 'unknown',
    );
    const outputPath = String.fromEnvironment(
      'TRIP_STRESS_OUTPUT',
      defaultValue: '/tmp/trip_tracking_stress_report.json',
    );
    const injectText = String.fromEnvironment('TRIP_STRESS_INJECT_FAILURE');
    final report = const TripStressRunner().run(
      TripStressRunConfiguration(
        scenarioCount: int.parse(countText),
        masterSeed: int.parse(seedText),
        batchSize: int.parse(batchText),
        injectFailureAt: injectText.isEmpty ? null : int.parse(injectText),
        gitRevision: revision,
      ),
    );
    File(outputPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report.toMap())}\n',
      flush: true,
    );
    expect(report.invalidScenarioCount, 0, reason: outputPath);
    expect(report.failureCount, 0, reason: outputPath);
  });
}
