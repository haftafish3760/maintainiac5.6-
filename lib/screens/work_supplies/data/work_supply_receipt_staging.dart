import '../../../shared/receipts/receipt_line_models.dart';
import 'work_supply_models.dart';

bool workSupplyInventoryLineCanCommit(ReceiptLineDraft line) {
  if (!line.isInventory) return false;
  if (!line.hasAssistedReview) return true;
  return line.reviewState == ReceiptLineReviewState.confirmed ||
      line.reviewState == ReceiptLineReviewState.corrected;
}

int unconfirmedAssistedInventoryLineCount(Iterable<ReceiptLineDraft> lines) {
  return lines
      .where(
        (line) => line.isInventory && !workSupplyInventoryLineCanCommit(line),
      )
      .length;
}

List<WorkSupplyInventoryRecord> inventoryRecordsReadyForCommit({
  required Iterable<ReceiptLineDraft> lines,
  required Iterable<WorkSupplyInventoryRecord> records,
}) {
  final commitLineIds = lines
      .where(workSupplyInventoryLineCanCommit)
      .map((line) => line.receiptLineId.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  return records
      .where((record) => commitLineIds.contains(record.sourceReceiptLineId))
      .toList(growable: false);
}

int stagedInventoryRecordIndexForLine(
  List<WorkSupplyInventoryRecord> records,
  ReceiptLineDraft line,
) {
  final lineId = line.receiptLineId.trim();
  if (lineId.isNotEmpty) {
    final index = records.indexWhere(
      (record) => record.sourceReceiptLineId == lineId,
    );
    if (index != -1) return index;
  }
  return records.indexWhere((record) => record.item.id == line.inventoryItemId);
}

WorkSupplyInventoryRecord syncedInventoryRecordForLine({
  required WorkSupplyInventoryRecord record,
  required ReceiptLineDraft line,
}) {
  return record.copyWith(
    onHand: line.totalUnits,
    lastUnitCost: line.unitCostWithTax,
    businessUse: line.businessUse,
    businessPercent: line.businessPercent,
    lineSubtotal: line.subtotal,
    taxRate: line.taxRate,
    packagesPurchased: line.quantity,
    unitsPerPackage: line.unitsPerPackage,
    purchaseType: line.purchaseType,
    storageArea: line.storageArea,
    storageDetail: line.storageDetail,
    sourceReceiptLineId: line.receiptLineId.trim().isEmpty
        ? record.sourceReceiptLineId
        : line.receiptLineId.trim(),
  );
}
