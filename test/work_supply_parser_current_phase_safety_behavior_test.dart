import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('inventory parser current-phase safety behavior', () {
    test('receipt noise never becomes an inventory material match', () {
      const noiseLines = [
        'SUBTOTAL 123.45',
        'SALES TAX 8.64',
        'TOTAL 132.09',
        'CREDIT CARD APPROVED',
        'CHANGE DUE 0.00',
      ];

      for (final line in noiseLines) {
        expect(
          matchReceiptLineToCatalog(line, maxCandidates: 300),
          isNull,
          reason: 'Receipt noise must not create inventory candidates: $line',
        );
      }
    });

    test('dangerous generic words stay unknown or low-confidence alone', () {
      const dangerousWords = [
        'PVC',
        'tape',
        'filter',
        'box',
        'adapter',
        'coupling',
        'elbow',
        'pipe',
        'wire',
        'valve',
      ];

      for (final word in dangerousWords) {
        final match = matchReceiptLineToCatalog(word, maxCandidates: 300);
        expect(
          match == null || match.confidence < .82,
          isTrue,
          reason: 'Generic word must not force a confident match: $word',
        );
      }
    });

    test('trade context separates plumbing PVC from electrical conduit', () {
      final plumbing = matchReceiptLineToCatalog(
        '3/4 PVC COUPLING SCH40',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      final electrical = matchReceiptLineToCatalog(
        '3/4 PVC COND COUPLING',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );

      expect(plumbing, isNotNull);
      expect(plumbing!.item.trade, 'Plumbing');
      expect(plumbing.item.name.toLowerCase(), contains('pvc'));
      expect(plumbing.confidenceLevel, ReceiptConfidenceLevel.good);
      expect(electrical, isNotNull);
      expect(electrical!.item.trade, 'Electrical');
      expect(electrical.item.name.toLowerCase(), contains('conduit'));
      expect(electrical.confidenceLevel, ReceiptConfidenceLevel.good);
    });

    test('tape context separates HVAC foil tape from electrical tape', () {
      final hvac = matchReceiptLineToCatalog(
        'UL181 FOIL TAPE',
        tradeScope: 'HVAC',
        maxCandidates: 320,
      );
      final electrical = matchReceiptLineToCatalog(
        'BLACK ELEC TAPE',
        tradeScope: 'Electrical',
        maxCandidates: 320,
      );

      expect(hvac, isNotNull);
      expect(hvac!.item.trade, 'HVAC');
      expect(hvac.item.name.toLowerCase(), contains('tape'));
      expect(electrical, isNotNull);
      expect(electrical!.item.trade, 'Electrical');
      expect(electrical.item.name.toLowerCase(), contains('tape'));
      expect(electrical.item.id, isNot(hvac.item.id));
    });

    test('search index returns empty for impossible mixed-token query', () {
      final results = searchWorkSupplies(
        'banana submarine copper pex thermostat',
      );

      expect(results, isEmpty);
    });

    test(
      'Hive inventory store remains local authority for stock state',
      () async {
        final hiveDirectory = await Directory.systemTemp.createTemp(
          'work_supply_current_phase_authority_',
        );
        Hive.init(hiveDirectory.path);
        try {
          final store = await WorkSupplyInventoryStore.create();
          final item = _catalogItem(
            'Plumbing',
            'Copper 90 Elbow',
            variant: '1/2',
          );

          final first = await store.addStock(
            _record(
              item,
              onHand: 5,
              storageArea: 'Truck 1',
              storageDetail: 'Drawer A',
              sourceReceiptLineId: 'RCP-HIVE-L1',
            ),
          );
          await store.addStock(
            _record(
              item,
              onHand: 3,
              storageArea: 'Truck 1',
              storageDetail: 'Drawer A',
              sourceReceiptLineId: 'RCP-HIVE-L2',
            ),
          );
          await store.markOutOfStock(first);

          final inventory = store.loadInventory();
          final events = store.loadEvents();
          final transactions = store.loadTransactions();

          expect(inventory, hasLength(1));
          expect(inventory.single.id, first.id);
          expect(inventory.single.onHand, 0);
          expect(events.first.type, WorkSupplyStockEventType.countAdjusted);
          expect(
            transactions.first.type,
            WorkSupplyStockEventType.countAdjusted,
          );
          expect(
            transactions.where(
              (transaction) =>
                  transaction.type == WorkSupplyStockEventType.stockAdded,
            ),
            hasLength(2),
          );
        } finally {
          await Hive.close();
          if (hiveDirectory.existsSync()) {
            await hiveDirectory.delete(recursive: true);
          }
        }
      },
    );
  });
}

WorkSupplyItem _catalogItem(
  String trade,
  String namePart, {
  String variant = '',
}) {
  return workSupplyCatalogItems.firstWhere(
    (item) =>
        item.trade == trade &&
        item.name.toLowerCase().contains(namePart.toLowerCase()) &&
        (variant.isEmpty || item.variant.contains(variant)),
  );
}

WorkSupplyInventoryRecord _record(
  WorkSupplyItem item, {
  required double onHand,
  required String storageArea,
  required String storageDetail,
  required String sourceReceiptLineId,
}) {
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: onHand,
    threshold: 1,
    lastUnitCost: 2.5,
    storageArea: storageArea,
    storageDetail: storageDetail,
    receiptLinked: true,
    sourceReceiptId: 'RCP-HIVE',
    sourceReceiptLineId: sourceReceiptLineId,
  );
}
