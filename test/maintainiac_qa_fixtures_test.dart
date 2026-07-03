import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('fixture catalog accepts reviewed behavior fixtures', () {
    const catalog = MaintainiacFixtureCatalog([
      MaintainiacFixtureDescriptor(
        id: 'expense_json_smoke',
        kind: MaintainiacFixtureKind.json,
        module: 'expenses',
        path: 'test/fixtures/expenses/expense_smoke.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: 'expense total remains deterministic',
      ),
      MaintainiacFixtureDescriptor(
        id: 'inventory_bug_regression',
        kind: MaintainiacFixtureKind.bugRegression,
        module: 'inventory',
        path: 'test/fixtures/work_supply_parser/regressions.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: 'ambiguous PVC stays review-only',
      ),
    ]);

    expect(catalog.validate(), isEmpty);
    expect(catalog.toJson().toString(), contains('bugRegression'));
    expect(catalog.toJson().toString(), contains('expenses'));
  });

  test('fixture catalog rejects duplicate or unreviewed weak evidence', () {
    const catalog = MaintainiacFixtureCatalog([
      MaintainiacFixtureDescriptor(
        id: 'duplicate',
        kind: MaintainiacFixtureKind.bugRegression,
        module: '',
        path: '',
        owner: '',
        synthetic: true,
        reviewed: false,
      ),
      MaintainiacFixtureDescriptor(
        id: 'duplicate',
        kind: MaintainiacFixtureKind.json,
        module: 'expenses',
        path: 'test/fixtures/expenses/expense.json',
        owner: 'qa',
        synthetic: true,
        reviewed: true,
        expectedBehavior: '',
      ),
    ]);

    final failures = catalog.validate().join('\n');

    expect(failures, contains('duplicate fixture duplicate'));
    expect(failures, contains('missing module'));
    expect(failures, contains('missing path'));
    expect(failures, contains('missing owner'));
    expect(failures, contains('missing expected behavior'));
    expect(failures, contains('bug regression fixtures must be reviewed'));
  });
}
