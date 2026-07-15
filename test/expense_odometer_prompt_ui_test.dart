import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every Expense receipt keeps optional odometer entry available',
    () async {
      final panel = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_odometer_panel.dart',
      ).readAsString();
      final prompt = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_odometer_prompt.dart',
      ).readAsString();

      expect(panel, contains('Optional vehicle odometer'));
      expect(panel, contains('No reading added to this expense'));
      expect(prompt, contains("Don't ask again for \$category"));
      expect(prompt, contains('_expenseOdometerReading'));
    },
  );
}
