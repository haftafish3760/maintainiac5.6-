// Calendar month projection reader. This read-only composition supplies
// meaningful month badges without creating a calendar-owned record store.

import 'package:flutter/widgets.dart';

import '../../screens/dashboard/data/active_workday_store.dart';
import '../../screens/expenses/data/expense_ledger_scope_filter.dart';
import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/expenses/data/expense_reminder_store.dart';
import '../../screens/invoices/data/invoice_ledger_store.dart';
import '../../shared/jobs/maintainiac_job_store.dart';
import '../context/operational_context_models.dart';
import '../context/operational_context_store.dart';
import '../profiles/employee_work_time_store.dart';
import '../state/app_state.dart';
import 'calendar_active_workday_projection_adapter.dart';
import 'calendar_expense_projection_adapter.dart';
import 'calendar_expense_reminder_projection_adapter.dart';
import 'calendar_flow_models.dart';
import 'calendar_invoice_projection_adapter.dart';
import 'calendar_job_projection_adapter.dart';
import 'calendar_maintenance_due_projection_adapter.dart';
import 'calendar_maintenance_projection_adapter.dart';
import 'calendar_projection_contract.dart';
import 'calendar_schedule_projection_adapter.dart';
import 'calendar_schedule_record.dart';
import 'calendar_work_time_projection_adapter.dart';
import 'calendar_workday_context_projection_adapter.dart';

class CalendarMonthProjectionReader {
  const CalendarMonthProjectionReader._();

  static List<CalendarProjectionEvent> eventsForDay(
    BuildContext context,
    CalendarFlowSource source,
    DateTime day, {
    String? employeeId,
  }) {
    final active = OperationalContextScope.maybeOf(context)?.context;
    final expenses = ExpenseLedgerScope.maybeOf(context);
    final reminders = context
        .dependOnInheritedWidgetOfExactType<ExpenseReminderScope>()
        ?.notifier;
    final jobs = MaintainiacJobScope.maybeOf(context);
    final invoices = InvoiceLedgerScope.maybeOf(context);
    final workTime = EmployeeWorkTimeScope.maybeOf(context);
    final workdays = ActiveWorkdayScope.maybeOf(context);
    final appState = AppStateScope.of(context);
    final expenseScope = ExpenseLedgerScopeFilter(
      vehicleId: active?.activeVehicleId ?? '',
      workProfileId: active?.workProfileId ?? '',
    );
    final events = <CalendarProjectionEvent>[
      if (source == CalendarFlowSource.dashboard && workdays != null)
        ...CalendarActiveWorkdayProjectionAdapter.eventsForDay(
          workdays.sessions,
          day,
        ),
      if (source == CalendarFlowSource.dashboard && workdays != null)
        ...CalendarWorkdayContextProjectionAdapter.eventsForDay(
          workdays.sessions,
          day,
        ),
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.contractor ||
          source == CalendarFlowSource.expenses)
        if (expenses != null)
          ...CalendarExpenseProjectionAdapter.eventsForDay(
            expenses,
            day,
            scope: expenseScope,
          ),
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.expenses)
        if (reminders != null)
          ...CalendarExpenseReminderProjectionAdapter.eventsForDay(
            reminders.records,
            day,
          ),
      ...calendarScheduleEventsForDay(
        context,
        source,
        day,
        employeeId: employeeId,
      ),
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.contractor ||
          source == CalendarFlowSource.jobs)
        if (jobs != null)
          ...CalendarJobProjectionAdapter.eventsForDay(jobs, day),
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.invoices)
        if (invoices != null)
          ...CalendarInvoiceProjectionAdapter.eventsForDay(
            invoices.records,
            day,
          ),
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.maintenance) ...[
        ...CalendarMaintenanceProjectionAdapter.eventsForDay(
          appState.maintenanceEvents,
          day,
        ),
        ...CalendarMaintenanceDueProjectionAdapter.eventsForDay(
          appState.allMaintenanceRecords,
          day,
        ),
      ],
      if (source == CalendarFlowSource.dashboard ||
          source == CalendarFlowSource.contractor)
        if (workTime != null)
          ...CalendarWorkTimeProjectionAdapter.eventsForDay(
            workTime.records,
            day,
          ),
      if (source == CalendarFlowSource.employee &&
          workTime != null &&
          (employeeId?.trim().isNotEmpty ?? false))
        ...CalendarWorkTimeProjectionAdapter.eventsForDay(
          workTime.recordsForEmployee(employeeId!.trim()),
          day,
        ),
    ];
    return CalendarProjectionTimeline.normalize(
      events.where((event) => _matchesContext(event, active)),
    );
  }

  /// Calendar-owned plans are visible on Dashboard and on the source calendar
  /// where they were created. Context filtering prevents vehicle/profile bleed.
  static List<CalendarProjectionEvent> calendarScheduleEventsForDay(
    BuildContext context,
    CalendarFlowSource source,
    DateTime day, {
    String? employeeId,
  }) {
    final active = OperationalContextScope.maybeOf(context)?.context;
    final schedules = CalendarScheduleScope.maybeOf(context);
    if (schedules == null) return const [];
    return CalendarProjectionTimeline.normalize(
      CalendarScheduleProjectionAdapter.eventsForDay(
        schedules.records.where(
          (schedule) =>
              source == CalendarFlowSource.dashboard ||
              (schedule.screenScope == source.name &&
                  (source != CalendarFlowSource.employee ||
                      (employeeId?.trim().isNotEmpty ?? false) &&
                          schedule.employeeId == employeeId!.trim())),
        ),
        day,
      ).where((event) => _matchesContext(event, active)),
    );
  }

  static bool _matchesContext(
    CalendarProjectionEvent event,
    ActiveOperationalContext? active,
  ) {
    if (active == null) return true;
    return (event.vehicleIds.isEmpty ||
            event.vehicleIds.contains(active.activeVehicleId)) &&
        (event.workProfileId == null ||
            event.workProfileId == active.workProfileId);
  }
}
