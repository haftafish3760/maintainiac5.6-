// Calendar delegates creation to the source-owning module. It never saves a
// duplicate generic calendar record.

import 'package:flutter/material.dart';

import '../../screens/expenses/entry/expense_receipt_entry_screen.dart';
import '../../screens/expenses/reminders/expense_reminder_screen.dart';
import '../../screens/invoices/data/invoice_ledger_models.dart';
import '../../screens/invoices/home/invoice_form_screen.dart';
import '../../screens/maintenance/maintenance_log_service_screen.dart';
import '../../screens/work_supplies/entry/work_supply_add_items_screen.dart';
import '../../screens/work_supplies/jobs/work_supply_jobs_screen.dart';
import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import 'calendar_flow_models.dart';

class CalendarOwnerEntryRouter {
  const CalendarOwnerEntryRouter._();

  static Future<void> open({
    required BuildContext context,
    required DateTime day,
    required CalendarEntryType type,
  }) async {
    final route = _ownerRoute(context: context, day: day, type: type);
    if (route != null) {
      await Navigator.of(context).push(route);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open the owning module'),
        content: Text(
          '${calendarEntryMeta(type).label} does not have a source-owned '
          'date-entry route yet. Calendar will not create a duplicate record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Route<void>? _ownerRoute({
    required BuildContext context,
    required DateTime day,
    required CalendarEntryType type,
  }) => switch (type) {
    CalendarEntryType.expense ||
    CalendarEntryType.receiptPhoto => appNativeRoute<void>(
      context,
      ExpenseReceiptEntryScreen(initialDate: day),
    ),
    CalendarEntryType.invoiceEstimate => appNativeRoute<void>(
      context,
      InvoiceFormScreen(documentType: InvoiceDocumentType.invoice),
    ),
    CalendarEntryType.payment => appNativeRoute<void>(
      context,
      InvoiceFormScreen(documentType: InvoiceDocumentType.invoice),
    ),
    CalendarEntryType.maintenance => appNativeRoute<void>(
      context,
      MaintenanceLogServiceScreen(
        records: AppStateScope.of(context).allMaintenanceRecords,
      ),
    ),
    CalendarEntryType.note || CalendarEntryType.reminderSchedule =>
      appNativeRoute<void>(context, const ExpenseReminderScreen()),
    CalendarEntryType.job ||
    CalendarEntryType.stop ||
    CalendarEntryType.pickup ||
    CalendarEntryType.delivery => appNativeRoute<void>(
      context,
      WorkSupplyJobsScreen(initialDay: day),
    ),
    CalendarEntryType.materials => appNativeRoute<void>(
      context,
      const WorkSupplyAddItemsScreen(),
    ),
    CalendarEntryType.tripEntry => null,
  };
}
