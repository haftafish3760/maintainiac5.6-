part of 'work_supply_inventory_store.dart';

Map<String, Object?> _recordToMap(WorkSupplyInventoryRecord record) {
  return {
    'id': record.id,
    'item': _itemToMap(record.item),
    'onHand': record.onHand,
    'threshold': record.threshold,
    'lastUnitCost': record.lastUnitCost,
    'storageArea': record.storageArea,
    'storageDetail': record.storageDetail,
    'receiptLinked': record.receiptLinked,
    'jobNumber': record.jobNumber,
    'jobName': record.jobName,
    'createdAt': record.createdAt?.toIso8601String(),
    'updatedAt': record.updatedAt?.toIso8601String(),
    'packagesPurchased': record.packagesPurchased,
    'unitsPerPackage': record.unitsPerPackage,
    'purchaseType': record.purchaseType,
    'lineSubtotal': record.lineSubtotal,
    'taxRate': record.taxRate,
    'markupRate': record.markupRate,
    'businessUse': record.businessUse,
    'businessPercent': record.businessPercent,
    'loggedAt': record.loggedAt?.toIso8601String(),
    'sourceReceiptId': record.sourceReceiptId,
    'sourceReceiptLineId': record.sourceReceiptLineId,
    'sourceMerchantName': record.sourceMerchantName,
  };
}

WorkSupplyInventoryRecord? _recordFromStoredValue(Object? value) {
  if (value is! Map) return null;
  final item = _itemFromStoredValue(value['item']);
  if (item == null) return null;
  return WorkSupplyInventoryRecord(
    id: _string(value['id']),
    item: item,
    onHand: _double(value['onHand']),
    threshold: _double(value['threshold']),
    lastUnitCost: _double(value['lastUnitCost']),
    storageArea: _string(value['storageArea'], fallback: 'Active vehicle'),
    storageDetail: _string(value['storageDetail']),
    receiptLinked: _bool(value['receiptLinked']),
    jobNumber: _string(value['jobNumber']),
    jobName: _string(value['jobName']),
    createdAt: _date(value['createdAt']),
    updatedAt: _date(value['updatedAt']),
    packagesPurchased: _double(value['packagesPurchased'], fallback: 1),
    unitsPerPackage: _double(value['unitsPerPackage'], fallback: 1),
    purchaseType: _string(value['purchaseType'], fallback: 'each'),
    lineSubtotal: _double(value['lineSubtotal']),
    taxRate: _double(value['taxRate']),
    markupRate: _double(value['markupRate']),
    businessUse: _string(value['businessUse'], fallback: 'business'),
    businessPercent: _double(value['businessPercent'], fallback: 1),
    loggedAt: _date(value['loggedAt']),
    sourceReceiptId: _string(value['sourceReceiptId']),
    sourceReceiptLineId: _string(value['sourceReceiptLineId']),
    sourceMerchantName: _string(value['sourceMerchantName']),
  );
}

Map<String, Object?> _itemToMap(WorkSupplyItem item) {
  return {
    'id': item.id,
    'name': item.name,
    'trade': item.trade,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'variant': item.variant,
    'unit': item.unit,
    'aliases': item.aliases,
  };
}

WorkSupplyItem? _itemFromStoredValue(Object? value) {
  if (value is! Map) return null;
  final id = _string(value['id']);
  return WorkSupplyItem(
    id: id,
    name: _string(value['name'], fallback: 'Custom Inventory Item'),
    trade: _string(value['trade'], fallback: 'Custom'),
    category: _string(value['category'], fallback: 'Custom'),
    system: _string(value['system'], fallback: 'User Added'),
    itemType: _string(value['itemType'], fallback: 'Manual Item'),
    variant: _string(value['variant'], fallback: 'manual'),
    unit: _string(value['unit'], fallback: 'each'),
    aliases: _stringList(value['aliases']),
  );
}

Map<String, Object?> _eventToMap(WorkSupplyStockEvent event) {
  return {
    'id': event.id,
    'inventoryRecordId': event.inventoryRecordId,
    'itemId': event.itemId,
    'itemName': event.itemName,
    'type': event.type.name,
    'quantityChange': event.quantityChange,
    'quantityBefore': event.quantityBefore,
    'quantityAfter': event.quantityAfter,
    'storageArea': event.storageArea,
    'occurredAt': event.occurredAt.toIso8601String(),
    'receiptLinked': event.receiptLinked,
    'note': event.note,
  };
}

