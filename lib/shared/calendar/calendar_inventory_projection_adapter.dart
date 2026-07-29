// Inventory Calendar projection. Inventory owns stock transactions; Calendar
// only renders their source-recorded history and routes to the owning module.

import '../../screens/work_supplies/data/work_supply_models.dart';
import 'calendar_projection_contract.dart';

class CalendarInventoryProjectionAdapter {
  const CalendarInventoryProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<WorkSupplyInventoryTransaction> transactions,
    DateTime day,
  ) => CalendarProjectionTimeline.normalize(
    transactions
        .where((transaction) => _sameDay(transaction.occurredAt, day))
        .map(fromTransaction),
  );

  static CalendarProjectionEvent fromTransaction(
    WorkSupplyInventoryTransaction transaction,
  ) => CalendarProjectionEvent(
    eventId: 'inventory:${transaction.id}',
    source: CalendarProjectionSource.inventory,
    sourceRecordId: transaction.id,
    timing: CalendarProjectionTiming(
      eventDate: transaction.occurredAt,
      actualAt: transaction.occurredAt,
      recordedAt: transaction.createdAt ?? transaction.occurredAt,
      timeSource: CalendarTimeSource.actual,
    ),
    title: '${_typeLabel(transaction.type)} · ${transaction.item.name}',
    conciseDetail: _detailFor(transaction),
    state: CalendarProjectionState.confirmed,
    sourceRecordStatus: 'inventory transaction recorded',
    revision: _revisionFor(transaction),
    deepLink: CalendarProjectionDeepLink(
      target: CalendarDeepLinkTarget.inventoryDetail,
      sourceRecordId: transaction.id,
    ),
    jobId: _emptyToNull(transaction.jobNumber),
    businessClassification: _classificationFor(transaction),
    evidence: CalendarProjectionEvidence(
      evidenceId: _emptyToNull(transaction.sourceReceiptId),
      summary: transaction.receiptLinked
          ? 'Inventory transaction linked to source receipt.'
          : 'Inventory transaction recorded by the Inventory owner.',
      strength: transaction.receiptLinked
          ? 'source receipt linked'
          : 'manual inventory transaction',
      explanation:
          'This records stock movement. It does not create or reclassify an expense.',
    ),
    auditReference: transaction.createdAt == null
        ? null
        : 'Recorded ${transaction.createdAt!.toIso8601String()}',
  );
}

CalendarBusinessClassification _classificationFor(
  WorkSupplyInventoryTransaction transaction,
) {
  final use = transaction.businessUse.trim().toLowerCase();
  if (use == 'business' && transaction.businessPercent >= 1) {
    return CalendarBusinessClassification.business;
  }
  if (use == 'personal' || transaction.businessPercent <= 0) {
    return CalendarBusinessClassification.personal;
  }
  if (use == 'unclassified' || use.isEmpty) {
    return CalendarBusinessClassification.unclassified;
  }
  return CalendarBusinessClassification.mixed;
}

String _typeLabel(WorkSupplyStockEventType type) => switch (type) {
  WorkSupplyStockEventType.stockAdded => 'Stock added',
  WorkSupplyStockEventType.countAdjusted => 'Stock adjusted',
  WorkSupplyStockEventType.stockConsumed => 'Stock consumed',
  WorkSupplyStockEventType.transfer => 'Stock transferred',
};

String _detailFor(WorkSupplyInventoryTransaction transaction) {
  final quantity = transaction.quantityChange.toStringAsFixed(2);
  final location = transaction.storageArea.trim();
  final job = transaction.jobName.trim();
  return [
    '${quantity.startsWith('-') ? '' : '+'}$quantity ${transaction.item.unit}',
    if (location.isNotEmpty) location,
    if (job.isNotEmpty) job,
  ].join(' · ');
}

int _revisionFor(WorkSupplyInventoryTransaction transaction) {
  final createdAt = transaction.createdAt;
  if (createdAt == null || createdAt.microsecondsSinceEpoch < 0) return 0;
  return createdAt.microsecondsSinceEpoch;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
