import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt exit offers draft recovery or explicit discard', () {
    final manualFlow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();
    final exitActions = File(
      'lib/screens/expenses/entry/expense_receipt_entry_exit_actions.dart',
    ).readAsStringSync();

    expect(manualFlow, contains("'Leave this receipt?'"));
    expect(manualFlow, contains("'Keep editing'"));
    expect(manualFlow, contains("'Exit without saving'"));
    expect(manualFlow, contains("'Save draft and exit'"));
    expect(exitActions, contains('_saveDraftNow()'));
    expect(exitActions, contains('deleteDraft(_draftId)'));
    expect(
      exitActions,
      contains('openAppSectionRoot(context, AppSection.expenses);'),
    );
    expect(exitActions, isNot(contains('Navigator.of(context).maybePop()')));
    expect(manualFlow, contains('Colors.redAccent'));
    expect(manualFlow, contains('backgroundColor: const Color(0xFF28A745)'));
  });
}
