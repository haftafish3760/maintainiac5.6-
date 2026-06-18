import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_custom_catalog_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'work_supply_custom_catalog_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('saves a user-created item as reusable custom catalog data', () async {
    final store = await WorkSupplyCustomCatalogStore.create();
    const item = WorkSupplyItem(
      id: 'USER-test-fence-post',
      name: '8 ft pressure treated fence post',
      trade: 'Fencing',
      category: 'Posts and Framework',
      system: 'Wood Posts',
      itemType: 'Fence Posts',
      variant: 'receipt wording: PT POST 8FT',
      unit: 'each',
      aliases: ['PT POST 8FT'],
    );

    await store.saveItem(item);

    final saved = store.loadItems().single;
    expect(saved.id, item.id);
    expect(
      saved.path,
      'Fencing / Posts and Framework / Wood Posts / Fence Posts',
    );
    expect(store.searchItems('pt post'), hasLength(1));
  });

  test('merged search shows custom catalog items before starter results', () {
    const custom = WorkSupplyItem(
      id: 'USER-custom-barbed-wire',
      name: 'Custom 1320 ft barbed wire roll',
      trade: 'Fencing',
      category: 'Wire and Farm Fence',
      system: 'Barbed Wire',
      itemType: 'Wire Rolls',
      variant: 'local supplier',
      unit: 'roll',
      aliases: ['bob wire'],
    );

    final results = mergeWorkSupplySearchResults(
      query: 'barbed wire',
      customItems: const [custom],
    );

    expect(results.first.id, custom.id);
    expect(results.map((item) => item.id), contains(custom.id));
  });
}
