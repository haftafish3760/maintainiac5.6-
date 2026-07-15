import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Expense settings exposes per-category odometer prompt controls',
    () async {
      final source = await File(
        'lib/screens/expenses/settings/expense_odometer_prompt_settings.dart',
      ).readAsString();

      expect(source, contains('Odometer Prompts By Category'));
      expect(source, contains('Ask for an odometer reading'));
      expect(source, contains('setOdometerPromptSuppressed'));
    },
  );
}
