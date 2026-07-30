// Dashboard master-day projection. It composes source-owned events and recap
// inputs without creating a dashboard or calendar record store.

import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/invoices/data/invoice_record.dart';
import '../profiles/employee_work_time_contract.dart';
import 'calendar_cross_module_recap.dart';
import 'calendar_flow_models.dart';
import 'calendar_projection_contract.dart';
import 'calendar_recap_period_contract.dart';

class CalendarDashboardDayProjection {
  const CalendarDashboardDayProjection._();

  static CalendarDayData fromSources({
    required DateTime day,
    required Iterable<CalendarProjectionEvent> events,
    ExpenseLedgerController? expenses,
    Iterable<InvoiceRecord> invoices = const [],
    Iterable<EmployeeWorkTimeRecord> workTime = const [],
    CalendarRecapScope scope = const CalendarRecapScope(),
  }) {
    final date = DateTime(day.year, day.month, day.day);
    final recap = CalendarCrossModuleRecap.fromSources(
      range: CalendarRecapDateRange(start: date, end: date),
      events: events,
      expenses: expenses,
      invoices: invoices,
      workTime: workTime,
      scope: scope,
    );
    final normalized = CalendarProjectionTimeline.normalize(events);
    return CalendarDayData(
      recapItems: [
        CalendarRecapItem(
          label: 'Total entries',
          value: '${normalized.length}',
        ),
        CalendarRecapItem(
          label: 'Stops',
          value:
              '${normalized.where((event) => event.source == CalendarProjectionSource.stop).length}',
        ),
        CalendarRecapItem(
          label: 'Awaiting review',
          value:
              '${recap.proposedCount + recap.needsReviewCount + recap.incompleteCount}',
        ),
        CalendarRecapItem(
          label: 'Cash received',
          value: _money(recap.paymentReceived),
        ),
        CalendarRecapItem(
          label: 'Business spend',
          value: _money(recap.businessExpense),
        ),
        CalendarRecapItem(
          label: 'Net cash flow',
          value: _money(recap.netCashFlow),
        ),
        CalendarRecapItem(
          label: 'Approved hours',
          value: recap.approvedWorkHours.toStringAsFixed(2),
        ),
      ],
      entries: [
        for (final event in normalized)
          CalendarTimelineEntry.fromProjection(event),
      ],
    );
  }
}

String _money(double amount) => '\$${amount.toStringAsFixed(2)}';
