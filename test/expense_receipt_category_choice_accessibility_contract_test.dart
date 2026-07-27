import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category choices expose selected button semantics', () async {
    final source = await File(
      'lib/screens/expenses/entry/expense_receipt_category_picker_widgets.dart',
    ).readAsString();

    expect(source, contains('return Semantics('));
    expect(source, contains('button: true'));
    expect(source, contains('selected: selected'));
    expect(source, contains('label: label'));
    expect(source, isNot(contains('child: ChoiceChip(')));
  });
}
