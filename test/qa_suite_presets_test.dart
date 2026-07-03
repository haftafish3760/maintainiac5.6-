import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_suite_presets.dart';

void main() {
  test('explicit suite filter overrides named presets', () {
    expect(
      qaSuiteFilterFrom(
        suiteCsv: ' inventory.security_privacy, qa.threshold_gate ',
        preset: 'quick',
      ),
      {'inventory.security_privacy', 'qa.threshold_gate'},
    );
  });

  test('quick preset contains fast non-parser harness safety suites', () {
    final suites = qaSuiteFilterFrom(suiteCsv: '', preset: 'quick');

    expect(suites, contains('inventory.security_privacy'));
    expect(suites, contains('inventory.boundary_guard'));
    expect(suites, contains('inventory.no_live_services_contract'));
    expect(suites, contains('inventory.review_safety_contract'));
    expect(suites, contains('inventory.result_contract'));
    expect(suites, contains('inventory.evidence_attribution'));
    expect(suites, contains('inventory.pack_lifecycle'));
    expect(suites, contains('inventory.pack_recovery_contract'));
    expect(suites, contains('inventory.pack_health_score'));
    expect(suites, contains('inventory.scalability'));
    expect(suites, contains('inventory.runtime_profile_contract'));
    expect(suites, contains('inventory.runtime_measurement'));
    expect(suites, contains('inventory.generated_manifest_contract'));
    expect(
      suites,
      contains('inventory.generated_fixture_performance_contract'),
    );
    expect(suites, contains('inventory.failure_taxonomy_contract'));
    expect(suites, contains('inventory.fixture_governance'));
    expect(suites, contains('inventory.fixture_coverage_matrix'));
    expect(suites, contains('inventory.fixture_corpus_contract'));
    expect(suites, contains('inventory.holdout_fixture_contract'));
    expect(suites, contains('inventory.determinism'));
    expect(suites, contains('inventory.metamorphic_variants'));
    expect(suites, contains('inventory.property_cases'));
    expect(suites, contains('inventory.trade_context'));
    expect(suites, contains('inventory.conflict_graph'));
    expect(suites, contains('inventory.ranked_candidate_accuracy'));
    expect(suites, contains('inventory.merchant_rules'));
    expect(suites, contains('inventory.noise_lines'));
    expect(suites, contains('inventory.accuracy_budget'));
    expect(suites, contains('inventory.economics_contract'));
    expect(suites, contains('inventory.estimate_section_ranking'));
    expect(suites, contains('inventory.confidence_calibration'));
    expect(suites, contains('inventory.math_reconciliation'));
    expect(suites, contains('inventory.separation_safety'));
    expect(suites, contains('inventory.locale_contract'));
    expect(suites, contains('inventory.telemetry_contract'));
    expect(suites, contains('inventory.device_storage_contract'));
    expect(suites, contains('inventory.correction_feedback_contract'));
    expect(suites, contains('inventory.release_manifest'));
    expect(suites, contains('inventory.release_orchestration_contract'));
    expect(suites, contains('inventory.release_shard_manifest'));
    expect(suites, contains('inventory.release_signoff_manifest'));
    expect(suites, contains('inventory.harness_registry'));
    expect(suites, contains('inventory.known_debt_ledger'));
    expect(suites, contains('inventory.artifact_contract'));
    expect(suites, contains('inventory.artifact_retention_contract'));
    expect(suites, contains('inventory.admin_report_contract'));
    expect(suites, contains('inventory.execution_command_contract'));
    expect(suites, contains('inventory.portability_contract'));
    expect(suites, contains('inventory.harness_maintainability_contract'));
    expect(suites, contains('inventory.parser_platform_contract'));
    expect(suites, contains('inventory.category_reuse_contract'));
    expect(suites, contains('inventory.data_provenance_contract'));
    expect(suites, contains('inventory.legal_safety_contract'));
    expect(suites, contains('inventory.validation_strategy_contract'));
    expect(suites, contains('inventory.slo_metrics_contract'));
    expect(suites, contains('inventory.mutation_contract'));
    expect(suites, contains('inventory.mutation_scenario_matrix'));
    expect(suites, contains('inventory.mutation_dry_run_plan'));
    expect(suites, contains('inventory.mutation_fault_probe'));
    expect(suites, contains('inventory.mutation_runner_contract'));
    expect(suites, contains('inventory.requirement_coverage'));
    expect(suites, contains('inventory.profile_matrix'));
    expect(suites, contains('inventory.baseline_contract'));
    expect(suites, contains('qa.threshold_gate'));
    expect(suites, isNot(contains('inventory.changed_item_impact')));
    expect(suites, isNot(contains('inventory.catalog_schema')));
    expect(suites, isNot(contains('inventory.golden_fixtures')));
  });

  test('fixtures preset keeps semantic fixture work isolated', () {
    expect(qaSuiteFilterFrom(suiteCsv: '', preset: 'fixtures'), {
      'inventory.golden_fixtures',
      'inventory.review_safety_contract',
      'inventory.result_contract',
      'inventory.evidence_attribution',
      'inventory.pack_lifecycle',
      'inventory.pack_recovery_contract',
      'inventory.pack_health_score',
      'inventory.scalability',
      'inventory.no_live_services_contract',
      'inventory.runtime_profile_contract',
      'inventory.runtime_measurement',
      'inventory.generated_manifest_contract',
      'inventory.generated_fixture_performance_contract',
      'inventory.failure_taxonomy_contract',
      'inventory.fixture_governance',
      'inventory.fixture_coverage_matrix',
      'inventory.fixture_corpus_contract',
      'inventory.holdout_fixture_contract',
      'inventory.changed_item_impact',
      'inventory.determinism',
      'inventory.metamorphic_variants',
      'inventory.separation_safety',
      'inventory.conflict_graph',
      'inventory.ranked_candidate_accuracy',
      'inventory.accuracy_budget',
      'inventory.estimate_section_ranking',
      'inventory.telemetry_contract',
      'inventory.device_storage_contract',
      'inventory.correction_feedback_contract',
      'inventory.release_manifest',
      'inventory.release_orchestration_contract',
      'inventory.release_shard_manifest',
      'inventory.release_signoff_manifest',
      'inventory.harness_registry',
      'inventory.known_debt_ledger',
      'inventory.artifact_contract',
      'inventory.artifact_retention_contract',
      'inventory.admin_report_contract',
      'inventory.execution_command_contract',
      'inventory.portability_contract',
      'inventory.harness_maintainability_contract',
      'inventory.parser_platform_contract',
      'inventory.category_reuse_contract',
      'inventory.data_provenance_contract',
      'inventory.legal_safety_contract',
      'inventory.validation_strategy_contract',
      'inventory.slo_metrics_contract',
      'inventory.mutation_contract',
      'inventory.mutation_scenario_matrix',
      'inventory.mutation_dry_run_plan',
      'inventory.mutation_fault_probe',
      'inventory.mutation_runner_contract',
      'inventory.requirement_coverage',
      'inventory.profile_matrix',
      'inventory.baseline_contract',
      'qa.threshold_gate',
    });
  });

  test('catalog preset keeps broad catalog scans isolated', () {
    expect(qaSuiteFilterFrom(suiteCsv: '', preset: 'catalog'), {
      'inventory.catalog_schema',
      'inventory.catalog_coverage',
      'inventory.alias_conflicts',
      'inventory.changed_item_impact',
      'inventory.pack_lifecycle',
      'inventory.pack_health_score',
      'inventory.scalability',
      'qa.threshold_gate',
    });
  });
}
