import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt exit offers draft recovery or explicit discard', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();

    expect(source, contains("'Leave this receipt?'"));
    expect(source, contains("'Keep editing'"));
    expect(source, contains("'Exit without saving'"));
    expect(source, contains("'Save draft and exit'"));
    expect(source, contains('_saveDraftNow()'));
    expect(source, contains('deleteDraft(_draftId)'));
    expect(source, contains('Colors.redAccent'));
    expect(source, contains('backgroundColor: const Color(0xFF28A745)'));
  });
}
