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
}
