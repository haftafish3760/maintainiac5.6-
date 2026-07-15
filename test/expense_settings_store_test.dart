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

  test('recap tiles are visible by default and can be hidden', () async {
    final settings = await ExpenseSettingsController.create();

    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.hiddenRecapTiles, isEmpty);

    await settings.setRecapTileVisible('fuelSpend', false);

    expect(settings.recapTileVisible('fuelSpend'), isFalse);
    expect(settings.hiddenRecapTiles, ['fuelSpend']);

    await settings.setRecapTileVisible('fuelSpend', true);

    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.hiddenRecapTiles, isEmpty);
  });

  test('recap tile reset shows everything again', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setRecapTileVisible('fuelSpend', false);
    await settings.setRecapTileVisible('materialsSpend', false);
    await settings.resetRecapTiles();

    expect(settings.hiddenRecapTiles, isEmpty);
    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.recapTileVisible('materialsSpend'), isTrue);
  });

  test('receipt review style saves the expense receipt default', () async {
    final settings = await ExpenseSettingsController.create();

    expect(
      settings.receiptReviewStyle,
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
    expect(
      ExpenseReceiptReviewStyle.basicReceipt.label,
      'Basic receipt review',
    );
    expect(
      ExpenseReceiptReviewStyle.simpleAmounts.label,
      'Simple receipt review',
    );
    expect(
      ExpenseReceiptReviewStyle.fullItemDetails.label,
      'Detailed receipt review',
    );

    await settings.setReceiptReviewStyle(
      ExpenseReceiptReviewStyle.fullItemDetails,
    );

    expect(
      settings.receiptReviewStyle,
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      settings.toBackupMap(
        ownerUid: 'owner',
        exportedAtUtc: DateTime.utc(2026),
      ),
      containsPair('receiptReviewStyle', 'fullItemDetails'),
    );
  });

  test('receipt review style restores padded and case-varied values', () {
    expect(
      ExpenseReceiptReviewStyle.fromName(' basicReceipt '),
      ExpenseReceiptReviewStyle.basicReceipt,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName(' fullItemDetails '),
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('FULLITEMDETAILS'),
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('simpleAmounts'),
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('unknown'),
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
  });

  test('cloud sync and receipt retention choices persist for backup', () async {
    final settings = await ExpenseSettingsController.create();

    expect(settings.cloudSyncPreference, ExpenseCloudSyncPreference.manual);
    expect(
      settings.receiptCopyRetention,
      ExpenseReceiptCopyRetention.keepOptimizedCopy,
    );
    await settings.setCloudSyncPreference(ExpenseCloudSyncPreference.wifiOnly);
    await settings.setReceiptCopyRetention(
      ExpenseReceiptCopyRetention.cloudOnlyAfterVerifiedUpload,
    );

    final backup = settings.toBackupMap(
      ownerUid: 'owner',
      exportedAtUtc: DateTime.utc(2026),
    );
    expect(backup['cloudSyncPreference'], 'wifiOnly');
    expect(backup['receiptCopyRetention'], 'cloudOnlyAfterVerifiedUpload');
  });

  test(
    'receipt review style ignores corrupted non-string storage values',
    () async {
      final settings = await ExpenseSettingsController.create();
      final box = Hive.box<dynamic>(ExpenseSettingsController.boxName);

      await box.put('receiptReviewStyle', 17);

      expect(
        settings.receiptReviewStyle,
        ExpenseReceiptReviewStyle.simpleAmounts,
      );
    },
  );

  test(
    'expense settings scope can be optional for shared receipt widgets',
    () async {
      final source = await File(
        'lib/shared/state/expense_settings_store.dart',
      ).readAsString();

      expect(source, contains('static ExpenseSettingsController? maybeOf'));
      expect(
        source,
        contains(
          'getElementForInheritedWidgetOfExactType<ExpenseSettingsScope>',
        ),
      );
    },
  );
}
