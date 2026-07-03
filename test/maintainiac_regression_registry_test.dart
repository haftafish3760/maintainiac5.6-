import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('regression registry records permanent bug fixtures by area', () {
    const registry = maintainiacRegressionRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['caseCount'], greaterThanOrEqualTo(3));
    expect(registry.toJson().toString(), contains('INV-0001'));
    expect(registry.toJson().toString(), contains('EXP-0001'));
    expect(registry.toJson().toString(), contains('SYN-0001'));
    expect(registry.toJson().toString(), contains('inventory_parser'));
  });

  test(
    'regression registry rejects non-permanent or incomplete bug records',
    () {
      const registry = MaintainiacRegressionRegistry([
        MaintainiacRegressionCase(
          bugId: 'bad',
          description: '',
          rootCause: '',
          inputFixture: '',
          expectedBehavior: '',
          fixedVersion: '',
          area: 'inventory_parser',
          moduleTags: {'inventory'},
          permanentTest: 'work_supply_parser_generated_fixture_runner_test',
        ),
        MaintainiacRegressionCase(
          bugId: 'INV-0002',
          description: 'duplicate',
          rootCause: 'duplicate',
          inputFixture: 'fixture',
          expectedBehavior: 'expected',
          fixedVersion: '2026.07.03',
          area: 'inventory_parser',
          moduleTags: {'inventory', 'regression'},
          permanentTest:
              'test/work_supply_parser_generated_fixture_runner_test.dart',
        ),
        MaintainiacRegressionCase(
          bugId: 'INV-0002',
          description: 'duplicate again',
          rootCause: 'duplicate again',
          inputFixture: 'fixture',
          expectedBehavior: 'expected',
          fixedVersion: '2026.07.03',
          area: 'inventory_parser',
          moduleTags: {'inventory', 'regression'},
          permanentTest:
              'test/work_supply_parser_generated_fixture_runner_test.dart',
        ),
      ]);

      final failures = registry.validate().join('\n');

      expect(failures, contains('bad: bug id must look like AREA-0001'));
      expect(failures, contains('bad: missing description'));
      expect(failures, contains('bad: missing root cause'));
      expect(failures, contains('bad: permanent test must be a test/ path'));
      expect(failures, contains('bad: module tags must include regression'));
      expect(failures, contains('duplicate bug id INV-0002'));
      expect(
        failures,
        contains('regression registry missing area expense_parser'),
      );
      expect(failures, contains('regression registry missing area sync'));
    },
  );
}
