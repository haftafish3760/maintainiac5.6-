import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('Plumbing indexed candidates preserve full-scan recall and order', () {
    const requiredFamilies = [
      ['pex', 'drop-ear'],
      ['push-fit', 'supply', 'stop'],
      ['cpvc', 'coupling'],
      ['abs', 'sanitary', 'tee'],
      ['dishwasher', 'branch', 'tailpiece'],
      ['cleanout', 'plug'],
      ['shower', 'cartridge'],
    ];
    for (final requiredParts in requiredFamilies) {
      final parity = receiptCatalogIndexParityForQa(
        catalogItems: workSupplyCatalogItems,
        requiredNameParts: requiredParts,
        tradeScope: 'Plumbing',
      );
      expect(parity.indexedIds, parity.fullScanIds, reason: '$requiredParts');
      expect(parity.indexedIds, isNotEmpty, reason: '$requiredParts');
    }
  });

  test('Plumbing index preserves legacy fallback for an absent token', () {
    final parity = receiptCatalogIndexParityForQa(
      catalogItems: workSupplyCatalogItems,
      requiredNameParts: const ['token-that-does-not-exist'],
      tradeScope: 'Plumbing',
    );
    expect(parity.indexedIds, parity.fullScanIds);
    expect(parity.indexedIds.length, 12510);
  });

  test('Plumbing index retains target in a 50000-item catalog', () {
    final target = workSupplyCatalogItems.firstWhere(
      (item) =>
          item.trade == 'Plumbing' &&
          item.name.toLowerCase().contains('push-fit supply stop'),
    );
    final items = <WorkSupplyItem>[
      for (var index = 0; index < 25000; index++) _decoy(index),
      target,
      for (var index = 25000; index < 49999; index++) _decoy(index),
    ];
    final first = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['push-fit', 'supply', 'stop'],
      tradeScope: 'Plumbing',
    );
    final second = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['push-fit', 'supply', 'stop'],
      tradeScope: 'Plumbing',
    );
    expect(first.indexedIds, first.fullScanIds);
    expect(first.indexedIds, [target.id]);
    expect(second.indexedIds, first.indexedIds);
  });
}

WorkSupplyItem _decoy(int index) {
  return WorkSupplyItem(
    id: 'PLUMBING-SCALE-$index',
    name: 'Synthetic Plumbing Inventory Item $index',
    trade: 'Plumbing',
    category: 'Scale QA',
    system: 'Synthetic',
    itemType: 'Decoy',
    variant: '$index unit',
    unit: 'each',
    aliases: const ['synthetic inventory decoy'],
  );
}
