import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mixed allocation review stays hidden until a receipt is actually mixed',
    () async {
      final source = await File(
        'lib/screens/expenses/entry/expense_receipt_recap.dart',
      ).readAsString();

      expect(source, contains('Business or Personal is receipt-wide.'));
      expect(source, contains('line.use == _ExpenseLineUse.unclassified'));
      expect(source, contains('line.use == _ExpenseLineUse.split'));
    },
  );
}
