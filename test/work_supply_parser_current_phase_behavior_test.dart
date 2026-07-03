import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_export.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_receipt_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_receipt_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_staging.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_manifest.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';

void main() {
  group('inventory parser current-phase executable behavior', () {
    test(
      'normalizes product wording and merchant aliases into item matches',
      () {
        final merchantNames = {
          'THE HOME DEPOT #4612': 'home depot',
          'LOWE S PRO DESK': 'lowes',
          'FERG WTRWORKS': 'ferguson',
          'GRAINGER WILL CALL': 'grainger',
        };

        for (final entry in merchantNames.entries) {
          expect(normalizeMerchantName(entry.key), entry.value);
        }

        final halfInchPex = matchReceiptLineToCatalog(
          'LOWES 1/2IN PEX CRMP ELL 90 BR',
          tradeScope: 'Plumbing',
          maxCandidates: 300,
        );
        final spelledOutPex = matchReceiptLineToCatalog(
          'LOWES HALF INCH BRASS PEX CRIMP NINETY ELBOW',
          tradeScope: 'Plumbing',
          maxCandidates: 300,
        );

        expect(halfInchPex, isNotNull);
        expect(spelledOutPex, isNotNull);
        expect(halfInchPex!.item.id, spelledOutPex!.item.id);
        expect(halfInchPex.confidenceLevel, ReceiptConfidenceLevel.good);
        expect(halfInchPex.needsReview, isTrue);
      },
    );

    test('category inference uses trade context without forcing ambiguity', () {
      final plumbing = matchReceiptLineToCatalog(
        'PVC 90 3/4',
        tradeScope: 'Plumbing',
        maxCandidates: 300,
      );
      final electrical = matchReceiptLineToCatalog(
        'PVC COND 3/4 90',
        tradeScope: 'Electrical',
        maxCandidates: 300,
      );
      final unscoped = matchReceiptLineToCatalog(
        'PVC 90 3/4',
        maxCandidates: 300,
      );

      expect(plumbing, isNotNull);
      expect(plumbing!.item.trade, 'Plumbing');
      expect(plumbing.needsReview, isTrue);
      expect(electrical, isNotNull);
      expect(electrical!.item.trade, 'Electrical');
      expect(electrical.needsReview, isTrue);
      expect(
        unscoped == null || unscoped.confidence < plumbing.confidence,
        isTrue,
        reason: 'Unscoped ambiguous PVC must not outrank scoped context.',
      );
    });

    test('search/indexing supports aliases, sizes, and abbreviations', () {
      final pexResults = searchWorkSupplies('half inch pex crimp elbow');
      final electricalResults = searchWorkSupplies('3/4 pvc conduit coupling');
      final hvacResults = searchWorkSupplies('pleated air filter');

      expect(pexResults, isNotEmpty);
      expect(
        pexResults.any(
          (item) =>
              item.trade == 'Plumbing' &&
              item.name.toLowerCase().contains('pex'),
        ),
        isTrue,
      );
      expect(electricalResults, isNotEmpty);
      expect(electricalResults.first.trade, 'Electrical');
      expect(hvacResults, isNotEmpty);
      expect(hvacResults.first.trade, 'HVAC');
    });

    test('trusted identities beat catalog guesses but stay reviewable', () {
      final expected = searchWorkSupplies(
        '3/4 in Push-Fit Coupling',
      ).firstWhere((item) => item.trade == 'Plumbing');
      final match = matchReceiptLineToCatalog(
        'LOCAL SUPPLY X-TRUCK-774433 GENERIC COUPLING',
        trustedItemIdentityIds: {'X-TRUCK-774433': expected.id},
        tradeScope: 'Plumbing',
        maxCandidates: 1,
      );

      expect(match, isNotNull);
      expect(match!.item.id, expected.id);
      expect(match.source, ReceiptMatchSource.trustedItemIdentity);
      expect(match.confidence, .99);
      expect(match.needsReview, isTrue);
    });

    test(
      'receipt line mapping feeds review-only inventory and job actions',
      () {
        final copperElbow = _catalogItem(
          'Plumbing',
          'Copper 90 Elbow',
          variant: '1/2',
        );
        final parsed = ExpenseReceiptParseResult(
          sourceText: 'LOWES 1/2 COPPER 90 12.00 SHOP TOWELS 4.00',
          merchantName: 'LOWES',
          enteredSubtotal: 16,
          enteredTax: 1.28,
          lines: [
            ExpenseReceiptLineRecord(
              id: 'L1',
              description: '1/2 COPPER 90',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 2,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
              catalogItemId: copperElbow.id,
              catalogItemName: copperElbow.name,
              catalogItemPath: copperElbow.path,
              catalogMatchConfidence: .91,
              catalogMatchedTerms: const ['1/2', 'copper', '90'],
              parserConfidence: .88,
            ),
            const ExpenseReceiptLineRecord(
              id: 'L2',
              description: 'SHOP TOWELS',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 4,
            ),
          ],
        );

        final draft = buildWorkSupplyParsedReceiptDraft(
          parsed: parsed,
          receiptId: 'RCP-current-phase',
          loggedAt: DateTime.utc(2026, 7, 2),
          storageArea: 'Truck 1',
          merchantName: 'LOWES',
          source: ReceiptProcessingSource.importedText,
        );

        expect(draft.canCommitInventory, isFalse);
        expect(draft.inventoryLineCount, 1);
        expect(draft.businessOnlyLineCount, 1);
        expect(draft.lines.first.kind, ReceiptLineKind.inventory);
        expect(draft.lines.first.canStageForJobOrEstimate, isTrue);
        expect(draft.lines.first.suggestedMaterialActions, [
          'addToInventory',
          'addToActiveJob',
          'addToEstimateDraft',
          'stageForInvoiceProof',
        ]);
        expect(draft.lines.first.taxRate, closeTo(.08, .001));
        expect(draft.inventoryRecords.single.lastUnitCost, closeTo(6.48, .001));
        expect(workSupplyInventoryLineCanCommit(draft.lines.first), isFalse);
        expect(
          workSupplyInventoryLineCanCommit(
            draft.lines.first.confirmedAssistedReview(),
          ),
          isTrue,
        );
      },
    );

    test(
      'duplicate receipt lines map by source line id, not item id alone',
      () {
        final item = _catalogItem(
          'Plumbing',
          'Copper 90 Elbow',
          variant: '1/2',
        );
        final records = [
          _record(item, lineId: 'RCP-1-L1', onHand: 1),
          _record(item, lineId: 'RCP-1-L2', onHand: 1),
        ];
        const editedSecondLine = ReceiptLineDraft(
          kind: ReceiptLineKind.inventory,
          description: '1/2 in Copper 90 Elbow',
          receiptLineId: 'RCP-1-L2',
          inventoryItemId: 'same-item',
          quantity: 3,
          unitsPerPackage: 2,
          subtotal: 30,
          taxRate: .1,
          storageArea: 'Truck 2',
          storageDetail: 'Bin B',
        );

        final index = stagedInventoryRecordIndexForLine(
          records,
          editedSecondLine,
        );
        final synced = syncedInventoryRecordForLine(
          record: records[index],
          line: editedSecondLine,
        );

        expect(index, 1);
        expect(synced.sourceReceiptLineId, 'RCP-1-L2');
        expect(synced.onHand, 6);
        expect(records.first.sourceReceiptLineId, 'RCP-1-L1');
        expect(records.first.storageArea, 'Truck 1');
      },
    );

    test('financial totals include tax allocation and markup behavior', () {
      final item = _catalogItem('Plumbing', 'Copper 90 Elbow', variant: '1/2');
      final record = _record(
        item,
        lineId: 'RCP-tax-L1',
        onHand: 10,
        lineSubtotal: 100,
        taxRate: .06,
        markupRate: .25,
        packagesPurchased: 2,
        unitsPerPackage: 5,
      );
      final receiptLine = WorkSupplyInventoryReceiptLine(
        id: 'WRL-tax',
        item: item,
        displayName: item.name,
        quantity: 2,
        unitsPerPackage: 5,
        subtotal: 100,
        taxRate: .06,
      );

      expect(record.totalUnitsPurchased, 10);
      expect(record.lineTax, 6);
      expect(record.unitCostWithTax, 10.6);
      expect(record.billableUnitCost, 13.25);
      expect(receiptLine.totalWithTax, 106);
      expect(receiptLine.unitCostWithTax, 10.6);
    });

    test('import/export safety keeps pack manifests Firestore-read safe', () {
      final manifest = buildWorkSupplyTradePackManifest(
        const WorkSupplyTradePackOption(
          tradeName: 'Plumbing',
          marketScope: WorkSupplyMarketScope.residential,
          tier: WorkSupplyTradePackTier.core,
          itemCount: 1,
          estimatedRawBytes: 2048,
          estimatedCompressedBytes: 1024,
          storagePath: 'catalog-packs/plumbing/residential/core',
          localePackId: 'en-US',
          countryCodes: ['US'],
        ),
        generatedAt: DateTime.utc(2026, 7, 2),
      );
      final exported = WorkSupplyInventoryExportSnapshot(
        exportedAt: DateTime.utc(2026, 7, 2),
        inventoryRecords: [
          _record(
            _catalogItem('Plumbing', 'Copper 90 Elbow', variant: '1/2'),
            lineId: 'RCP-export-L1',
            sourceReceiptId: 'RCP-export',
          ),
        ],
        stockEvents: const [],
      );

      expect(manifest.isFirestoreReadSafe, isTrue);
      expect(manifest.firestoreManifestReadCount, lessThanOrEqualTo(2));
      expect(manifest.firestoreItemDocumentReadCount, 0);
      expect(
        manifest.toMap()['deliveryMode'],
        'trade_pack_manifest_storage_chunks',
      );
      expect(exported.toInventoryCsv(), contains('source_receipt_line_id'));
      expect(exported.toInventoryCsv(), contains('RCP-export-L1'));
      expect(exported.toManifest()['inventoryRecordCount'], 1);
    });

    test('receipt and invoice feed preserves source evidence immutably', () {
      const parsedLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: '1/2 in Copper 90 Elbow',
        receiptLineId: 'RCP-source-L1',
        inventoryItemId: 'MI-COPPER-90',
        rawReceiptText: 'LOWES HALF COP ELL 90',
        parserConfidence: .91,
        parserReviewLabel: 'Good',
        parserReviewReason: 'Catalog match found from receipt text.',
        parserNeedsReview: false,
        originalParsedDescription: '1/2 in Copper 90 Elbow',
        originalParsedInventoryItemId: 'MI-COPPER-90',
        originalParsedInventoryPath: 'Plumbing / Fittings / Copper',
        reviewAction: 'parsed',
      );

      final confirmed = parsedLine.confirmedAssistedReview();
      final corrected = parsedLine.copyWith(
        description: '3/4 in Copper 90 Elbow',
        inventoryItemId: 'MI-COPPER-90-075',
        reviewAction: 'edited',
      );

      expect(parsedLine.rawReceiptText, 'LOWES HALF COP ELL 90');
      expect(parsedLine.requiresInventoryConfirmation, isTrue);
      expect(confirmed.rawReceiptText, parsedLine.rawReceiptText);
      expect(confirmed.originalParsedInventoryItemId, 'MI-COPPER-90');
      expect(corrected.wasChangedFromParsedGuess, isTrue);
      expect(corrected.originalParsedInventoryItemId, 'MI-COPPER-90');
      expect(
        corrected.suggestedMaterialActions,
        contains('stageForInvoiceProof'),
      );
    });

    test(
      'Hive receipt persistence keeps parser review and source metadata',
      () async {
        final hiveDirectory = await Directory.systemTemp.createTemp(
          'work_supply_current_phase_behavior_',
        );
        Hive.init(hiveDirectory.path);
        try {
          final store = await WorkSupplyInventoryReceiptStore.create();
          final item = _catalogItem(
            'Plumbing',
            'Copper 90 Elbow',
            variant: '1/2',
          );
          final receipt = WorkSupplyInventoryReceiptRecord(
            id: 'WRS-current-phase',
            source: WorkSupplyInventoryIntakeSource.photoAssist,
            merchantName: 'LOWES',
            receiptDate: DateTime.utc(2026, 7, 2),
            lines: [
              WorkSupplyInventoryReceiptLine(
                id: 'WRL-current-phase',
                item: item,
                displayName: item.name,
                rawReceiptText: 'LOWES 1/2 COP 90',
                quantity: 2,
                unitsPerPackage: 1,
                subtotal: 12,
                taxRate: .08,
                confidence: .88,
                reviewStatus: WorkSupplyLineReviewStatus.highConfidenceReview,
                originalParsedDescription: item.name,
                originalParsedInventoryItemId: item.id,
                originalParsedInventoryPath: item.path,
                reviewAction: 'parsed',
              ),
            ],
          );

          await store.saveReceipt(receipt);
          final loaded = store.receiptById('WRS-current-phase')!;

          expect(loaded.lines.single.rawReceiptText, 'LOWES 1/2 COP 90');
          expect(loaded.lines.single.originalParsedInventoryItemId, item.id);
          expect(loaded.lines.single.reviewAction, 'parsed');
          expect(loaded.lines.single.needsReview, isTrue);
          expect(loaded.lines.single.totalWithTax, 12.96);
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
  required String lineId,
  double onHand = 1,
  double lineSubtotal = 10,
  double taxRate = 0,
  double markupRate = 0,
  double packagesPurchased = 1,
  double unitsPerPackage = 1,
  String sourceReceiptId = 'RCP-1',
}) {
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: onHand,
    threshold: 1,
    lastUnitCost: 1,
    storageArea: 'Truck 1',
    receiptLinked: true,
    lineSubtotal: lineSubtotal,
    taxRate: taxRate,
    markupRate: markupRate,
    packagesPurchased: packagesPurchased,
    unitsPerPackage: unitsPerPackage,
    sourceReceiptId: sourceReceiptId,
    sourceReceiptLineId: lineId,
  );
}
