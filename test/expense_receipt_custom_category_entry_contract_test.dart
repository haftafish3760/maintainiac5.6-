import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a typed custom Expense category is retained on the saved line',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
      ).readAsString();

      expect(
        source,
        contains(
          '_availableExpenseCategoryNames(context).contains(typedCategory)',
        ),
      );
    },
  );
}
