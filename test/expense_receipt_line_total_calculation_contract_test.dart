import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt line total derives from quantity and unit price', () {
    final editor = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor.dart',
    ).readAsStringSync();
    final derived = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_derived_fields.dart',
    ).readAsStringSync();
    final actions = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
    ).readAsStringSync();

    expect(
      editor.indexOf('_ExpenseCategorySearch('),
      lessThan(editor.indexOf('Item description')),
    );
    expect(
      editor.indexOf('_LineUseBanner('),
      lessThan(editor.indexOf('Item description')),
    );
    expect(derived, contains('double? get _calculatedLineSubtotal'));
    expect(derived, contains('quantity * unitPrice'));
    expect(
      derived,
      contains('_calculatedLineSubtotal ?? _enteredLineSubtotal'),
    );
    expect(actions, contains('final subtotal = _resolvedLineSubtotal ?? 0;'));
    expect(actions, isNot(contains('Enter the line subtotal first.')));
  });
}
