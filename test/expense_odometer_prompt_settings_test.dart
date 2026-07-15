import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_odometer_prompt_settings_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test('persists category-specific optional odometer prompt choices', () async {
    final settings = await ExpenseSettingsController.create();

    expect(settings.shouldPromptForOdometer('Materials'), isTrue);
    await settings.setOdometerPromptSuppressed('Materials', true);
    expect(settings.shouldPromptForOdometer('Materials'), isFalse);
    expect(settings.shouldPromptForOdometer('Fuel'), isTrue);

    await settings.setOdometerPromptEnabled(false);
    expect(settings.shouldPromptForOdometer('Fuel'), isFalse);
    expect(
      settings.toBackupMap(
        ownerUid: 'user-1',
        exportedAtUtc: DateTime.utc(2026, 7, 15),
      )['odometerPromptSuppressedCategories'],
      ['Materials'],
    );
  });
}
