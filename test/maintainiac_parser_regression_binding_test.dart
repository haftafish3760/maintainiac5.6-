import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('parser regression bindings cover required consumer risk families', () {
    const registry = maintainiacParserRegressionBindingRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['bindingCount'], 4);
    expect(registry.toJson().toString(), contains('INVPARSER-0001'));
    expect(registry.toJson().toString(), contains('EXPPARSER-0002'));
    expect(
      registry.toJson().toString(),
      contains('expense_receipt_parser:draft_storage_lifecycle'),
    );
  });

  test('parser regression bindings reject duplicate or unowned regressions', () {
    const badRegistry = MaintainiacParserRegressionBindingRegistry([
      MaintainiacParserRegressionBinding(
        consumerId: 'expense_receipt_parser',
        familyId: 'privacy_redaction',
        permanentCommand: 'dart test bad',
        regression: MaintainiacRegressionCase(
          bugId: 'BAD-001',
          description: 'Bad case',
          rootCause: 'Bad root cause',
          inputFixture: 'bad_fixture',
          expectedBehavior: 'bad behavior',
          fixedVersion: '2026.07.03',
          area: 'expense_parser',
          moduleTags: {'expenses'},
          permanentTest: 'bad_test',
        ),
      ),
      MaintainiacParserRegressionBinding(
        consumerId: 'expense_receipt_parser',
        familyId: 'privacy_redaction',
        permanentCommand: 'flutter test test/bad_test.dart',
        regression: MaintainiacRegressionCase(
          bugId: 'BAD-001',
          description: 'Duplicate case',
          rootCause: 'Duplicate root cause',
          inputFixture: 'bad_fixture_2',
          expectedBehavior: 'bad behavior 2',
          fixedVersion: '2026.07.03',
          area: 'expense_parser',
          moduleTags: {'parser'},
          permanentTest: 'bad_test_2',
        ),
      ),
    ]);

    final failures = badRegistry.validate().join('\n');

    expect(failures, contains('BAD-001 needs focused flutter command'));
    expect(failures, contains('BAD-001 must be tagged parser'));
    expect(
      failures,
      contains('BAD-001 must tag owning consumer expense_receipt_parser'),
    );
    expect(failures, contains('duplicate parser regression BAD-001'));
    expect(
      failures,
      contains(
        'missing parser regression binding work_supply_inventory_parser:dangerous_ambiguity_context',
      ),
    );
  });
}
