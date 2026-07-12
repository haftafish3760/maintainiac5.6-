import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('Electrical indexed candidates preserve full-scan recall and order', () {
    const requiredFamilies = [
      ['gfci', 'receptacle'],
      ['liquidtight', 'conduit'],
      ['thhn', 'copper', 'wire'],
      ['circuit', 'breaker'],
      ['wall', 'plate'],
      ['ground', 'rod'],
      ['smoke', 'alarm'],
    ];
    for (final requiredParts in requiredFamilies) {
      final parity = receiptCatalogIndexParityForQa(
        catalogItems: workSupplyCatalogItems,
        requiredNameParts: requiredParts,
        tradeScope: 'Electrical',
      );
      expect(parity.indexedIds, parity.fullScanIds, reason: '$requiredParts');
      expect(parity.indexedIds, isNotEmpty, reason: '$requiredParts');
    }
  });

  test('Electrical parser retains target in a 50000-item catalog', () {
    final items = <WorkSupplyItem>[
      for (var index = 0; index < 25000; index++) _decoy(index),
      _target,
      for (var index = 25000; index < 49999; index++) _decoy(index),
    ];
    final first = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['gfci', 'receptacle'],
      tradeScope: 'Electrical',
    );
    final second = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['gfci', 'receptacle'],
      tradeScope: 'Electrical',
    );
    expect(first.indexedIds, first.fullScanIds);
    expect(first.indexedIds, [_target.id]);
    expect(second.indexedIds, first.indexedIds);

    final match = matchReceiptLineToCatalog(
      'HD 20A GFCI RECEPTACLE WHITE',
      catalogItems: items,
      tradeScope: 'Electrical',
      maxCandidates: 80,
    );
    expect(match?.item.id, _target.id);
  });
}

const _target = WorkSupplyItem(
  id: 'ELECTRICAL-SCALE-TARGET',
  name: '20 Amp GFCI Receptacle White',
  trade: 'Electrical',
  category: 'Devices',
  system: 'Receptacles',
  itemType: 'GFCI Receptacle',
  variant: '20 Amp White',
  unit: 'each',
  aliases: ['20a gfi outlet white', 'ground fault receptacle'],
);

WorkSupplyItem _decoy(int index) {
  return WorkSupplyItem(
    id: 'ELECTRICAL-SCALE-$index',
    name: 'Synthetic Electrical Inventory Item $index',
    trade: 'Electrical',
    category: 'Scale QA',
    system: 'Synthetic',
    itemType: 'Decoy',
    variant: '$index unit',
    unit: 'each',
    aliases: const ['synthetic inventory decoy'],
  );
}
