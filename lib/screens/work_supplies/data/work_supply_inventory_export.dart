import '../../../shared/data_export/csv_writer.dart';
import 'work_supply_models.dart';

class WorkSupplyInventoryExportSnapshot {
  const WorkSupplyInventoryExportSnapshot({
    required this.exportedAt,
    required this.inventoryRecords,
    required this.stockEvents,
    this.transactions = const [],
  });

  final DateTime exportedAt;
  final List<WorkSupplyInventoryRecord> inventoryRecords;
  final List<WorkSupplyStockEvent> stockEvents;
  final List<WorkSupplyInventoryTransaction> transactions;

  String toInventoryCsv() {
    return buildCsv([
      [
        'record_id',
        'item_id',
        'item_name',
        'trade',
        'category',
        'system',
        'item_type',
        'variant',
        'unit',
        'on_hand',
        'threshold',
        'last_unit_cost',
        'storage_area',
        'storage_detail',
        'receipt_linked',
        'job_number',
        'job_name',
        'packages_purchased',
        'units_per_package',
        'purchase_type',
        'line_subtotal',
        'tax_rate',
        'markup_rate',
        'business_use',
        'business_percent',
        'source_receipt_id',
        'source_receipt_line_id',
        'source_merchant_name',
        'logged_at',
        'created_at',
        'updated_at',
      ],
      for (final record in inventoryRecords)
        [
          record.id,
          record.item.id,
          record.item.name,
          record.item.trade,
          record.item.category,
          record.item.system,
          record.item.itemType,
          record.item.variant,
          record.item.unit,
          record.onHand,
          record.threshold,
          record.lastUnitCost,
          record.storageArea,
          record.storageDetail,
          record.receiptLinked,
          record.jobNumber,
          record.jobName,
          record.packagesPurchased,
          record.unitsPerPackage,
          record.purchaseType,
          record.lineSubtotal,
          record.taxRate,
          record.markupRate,
          record.businessUse,
          record.businessPercent,
          record.sourceReceiptId,
          record.sourceReceiptLineId,
          record.sourceMerchantName,
          _date(record.loggedAt),
          _date(record.createdAt),
          _date(record.updatedAt),
        ],
    ]);
  }

  String toStockEventsCsv() {
    return buildCsv([
      [
        'event_id',
        'inventory_record_id',
        'item_id',
        'item_name',
        'event_type',
        'quantity_change',
        'quantity_before',
        'quantity_after',
        'storage_area',
        'occurred_at',
        'receipt_linked',
        'note',
      ],
      for (final event in stockEvents)
        [
          event.id,
          event.inventoryRecordId,
          event.itemId,
          event.itemName,
          event.type.name,
          event.quantityChange,
          event.quantityBefore,
          event.quantityAfter,
          event.storageArea,
          _date(event.occurredAt),
          event.receiptLinked,
          event.note,
        ],
    ]);
  }

  String toTransactionsCsv() {
    return buildCsv([
      [
        'transaction_id',
        'inventory_record_id',
        'item_id',
        'item_name',
        'trade',
        'category',
        'system',
        'item_type',
        'variant',
        'unit',
        'transaction_type',
        'quantity_change',
        'quantity_before',
        'quantity_after',
        'storage_area',
        'storage_detail',
        'destination_storage_area',
        'destination_storage_detail',
        'occurred_at',
        'packages_purchased',
        'units_per_package',
        'purchase_type',
        'line_subtotal',
        'tax_rate',
        'markup_rate',
        'business_use',
        'business_percent',
        'receipt_linked',
        'source_receipt_id',
        'source_receipt_line_id',
        'source_merchant_name',
        'job_number',
        'job_name',
        'note',
        'created_at',
        'replaces_transaction_id',
        'reversed_transaction_id',
      ],
      for (final transaction in transactions)
        [
          transaction.id,
          transaction.inventoryRecordId,
          transaction.item.id,
          transaction.item.name,
          transaction.item.trade,
          transaction.item.category,
          transaction.item.system,
          transaction.item.itemType,
          transaction.item.variant,
          transaction.item.unit,
          transaction.type.name,
          transaction.quantityChange,
          transaction.quantityBefore,
          transaction.quantityAfter,
          transaction.storageArea,
          transaction.storageDetail,
          transaction.destinationStorageArea,
          transaction.destinationStorageDetail,
          _date(transaction.occurredAt),
          transaction.packagesPurchased,
          transaction.unitsPerPackage,
          transaction.purchaseType,
          transaction.lineSubtotal,
          transaction.taxRate,
          transaction.markupRate,
          transaction.businessUse,
          transaction.businessPercent,
          transaction.receiptLinked,
          transaction.sourceReceiptId,
          transaction.sourceReceiptLineId,
          transaction.sourceMerchantName,
          transaction.jobNumber,
          transaction.jobName,
          transaction.note,
          _date(transaction.createdAt),
          transaction.replacesTransactionId,
          transaction.reversedTransactionId,
        ],
    ]);
  }

  Map<String, Object?> toManifest() {
    return {
      'app': 'Maintaniac',
      'exportType': 'work_supply_inventory',
      'exportedAt': exportedAt.toIso8601String(),
      'inventoryRecordCount': inventoryRecords.length,
      'stockEventCount': stockEvents.length,
      'transactionCount': transactions.length,
      'files': [
        'work_supply_inventory.csv',
        'work_supply_stock_events.csv',
        'work_supply_inventory_transactions.csv',
      ],
    };
  }
}

String _date(DateTime? value) => value?.toIso8601String() ?? '';
