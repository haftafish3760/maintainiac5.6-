import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('mutation guard allows derived output collections only', () {
    const probe = MaintainiacMutationGuardProbe();
    final failures = probe.validateDerivedOutputWrites(
      operation: 'daily_recap',
      writeTargets: const [
        'accounts/acct_1/recaps/day_2026_07_03',
        'accounts/acct_1/exports/export_1',
      ],
    );

    expect(failures, isEmpty);
    expect(
      probe.isDerivedCollection('accounts/acct_1/invoices/invoice_1'),
      isTrue,
    );
  });

  test(
    'mutation guard blocks recaps exports and notifications mutating sources',
    () {
      const probe = MaintainiacMutationGuardProbe();
      final failures = probe.validateDerivedOutputWrites(
        operation: 'monthly_export',
        writeTargets: const [
          'accounts/acct_1/expenses/expense_1',
          'accounts/acct_1/trips/trip_1',
          'accounts/acct_1/inventory/item_1',
        ],
      );

      expect(
        failures,
        contains('monthly_export mutated source collection expenses'),
      );
      expect(
        failures,
        contains('monthly_export mutated source collection trips'),
      );
      expect(
        failures,
        contains('monthly_export mutated source collection inventory'),
      );
    },
  );

  test('mutation guard allows only explicitly scoped source operations', () {
    const probe = MaintainiacMutationGuardProbe();
    final failures = probe.validateSourceOperationWrites(
      operation: 'confirm_expense',
      writeTargets: const [
        'accounts/acct_1/expenses/expense_1',
        'accounts/acct_1/inventory/item_1',
      ],
      allowedSourceCollections: const {'expenses'},
    );

    expect(failures, [
      'confirm_expense wrote disallowed source collection inventory',
    ]);
  });

  test('mutation guard matrix captures clean and failing side effects', () {
    const matrix = maintainiacMutationGuardMatrix;

    expect(matrix.validate(), isEmpty);
    expect(
      matrix.toJson().toString(),
      contains('recap_writes_only_derived_outputs'),
    );
    expect(
      matrix.toJson().toString(),
      contains('export_mutating_expenses_blocked'),
    );
  });

  test('mutation guard matrix rejects mismatched expectations', () {
    const matrix = MaintainiacMutationGuardMatrix([
      MaintainiacMutationGuardCase(
        id: 'bad',
        operation: '',
        writeTargets: {'accounts/acct_1/expenses/expense_1'},
        allowedSourceCollections: {'expenses'},
        derivedOnly: true,
        expectedFailures: {},
        reason: '',
      ),
    ]);

    final failures = matrix.validate().join('\n');

    expect(failures, contains('bad missing operation'));
    expect(failures, contains('bad missing reason'));
    expect(
      failures,
      contains('bad expected failures do not match actual failures'),
    );
    expect(
      failures,
      contains('bad derived-only case must not allow source collections'),
    );
    expect(failures, contains('mutation guard matrix missing failing case'));
  });
}
