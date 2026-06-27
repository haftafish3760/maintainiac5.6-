import '../../work_supplies/data/work_supply_inventory_receipt_models.dart';
import '../../work_supplies/data/work_supply_inventory_receipt_store.dart';
import '../../work_supplies/data/work_supply_catalog.dart';
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
    final reviewLines = receipt.lines
        .where((line) => line.subtotal > 0)
        .toList(growable: false);
    if (reviewLines.isEmpty) return null;

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
        for (final line in reviewLines)
          WorkSupplyInventoryReceiptLine(
            id: _workSupplyLineId(receipt.id, line.id),
            item: _itemForLine(line),
            displayName: line.displayDescription,
            kind: _kindForLine(line),
            rawReceiptText: line.receiptEvidenceText,
            expenseCategory: line.category,
            quantity: line.quantity,
            unitsPerPackage: line.unitsPerPackage,
            purchaseType: line.unitsPerPackage > 1 ? 'package' : 'each',
            unit: line.unit,
            subtotal: line.subtotal,
            taxRate: receipt.effectiveTaxRate ?? 0,
            businessUse: line.use.name,
            businessPercent: line.effectiveBusinessPercent,
            confidence: _confidenceForLine(line),
            reviewStatus: _reviewStatusForLine(line),
            note: _reviewNoteForLine(line),
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

  WorkSupplyReceiptLineKind _kindForLine(ExpenseReceiptLineRecord line) {
    if (line.use == ExpenseLineUse.personal) {
      return WorkSupplyReceiptLineKind.personal;
    }
    if (line.category == 'Materials') {
      return WorkSupplyReceiptLineKind.inventory;
    }
    return WorkSupplyReceiptLineKind.businessExpense;
  }

  WorkSupplyLineReviewStatus _reviewStatusForLine(
    ExpenseReceiptLineRecord line,
  ) {
    if (_kindForLine(line) == WorkSupplyReceiptLineKind.inventory ||
        line.use == ExpenseLineUse.split ||
        line.parserNeedsReview) {
      return WorkSupplyLineReviewStatus.needsReview;
    }
    return WorkSupplyLineReviewStatus.confirmed;
  }

  double _confidenceForLine(ExpenseReceiptLineRecord line) {
    return line.catalogMatchConfidence ??
        line.parserConfidence ??
        (_kindForLine(line) == WorkSupplyReceiptLineKind.inventory ? .55 : .9);
  }

  String _reviewNoteForLine(ExpenseReceiptLineRecord line) {
    return switch (_kindForLine(line)) {
      WorkSupplyReceiptLineKind.inventory =>
        'Confirm exact catalog item and storage before adding to stock.',
      WorkSupplyReceiptLineKind.businessExpense =>
        line.use == ExpenseLineUse.split
            ? 'Confirm the business percentage before saving this non-inventory line.'
            : 'Business-only receipt line. It stays out of inventory.',
      WorkSupplyReceiptLineKind.personal =>
        'Personal receipt line. It stays out of business inventory and totals.',
    };
  }

  WorkSupplyItem _itemForLine(ExpenseReceiptLineRecord line) {
    final catalogItem = _catalogItemForLine(line);
    if (catalogItem != null) return catalogItem;
    return _placeholderItemForLine(line);
  }

  WorkSupplyItem? _catalogItemForLine(ExpenseReceiptLineRecord line) {
    final itemId = line.catalogItemId?.trim();
    if (itemId == null || itemId.isEmpty) return null;
    for (final item in workSupplyCatalogItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  WorkSupplyItem _placeholderItemForLine(ExpenseReceiptLineRecord line) {
    final kind = _kindForLine(line);
    final trade = switch (kind) {
      WorkSupplyReceiptLineKind.inventory => 'Needs Review',
      WorkSupplyReceiptLineKind.businessExpense => 'Business Expense',
      WorkSupplyReceiptLineKind.personal => 'Personal',
    };
    final itemType = switch (kind) {
      WorkSupplyReceiptLineKind.inventory => line.category,
      WorkSupplyReceiptLineKind.businessExpense => 'Expense line',
      WorkSupplyReceiptLineKind.personal => 'Personal line',
    };
    return WorkSupplyItem(
      id: 'EXP-MATERIAL-${line.id}',
      name: line.displayDescription,
      trade: trade,
      category: line.category.trim().isEmpty ? 'Uncategorized' : line.category,
      system: 'Expense Receipt',
      itemType: itemType,
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
