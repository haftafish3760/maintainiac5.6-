@Timeout(Duration(minutes: 10))
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_baseline_diff.dart';
import 'support/qa_harness/qa_harness.dart';
import 'support/qa_harness/qa_suite_presets.dart';
import 'support/qa_harness/qa_threshold_gate.dart';
import 'support/work_supply_parser_qa/work_supply_parser_qa.dart';

void main() {
  test('work supply parser QA harness report', () async {
    const strict = bool.fromEnvironment('PARSER_QA_STRICT');
    const maxGeneratedCases = int.fromEnvironment(
      'PARSER_QA_MAX_GENERATED_CASES',
      defaultValue: 100,
    );
    const maxFailuresPerSuite = int.fromEnvironment(
      'PARSER_QA_MAX_FAILURES_PER_SUITE',
      defaultValue: 100,
    );
    const catalogSchemaSampleLimit = int.fromEnvironment(
      'PARSER_QA_CATALOG_SCHEMA_SAMPLE_LIMIT',
      defaultValue: 6000,
    );
    const aliasSampleLimit = int.fromEnvironment(
      'PARSER_QA_ALIAS_SAMPLE_LIMIT',
      defaultValue: 2500,
    );
    const profile = String.fromEnvironment(
      'PARSER_QA_PROFILE',
      defaultValue: 'smoke',
    );
    const preset = String.fromEnvironment('PARSER_QA_PRESET');
    const baselinePath = String.fromEnvironment('PARSER_QA_BASELINE');
    const suiteCsv = String.fromEnvironment('PARSER_QA_SUITES');
    const fixtureIds = String.fromEnvironment('PARSER_QA_FIXTURE_IDS');
    const mutationMode = String.fromEnvironment('PARSER_QA_MUTATION_MODE');
    const mutationScenarios = String.fromEnvironment(
      'PARSER_QA_MUTATION_SCENARIOS',
    );
    const mutationDryRun = bool.fromEnvironment(
      'PARSER_QA_MUTATION_DRY_RUN',
      defaultValue: true,
    );
    const shardId = String.fromEnvironment('PARSER_QA_SHARD_ID');
    const timeoutBudgetMs = int.fromEnvironment(
      'PARSER_QA_TIMEOUT_BUDGET_MS',
      defaultValue: 0,
    );
    const resumeFrom = String.fromEnvironment('PARSER_QA_RESUME_FROM');
    final suiteFilter = qaSuiteFilterFrom(suiteCsv: suiteCsv, preset: preset);
    final runConfig = QaRunConfig(
      profile: profile,
      preset: preset,
      baselinePath: baselinePath,
      maxGeneratedCases: maxGeneratedCases,
      maxFailuresPerSuite: maxFailuresPerSuite,
      catalogSchemaSampleLimit: catalogSchemaSampleLimit,
      aliasSampleLimit: aliasSampleLimit,
      fixtureIds: fixtureIds,
      mutationMode: mutationMode,
      mutationScenarios: mutationScenarios,
      mutationDryRun: mutationDryRun,
      shardId: shardId,
      timeoutBudgetMs: timeoutBudgetMs,
      resumeFrom: resumeFrom,
      suiteFilter: suiteFilter,
    );
    final context = QaContext(
      strict: strict,
      redactor: const QaRedactor(),
      profile: profile,
      maxGeneratedCases: maxGeneratedCases,
      maxFailuresPerSuite: maxFailuresPerSuite,
      catalogSchemaSampleLimit: catalogSchemaSampleLimit,
      aliasSampleLimit: aliasSampleLimit,
      suiteFilter: suiteFilter,
      thresholds: QaThresholds.forProfile(profile),
    );
    final harness = buildWorkSupplyParserQaHarness();
    final baseReport = await runQaHarnessWithThresholdGate(
      harness: harness,
      runConfig: runConfig,
      context: context,
    );
    final report = await appendQaBaselineDiff(
      report: baseReport,
      context: context,
      baselinePath: baselinePath,
    );
    final artifact = await writeQaReport(report: report);

    // ignore: avoid_print
    print(report.toSummary());
    // ignore: avoid_print
    print(
      'QA_ARTIFACT json=${artifact.timestampedJsonPath} '
      'latestJson=${artifact.latestJsonPath} '
      'latestSummary=${artifact.latestSummaryPath} '
      'packHealthJson=${artifact.timestampedPackHealthJsonPath} '
      'latestPackHealthJson=${artifact.latestPackHealthJsonPath}',
    );

    expect(report.hasBlockingFailures, isFalse, reason: report.toSummary());
    if (strict) {
      expect(report.failures, isEmpty, reason: report.toSummary());
    } else {
      expect(report.checked, greaterThan(0));
    }
  });
}
