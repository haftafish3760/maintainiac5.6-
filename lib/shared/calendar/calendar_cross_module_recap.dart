// Cross-module calendar recap. It derives a read-only range summary from
// source records; it neither persists totals nor treats cash flow as profit.

import '../../screens/expenses/data/expense_ledger_scope_filter.dart';
import '../../screens/expenses/data/expense_ledger_models.dart';
import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/invoices/data/invoice_ledger_models.dart';
import '../../screens/invoices/data/invoice_record.dart';
import '../profiles/employee_work_time_contract.dart';
import 'calendar_projection_contract.dart';
import 'calendar_recap_period_contract.dart';

class CalendarRecapScope {
  const CalendarRecapScope({this.vehicleId = '', this.workProfileId = ''});

  final String vehicleId;
  final String workProfileId;
}

class CalendarCrossModuleRecap {
  const CalendarCrossModuleRecap({
    required this.range,
    required this.eventCount,
    required this.confirmedCount,
    required this.proposedCount,
    required this.needsReviewCount,
    required this.incompleteCount,
    required this.businessExpense,
    required this.personalExpense,
    required this.invoiceBilled,
    required this.estimateProposed,
    required this.paymentReceived,
    required this.approvedWorkMinutes,
    required this.pendingWorkMinutes,
  });

  final CalendarRecapDateRange range;
  final int eventCount;
  final int confirmedCount;
  final int proposedCount;
  final int needsReviewCount;
  final int incompleteCount;
  final double businessExpense;
  final double personalExpense;
  final double invoiceBilled;
  final double estimateProposed;
  final double paymentReceived;
  final int approvedWorkMinutes;
  final int pendingWorkMinutes;

  /// Cash received minus business expenses. This is deliberately not labeled
  /// profit because taxes, payroll, depreciation, and other source domains
  /// may not yet be represented in the selected range.
  double get netCashFlow => paymentReceived - businessExpense;
  double get approvedWorkHours => approvedWorkMinutes / 60;
  double get pendingWorkHours => pendingWorkMinutes / 60;

  static CalendarCrossModuleRecap fromSources({
    required CalendarRecapDateRange range,
    required Iterable<CalendarProjectionEvent> events,
    ExpenseLedgerController? expenses,
    Iterable<InvoiceRecord> invoices = const [],
    Iterable<EmployeeWorkTimeRecord> workTime = const [],
    CalendarRecapScope scope = const CalendarRecapScope(),
  }) {
    final includedEvents = events
        .where((event) => range.contains(event.timing.eventDate))
        .where((event) => _eventMatchesScope(event, scope))
        .toList(growable: false);
    final expenseSummary = _expenseSummaryFor(expenses, range, scope);
    final scopedInvoices = invoices.where(
      (record) =>
          _invoiceMatchesScope(record, scope) &&
          range.contains(record.issueDate),
    );
    final scopedWorkTime = workTime.where(
      (record) =>
          range.contains(record.workDate) &&
          _workTimeMatchesScope(record, scope),
    );
    final payments = invoices
        .where((record) => _invoiceMatchesScope(record, scope))
        .where((record) => record.status != InvoiceRecordStatus.voided)
        .expand((record) => record.payments)
        .where((payment) => range.contains(payment.paidAt));
    return CalendarCrossModuleRecap(
      range: range,
      eventCount: includedEvents.length,
      confirmedCount: includedEvents
          .where((event) => event.state == CalendarProjectionState.confirmed)
          .length,
      proposedCount: includedEvents
          .where((event) => event.state == CalendarProjectionState.proposed)
          .length,
      needsReviewCount: includedEvents
          .where((event) => event.state == CalendarProjectionState.needsReview)
          .length,
      incompleteCount: includedEvents
          .where((event) => event.state == CalendarProjectionState.incomplete)
          .length,
      businessExpense: expenseSummary.business,
      personalExpense: expenseSummary.personal,
      invoiceBilled: scopedInvoices
          .where(
            (record) =>
                record.documentType == InvoiceDocumentType.invoice &&
                record.status != InvoiceRecordStatus.draft &&
                record.status != InvoiceRecordStatus.voided,
          )
          .fold<double>(0, (sum, record) => sum + record.total),
      estimateProposed: scopedInvoices
          .where(
            (record) => record.documentType == InvoiceDocumentType.estimate,
          )
          .where((record) => record.status != InvoiceRecordStatus.voided)
          .fold<double>(0, (sum, record) => sum + record.total),
      paymentReceived: payments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      ),
      approvedWorkMinutes: scopedWorkTime
          .where((record) => record.countsTowardGrossPay)
          .fold<int>(0, (sum, record) => sum + record.paidMinutes),
      pendingWorkMinutes: scopedWorkTime
          .where(
            (record) =>
                !record.countsTowardGrossPay &&
                record.status != EmployeeWorkTimeStatus.rejected,
          )
          .fold<int>(0, (sum, record) => sum + record.paidMinutes),
    );
  }
}

ExpenseLedgerSummary _expenseSummaryFor(
  ExpenseLedgerController? ledger,
  CalendarRecapDateRange range,
  CalendarRecapScope scope,
) {
  if (ledger == null || ledger.receipts.isEmpty) {
    return const ExpenseLedgerSummary(
      totalCents: 0,
      businessCents: 0,
      personalCents: 0,
      unclassifiedCents: 0,
      recordCount: 0,
    );
  }
  final earliest = ledger.receipts
      .map((receipt) => receipt.receiptDate)
      .reduce((left, right) => left.isBefore(right) ? left : right);
  return ledger.summaryForRange(
    ExpenseDateRange(start: range.start ?? earliest, end: range.end),
    scope: ExpenseLedgerScopeFilter(
      vehicleId: scope.vehicleId,
      workProfileId: scope.workProfileId,
    ),
  );
}

bool _eventMatchesScope(
  CalendarProjectionEvent event,
  CalendarRecapScope scope,
) {
  final vehicleId = scope.vehicleId.trim();
  final profileId = scope.workProfileId.trim();
  return (vehicleId.isEmpty ||
          event.vehicleIds.isEmpty ||
          event.vehicleIds.contains(vehicleId)) &&
      (profileId.isEmpty ||
          event.workProfileId == null ||
          event.workProfileId == profileId);
}

bool _invoiceMatchesScope(InvoiceRecord record, CalendarRecapScope scope) =>
    (scope.vehicleId.trim().isEmpty || record.vehicleId == scope.vehicleId) &&
    (scope.workProfileId.trim().isEmpty ||
        record.profileId == scope.workProfileId);

bool _workTimeMatchesScope(
  EmployeeWorkTimeRecord record,
  CalendarRecapScope scope,
) =>
    (scope.vehicleId.trim().isEmpty ||
        record.vehicleIds.isEmpty ||
        record.vehicleIds.contains(scope.vehicleId)) &&
    (scope.workProfileId.trim().isEmpty ||
        record.workProfileId == null ||
        record.workProfileId == scope.workProfileId);
