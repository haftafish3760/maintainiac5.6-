import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('sync scenario runner proves local-first mirror behavior', () {
    final results = const MaintainiacSyncScenarioRunner().runAll();

    expect(results, hasLength(5));
    expect(results.every((result) => result.passed), isTrue);
    expect(
      results.map((result) => result.scenario),
      containsAll([
        'sync.local_write_before_mirror',
        'sync.dirty_marker_lifecycle',
        'sync.network_policy_matrix',
        'sync.restart_and_conflict_policy',
        'sync.mirror_payload_parity',
      ]),
    );
  });

  test('security scenario runner proves privacy and scope behavior', () {
    final results = const MaintainiacSecurityScenarioRunner().runAll();

    expect(results, hasLength(4));
    expect(results.every((result) => result.passed), isTrue);
    expect(
      results.map((result) => result.scenario),
      containsAll([
        'security.ownership_isolation',
        'security.forbidden_data_scan',
        'security.permission_denial',
        'security.export_scope',
      ]),
    );
    expect(
      results
          .singleWhere(
            (result) => result.scenario == 'security.forbidden_data_scan',
          )
          .metrics['unsafeMatches'],
      greaterThanOrEqualTo(3),
    );
  });

  test('financial scenario runner proves deterministic money behavior', () {
    final results = const MaintainiacFinancialScenarioRunner().runAll();

    expect(results, hasLength(3));
    expect(results.every((result) => result.passed), isTrue);
    expect(
      results.map((result) => result.scenario),
      containsAll([
        'financial.expense_adjustment_math',
        'financial.tax_allocation_math',
        'financial.invoice_estimate_read_only_math',
      ]),
    );
  });

  test('performance scenario runner proves large-data budgets', () {
    final results = const MaintainiacPerformanceBudgetRunner().runAll();

    expect(results, hasLength(3));
    expect(results.every((result) => result.passed), isTrue);
    expect(
      results.map((result) => result.scenario),
      containsAll([
        'performance.generated_dataset_budget',
        'performance.storage_shape_budget',
        'performance.search_index_budget',
      ]),
    );
    expect(
      results
          .singleWhere(
            (result) => result.scenario == 'performance.search_index_budget',
          )
          .metrics['maxCandidates'],
      lessThan(100000),
    );
  });

  test(
    'accessibility localization runner proves release UI language gates',
    () {
      final results = const MaintainiacAccessibilityLocalizationRunner()
          .runAll();

      expect(results, hasLength(3));
      expect(results.every((result) => result.passed), isTrue);
      expect(
        results.map((result) => result.scenario),
        containsAll([
          'accessibility.review_surface',
          'localization.locale_unit_coverage',
          'localization.translated_review_reasons',
        ]),
      );
      expect(
        results
            .singleWhere(
              (result) =>
                  result.scenario == 'localization.locale_unit_coverage',
            )
            .metrics['localeCount'],
        greaterThanOrEqualTo(3),
      );
    },
  );

  test('cost quota runner proves cloud usage stays budgeted and opt-in', () {
    final results = const MaintainiacCostQuotaRunner().runAll();

    expect(results, hasLength(3));
    expect(results.every((result) => result.passed), isTrue);
    expect(
      results.map((result) => result.scenario),
      containsAll([
        'cost_quota.no_live_cloud_in_local_qa',
        'cost_quota.local_qa_budget',
        'cost_quota.cloud_assist_opt_in',
      ]),
    );
    expect(
      results
          .singleWhere(
            (result) => result.scenario == 'cost_quota.local_qa_budget',
          )
          .metrics['maxLiveWritesPerQaRun'],
      0,
    );
  });
}
