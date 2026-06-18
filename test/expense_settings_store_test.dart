import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_settings_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('quick category order saves without duplicates', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setQuickCategoryOrder([
      'Fuel',
      'fuel',
      'Materials',
      ' Materials ',
      'Parking',
    ]);

    expect(settings.quickCategoryOrder, ['Fuel', 'Materials', 'Parking']);
  });

  test('quick category add and remove update saved home buttons', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.addQuickCategory('Fuel');
    await settings.addQuickCategory('Meals');
    await settings.addQuickCategory('fuel');
    await settings.removeQuickCategory('FUEL');

    expect(settings.quickCategoryOrder, ['Meals']);
  });

  test('top three selection keeps the newest category first', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.useCategoryInTopThree('Parking');

    expect(settings.topThreeCategories, ['Parking', 'Fuel', 'Meals']);
  });

  test('reset restores release defaults', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setQuickCategoryOrder(['Parking', 'Tolls']);
    await settings.useCategoryInTopThree('Parking');
    await settings.resetCategoryLayout();

    expect(settings.quickCategoryOrder, isEmpty);
    expect(settings.topThreeCategories, ['Fuel', 'Meals', 'Materials']);
  });
}
