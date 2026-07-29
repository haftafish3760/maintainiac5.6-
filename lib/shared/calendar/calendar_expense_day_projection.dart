// Expense calendar day projection. Calendar reads the Expense ledger through
// this adapter and does not create another receipt persistence path.

import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/expenses/data/expense_ledger_models.dart';
import '../../screens/expenses/data/expense_ledger_scope_filter.dart';
import '../../screens/expenses/data/expense_reminder_store.dart';
import 'calendar_expense_projection_adapter.dart';
import 'calendar_expense_reminder_projection_adapter.dart';
import 'calendar_flow_models.dart';

class CalendarExpenseDayProjection {
  const CalendarExpenseDayProjection._();

  static CalendarDayData forDay(
    ExpenseLedgerController ledger,
    DateTime day, {
    String vehicleId = '',
    String workProfileId = '',
    Iterable<ExpenseReminderRecord> reminders = const [],
  }) {
    final scope = ExpenseLedgerScopeFilter(
      vehicleId: vehicleId,
      workProfileId: workProfileId,
    );
    final range = ExpenseDateRange(
      start: DateTime(day.year, day.month, day.day),
      end: DateTime(day.year, day.month, day.day),
    );
    final summary = ledger.summaryForRange(range, scope: scope);
    final events = CalendarExpenseProjectionAdapter.eventsForDay(
      ledger,
      day,
      scope: scope,
    );
    final reminderEvents =
        CalendarExpenseReminderProjectionAdapter.eventsForDay(
          reminders,
          day,
        ).toList(growable: false);
    final needsReview =
        events.where((event) => event.isActionable).length +
        reminderEvents.where((event) => event.isActionable).length;
    return CalendarDayData(
      recapItems: [
        CalendarRecapItem(label: 'Business', value: _money(summary.business)),
        CalendarRecapItem(label: 'Personal', value: _money(summary.personal)),
        CalendarRecapItem(
          label: 'Receipts',
          value: summary.recordCount.toString(),
        ),
        CalendarRecapItem(label: 'Needs review', value: needsReview.toString()),
      ],
      entries: [
        for (final event in events) CalendarTimelineEntry.fromProjection(event),
        for (final event in reminderEvents)
          CalendarTimelineEntry.fromProjection(event),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
