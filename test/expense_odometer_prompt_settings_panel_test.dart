import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Expense settings explains that every expense needs an odometer reading',
    () async {
      final panelSource = await File(
        'lib/screens/expenses/settings/expense_odometer_prompt_settings.dart',
      ).readAsString();
      final localizationSource = await File(
        'lib/shared/localization/maintaniac_localizations.dart',
      ).readAsString();

      expect(panelSource, contains('expenseOdometerRequiredTitle'));
      expect(panelSource, contains('expenseOdometerRequiredExplanation'));
      expect(panelSource, isNot(contains('SwitchListTile')));
      expect(panelSource, isNot(contains('setOdometerPromptSuppressed')));
      expect(localizationSource, contains('Odometer Reading Required'));
      expect(
        localizationSource,
        contains('Every expense needs the vehicle odometer reading'),
      );
    },
  );
}
