import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review preserves OCR wording and requires split confirmation', () {
    final applyActions = File(
      'lib/screens/expenses/entry/expense_receipt_entry_parse_apply_actions.dart',
    ).readAsStringSync();
    final editorActions = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart',
    ).readAsStringSync();
    final lineFields = File(
      'lib/screens/expenses/entry/expense_receipt_line_computed_fields.dart',
    ).readAsStringSync();

    expect(
      applyActions,
      contains(
        'description: sourceText.trim().isEmpty ? line.description : sourceText',
      ),
    );
    expect(lineFields, contains("if (businessPercent == null) return '';"));
    expect(editorActions, contains('_enteredBusinessPercent'));
    expect(
      editorActions,
      contains(
        'Enter a business percentage for this split line before saving.',
      ),
    );
  });
}
