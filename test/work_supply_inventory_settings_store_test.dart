import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_settings_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'work_supply_inventory_settings_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('stores receipt assistance preferences', () async {
    final settings = await WorkSupplyInventorySettingsController.create();

    expect(settings.appAssistedReceipts, isFalse);
    expect(settings.localOnlyReceiptAssistance, isTrue);
    expect(settings.hasSeenWorkSupplyIntro, isFalse);

    await settings.setAppAssistedReceipts(true);
    await settings.setLocalOnlyReceiptAssistance(false);
    await settings.setHasSeenWorkSupplyIntro(true);

    expect(settings.appAssistedReceipts, isTrue);
    expect(settings.localOnlyReceiptAssistance, isFalse);
    expect(settings.hasSeenWorkSupplyIntro, isTrue);
  });

  test('tracks followed and hidden catalog paths', () async {
    final settings = await WorkSupplyInventorySettingsController.create();
    final item = searchWorkSupplies('drywall mud').first;

    await settings.setTradeFollowed(item.trade, true);
    await settings.setCategoryFollowed(item.trade, item.category, true);
    await settings.setItemFollowed(item, true);

    expect(settings.followsTrade(item.trade), isTrue);
    expect(settings.followsCategory(item.trade, item.category), isTrue);
    expect(settings.followsItem(item), isTrue);
    expect(settings.itemIsVisible(item), isTrue);

    await settings.setItemHidden(item, true);

    expect(settings.hidesItem(item), isTrue);
    expect(settings.followsItem(item), isFalse);
    expect(settings.itemIsVisible(item), isFalse);
  });

  test('show only followed catalog hides unrelated items', () async {
    final settings = await WorkSupplyInventorySettingsController.create();
    final followed = searchWorkSupplies('deck screws').first;
    final unrelated = searchWorkSupplies('copper 90').first;

    await settings.setShowOnlyFollowedCatalog(true);
    await settings.setTradeFollowed(followed.trade, true);

    expect(settings.itemIsVisible(followed), isTrue);
    expect(settings.itemIsVisible(unrelated), isFalse);
  });

  test('reset clears followed and hidden catalog choices', () async {
    final settings = await WorkSupplyInventorySettingsController.create();
    final item = searchWorkSupplies('gfci outlet').first;

    await settings.setTradeFollowed(item.trade, true);
    await settings.setCategoryHidden(item.trade, item.category, true);
    await settings.setItemHidden(item, true);

    await settings.resetCatalogPreferences();

    expect(settings.followedTrades, isEmpty);
    expect(settings.hiddenCategories, isEmpty);
    expect(settings.hiddenItems, isEmpty);
  });

  test(
    'tracks installed trade pack choices separately from visibility',
    () async {
      final settings = await WorkSupplyInventorySettingsController.create();
      final option = buildWorkSupplyTradePackOptions('Plumbing').first;

      expect(settings.hasInstalledTradePackOption(option), isFalse);

      await settings.setTradePackOptionInstalled(option, true);

      expect(settings.hasInstalledTradePackOption(option), isTrue);
      expect(settings.installedTradePackOptions, contains('plumbing:core'));

      await settings.setTradePackOptionInstalled(option, false);

      expect(settings.hasInstalledTradePackOption(option), isFalse);
    },
  );
}
