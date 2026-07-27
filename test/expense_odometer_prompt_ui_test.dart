import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipts use the shared odometer prompt when added', () async {
    final panel = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_odometer_panel.dart',
    ).readAsString();
    final prompt = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_odometer_prompt.dart',
    ).readAsString();
    final lifecycle = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_lifecycle_helpers.dart',
    ).readAsString();
    final manualDetails = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_details_widgets.dart',
    ).readAsString();

    expect(panel, contains('Add the current odometer to include it with this expense.'));
    expect(panel, contains('Add Odometer'));
    expect(panel, isNot(contains('RecordFormPanel')));
    expect(prompt, isNot(contains("Don't ask again")));
    expect(prompt, contains('openOdometerEntryResult'));
    expect(prompt, contains('Add Odometer To Expense'));
    expect(prompt, contains('Use For Expense'));
    expect(prompt, contains('_expenseOdometerReading'));
    expect(lifecycle, isNot(contains('_promptForOdometerIfNeeded')));
    expect(prompt, isNot(contains('_promptForOdometerIfNeeded')));
    expect(manualDetails, contains('_ManualReceiptOdometerAction'));
    expect(
      manualDetails,
      contains('Enter your current odometer to add it to the receipt.'),
    );
  });
}
