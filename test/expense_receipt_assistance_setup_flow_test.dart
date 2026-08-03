import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Expense first-use receipt setup is full screen and conditional', () {
    final home = File(
      'lib/screens/expenses/home/expenses_home_screen.dart',
    ).readAsStringSync();
    final setup = File(
      'lib/screens/expenses/settings/expense_receipt_assistance_setup_screen.dart',
    ).readAsStringSync();

    expect(home, contains('hasCompletedExpenseReceiptSetup'));
    expect(home, contains('ExpenseReceiptAssistanceSetupScreen'));
    expect(setup, contains('class ExpenseReceiptAssistanceSetupScreen'));
    expect(setup, contains('Scaffold('));
    expect(setup, isNot(contains('showModalBottomSheet')));
    expect(setup, contains('Would you like help with your receipts?'));
    expect(setup, contains('Yes, help me'));
    expect(setup, contains('No, I will enter receipts myself'));
    expect(setup, contains('Local receipt extraction'));
    expect(setup, contains('ChatGPT-assisted receipts'));
    expect(setup, isNot(contains('Use Maintainiac AI when I choose it')));
  });

  test(
    'app-assisted Add Expense opens the full source chooser, manual does not',
    () {
      final attachment = File(
        'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
      ).readAsStringSync();

      expect(attachment, contains('openImportOptionsOnFirstBuild:'));
      expect(
        attachment,
        contains('receiptSettings?.appAssistedEnabledFor(_receiptCaptureArea)'),
      );
      expect(attachment, contains('!_isEditingReceipt'));
    },
  );
}
