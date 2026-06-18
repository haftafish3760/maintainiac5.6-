import 'package:hive_flutter/hive_flutter.dart';

import 'work_supply_inventory_export.dart';
import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

part 'work_supply_inventory_store_mappers.dart';

class WorkSupplyInventoryStore {
  WorkSupplyInventoryStore._(
    this._recordsBox,
    this._eventsBox,
    this._transactionsBox,
  );

  static const recordsBoxName = 'work_supply_inventory_records';
  static const eventsBoxName = 'work_supply_inventory_events';
  static const transactionsBoxName = 'work_supply_inventory_transactions';

  final Box<dynamic> _recordsBox;
  final Box<dynamic> _eventsBox;
  final Box<dynamic> _transactionsBox;

  static Future<WorkSupplyInventoryStore> create() async {
    final recordsBox = await Hive.openBox<dynamic>(recordsBoxName);
    final eventsBox = await Hive.openBox<dynamic>(eventsBoxName);
    final transactionsBox = await Hive.openBox<dynamic>(transactionsBoxName);
    return WorkSupplyInventoryStore._(recordsBox, eventsBox, transactionsBox);
  }

  List<WorkSupplyInventoryRecord> loadInventory() {
    final records = <WorkSupplyInventoryRecord>[];
    for (final key in _recordsBox.keys) {
      if (_isSeedDemoKey(key)) continue;
      final value = _recordsBox.get(key);
      if (_isSeedDemoStoredValue(value)) continue;
      final record = _recordFromStoredValue(value);
      if (record != null) records.add(record);
    }
    records.sort((a, b) {
      final location = a.storageArea.compareTo(b.storageArea);
      if (location != 0) return location;
      final detail = a.storageDetail.compareTo(b.storageDetail);
      if (detail != 0) return detail;
      return a.item.name.compareTo(b.item.name);
    });
    return records;
  }

  List<WorkSupplyStockEvent> loadEvents() {
    final events = <WorkSupplyStockEvent>[];
    for (final key in _eventsBox.keys) {
      final value = _eventsBox.get(key);
      if (_isSeedDemoStoredValue(value)) continue;
      final event = _eventFromStoredValue(value);
      if (event != null) events.add(event);
    }
    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events;
  }

  List<WorkSupplyInventoryTransaction> loadTransactions() {
    final transactions = <WorkSupplyInventoryTransaction>[];
    for (final key in _transactionsBox.keys) {
      final value = _transactionsBox.get(key);
      if (_isSeedDemoStoredValue(value)) continue;
      final transaction = _transactionFromStoredValue(value);
      if (transaction != null) transactions.add(transaction);
    }
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return transactions;
  }

  List<WorkSupplyInventoryTransaction> recentTransactionsForItem(
    WorkSupplyItem item, {
    int limit = 10,
    bool purchasesOnly = true,
  }) {
    final itemKey = canonicalWorkSupplyItemKey(item);
    final transactions = loadTransactions().where((transaction) {
      final sameItem = canonicalWorkSupplyItemKey(transaction.item) == itemKey;
      if (!sameItem) return false;
      if (!purchasesOnly) return true;
      return transaction.type == WorkSupplyStockEventType.stockAdded;
    }).toList();
    return transactions.take(limit).toList();
  }

  WorkSupplyInventoryExportSnapshot buildExportSnapshot({
    DateTime? exportedAt,
  }) {
    return WorkSupplyInventoryExportSnapshot(
      exportedAt: exportedAt ?? DateTime.now(),
      inventoryRecords: loadInventory(),
      stockEvents: loadEvents(),
      transactions: loadTransactions(),
    );
  }

