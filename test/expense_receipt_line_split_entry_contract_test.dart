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
      final categoryPicker = await File(
        'lib/screens/expenses/entry/expense_receipt_category_picker.dart',
      ).readAsString();
      final actions = await File(
        'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
      ).readAsString();
      final lineChoice = await File(
        'lib/screens/expenses/entry/expense_receipt_line_actions.dart',
      ).readAsString();
      final scaffold = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
      ).readAsString();
      final splitDetails = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_split_percent_actions.dart',
      ).readAsString();

      expect(editor, contains('ExpenseSplitAllocationMethod _splitMethod'));
      expect(editor, contains("label: 'Item description'"));
      expect(editor, contains('onChanged: _chooseLineUse'));
      expect(editor, isNot(contains('_SplitAllocationFields(')));
      expect(editor, contains('_unitPriceLabel'));
      expect(editor, contains('Printed line total'));
      expect(editor, isNot(contains('_ReceiptItemDetailsCard(')));
      expect(
        editor.indexOf('_ExpenseCategorySearch('),
        lessThan(editor.indexOf('_LineUseBanner(')),
      );
      expect(
        editor.indexOf('_LineUseBanner('),
        lessThan(editor.indexOf("label: 'Item description'")),
      );
      expect(
        editor.indexOf("label: 'Item description'"),
        lessThan(editor.indexOf('label: _unitPriceLabel')),
      );
      expect(
        editor.indexOf('label: _unitPriceLabel'),
        lessThan(editor.indexOf('_categoryRule.quantityLabel')),
      );
      expect(categoryPicker, contains('Category (optional)'));
      expect(categoryPicker, contains("'CATEGORY (OPTIONAL)'"));
      expect(categoryPicker, contains("'Next'"));
      expect(editor, contains("label: 'Unit of measure'"));
      expect(editor, contains('_ReceiptItemLineTotal('));
      expect(editor, contains('bottomNavigationBar: SafeArea('));
      expect(editor, contains("'Add Item'"));
      expect(editor, contains('labelMaxWidthFactor: .94'));
      expect(editor, isNot(contains('ReceiptFormPanel(')));
      expect(fields, isNot(contains('class _ReceiptItemDetailsCard')));
      expect(fields, contains('class _ReceiptItemLineTotal'));
      expect(fields, contains('fillColor: Color(0xFF101315)'));
      expect(fields, contains("'Line total'"));
      expect(fields, isNot(contains('class _SplitAllocationFields')));
      expect(actions, contains('Business amount cannot exceed'));
      expect(actions, contains('Future<void> _chooseLineUse'));
      expect(actions, contains('_SplitDetailsScreen(line: previewLine'));
      expect(actions, contains('ExpenseSplitAllocationMethod.amount'));
      expect(actions, contains('final unitPrice = _unitPriceForSave'));
      expect(lineChoice, contains("? 'Add Item'"));
      expect(lineChoice, contains('onTap: onAddItem'));
      expect(lineChoice, isNot(contains('_showReceiptItemChoice')));
      expect(scaffold, contains('onAddItem: () => _editLine('));
      expect(
        scaffold,
        contains(
          'onEdit: (index) =>\n                    _editLine(index: index, initial: _lines[index])',
        ),
      );
      expect(splitDetails, contains('class _SplitDetailsScreen'));
      expect(splitDetails, contains("'Split Details'"));
      expect(splitDetails, contains("'Percentage (%)'"));
      expect(splitDetails, contains(r"'Amount (\$)'"));
      expect(splitDetails, contains("'APPLY SPLIT'"));
      expect(splitDetails, contains('Allocation is valid.'));
    },
  );
}
