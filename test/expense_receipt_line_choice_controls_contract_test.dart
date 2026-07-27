import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt line choices use rectangular semantic controls', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_line_fields.dart',
    ).readAsStringSync();

    expect(source, contains('class _LineChoiceButton'));
    expect(source, contains('minimumSize: const Size(0, 36)'));
    expect(source, contains('borderRadius: BorderRadius.circular(5)'));
    expect(source, contains('selected: selected'));
    expect(source, isNot(contains('ChoiceChip(')));
  });
}
