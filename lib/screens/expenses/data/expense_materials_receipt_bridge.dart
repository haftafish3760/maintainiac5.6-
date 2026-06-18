import '../../work_supplies/data/work_supply_inventory_receipt_models.dart';
import '../../work_supplies/data/work_supply_inventory_receipt_store.dart';
import '../../work_supplies/data/work_supply_models.dart';
import 'expense_ledger_models.dart';

class ExpenseMaterialsReceiptBridge {
  const ExpenseMaterialsReceiptBridge(this._store);

  final WorkSupplyInventoryReceiptStore _store;

  static Future<ExpenseMaterialsReceiptBridge> create() async {
    return ExpenseMaterialsReceiptBridge(
      await WorkSupplyInventoryReceiptStore.create(),
    );
  }

  Future<WorkSupplyInventoryReceiptRecord?> syncReceipt(
    ExpenseReceiptRecord receipt,
  ) async {
    if (!_shouldTrackMaterials(receipt)) return null;
    final materialLines = receipt.lines
        .where((line) => line.category == 'Materials')
        .toList(growable: false);
    if (materialLines.isEmpty) return null;

    final record = WorkSupplyInventoryReceiptRecord(
      id: _workSupplyReceiptId(receipt.id),
      source: receipt.hasReceiptAttachment
          ? WorkSupplyInventoryIntakeSource.manualWithReceipt
          : WorkSupplyInventoryIntakeSource.manualWithoutReceipt,
      merchantName: receipt.merchantName,
      merchantPhone: receipt.phone,
      merchantAddress: _merchantAddress(receipt),
      receiptDate: receipt.sortDate,
      proofs: [
        for (final attachment in receipt.attachments)
          WorkSupplyReceiptProofRef(
            id: attachment.id,
            kind: attachment.kind.name,
            uri: attachment.path,
            label: attachment.label,
            createdAt: attachment.createdAt,
          ),
      ],
      note: [
        'Created from expense receipt ${receipt.id}.',
        if (receipt.notes.trim().isNotEmpty) receipt.notes.trim(),
      ].join(' '),
      lines: [
        for (final line in materialLines)
          WorkSupplyInventoryReceiptLine(
            id: _workSupplyLineId(receipt.id, line.id),
            item: _placeholderItemForLine(line),
            displayName: line.description.trim().isEmpty
                ? 'Material line'
                : line.description.trim(),
            kind: WorkSupplyReceiptLineKind.inventory,
            rawReceiptText: line.description,
            expenseCategory: line.category,
            quantity: line.quantity,
            unitsPerPackage: line.unitsPerPackage,
            purchaseType: line.unitsPerPackage > 1 ? 'package' : 'each',
            unit: line.unit,
            subtotal: line.subtotal,
            taxRate: receipt.effectiveTaxRate ?? 0,
            businessUse: line.use.name,
            businessPercent: line.effectiveBusinessPercent,
            confidence: line.parserConfidence ?? .55,
            reviewStatus: WorkSupplyLineReviewStatus.needsReview,
            note:
                'Confirm exact catalog item and storage before adding to stock.',
          ),
      ],
    );

    return _store.saveReceipt(record);
  }

  bool _shouldTrackMaterials(ExpenseReceiptRecord receipt) {
    return receipt.sourceScreen == 'materials_expense_receipt' &&
        receipt.trackMaterialsInInventory;
  }

  String _merchantAddress(ExpenseReceiptRecord receipt) {
    return [
      receipt.street,
      receipt.city,
      receipt.state,
      receipt.zip,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  WorkSupplyItem _placeholderItemForLine(ExpenseReceiptLineRecord line) {
    final description = line.description.trim();
    return WorkSupplyItem(
      id: 'EXP-MATERIAL-${line.id}',
      name: description.isEmpty ? 'Material line' : description,
      trade: 'Needs Review',
      category: 'Materials',
      system: 'Expense Receipt',
      itemType: line.category,
      variant: '',
      unit: line.unit,
    );
  }

  String _workSupplyReceiptId(String receiptId) {
    return 'WRS-FROM-$receiptId';
  }

  String _workSupplyLineId(String receiptId, String lineId) {
    return 'WRL-FROM-$receiptId-$lineId';
  }
}
