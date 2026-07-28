import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt step indicator keeps all receipt steps explorable', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
    ).readAsStringSync();

    expect(source, contains('selected: itemIndex == index'));
    expect(source, contains('const Color(0xFFFFD166)'));
    expect(source, contains('completed: itemIndex < index'));
    expect(source, contains('const Color(0xFF2D7A4B)'));
    expect(source, contains('enabled: true'));
    expect(source, isNot(contains('color: itemIndex <= index')));
  });
}
