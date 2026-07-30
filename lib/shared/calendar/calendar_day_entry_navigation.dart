// Calendar ownership: routes a projected event to its owning detail flow.
// The Calendar never substitutes a generic editor for a source-owned record.

import 'package:flutter/material.dart';

import '../../screens/expenses/calendar/expense_calendar.dart';
import '../../screens/expenses/reminders/expense_reminder_screen.dart';
import '../../screens/invoices/home/invoice_form_screen.dart';
import '../../screens/maintenance/maintenance_item_detail_screen.dart';
import '../../screens/maintenance/maintenance_service_event_detail_screen.dart';
import '../../screens/profiles/employee_work_time_detail_screen.dart';
import '../../screens/work_supplies/jobs/maintainiac_job_detail_screen.dart';
import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import 'calendar_active_workday_projection_route.dart';
import 'calendar_entry_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_maintenance_projection_adapter.dart';
import 'calendar_projection_contract.dart';
import 'calendar_schedule_editor_screen.dart';
import 'calendar_schedule_record.dart';

void calendarOpenDayEntry(
  BuildContext context, {
  required DateTime day,
  required CalendarDayMode mode,
  required CalendarFlowSource source,
  required CalendarTimelineEntry entry,
  String? employeeId,
  CalendarSourceEventDetailBuilder? sourceEventDetailBuilder,
}) {
  final deepLink = entry.projection?.deepLink;
  final sourceDetail = entry.projection == null
      ? null
      : sourceEventDetailBuilder?.call(entry.projection!);
  if (sourceDetail != null) {
    _push(context, sourceDetail);
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.expenseDetail) {
    _push(
      context,
      ExpenseReceiptDetailScreen(receiptId: deepLink!.sourceRecordId),
    );
    return;
  }
  if (deepLink != null &&
      calendarOpenActiveWorkdayProjectionRoute(context, deepLink)) {
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.jobDetail) {
    _push(context, MaintainiacJobDetailScreen(jobId: deepLink!.sourceRecordId));
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.maintenanceDetail) {
    final state = AppStateScope.of(context);
    final record = state.allMaintenanceRecords.where(
      (item) => item.recordId == deepLink!.sourceRecordId,
    );
    if (record.isNotEmpty) {
      _push(context, MaintenanceItemDetailScreen(record: record.first));
      return;
    }
    final event = state.maintenanceEvents.where(
      (item) =>
          CalendarMaintenanceProjectionAdapter.sourceIdFor(item) ==
          deepLink!.sourceRecordId,
    );
    if (event.isNotEmpty) {
      _push(context, MaintenanceServiceEventDetailScreen(event: event.first));
      return;
    }
  }
  if (deepLink?.target == CalendarDeepLinkTarget.workTimeDetail) {
    _push(
      context,
      EmployeeWorkTimeDetailScreen(recordId: deepLink!.sourceRecordId),
    );
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.invoiceDetail ||
      deepLink?.target == CalendarDeepLinkTarget.estimateDetail ||
      deepLink?.target == CalendarDeepLinkTarget.paymentDetail) {
    _push(context, InvoiceFormScreen(recordId: deepLink!.sourceRecordId));
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.reminderDetail) {
    _push(
      context,
      ExpenseReminderScreen(initialReminderId: deepLink!.sourceRecordId),
    );
    return;
  }
  if (deepLink?.target == CalendarDeepLinkTarget.calendarScheduleDetail) {
    final records =
        CalendarScheduleScope.maybeOf(context)?.records ??
        const <CalendarScheduleRecord>[];
    for (final record in records) {
      if (record.id == deepLink!.sourceRecordId) {
        _push(
          context,
          CalendarScheduleEditorScreen(
            day: day,
            source: source,
            record: record,
            employeeId: record.employeeId,
          ),
        );
        return;
      }
    }
  }
  if (entry.projection != null) {
    _showUnavailableSourceRecord(context, entry.projection!);
    return;
  }
  _push(
    context,
    CalendarEntryDetailScreen(
      day: day,
      mode: mode,
      entry: entry,
      source: source,
      employeeId: employeeId,
    ),
  );
}

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(appNativeRoute<void>(context, screen));

Future<void> _showUnavailableSourceRecord(
  BuildContext context,
  CalendarProjectionEvent event,
) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Source record unavailable'),
    content: Text(
      '${event.source.name} record ${event.sourceRecordId} cannot be opened because its owner route is not available in this build. Calendar did not open a duplicate editor.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Close'),
      ),
    ],
  ),
);
