import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('split ownership is never silently defaulted to fifty percent', () {
    final computedFields = File(
      'lib/screens/expenses/entry/expense_receipt_line_computed_fields.dart',
    ).readAsStringSync();
    final editorActions = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
    ).readAsStringSync();
    final editorDerived = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_derived_fields.dart',
    ).readAsStringSync();
    final recap = File(
      'lib/screens/expenses/entry/expense_receipt_recap_classification.dart',
    ).readAsStringSync();

    expect(
      computedFields,
      contains(
        "if (businessPercent == null && splitAllocation == null) return '';",
      ),
    );
    expect(editorDerived, contains('double? get _enteredBusinessPercent'));
    expect(editorDerived, isNot(contains('if (numeric == null) return .5')));
    expect(
      editorActions,
      contains('Enter a business percentage from 0 to 100 before saving'),
    );
    expect(editorActions, contains('_splitAllocationForEditedLine'));
    expect(recap, contains('Every split requires your allocation.'));
  });
}
