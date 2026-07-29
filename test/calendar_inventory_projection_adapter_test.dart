import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/shared/calendar/calendar_inventory_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('inventory transaction retains source timing and receipt evidence', () {
    final event = CalendarInventoryProjectionAdapter.fromTransaction(
      _transaction(
        receiptLinked: true,
        sourceReceiptId: 'receipt-1',
        createdAt: DateTime(2026, 7, 29, 10),
      ),
    );

    expect(event.timing.actualAt, DateTime(2026, 7, 22, 8));
    expect(event.timing.recordedAt, DateTime(2026, 7, 29, 10));
    expect(event.deepLink.target, CalendarDeepLinkTarget.inventoryDetail);
    expect(event.evidence.evidenceId, 'receipt-1');
    expect(
      event.businessClassification,
      CalendarBusinessClassification.business,
    );
  });

  test('inventory use stays personal, mixed, or unclassified as recorded', () {
    expect(
      CalendarInventoryProjectionAdapter.fromTransaction(
        _transaction(businessUse: 'personal', businessPercent: 0),
      ).businessClassification,
      CalendarBusinessClassification.personal,
    );
    expect(
      CalendarInventoryProjectionAdapter.fromTransaction(
        _transaction(businessUse: 'split', businessPercent: .4),
      ).businessClassification,
      CalendarBusinessClassification.mixed,
    );
    expect(
      CalendarInventoryProjectionAdapter.fromTransaction(
        _transaction(businessUse: 'unclassified'),
      ).businessClassification,
      CalendarBusinessClassification.unclassified,
    );
  });

  test('only transactions on the selected day project', () {
    final events = CalendarInventoryProjectionAdapter.eventsForDay([
      _transaction(),
      _transaction(id: 'other-day', occurredAt: DateTime(2026, 7, 23, 8)),
    ], DateTime(2026, 7, 22));

    expect(events.map((event) => event.sourceRecordId), ['inventory-1']);
  });
}

WorkSupplyInventoryTransaction _transaction({
  String id = 'inventory-1',
  DateTime? occurredAt,
  DateTime? createdAt,
  bool receiptLinked = false,
  String sourceReceiptId = '',
  String businessUse = 'business',
  double businessPercent = 1,
}) => WorkSupplyInventoryTransaction(
  id: id,
  inventoryRecordId: 'record-1',
  item: const WorkSupplyItem(
    id: 'pipe',
    name: 'PVC pipe',
    trade: 'Plumbing',
    category: 'Pipe',
    system: 'Drain',
    itemType: 'Pipe',
    variant: '1 inch',
    unit: 'each',
  ),
  type: WorkSupplyStockEventType.stockAdded,
  quantityChange: 4,
  quantityBefore: 2,
  quantityAfter: 6,
  storageArea: 'Truck 1',
  occurredAt: occurredAt ?? DateTime(2026, 7, 22, 8),
  createdAt: createdAt,
  receiptLinked: receiptLinked,
  sourceReceiptId: sourceReceiptId,
  businessUse: businessUse,
  businessPercent: businessPercent,
);
