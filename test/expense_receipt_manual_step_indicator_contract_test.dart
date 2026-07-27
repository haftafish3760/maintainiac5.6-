import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manual receipt step indicator distinguishes current and completed work',
    () {
      final source = File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
      ).readAsStringSync();

      expect(source, contains('color: itemIndex == index'));
      expect(source, contains('const Color(0xFFFFD166)'));
      expect(source, contains('itemIndex < index'));
      expect(source, contains('const Color(0xFF2D7A4B)'));
      expect(source, isNot(contains('color: itemIndex <= index')));
    },
  );
}