  Future<WorkSupplyInventoryRecord> addStock(
    WorkSupplyInventoryRecord record,
  ) async {
    final now = DateTime.now();
    final existing = _matchingRecord(record);
    if (existing == null) {
      final saved = record.copyWith(
        id: _newId('inv', now),
        createdAt: record.createdAt ?? now,
        updatedAt: now,
      );
      await _recordsBox.put(saved.id, _recordToMap(saved));
      await _saveEvent(
        WorkSupplyStockEvent(
          id: _newId('evt', now),
          inventoryRecordId: saved.id,
          itemId: saved.item.id,
          itemName: saved.item.name,
          type: WorkSupplyStockEventType.stockAdded,
          quantityChange: saved.onHand,
          quantityBefore: 0,
          quantityAfter: saved.onHand,
          storageArea: saved.storageArea,
          occurredAt: saved.loggedAt ?? now,
          receiptLinked: saved.receiptLinked,
          note: 'Added stock to inventory.',
        ),
      );
      await _saveTransaction(
        _transactionFromRecord(
          id: _newId('txn', now),
          record: saved,
          type: WorkSupplyStockEventType.stockAdded,
          quantityChange: saved.onHand,
          quantityBefore: 0,
          quantityAfter: saved.onHand,
          occurredAt: saved.loggedAt ?? now,
          note: 'Added stock to inventory.',
        ),
      );
      return saved;
    }

    final before = existing.onHand;
    final after = before + record.onHand;
    final saved = existing.copyWith(
      onHand: after,
      threshold: record.threshold,
      lastUnitCost: record.lastUnitCost,
      receiptLinked: existing.receiptLinked || record.receiptLinked,
      storageDetail: record.storageDetail,
      packagesPurchased: record.packagesPurchased,
      unitsPerPackage: record.unitsPerPackage,
      purchaseType: record.purchaseType,
      lineSubtotal: record.lineSubtotal,
      taxRate: record.taxRate,
      markupRate: record.markupRate,
      businessUse: record.businessUse,
      businessPercent: record.businessPercent,
      loggedAt: record.loggedAt,
      sourceMerchantName: record.sourceMerchantName,
      updatedAt: now,
    );
    await _recordsBox.put(saved.id, _recordToMap(saved));
    await _saveEvent(
      WorkSupplyStockEvent(
        id: _newId('evt', now),
        inventoryRecordId: saved.id,
        itemId: saved.item.id,
        itemName: saved.item.name,
        type: WorkSupplyStockEventType.stockAdded,
        quantityChange: record.onHand,
        quantityBefore: before,
        quantityAfter: after,
        storageArea: saved.storageArea,
        occurredAt: record.loggedAt ?? now,
        receiptLinked: record.receiptLinked,
        note: 'Added stock to existing inventory item.',
      ),
    );
    await _saveTransaction(
      _transactionFromRecord(
        id: _newId('txn', now),
        record: saved,
        type: WorkSupplyStockEventType.stockAdded,
        quantityChange: record.onHand,
        quantityBefore: before,
        quantityAfter: after,
        occurredAt: record.loggedAt ?? now,
        note: 'Added stock to existing inventory item.',
      ),
    );
    return saved;
  }

  Future<WorkSupplyInventoryRecord> markOutOfStock(
    WorkSupplyInventoryRecord record,
  ) async {
    final current = _recordById(record.id) ?? record;
    final now = DateTime.now();
    final saved = current.copyWith(onHand: 0, updatedAt: now);
    await _recordsBox.put(saved.id, _recordToMap(saved));
    await _saveEvent(
      WorkSupplyStockEvent(
        id: _newId('evt', now),
        inventoryRecordId: saved.id,
        itemId: saved.item.id,
        itemName: saved.item.name,
        type: WorkSupplyStockEventType.countAdjusted,
        quantityChange: -current.onHand,
        quantityBefore: current.onHand,
        quantityAfter: 0,
        storageArea: saved.storageArea,
        occurredAt: now,
        receiptLinked: saved.receiptLinked,
        note: 'Marked out of stock from inventory review.',
      ),
    );
    await _saveTransaction(
      _transactionFromRecord(
        id: _newId('txn', now),
        record: saved,
        type: WorkSupplyStockEventType.countAdjusted,
        quantityChange: -current.onHand,
        quantityBefore: current.onHand,
        quantityAfter: 0,
        occurredAt: now,
        note: 'Marked out of stock from inventory review.',
      ),
    );
    return saved;
  }

  Future<int> purgeObsoleteSeedInventoryRecords() async {
    var removed = 0;
    for (final key in _recordsBox.keys.toList()) {
      if (!_isSeedDemoKey(key)) continue;
      await _recordsBox.delete(key);
      removed++;
    }
    for (final key in _eventsBox.keys.toList()) {
      final value = _eventsBox.get(key);
      if (_isSeedDemoStoredValue(value)) {
        await _eventsBox.delete(key);
        removed++;
      }
    }
    for (final key in _transactionsBox.keys.toList()) {
      final value = _transactionsBox.get(key);
      if (_isSeedDemoStoredValue(value)) {
        await _transactionsBox.delete(key);
        removed++;
      }
    }
    return removed;
  }

  WorkSupplyInventoryRecord? _matchingRecord(
    WorkSupplyInventoryRecord incoming,
  ) {
    for (final record in loadInventory()) {
      if (canonicalWorkSupplyItemKey(record.item) ==
              canonicalWorkSupplyItemKey(incoming.item) &&
          record.storageArea == incoming.storageArea &&
          record.storageDetail == incoming.storageDetail) {
        return record;
      }
    }
    return null;
  }

  WorkSupplyInventoryRecord? _recordById(String id) {
    if (id.isEmpty) return null;
    return _recordFromStoredValue(_recordsBox.get(id));
  }

  Future<void> _saveEvent(WorkSupplyStockEvent event) async {
    await _eventsBox.put(event.id, _eventToMap(event));
  }

  Future<void> _saveTransaction(
    WorkSupplyInventoryTransaction transaction,
  ) async {
    await _transactionsBox.put(transaction.id, _transactionToMap(transaction));
  }
}
