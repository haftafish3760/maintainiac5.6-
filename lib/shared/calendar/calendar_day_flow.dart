import 'package:flutter/material.dart';
import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/expenses/data/expense_reminder_store.dart';
import '../../screens/invoices/data/invoice_ledger_store.dart';
import '../jobs/maintainiac_job_store.dart';
import '../context/operational_context_store.dart';
import '../profiles/employee_work_time_store.dart';
import '../navigation/app_page_routes.dart';
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
import 'calendar_day_entry_navigation.dart';
import 'calendar_cross_module_recap.dart';
import 'calendar_entry_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_month_projection_reader.dart';
import 'calendar_projection_contract.dart';
import 'calendar_schedule_editor_screen.dart';

class CalendarDayFlowScreen extends StatefulWidget {
  const CalendarDayFlowScreen({
    super.key,
    required this.day,
    this.source = CalendarFlowSource.dashboard,
    this.employeeId,
    this.sourceEventsForDay,
    this.sourceEventDetailBuilder,
  });

  final DateTime day;
  final CalendarFlowSource source;
  final String? employeeId;
  final List<CalendarProjectionEvent> Function(DateTime day)?
  sourceEventsForDay;
  final CalendarSourceEventDetailBuilder? sourceEventDetailBuilder;

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
        onPressed: () => _openScheduleEditor(context, _selectedDay),
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
          calendarDataWithSchedules(
            context,
            CalendarExpenseDayProjection.forDay(
              ledger,
              day,
              vehicleId: active?.activeVehicleId ?? '',
              workProfileId: active?.workProfileId ?? '',
              reminders: ExpenseReminderScope.of(context).records,
            ),
            CalendarFlowSource.expenses,
            day,
          ),
        );
      }
    }
    if (widget.source == CalendarFlowSource.contractor) {
      return calendarFilterToActiveContext(
        context,
        calendarDataWithSchedules(
          context,
          CalendarContractorDayProjection.forDay(
            day: day,
            expenses: ExpenseLedgerScope.maybeOf(context),
            jobs: MaintainiacJobScope.maybeOf(context),
            workTime: EmployeeWorkTimeScope.maybeOf(context),
          ),
          CalendarFlowSource.contractor,
          day,
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
          calendarDataWithSchedules(
            context,
            CalendarEmployeeDayProjection.forDay(
              workTime.recordsForEmployee(employeeId),
              day,
            ),
            CalendarFlowSource.employee,
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
          calendarDataWithSchedules(
            context,
            CalendarInvoiceDayProjection.forDay(ledger, day),
            CalendarFlowSource.invoices,
            day,
          ),
        );
      }
    }
    if (widget.source == CalendarFlowSource.maintenance) {
      return calendarFilterToActiveContext(
        context,
        calendarDataWithSchedules(
          context,
          calendarMaintenanceDataFor(context, day),
          CalendarFlowSource.maintenance,
          day,
        ),
      );
    }
    if (widget.source == CalendarFlowSource.materials &&
        widget.sourceEventsForDay != null) {
      final events = CalendarProjectionTimeline.normalize([
        ...widget.sourceEventsForDay!(day),
        ...CalendarMonthProjectionReader.calendarScheduleEventsForDay(
          context,
          CalendarFlowSource.materials,
          day,
        ),
      ]);
      return CalendarDayData(
        recapItems: [
          CalendarRecapItem(
            label: 'Inventory entries',
            value: '${events.length}',
          ),
          CalendarRecapItem(
            label: 'Needs review',
            value: '${events.where((event) => event.isActionable).length}',
          ),
        ],
        entries: [
          for (final event in events)
            CalendarTimelineEntry.fromProjection(event),
        ],
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
        actionLabel: 'Schedule item',
        onPressed: () => _openScheduleEditor(context, day),
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
        onOpen: (entry) => calendarOpenDayEntry(
          context,
          day: day,
          mode: mode,
          source: widget.source,
          entry: entry,
          sourceEventDetailBuilder: widget.sourceEventDetailBuilder,
        ),
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

  void _openScheduleEditor(BuildContext context, DateTime day) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarScheduleEditorScreen(day: day, source: widget.source),
      ),
    );
  }

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
