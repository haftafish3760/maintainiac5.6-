import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_item_identity_resolver.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('normalizes common spoken size wording for parser/manual input', () {
    expect(
      normalizeWorkSupplyItemSize('half inch x three quarter inch x half inch'),
      '1/2 in x 3/4 in x 1/2 in',
    );
    expect(normalizeWorkSupplyItemSize('1-1/4"'), '1-1/4 in');
    expect(
      normalizeWorkSupplyItemSize('1/2 x 3/4 x 1/2'),
      '1/2 in x 3/4 in x 1/2 in',
    );
  });

  test('resolver matches mixed copper tee draft to existing catalog item', () {
    final catalogItem = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.trade == 'Plumbing' &&
          item.category == 'Fittings' &&
          item.system == 'Copper' &&
          item.itemType == 'Tees' &&
          item.variant == '1/2 x 3/4 x 1/2',
    );

    final resolved = resolveWorkSupplyItemIdentity(
      draft: const WorkSupplyItemIdentityDraft(
        trade: 'Plumbing',
        category: 'Fittings',
        template: 'T',
        composition: 'Copper',
        size: 'half inch x three quarter inch x half inch',
        aliases: ['copper t', 'reducing tee'],
      ),
      catalogItems: workSupplyCatalogItems,
    );

    expect(resolved.created, isFalse);
    expect(resolved.item.id, catalogItem.id);
    expect(resolved.canonicalKey, canonicalWorkSupplyItemKey(catalogItem));
  });

  test('resolver matches singular elbow draft to plural catalog template', () {
    final catalogItem = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.trade == 'Plumbing' &&
          item.category == 'Fittings' &&
          item.system == 'Copper' &&
          item.itemType == '90 Elbows' &&
          item.variant == '1/2 in',
    );

    final resolved = resolveWorkSupplyItemIdentity(
      draft: const WorkSupplyItemIdentityDraft(
        trade: 'Plumbing',
        category: 'Fittings',
        template: '90 elbow',
        composition: 'Copper',
        size: '1/2',
        aliases: ['copper 90', 'ell'],
      ),
      catalogItems: workSupplyCatalogItems,
    );

    expect(resolved.created, isFalse);
    expect(resolved.item.id, catalogItem.id);
  });

  test('unknown draft creates one stable user item identity', () {
    const draft = WorkSupplyItemIdentityDraft(
      trade: 'Plumbing',
      category: 'Fittings',
      template: 'Test Fitting',
      composition: 'Unobtainium',
      size: '7/8',
      aliases: ['field-only part'],
    );

    final first = resolveWorkSupplyItemIdentity(draft: draft);
    final second = resolveWorkSupplyItemIdentity(
      draft: draft,
      customItems: [first.item],
    );

    expect(first.created, isTrue);
    expect(second.created, isFalse);
    expect(second.item.id, first.item.id);
    expect(first.item.id, startsWith('USER-'));
  });

  group('inventory store canonical item merging', () {
    late Directory hiveDirectory;

    setUp(() async {
      hiveDirectory = await Directory.systemTemp.createTemp(
        'work_supply_identity_store_test_',
      );
      Hive.init(hiveDirectory.path);
    });

    tearDown(() async {
      await Hive.close();
      if (hiveDirectory.existsSync()) {
        await hiveDirectory.delete(recursive: true);
      }
    });

    test(
      'merges manual/parser item with catalog item at same destination',
      () async {
        final store = await WorkSupplyInventoryStore.create();
        final catalogItem = workSupplyCatalogItems.firstWhere(
          (item) =>
              item.trade == 'Plumbing' &&
              item.category == 'Fittings' &&
              item.system == 'Copper' &&
              item.itemType == '90 Elbows' &&
              item.variant == '1/2 in',
        );
        const manualSameItem = WorkSupplyItem(
          id: 'manual-parser-copper-90',
          name: 'half inch copper ninety',
          trade: 'Plumbing',
          category: 'Fittings',
          system: 'Copper',
          itemType: '90 Elbow',
          variant: 'half inch',
          unit: 'each',
          aliases: ['copper 90', 'ell'],
        );

        await store.addStock(
          WorkSupplyInventoryRecord(
            item: catalogItem,
            onHand: 4,
            threshold: 2,
            lastUnitCost: 2.50,
            storageArea: 'Work Truck 1 inventory',
            receiptLinked: true,
            sourceMerchantName: 'Lowes',
            loggedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await store.addStock(
          WorkSupplyInventoryRecord(
            item: manualSameItem,
            onHand: 6,
            threshold: 2,
            lastUnitCost: 2.75,
            storageArea: 'Work Truck 1 inventory',
            receiptLinked: true,
            sourceMerchantName: 'Supply House',
            loggedAt: DateTime.utc(2026, 2, 1),
          ),
        );

        final records = store.loadInventory();
        final transactions = store.recentTransactionsForItem(catalogItem);

        expect(records, hasLength(1));
        expect(records.single.onHand, 10);
        expect(records.single.item.id, catalogItem.id);
        expect(transactions, hasLength(2));
        expect(
          transactions.map((entry) => entry.sourceMerchantName),
          containsAll(['Lowes', 'Supply House']),
        );
      },
    );
  });
}
