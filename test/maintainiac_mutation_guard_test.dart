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
}
