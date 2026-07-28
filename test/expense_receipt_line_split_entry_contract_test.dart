import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manual receipt split entry supports percentage and dollar methods',
    () async {
      final editor = await File(
        'lib/screens/expenses/entry/expense_receipt_line_editor.dart',
      ).readAsString();
      final fields = await File(
        'lib/screens/expenses/entry/expense_receipt_line_fields.dart',
      ).readAsString();
      final actions = await File(
        'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
      ).readAsString();
      final lineChoice = await File(
        'lib/screens/expenses/entry/expense_receipt_line_actions.dart',
      ).readAsString();

      expect(editor, contains('ExpenseSplitAllocationMethod _splitMethod'));
      expect(editor, contains('Printed item description'));
      expect(editor, contains('Price each'));
      expect(editor, contains('Printed line total'));
      expect(editor, contains('Category is optional.'));
      expect(editor, isNot(contains('ReceiptFormPanel(')));
      expect(fields, contains('Business portion of this item'));
      expect(fields, contains('Dollar amount'));
      expect(fields, contains('The remaining amount is personal.'));
      expect(fields, contains(r'Business ${_money(amount)} | Personal'));
      expect(actions, contains('Business amount cannot exceed'));
      expect(actions, contains('ExpenseSplitAllocationMethod.amount'));
      expect(actions, contains('final unitPrice = _unitPriceForSave'));
      expect(lineChoice, contains("label: 'Business'"));
      expect(lineChoice, contains("label: 'Personal'"));
      expect(lineChoice, contains("label: 'Split'"));
      expect(lineChoice, contains("? 'Add Item'"));
    },
  );
}