WorkSupplyStockEvent? _eventFromStoredValue(Object? value) {
  if (value is! Map) return null;
  return WorkSupplyStockEvent(
    id: _string(value['id']),
    inventoryRecordId: _string(value['inventoryRecordId']),
    itemId: _string(value['itemId']),
    itemName: _string(value['itemName']),
    type: _eventType(value['type']),
    quantityChange: _double(value['quantityChange']),
    quantityBefore: _double(value['quantityBefore']),
    quantityAfter: _double(value['quantityAfter']),
    storageArea: _string(value['storageArea'], fallback: 'Active vehicle'),
    occurredAt:
        _date(value['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    receiptLinked: _bool(value['receiptLinked']),
    note: _string(value['note']),
  );
}

WorkSupplyInventoryTransaction _transactionFromRecord({
  required String id,
  required WorkSupplyInventoryRecord record,
  required WorkSupplyStockEventType type,
  required double quantityChange,
  required double quantityBefore,
  required double quantityAfter,
  required DateTime occurredAt,
  required String note,
}) {
  return WorkSupplyInventoryTransaction(
    id: id,
    inventoryRecordId: record.id,
    item: record.item,
    type: type,
    quantityChange: quantityChange,
    quantityBefore: quantityBefore,
    quantityAfter: quantityAfter,
    storageArea: record.storageArea,
    storageDetail: record.storageDetail,
    occurredAt: occurredAt,
    packagesPurchased: record.packagesPurchased,
    unitsPerPackage: record.unitsPerPackage,
    purchaseType: record.purchaseType,
    lineSubtotal: record.lineSubtotal,
    taxRate: record.taxRate,
    markupRate: record.markupRate,
    businessUse: record.businessUse,
    businessPercent: record.businessPercent,
    receiptLinked: record.receiptLinked,
    sourceReceiptId: record.sourceReceiptId,
    sourceReceiptLineId: record.sourceReceiptLineId,
    sourceMerchantName: record.sourceMerchantName,
    jobNumber: record.jobNumber,
    jobName: record.jobName,
    note: note,
    createdAt: DateTime.now(),
  );
}

Map<String, Object?> _transactionToMap(
  WorkSupplyInventoryTransaction transaction,
) {
  return {
    'id': transaction.id,
    'inventoryRecordId': transaction.inventoryRecordId,
    'item': _itemToMap(transaction.item),
    'type': transaction.type.name,
    'quantityChange': transaction.quantityChange,
    'quantityBefore': transaction.quantityBefore,
    'quantityAfter': transaction.quantityAfter,
    'storageArea': transaction.storageArea,
    'storageDetail': transaction.storageDetail,
    'destinationStorageArea': transaction.destinationStorageArea,
    'destinationStorageDetail': transaction.destinationStorageDetail,
    'occurredAt': transaction.occurredAt.toIso8601String(),
    'packagesPurchased': transaction.packagesPurchased,
    'unitsPerPackage': transaction.unitsPerPackage,
    'purchaseType': transaction.purchaseType,
    'lineSubtotal': transaction.lineSubtotal,
    'taxRate': transaction.taxRate,
    'markupRate': transaction.markupRate,
    'businessUse': transaction.businessUse,
    'businessPercent': transaction.businessPercent,
    'receiptLinked': transaction.receiptLinked,
    'sourceReceiptId': transaction.sourceReceiptId,
    'sourceReceiptLineId': transaction.sourceReceiptLineId,
    'sourceMerchantName': transaction.sourceMerchantName,
    'jobNumber': transaction.jobNumber,
    'jobName': transaction.jobName,
    'note': transaction.note,
    'createdAt': transaction.createdAt?.toIso8601String(),
    'replacesTransactionId': transaction.replacesTransactionId,
    'reversedTransactionId': transaction.reversedTransactionId,
  };
}

WorkSupplyInventoryTransaction? _transactionFromStoredValue(Object? value) {
  if (value is! Map) return null;
  final item = _itemFromStoredValue(value['item']);
  if (item == null) return null;
  return WorkSupplyInventoryTransaction(
    id: _string(value['id']),
    inventoryRecordId: _string(value['inventoryRecordId']),
    item: item,
    type: _eventType(value['type']),
    quantityChange: _double(value['quantityChange']),
    quantityBefore: _double(value['quantityBefore']),
    quantityAfter: _double(value['quantityAfter']),
    storageArea: _string(value['storageArea'], fallback: 'Active vehicle'),
    storageDetail: _string(value['storageDetail']),
    destinationStorageArea: _string(value['destinationStorageArea']),
    destinationStorageDetail: _string(value['destinationStorageDetail']),
    occurredAt:
        _date(value['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    packagesPurchased: _double(value['packagesPurchased']),
    unitsPerPackage: _double(value['unitsPerPackage'], fallback: 1),
    purchaseType: _string(value['purchaseType'], fallback: 'each'),
    lineSubtotal: _double(value['lineSubtotal']),
    taxRate: _double(value['taxRate']),
    markupRate: _double(value['markupRate']),
    businessUse: _string(value['businessUse'], fallback: 'business'),
    businessPercent: _double(value['businessPercent'], fallback: 1),
    receiptLinked: _bool(value['receiptLinked']),
    sourceReceiptId: _string(value['sourceReceiptId']),
    sourceReceiptLineId: _string(value['sourceReceiptLineId']),
    sourceMerchantName: _string(value['sourceMerchantName']),
    jobNumber: _string(value['jobNumber']),
    jobName: _string(value['jobName']),
    note: _string(value['note']),
    createdAt: _date(value['createdAt']),
    replacesTransactionId: _string(value['replacesTransactionId']),
    reversedTransactionId: _string(value['reversedTransactionId']),
  );
}

WorkSupplyStockEventType _eventType(Object? value) {
  final name = _string(value);
  for (final type in WorkSupplyStockEventType.values) {
    if (type.name == name) return type;
  }
  return WorkSupplyStockEventType.countAdjusted;
}

bool _isSeedDemoStoredValue(Object? value) {
  if (value is! Map) return false;
  final inventoryRecordId = _string(value['inventoryRecordId']);
  if (inventoryRecordId.startsWith('seed-')) return true;
  final id = _string(value['id']);
  if (id.contains('-seed-')) return true;
  return _string(value['note']).toLowerCase().contains('seeded demo inventory');
}

bool _isSeedDemoKey(Object? key) {
  return key != null && key.toString().startsWith('seed-');
}

String _newId(String prefix, DateTime now, {String suffix = ''}) {
  final safeSuffix = suffix
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final tail = safeSuffix.isEmpty ? '' : '-$safeSuffix';
  return '$prefix-${now.microsecondsSinceEpoch}$tail';
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}
