// Expense-to-calendar projection adapter. It reads source-owned expense
// records and never persists, edits, or reclassifies a receipt.

import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/expenses/data/expense_ledger_models.dart';
import '../../screens/expenses/data/expense_ledger_scope_filter.dart';
import 'calendar_projection_contract.dart';

class CalendarExpenseProjectionAdapter {
  const CalendarExpenseProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    ExpenseLedgerController ledger,
    DateTime day, {
    ExpenseLedgerScopeFilter scope = const ExpenseLedgerScopeFilter(),
  }) {
    final range = ExpenseDateRange(
      start: DateTime(day.year, day.month, day.day),
      end: DateTime(day.year, day.month, day.day),
    );
    return eventsFromReceipts(ledger.receiptsForRange(range, scope: scope));
  }

  static List<CalendarProjectionEvent> eventsFromReceipts(
    Iterable<ExpenseReceiptRecord> receipts,
  ) {
    return CalendarProjectionTimeline.normalize(
      receipts.where((receipt) => receipt.isActive).map(fromReceipt),
    );
  }

  static CalendarProjectionEvent fromReceipt(ExpenseReceiptRecord receipt) {
    final actualAt = _actualTime(receipt);
    final recordedAt =
        receipt.updatedAt ?? receipt.createdAt ?? receipt.receiptDate;
    final needsReview = receipt.ocrReview.needsReview;
    final evidenceSummary = _evidenceSummary(receipt);
    return CalendarProjectionEvent(
      eventId: 'expense:${receipt.id}',
      source: CalendarProjectionSource.expense,
      sourceRecordId: receipt.id,
      timing: CalendarProjectionTiming(
        eventDate: receipt.receiptDate,
        actualAt: actualAt,
        recordedAt: recordedAt,
        timeSource: actualAt == null
            ? CalendarTimeSource.unknown
            : CalendarTimeSource.actual,
      ),
      title: receipt.title,
      conciseDetail:
          '${receipt.primaryCategoryLabel} - ${_money(receipt.total)}',
      state: needsReview
          ? CalendarProjectionState.needsReview
          : CalendarProjectionState.confirmed,
      sourceRecordStatus: receipt.recordState.name,
      revision: receipt.localRevision,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.expenseDetail,
        sourceRecordId: receipt.id,
      ),
      vehicleIds: _ids(_effectiveVehicleId(receipt)),
      workProfileId: _emptyToNull(_effectiveWorkProfileId(receipt)),
      businessClassification: _classificationFor(receipt),
      evidence: CalendarProjectionEvidence(
        evidenceId: receipt.primaryFileHashSha256.isEmpty
            ? null
            : receipt.primaryFileHashSha256,
        summary: evidenceSummary,
        strength: receipt.hasReceiptAttachment
            ? 'receipt proof attached'
            : 'no receipt proof attached',
        explanation: needsReview
            ? receipt.ocrReview.commandCenterPrimaryAction
            : 'Expense record is saved in the source ledger.',
      ),
      auditReference: receipt.auditEvents.isEmpty
          ? null
          : receipt.auditEvents.last,
    );
  }
}

DateTime? _actualTime(ExpenseReceiptRecord receipt) {
  final minutes = receipt.receiptTimeMinutes;
  if (minutes == null || minutes < 0 || minutes >= 24 * 60) return null;
  return DateTime(
    receipt.receiptDate.year,
    receipt.receiptDate.month,
    receipt.receiptDate.day,
    minutes ~/ 60,
    minutes % 60,
  );
}

String _evidenceSummary(ExpenseReceiptRecord receipt) {
  final proof = receipt.hasReceiptAttachment
      ? 'Receipt proof attached'
      : 'No receipt proof attached';
  return '${receipt.primaryCategoryLabel}; $proof.';
}

List<String> _ids(String? value) {
  final id = _emptyToNull(value);
  return id == null ? const [] : [id];
}

String? _effectiveVehicleId(ExpenseReceiptRecord receipt) {
  final historicalId = receipt.contextSnapshot.vehicleId.trim();
  return historicalId.isEmpty ? receipt.vehicleId : historicalId;
}

String? _effectiveWorkProfileId(ExpenseReceiptRecord receipt) {
  final historicalId = receipt.contextSnapshot.workProfileId.trim();
  return historicalId.isEmpty ? receipt.workProfileId : historicalId;
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

CalendarBusinessClassification _classificationFor(
  ExpenseReceiptRecord receipt,
) {
  final business = receipt.businessTotalCents;
  final personal = receipt.personalTotalCents;
  final unclassified = receipt.unclassifiedTotalCents;
  if (business > 0 && personal == 0 && unclassified == 0) {
    return CalendarBusinessClassification.business;
  }
  if (personal > 0 && business == 0 && unclassified == 0) {
    return CalendarBusinessClassification.personal;
  }
  if (unclassified > 0 && business == 0 && personal == 0) {
    return CalendarBusinessClassification.unclassified;
  }
  return CalendarBusinessClassification.mixed;
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
