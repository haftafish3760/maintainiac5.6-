import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_staging.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';

void main() {
  const item = WorkSupplyItem(
    id: 'MI-COPPER-90',
    name: '1/2 in Copper 90 Elbow',
    trade: 'Plumbing',
    category: 'Fittings',
    system: 'Copper',
    itemType: '90 Elbows',
    variant: '1/2 in',
    unit: 'each',
  );

  WorkSupplyInventoryRecord record(String lineId) {
    return WorkSupplyInventoryRecord(
      item: item,
      onHand: 1,
      threshold: 1,
      lastUnitCost: 2,
      storageArea: 'Company inventory',
      receiptLinked: true,
      sourceReceiptId: 'RCP-1',
      sourceReceiptLineId: lineId,
    );
  }

  test('staged inventory sync uses receipt line id for duplicate items', () {
    final records = [record('RCP-1-L1'), record('RCP-1-L2')];
    const editedSecondLine = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in Copper 90 Elbow',
      receiptLineId: 'RCP-1-L2',
      inventoryItemId: 'MI-COPPER-90',
      quantity: 3,
      unitsPerPackage: 2,
      subtotal: 30,
      taxRate: .1,
      storageArea: 'Truck 2 inventory',
      storageDetail: 'Bin B',
    );

    final index = stagedInventoryRecordIndexForLine(records, editedSecondLine);
    final synced = syncedInventoryRecordForLine(
      record: records[index],
      line: editedSecondLine,
    );

    expect(index, 1);
    expect(synced.sourceReceiptLineId, 'RCP-1-L2');
    expect(synced.onHand, 6);
    expect(synced.storageArea, 'Truck 2 inventory');
    expect(records.first.storageArea, 'Company inventory');
  });

  test('parsed inventory lines cannot commit until confirmed or corrected', () {
    const parsedLine = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in Copper 90 Elbow',
      receiptLineId: 'RCP-1-L1',
      inventoryItemId: 'MI-COPPER-90',
      rawReceiptText: 'HALF COP ELL 90',
      parserConfidence: .91,
      parserReviewLabel: 'Good',
      parserReviewReason: 'Inventory catalog suggests copper elbow.',
      parserNeedsReview: false,
      reviewAction: 'parsed',
    );
    final confirmedLine = parsedLine.confirmedAssistedReview();
    final correctedLine = parsedLine.copyWith(reviewAction: 'edited');

    expect(workSupplyInventoryLineCanCommit(parsedLine), isFalse);
    expect(parsedLine.canConfirmAssistedReview, isTrue);
    expect(workSupplyInventoryLineCanCommit(confirmedLine), isTrue);
    expect(workSupplyInventoryLineCanCommit(correctedLine), isTrue);
    expect(
      unconfirmedAssistedInventoryLineCount([parsedLine, confirmedLine]),
      1,
    );
  });

  test('commit-ready inventory records exclude unconfirmed parsed lines', () {
    final records = [record('RCP-1-L1'), record('RCP-1-L2')];
    const parsedLine = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: '1/2 in Copper 90 Elbow',
      receiptLineId: 'RCP-1-L1',
      inventoryItemId: 'MI-COPPER-90',
      rawReceiptText: 'HALF COP ELL 90',
      parserConfidence: .91,
      reviewAction: 'parsed',
    );
    final confirmedLine = parsedLine
        .copyWith(receiptLineId: 'RCP-1-L2')
        .confirmedAssistedReview();

    final ready = inventoryRecordsReadyForCommit(
      lines: [parsedLine, confirmedLine],
      records: records,
    );

    expect(ready, hasLength(1));
    expect(ready.single.sourceReceiptLineId, 'RCP-1-L2');
  });
}
