import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_receipt_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_receipt_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'work_supply_inventory_receipt_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('saves inventory intake lines with proof privacy metadata', () async {
    final store = await WorkSupplyInventoryReceiptStore.create();
    final receipt = WorkSupplyInventoryReceiptRecord(
      id: 'WRS-test',
      source: WorkSupplyInventoryIntakeSource.manualWithReceipt,
      merchantName: 'Lowes',
      receiptDate: DateTime.utc(2026, 6, 8, 12),
      proofs: const [
        WorkSupplyReceiptProofRef(
          id: 'proof-1',
          kind: 'image',
          uri: 'local://receipts/proof-1.jpg',
          label: 'Receipt photo 1',
        ),
      ],
      lines: const [
        WorkSupplyInventoryReceiptLine(
          id: 'WRL-test',
          item: WorkSupplyItem(
            id: 'PL-COP-90-050',
            name: '1/2 in Copper 90 Elbow',
            trade: 'Plumbing',
            category: 'Fittings',
            system: 'Copper',
            itemType: '90 Elbows',
            variant: '1/2 in',
            unit: 'each',
          ),
          displayName: '1/2 in copper 90',
          quantity: 1,
          unitsPerPackage: 25,
          purchaseType: 'box',
          unit: 'each',
          subtotal: 40,
          taxRate: .07,
          storageArea: 'Work Truck 1 inventory',
          storageDetail: 'Top tray',
          businessUse: 'split',
          businessPercent: .75,
          invoiceProofMode: WorkSupplyInvoiceProofMode.lineOnly,
          invoiceProofCrop: WorkSupplyLineProofCrop(
            proofId: 'proof-1',
            left: .1,
            top: .2,
            width: .8,
            height: .12,
          ),
        ),
      ],
    );

    final saved = await store.saveReceipt(receipt);
    final loaded = store.receiptById(saved.id)!;

    expect(loaded.hasProof, isTrue);
    expect(loaded.lines.single.displayName, '1/2 in copper 90');
    expect(loaded.lines.single.totalUnits, 25);
    expect(loaded.lines.single.totalWithTax, 42.8);
    expect(loaded.lines.single.storageDetail, 'Top tray');
    expect(loaded.lines.single.businessUse, 'split');
    expect(loaded.lines.single.businessPercent, .75);
    expect(loaded.lines.single.confidenceLevel, ReceiptConfidenceLevel.good);
    expect(loaded.lines.single.confidenceLabel, 'Good');
    expect(loaded.lines.single.needsReview, isFalse);
    expect(loaded.lines.single.toMap()['confidenceLevel'], 'good');
    expect(
      loaded.lines.single.invoiceProofMode,
      WorkSupplyInvoiceProofMode.lineOnly,
    );
    expect(loaded.lines.single.invoiceProofCrop!.proofId, 'proof-1');
  });

  test(
    'replaces one editable line without losing the receipt record',
    () async {
      final store = await WorkSupplyInventoryReceiptStore.create();
      const item = WorkSupplyItem(
        id: 'USER-custom',
        name: 'Custom Fence Post',
        trade: 'Fencing',
        category: 'Posts and Framework',
        system: 'Wood Posts',
        itemType: 'Fence Posts',
        variant: '8 ft',
        unit: 'each',
      );
      const originalLine = WorkSupplyInventoryReceiptLine(
        id: 'WRL-edit',
        item: item,
        displayName: '8 ft fence post',
        quantity: 2,
        unitsPerPackage: 1,
        subtotal: 20,
      );
      await store.saveReceipt(
        const WorkSupplyInventoryReceiptRecord(
          id: 'WRS-edit',
          source: WorkSupplyInventoryIntakeSource.manualWithoutReceipt,
          lines: [originalLine],
        ),
      );

      await store.replaceLine(
        receiptId: 'WRS-edit',
        line: originalLine.copyWith(quantity: 3, subtotal: 30),
      );

      final edited = store.receiptById('WRS-edit')!;
      expect(edited.lines, hasLength(1));
      expect(edited.lines.single.quantity, 3);
      expect(edited.lines.single.subtotal, 30);
    },
  );

  test('saved receipt line keeps parser confidence review state', () async {
    final store = await WorkSupplyInventoryReceiptStore.create();
    const line = WorkSupplyInventoryReceiptLine(
      id: 'WRL-review',
      item: WorkSupplyItem(
        id: 'PL-COP-90-050',
        name: '1/2 in Copper 90 Elbow',
        trade: 'Plumbing',
        category: 'Fittings',
        system: 'Copper',
        itemType: '90 Elbows',
        variant: '1/2 in',
        unit: 'each',
      ),
      displayName: '1/2 in copper 90',
      rawReceiptText: 'LOWES COP EL',
      confidence: .68,
      reviewStatus: WorkSupplyLineReviewStatus.needsReview,
      originalParsedDescription: '3/4 in Copper 90 Elbow',
      originalParsedInventoryItemId: 'MI-999',
      originalParsedInventoryPath: 'Plumbing / Fittings / Copper',
      reviewAction: 'edited',
    );

    await store.saveReceipt(
      const WorkSupplyInventoryReceiptRecord(
        id: 'WRS-review',
        source: WorkSupplyInventoryIntakeSource.photoAssist,
        lines: [line],
      ),
    );

    final loaded = store.receiptById('WRS-review')!.lines.single;

    expect(loaded.confidenceLevel, ReceiptConfidenceLevel.okay);
    expect(loaded.confidenceLabel, 'Review');
    expect(loaded.confidenceGuidance, 'Review this line before saving.');
    expect(loaded.needsReview, isTrue);
    expect(loaded.wasCorrectedFromParser, isTrue);
    expect(loaded.originalParsedInventoryItemId, 'MI-999');
    expect(loaded.reviewAction, 'edited');
    expect(loaded.toMap()['confidenceLevel'], 'okay');
    expect(loaded.toMap()['reviewAction'], 'edited');
  });
}
