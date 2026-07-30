import 'package:flutter/material.dart';
import '../../screens/expenses/calendar/expense_calendar.dart';
import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/expenses/data/expense_reminder_store.dart';
import '../../screens/expenses/reminders/expense_reminder_screen.dart';
import '../../screens/maintenance/maintenance_service_event_detail_screen.dart';
import '../../screens/maintenance/maintenance_item_detail_screen.dart';
import '../../screens/profiles/employee_work_time_detail_screen.dart';
import '../../screens/invoices/data/invoice_ledger_store.dart';
import '../../screens/invoices/home/invoice_form_screen.dart';
import '../../screens/work_supplies/jobs/maintainiac_job_detail_screen.dart';
import '../jobs/maintainiac_job_store.dart';
import '../context/operational_context_store.dart';
import '../profiles/employee_work_time_store.dart';
import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen_shell.dart';
import 'app_date_picker.dart';
import 'calendar_employee_day_projection.dart';
import 'calendar_filtered_timeline.dart';
import 'calendar_expense_day_projection.dart';
import 'calendar_invoice_day_projection.dart';
import 'calendar_contractor_day_projection.dart';
import 'calendar_dashboard_day_projection.dart';
import 'calendar_day_flow_support.dart';
import 'calendar_active_workday_projection_route.dart';
import 'calendar_cross_module_recap.dart';
import 'calendar_entry_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_maintenance_projection_adapter.dart';
import 'calendar_month_projection_reader.dart';
import 'calendar_projection_contract.dart';

class CalendarDayFlowScreen extends StatefulWidget {
  const CalendarDayFlowScreen({
    super.key,
    required this.day,
    this.source = CalendarFlowSource.dashboard,
    this.employeeId,
  });

  final DateTime day;
  final CalendarFlowSource source;
  final String? employeeId;

  @override
  State<CalendarDayFlowScreen> createState() => _CalendarDayFlowScreenState();
}

