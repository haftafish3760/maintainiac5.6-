// Contractor master day projection. It composes read-only source adapters and
// deliberately does not create a dashboard-owned calendar database.

import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../shared/jobs/maintainiac_job_store.dart';
import '../profiles/employee_work_time_store.dart';
import 'calendar_expense_projection_adapter.dart';
import 'calendar_flow_models.dart';
import 'calendar_job_projection_adapter.dart';
import 'calendar_projection_contract.dart';
import 'calendar_work_time_projection_adapter.dart';

class CalendarContractorDayProjection {
  const CalendarContractorDayProjection._();

  static CalendarDayData forDay({
    required DateTime day,
    ExpenseLedgerController? expenses,
    MaintainiacJobController? jobs,
    EmployeeWorkTimeController? workTime,
  }) {
    final events = CalendarProjectionTimeline.normalize([
      if (expenses != null)
        ...CalendarExpenseProjectionAdapter.eventsForDay(expenses, day),
      if (jobs != null) ...CalendarJobProjectionAdapter.eventsForDay(jobs, day),
      if (workTime != null)
        ...CalendarWorkTimeProjectionAdapter.eventsForDay(
          workTime.records,
          day,
        ),
    ]);
    final expenseSummary = expenses?.summaryForDay(day);
    final scheduledJobs = events
        .where((event) => event.source == CalendarProjectionSource.job)
        .length;
    final needsReview = events.where((event) => event.isActionable).length;
    final workMinutes = events
        .where((event) => event.source == CalendarProjectionSource.workTime)
        .fold<int>(0, (total, event) {
          final matched = workTime?.recordById(event.sourceRecordId);
          return total + (matched?.paidMinutes ?? 0);
        });
    return CalendarDayData(
      recapItems: [
        CalendarRecapItem(label: 'Scheduled jobs', value: '$scheduledJobs'),
        CalendarRecapItem(
          label: 'Business spend',
          value: _money(expenseSummary?.business ?? 0),
        ),
        CalendarRecapItem(label: 'Work hours', value: _hours(workMinutes)),
        CalendarRecapItem(label: 'Needs review', value: '$needsReview'),
      ],
      entries: [
        for (final event in events) CalendarTimelineEntry.fromProjection(event),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _hours(int minutes) => (minutes / 60).toStringAsFixed(2);
