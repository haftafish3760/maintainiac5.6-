import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom category dialog uses the spacious dark settings treatment', () {
    final source = File(
      'lib/screens/expenses/settings/expense_settings_screen.dart',
    ).readAsStringSync();

    expect(source, contains('class _AddCustomCategoryDialog'));
    expect(source, contains('maxWidth: 520'));
    expect(source, contains('horizontal: 20, vertical: 28'));
    expect(source, contains("'Category name'"));
    expect(source, contains("'Add category'"));
    expect(source, contains('minimumSize: const Size.fromHeight(52)'));
  });
}
