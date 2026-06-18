import 'package:hive_flutter/hive_flutter.dart';

import 'work_supply_inventory_receipt_models.dart';

class WorkSupplyInventoryReceiptStore {
  WorkSupplyInventoryReceiptStore._(this._box);

  static const boxName = 'work_supply_inventory_receipts';

  final Box<dynamic> _box;

  static Future<WorkSupplyInventoryReceiptStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return WorkSupplyInventoryReceiptStore._(box);
  }

  List<WorkSupplyInventoryReceiptRecord> loadReceipts() {
    final receipts = <WorkSupplyInventoryReceiptRecord>[];
    for (final value in _box.values) {
      if (value is Map) {
        receipts.add(WorkSupplyInventoryReceiptRecord.fromMap(value));
      }
    }
    receipts.sort((a, b) {
      final aDate = a.receiptDate ?? a.createdAt ?? DateTime(0);
      final bDate = b.receiptDate ?? b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return receipts;
  }

  WorkSupplyInventoryReceiptRecord? receiptById(String id) {
    final value = _box.get(id);
    if (value is! Map) return null;
    return WorkSupplyInventoryReceiptRecord.fromMap(value);
  }

  Future<WorkSupplyInventoryReceiptRecord> saveReceipt(
    WorkSupplyInventoryReceiptRecord receipt,
  ) async {
    final now = DateTime.now();
    final saved = receipt.copyWith(
      createdAt: receipt.createdAt ?? now,
      updatedAt: now,
    );
    await _box.put(saved.id, saved.toMap());
    return saved;
  }

  Future<WorkSupplyInventoryReceiptRecord?> replaceLine({
    required String receiptId,
    required WorkSupplyInventoryReceiptLine line,
  }) async {
    final receipt = receiptById(receiptId);
    if (receipt == null) return null;
    final lines = [
      for (final current in receipt.lines)
        if (current.id == line.id) line else current,
    ];
    return saveReceipt(receipt.copyWith(lines: lines));
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
