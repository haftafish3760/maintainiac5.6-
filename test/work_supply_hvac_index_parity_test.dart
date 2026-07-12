import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('HVAC indexed candidates preserve full-scan recall and order', () {
    const requiredFamilies = [
      ['dual', 'run', 'capacitor'],
      ['pleated', 'air', 'filter'],
      ['condensate', 'float', 'switch'],
      ['flame', 'sensor'],
      ['foil', 'tape'],
      ['hard', 'start', 'kit'],
      ['time', 'delay', 'relay'],
    ];
    for (final requiredParts in requiredFamilies) {
      final parity = receiptCatalogIndexParityForQa(
        catalogItems: workSupplyCatalogItems,
        requiredNameParts: requiredParts,
        tradeScope: 'HVAC',
      );
      expect(parity.indexedIds, parity.fullScanIds, reason: '$requiredParts');
      expect(parity.indexedIds, isNotEmpty, reason: '$requiredParts');
    }
  });

  test('HVAC parser retains target in a 50000-item catalog', () {
    final items = <WorkSupplyItem>[
      for (var index = 0; index < 25000; index++) _decoy(index),
      _target,
      for (var index = 25000; index < 49999; index++) _decoy(index),
    ];
    final first = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['dual', 'run', 'capacitor'],
      tradeScope: 'HVAC',
    );
    final second = receiptCatalogIndexParityForQa(
      catalogItems: items,
      requiredNameParts: const ['dual', 'run', 'capacitor'],
      tradeScope: 'HVAC',
    );
    expect(first.indexedIds, first.fullScanIds);
    expect(first.indexedIds, [_target.id]);
    expect(second.indexedIds, first.indexedIds);

    final match = matchReceiptLineToCatalog(
      'SUPPLY 45/5 MFD DUAL RUN CAPACITOR 440V',
      catalogItems: items,
      tradeScope: 'HVAC',
      maxCandidates: 80,
    );
    expect(match?.item.id, _target.id);
  });
}

const _target = WorkSupplyItem(
  id: 'HVAC-SCALE-TARGET',
  name: '45/5 MFD Dual Run Capacitor 440V',
  trade: 'HVAC',
  category: 'Controls and Electrical',
  system: 'Capacitors and Contactors',
  itemType: 'Dual Run Capacitors',
  variant: '45/5 MFD 440V',
  unit: 'each',
  aliases: ['45 5 dual cap', 'dual run capacitor'],
);

WorkSupplyItem _decoy(int index) {
  return WorkSupplyItem(
    id: 'HVAC-SCALE-$index',
    name: 'Synthetic HVAC Inventory Item $index',
    trade: 'HVAC',
    category: 'Scale QA',
    system: 'Synthetic',
    itemType: 'Decoy',
    variant: '$index unit',
    unit: 'each',
    aliases: const ['synthetic inventory decoy'],
  );
}
