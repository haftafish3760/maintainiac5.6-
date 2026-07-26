import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every expense receipt requires an odometer entry', () async {
    final panel = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_odometer_panel.dart',
    ).readAsString();
    final prompt = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_odometer_prompt.dart',
    ).readAsString();
    final lifecycle = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_lifecycle_helpers.dart',
    ).readAsString();

    expect(panel, contains('Expense odometer'));
    expect(panel, contains('Required before saving this expense'));
    expect(prompt, isNot(contains("Don't ask again")));
    expect(prompt, contains('Expense Odometer'));
    expect(prompt, contains('_expenseOdometerReading'));
    expect(lifecycle, isNot(contains('_promptForOdometerIfNeeded')));
    expect(prompt, isNot(contains('_promptForOdometerIfNeeded')));
  });
}
