import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Expense receipt setup sends Android Back through onboarding steps', () {
    final setup = File(
      'lib/screens/expenses/settings/expense_receipt_assistance_setup_screen.dart',
    ).readAsStringSync();

    expect(setup, contains('onPopInvokedWithResult:'));
    expect(setup, contains('canPop: _leaving'));
    expect(setup, contains('if (!didPop && !_saving) _handleBack()'));
    expect(setup, contains('setState(() => _wantsReceiptHelp = false)'));
    expect(setup, contains('setState(() => _leaving = true)'));
  });
}
