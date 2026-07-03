import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('performance budget registry labels harness performance budgets', () {
    const registry = maintainiacPerformanceBudgetRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['budgetCount'], greaterThanOrEqualTo(6));
    expect(
      registry.budgetsFor('qa_backbone'),
      hasLength(greaterThanOrEqualTo(2)),
    );
    expect(
      registry.toJson().toString(),
      contains('surgical_rerun_router_budget'),
    );
    expect(
      registry.toJson().toString(),
      contains('parser_generated_fixture_run'),
    );
  });

  test('performance budget registry rejects missing or broad budgets', () {
    const registry = MaintainiacPerformanceBudgetRegistry([
      MaintainiacPerformanceBudget(
        id: 'bad',
        kind: MaintainiacPerformanceBudgetKind.coldStart,
        module: '',
        maxDurationMs: 0,
        maxMemoryMb: 0,
        measurementCommand: 'echo bad',
        failureAction: '',
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(failures, contains('bad missing module'));
    expect(failures, contains('bad needs positive duration budget'));
    expect(failures, contains('bad needs positive memory budget'));
    expect(failures, contains('bad needs focused measurement command'));
    expect(failures, contains('bad missing failure action'));
    expect(
      failures,
      contains('performance budget registry missing kind indexing'),
    );
  });
}
