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

    test(
      'mixed-trade PVC shorthand stays review-level without enough evidence',
      () {
        const lines = [
          'PVC EL 3/4',
          'PVC 90 1/2',
          'CODO PVC 3/4',
          '3/4 PVC COUPLING',
        ];

        for (final line in lines) {
          final match = matchReceiptLineToCatalog(line, maxCandidates: 400);

          expect(
            match == null || match.confidence <= .81,
            isTrue,
            reason:
                'Cross-trade PVC shorthand must not become a false-confident '
                'single answer without trade/job/merchant evidence: $line '
                '=> ${match?.item.path} confidence=${match?.confidence}',
          );
        }
      },
    );

    test(
      'mixed receipt sibling lines do not auto-confirm ambiguous materials',
      () {
        const receiptLines = [
          'HD SUPPLY PVC EL 3/4 2.18',
          '12/2 NM-B WIRE 25FT 24.98',
          'MERV 8 AIR FILTER 20X25X1 11.97',
          '1/2 PEX CRIMP RING 10PK 4.28',
          'BLACK ELEC TAPE 3.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final pvc = parsed['HD SUPPLY PVC EL 3/4 2.18'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(2),
          reason:
              'The regression must include enough sibling evidence to tempt '
              'trade inference without letting it auto-confirm ambiguity.',
        );
        expect(
          pvc == null || pvc.confidence <= .81,
          isTrue,
          reason:
              'A mixed receipt can contain electrical, HVAC, and plumbing '
              'lines together; sibling purchases must not convert PVC EL into '
              'a final confident trade answer without explicit line evidence.',
        );
      },
    );

    test(
      'mixed receipt sibling lines do not auto-confirm ambiguous copper tubing',
      () {
        const receiptLines = [
          'SUPPLY 3/4 COPPER TUBING 18.22',
          '12/2 NM-B WIRE 25FT 24.98',
          'MERV 8 AIR FILTER 20X25X1 11.97',
          '3/4 PVC COND COUPLING 2.18',
          '1/2 PEX CRIMP RING 10PK 4.28',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final copper = parsed['SUPPLY 3/4 COPPER TUBING 18.22'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough plumbing/electrical/HVAC '
              'siblings to tempt cross-trade inference without allowing a '
              'bare copper tubing line to jump to a final answer.',
        );
        expect(
          copper == null || copper.confidence <= .81,
          isTrue,
          reason:
              'A mixed receipt can contain plumbing, electrical, and HVAC '
              'neighbors together; sibling evidence must not convert bare '
              'copper tubing into a confident trade answer without explicit '
              'line-level clues.',
        );
      },
    );

    test(
      'mixed Spanish sibling lines do not auto-confirm ambiguous PVC shorthand',
      () {
        const receiptLines = [
          'FERRETERIA CODO PVC 3/4 2.18',
          'CABLE 12/2 NM-B 25FT 24.98',
          'DRENAJE CONDENSADO PVC 3/4 5.28',
          'VALVULA BOLA 1/2 8.49',
          'FILTRO AIRE 20X25X1 MERV 8 11.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(
              line,
              localePackId: 'es-US',
              maxCandidates: 420,
            ),
        };
        final pvc = parsed['FERRETERIA CODO PVC 3/4 2.18'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough Spanish-language plumbing, '
              'electrical, and HVAC siblings to tempt trade inference without '
              'allowing a bare PVC shorthand line to become a final answer.',
        );
        expect(
          pvc == null || pvc.confidence <= .81,
          isTrue,
          reason:
              'A mixed Spanish receipt can contain plumbing, electrical, and '
              'HVAC lines together; sibling and locale evidence must not '
              'convert CODO PVC into a confident single-trade answer without '
              'explicit line-level trade evidence.',
        );
      },
    );

    test('filter dimensions require HVAC air-filter evidence', () {
      final generic = matchReceiptLineToCatalog(
        'FILTER 20X25X1',
        maxCandidates: 400,
      );
      final hvac = matchReceiptLineToCatalog(
        'MERV 8 AIR FILTER 20X25X1',
        tradeScope: 'HVAC',
        maxCandidates: 400,
      );

      expect(
        generic == null || generic.confidence <= .81,
        isTrue,
        reason:
            'A bare filter size can mean water, oil, HVAC, or other filters '
            'and must stay review-level without air/MERV/furnace evidence.',
      );
      expect(hvac, isNotNull);
      expect(hvac!.item.trade, 'HVAC');
      expect(hvac.item.name.toLowerCase(), contains('filter'));
      expect(hvac.confidenceLevel, ReceiptConfidenceLevel.good);
    });

    test(
      'new Core service-stock generic families require specific evidence',
      () {
        const genericLines = [
          'BUSHING',
          'WIRE CONNECTOR',
          'CONDENSATE DRAIN',
          'SALT PELLETS',
          'CONNECTOR KIT',
        ];

        for (final line in genericLines) {
          final match = matchReceiptLineToCatalog(line, maxCandidates: 420);

          expect(
            match == null || match.confidence <= .81,
            isTrue,
            reason:
                'Generic service-stock wording must not become a confident '
                'single answer without stronger item/trade evidence: $line '
                '=> ${match?.item.path} confidence=${match?.confidence}',
          );
        }

        final antiShort = matchReceiptLineToCatalog(
          'MC ANTI SHORT BUSHING 100PK',
          tradeScope: 'Electrical',
          maxCandidates: 420,
        );
        expect(antiShort, isNotNull);
        expect(antiShort!.item.trade, 'Electrical');
        expect(antiShort.item.name, contains('Anti Short Bushing'));
        expect(antiShort.confidenceLevel, ReceiptConfidenceLevel.good);

        final drainGun = matchReceiptLineToCatalog(
          'CONDENSATE DRAIN GUN',
          tradeScope: 'HVAC',
          maxCandidates: 420,
        );
        expect(drainGun, isNotNull);
        expect(drainGun!.item.trade, 'HVAC');
        expect(drainGun.item.name, contains('Condensate Drain Gun'));
        expect(drainGun.confidenceLevel, ReceiptConfidenceLevel.good);

        final softenerSalt = matchReceiptLineToCatalog(
          '40LB WATER SOFTENER SALT PELLETS',
          tradeScope: 'Plumbing',
          maxCandidates: 420,
        );
        expect(softenerSalt, isNotNull);
        expect(softenerSalt!.item.trade, 'Plumbing');
        expect(
          softenerSalt.item.name.toLowerCase(),
          contains('water softener salt'),
        );
        expect(softenerSalt.confidenceLevel, ReceiptConfidenceLevel.good);
      },
    );

    test(
      'bare PVC COND shorthand stays review-level even in electrical scope',
      () {
        for (final line in const [
          'GRAINGER PVC COND 3/4 5.28',
          'GRAINGER PVC COND 3/4 45.08',
        ]) {
          final match = matchReceiptLineToCatalog(
            line,
            tradeScope: 'Electrical',
            maxCandidates: 320,
          );

          expect(match, isNotNull, reason: line);
          expect(match!.item.trade, 'Electrical', reason: line);
          expect(
            match.item.name.toLowerCase(),
            contains('conduit'),
            reason: line,
          );
          expect(
            match.confidence,
            lessThanOrEqualTo(.81),
            reason:
                'Bare PVC COND can mean conduit/condensate shorthand and must '
                'remain review-level without stronger product evidence: $line',
          );
        }
      },
    );

    test(
      'local supply-house mixed receipt does not auto-confirm PVC COND shorthand',
      () {
        const receiptLines = [
          'COUNTER SALE PVC COND 3/4 5.28',
          '12/2 NM-B WIRE 25FT 24.98',
          '3/4X3/8 LINE SET 50FT 89.00',
          '1/2 PEX TEE 2.49',
          'ELEC TAPE BLK 3.97',
        ];

        final parsed = {
          for (final line in receiptLines)
            line: matchReceiptLineToCatalog(line, maxCandidates: 420),
        };
        final pvcCond = parsed['COUNTER SALE PVC COND 3/4 5.28'];

        expect(
          parsed.values.whereType<ReceiptLineMatch>().length,
          greaterThanOrEqualTo(3),
          reason:
              'The regression must include enough local/supply-house sibling '
              'evidence to tempt PEH routing without letting merchant flavor '
              'or neighboring lines convert PVC COND into a final answer.',
        );
        expect(pvcCond, isNotNull);
        expect(
          pvcCond!.confidence,
          lessThanOrEqualTo(.81),
          reason:
              'Local or counter-sale merchant wording plus mixed PEH siblings '
              'must not auto-confirm PVC COND 3/4 without explicit line-level '
              'conduit or condensate evidence.',
        );
      },
    );

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
