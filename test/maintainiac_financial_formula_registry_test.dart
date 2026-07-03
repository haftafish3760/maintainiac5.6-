import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('financial formula registry labels deterministic money formulas', () {
    const registry = maintainiacFinancialFormulaRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.toJson()['formulaCount'], greaterThanOrEqualTo(6));
    expect(registry.formulasFor('expenses'), isNotEmpty);
    expect(registry.formulasFor('inventory'), isNotEmpty);
    expect(registry.formulasFor('invoices'), isNotEmpty);
    expect(registry.toJson().toString(), contains('invoice_grand_total_cents'));
    expect(registry.toJson().toString(), contains('--plain-name'));
  });

  test('financial formula registry rejects mutable or broad formulas', () {
    const registry = MaintainiacFinancialFormulaRegistry([
      MaintainiacFinancialFormula(
        id: 'bad',
        module: 'expenses',
        description: '',
        inputs: {},
        output: '',
        roundingPolicy: MaintainiacMoneyRoundingPolicy.integerCentsOnly,
        mutatesSourceRecords: true,
        testCommand: 'flutter test test/bad.dart',
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(failures, contains('bad missing description'));
    expect(failures, contains('bad missing inputs'));
    expect(failures, contains('bad missing output'));
    expect(
      failures,
      contains('bad financial formula must not mutate source records'),
    );
    expect(
      failures,
      contains('bad should be individually runnable with --plain-name'),
    );
    expect(
      failures,
      contains('financial formula registry missing module inventory'),
    );
  });
}
