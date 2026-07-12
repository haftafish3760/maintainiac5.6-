import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense receipt entry keeps a compact title and vehicle prompt', () {
    final header = File(
      'lib/screens/expenses/entry/expense_receipt_header.dart',
    ).readAsStringSync();
    final scaffold = File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsStringSync();
    final home = File(
      'lib/screens/expenses/home/expenses_home_screen.dart',
    ).readAsStringSync();

    expect(header, contains('const _ReceiptHeader({required this.title})'));
    expect(header, isNot(contains('required this.subtitle')));
    expect(scaffold, contains("'Expense Receipt'"));
    expect(
      scaffold,
      contains("'Select which vehicle this expense belongs to.'"),
    );
    expect(scaffold, isNot(contains('Record what was spent.')));
    expect(scaffold, isNot(contains('ReceiptDraftsPanel')));
    expect(home, contains('const ReceiptDraftsPanel()'));
  });
}