class _CalendarDayFlowScreenState extends State<CalendarDayFlowScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.day);

  @override
  Widget build(BuildContext context) {
    final mode = calendarModeFor(_selectedDay);
    final profile = calendarModeProfileFor(mode);
    final data = _calendarDataFor(context, _selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: profile.fabColor,
        foregroundColor: profile.fabForeground,
        icon: Icon(profile.fabIcon),
        label: Text(profile.fabLabel),
        onPressed: () => _openEntrySelector(context, _selectedDay, mode),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
          children: [
            const AppBackButton(),
            const SizedBox(height: 8),
            AppScreenHeader(title: calendarScreenTitle(widget.source)),
            const SizedBox(height: 12),
            GlobalOdometerHeader(
              section: calendarAppSectionFor(widget.source),
              headerLabel: 'ACTIVE VEHICLE / WORK PROFILE',
            ),
            const SizedBox(height: 12),
            const CalendarActiveContextStrip(),
            const SizedBox(height: 12),
            CalendarDayNavigation(
              day: _selectedDay,
              onPreviousDay: () => _shiftDay(-1),
              onNextDay: () => _shiftDay(1),
              onPickDate: _pickDay,
            ),
            const SizedBox(height: 12),
            CalendarModeHeader(day: _selectedDay, profile: profile),
            const SizedBox(height: 12),
            ..._sectionsForMode(context, _selectedDay, mode, data),
          ],
        ),
      ),
    );
  }

  List<Widget> _sectionsForMode(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return switch (mode) {
      CalendarDayMode.past => _pastDaySections(context, day, mode, data),
      CalendarDayMode.today => _todaySections(context, day, mode, data),
      CalendarDayMode.future => _futureSections(context, day, mode, data),
    };
  }

  Future<void> _pickDay() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDay,
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDay = DateUtils.dateOnly(picked));
  }

  CalendarDayData _calendarDataFor(BuildContext context, DateTime day) {
    if (widget.source == CalendarFlowSource.expenses) {
      final ledger = ExpenseLedgerScope.maybeOf(context);
      if (ledger != null) {
        final active = OperationalContextScope.maybeOf(context)?.context;
        return calendarFilterToActiveContext(
          context,
          CalendarExpenseDayProjection.forDay(
            ledger,
            day,
            vehicleId: active?.activeVehicleId ?? '',
            workProfileId: active?.workProfileId ?? '',
            reminders: ExpenseReminderScope.of(context).records,
          ),
        );
      }
    }
    if (widget.source == CalendarFlowSource.contractor) {
      return calendarFilterToActiveContext(
        context,
        CalendarContractorDayProjection.forDay(
          day: day,
          expenses: ExpenseLedgerScope.maybeOf(context),
          jobs: MaintainiacJobScope.maybeOf(context),
          workTime: EmployeeWorkTimeScope.maybeOf(context),
        ),
      );
    }
    if (widget.source == CalendarFlowSource.jobs) {
      final events = CalendarMonthProjectionReader.eventsForDay(
        context,
        CalendarFlowSource.jobs,
        day,
      );
      final needsReview = events.where((event) => event.isActionable).length;
      return CalendarDayData(
        recapItems: [
          CalendarRecapItem(label: 'Scheduled jobs', value: '${events.length}'),
          CalendarRecapItem(label: 'Needs review', value: '$needsReview'),
        ],
        entries: [
          for (final event in events)
            CalendarTimelineEntry.fromProjection(event),
        ],
      );
    }
    if (widget.source == CalendarFlowSource.dashboard) {
      final active = OperationalContextScope.maybeOf(context)?.context;
      final events = CalendarMonthProjectionReader.eventsForDay(
        context,
        CalendarFlowSource.dashboard,
        day,
      );
      return CalendarDashboardDayProjection.fromSources(
        day: day,
        events: events,
        expenses: ExpenseLedgerScope.maybeOf(context),
        invoices: InvoiceLedgerScope.maybeOf(context)?.records ?? const [],
        workTime: EmployeeWorkTimeScope.maybeOf(context)?.records ?? const [],
        scope: CalendarRecapScope(
          vehicleId: active?.activeVehicleId ?? '',
          workProfileId: active?.workProfileId ?? '',
        ),
      );
    }
    if (widget.source == CalendarFlowSource.employee) {
      final employeeId = widget.employeeId?.trim() ?? '';
      final workTime = EmployeeWorkTimeScope.maybeOf(context);
      if (employeeId.isNotEmpty && workTime != null) {
        return calendarFilterToActiveContext(
          context,
          CalendarEmployeeDayProjection.forDay(
            workTime.recordsForEmployee(employeeId),
            day,
          ),
        );
      }
      return const CalendarDayData(recapItems: [], entries: []);
    }
    if (widget.source == CalendarFlowSource.invoices) {
      final ledger = InvoiceLedgerScope.maybeOf(context);
      if (ledger != null) {
        return calendarFilterToActiveContext(
          context,
          CalendarInvoiceDayProjection.forDay(ledger, day),
        );
      }
    }
    if (widget.source == CalendarFlowSource.maintenance) {
      return calendarFilterToActiveContext(
        context,
        calendarMaintenanceDataFor(context, day),
      );
    }
    return const CalendarDayData(recapItems: [], entries: []);
  }

  List<Widget> _pastDaySections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      CalendarSectionTitle.withAction(
        label: 'COMPLETED DAY RECAP',
        actionLabel: 'View recap',
        onPressed: () =>
            calendarOpenRecap(context, day, widget.source, widget.employeeId),
      ),
      const SizedBox(height: 8),
      CalendarRecapStrip(items: data.recapItems),
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: widget.source == CalendarFlowSource.expenses
            ? 'EXPENSE ENTRIES'
            : 'CHRONOLOGICAL ENTRIES',
        actionLabel: 'Add missed entry',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, data.entries),
      const SizedBox(height: 14),
      const CalendarStatusPanel(
        icon: Icons.edit_calendar_rounded,
        title: 'Past day record',
        subtitle:
            'Use this screen to correct entries or add something that happened on this date.',
      ),
    ];
  }

  List<Widget> _todaySections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      CalendarSectionTitle.withAction(
        label: 'ACTIVE DAY STATE',
        actionLabel: 'View recap',
        onPressed: () =>
            calendarOpenRecap(context, day, widget.source, widget.employeeId),
      ),
      const SizedBox(height: 8),
      const CalendarStatusPanel(
        icon: Icons.timer_rounded,
        title: 'Work day in progress',
        subtitle:
            'Today can show scheduled work and completed records together.',
      ),
      if (data.recapItems.isNotEmpty) ...[
        const SizedBox(height: 12),
        CalendarRecapStrip(items: data.recapItems),
      ],
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: 'CHRONOLOGICAL ENTRIES',
        actionLabel: 'Add missed entry',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, data.entries),
    ];
  }

  List<Widget> _futureSections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      CalendarSectionTitle.withAction(
        label: 'PLANNED ITEMS',
        actionLabel: 'Plan item',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, data.entries),
      const SizedBox(height: 14),
      const CalendarStatusPanel(
        icon: Icons.info_outline_rounded,
        title: 'Planning only',
        subtitle:
            'Future dates do not show completed recap. They are for jobs, reminders, notes, vehicles, helpers, and linked work.',
      ),
    ];
  }

  List<Widget> _timelineRows(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    List<CalendarTimelineEntry> entries,
  ) {
    return [
      CalendarFilteredTimeline(
        entries: entries,
        enableFiltering: widget.source == CalendarFlowSource.dashboard,
        onOpen: (entry) => _openEntryDetail(context, day, mode, entry),
      ),
    ];
  }

  void _openEntrySelector(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryTypeSelectorScreen(
          day: day,
          mode: mode,
          source: widget.source,
        ),
      ),
    );
  }

  void _openEntryDetail(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarTimelineEntry entry,
  ) {
    final deepLink = entry.projection?.deepLink;
    if (deepLink?.target == CalendarDeepLinkTarget.expenseDetail) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          ExpenseReceiptDetailScreen(receiptId: deepLink!.sourceRecordId),
        ),
      );
      return;
    }
    if (deepLink != null &&
        calendarOpenActiveWorkdayProjectionRoute(context, deepLink)) {
      return;
    }
    if (deepLink?.target == CalendarDeepLinkTarget.jobDetail) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          MaintainiacJobDetailScreen(jobId: deepLink!.sourceRecordId),
        ),
      );
      return;
    }
    if (deepLink?.target == CalendarDeepLinkTarget.maintenanceDetail) {
      final record = AppStateScope.of(context).allMaintenanceRecords.where(
        (candidate) => candidate.recordId == deepLink!.sourceRecordId,
      );
      if (record.isNotEmpty) {
        Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            MaintenanceItemDetailScreen(record: record.first),
          ),
        );
        return;
      }
      final matching = AppStateScope.of(context).maintenanceEvents.where(
        (candidate) =>
            CalendarMaintenanceProjectionAdapter.sourceIdFor(candidate) ==
            deepLink!.sourceRecordId,
      );
      if (matching.isNotEmpty) {
        Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            MaintenanceServiceEventDetailScreen(event: matching.first),
          ),
        );
        return;
      }
    }
    if (deepLink?.target == CalendarDeepLinkTarget.workTimeDetail) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          EmployeeWorkTimeDetailScreen(recordId: deepLink!.sourceRecordId),
        ),
      );
      return;
    }
    if (deepLink?.target == CalendarDeepLinkTarget.invoiceDetail ||
        deepLink?.target == CalendarDeepLinkTarget.estimateDetail ||
        deepLink?.target == CalendarDeepLinkTarget.paymentDetail) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          InvoiceFormScreen(recordId: deepLink!.sourceRecordId),
        ),
      );
      return;
    }
    if (deepLink?.target == CalendarDeepLinkTarget.reminderDetail) {
      Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          ExpenseReminderScreen(initialReminderId: deepLink!.sourceRecordId),
        ),
      );
      return;
    }
    if (entry.projection != null) {
      _showUnavailableSourceRecord(context, entry.projection!);
      return;
    }
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryDetailScreen(
          day: day,
          mode: mode,
          entry: entry,
          source: widget.source,
        ),
      ),
    );
  }

  Future<void> _showUnavailableSourceRecord(
    BuildContext context,
    CalendarProjectionEvent event,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Source record unavailable'),
      content: Text(
        '${event.source.name} record ${event.sourceRecordId} cannot be opened '
        'because its owner route is not available in this build. Calendar did '
        'not open a duplicate editor.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  void _shiftDay(int offset) {
    setState(() {
      _selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + offset,
      );
    });
  }
}
