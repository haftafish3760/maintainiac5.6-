// Calendar range recap presentation. It reads source-owned records and never
// stores derived totals or invents lifetime event-state counts.

import 'package:flutter/material.dart';

import '../../screens/expenses/data/expense_ledger_store.dart';
import '../../screens/invoices/data/invoice_ledger_store.dart';
import '../context/operational_context_store.dart';
import '../profiles/employee_work_time_contract.dart';
import '../profiles/employee_work_time_store.dart';
import '../widgets/app_back_button.dart';
import 'calendar_cross_module_recap.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_month_projection_reader.dart';
import 'calendar_projection_contract.dart';
import 'calendar_recap_period_contract.dart';
import 'calendar_recap_reporting_window.dart';

class CalendarRecapScreen extends StatefulWidget {
  const CalendarRecapScreen({
    super.key,
    required this.anchorDay,
    required this.source,
    this.employeeId,
  });

  final DateTime anchorDay;
  final CalendarFlowSource source;
  final String? employeeId;

  @override
  State<CalendarRecapScreen> createState() => _CalendarRecapScreenState();
}

class _CalendarRecapScreenState extends State<CalendarRecapScreen> {
  var _period = CalendarRecapPeriod.currentWeek;

  @override
  Widget build(BuildContext context) {
    final range = calendarRecapRangeThroughToday(
      _period.rangeFor(widget.anchorDay),
    );
    final hasEventCoverage = range.start != null;
    final events = hasEventCoverage
        ? _eventsForRange(context, range)
        : const <CalendarProjectionEvent>[];
    final active = OperationalContextScope.maybeOf(context)?.context;
    final recap = CalendarCrossModuleRecap.fromSources(
      range: range,
      events: events,
      expenses: _includesExpenses ? ExpenseLedgerScope.maybeOf(context) : null,
      invoices: _includesInvoices
          ? InvoiceLedgerScope.maybeOf(context)?.records ?? const []
          : const [],
      workTime: _workTimeFor(context),
      scope: CalendarRecapScope(
        vehicleId: active?.activeVehicleId ?? '',
        workProfileId: active?.workProfileId ?? '',
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            const AppBackButton(),
            const SizedBox(height: 8),
            AppScreenHeader(title: '${_recapTitle(widget.source)} Recap'),
            const SizedBox(height: 12),
            CalendarStatusPanel(
              icon: Icons.insights_rounded,
              title: _period.label,
              subtitle: _rangeLabel(range),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final period in CalendarRecapPeriod.values)
                  ChoiceChip(
                    label: Text(period.label),
                    selected: period == _period,
                    onSelected: (_) => setState(() => _period = period),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const CalendarSectionTitle('FINANCIAL AND TIME RECAP'),
            const SizedBox(height: 8),
            if (_hasRangeTotals)
              CalendarRecapStrip(items: _financialItems(recap))
            else
              const CalendarStatusPanel(
                icon: Icons.info_outline_rounded,
                title: 'Maintenance cost range is source-owned',
                subtitle:
                    'Maintenance events are shown in Calendar, but this build does not derive a full maintenance-cost range total here. Calendar will not present a zero total as complete financial history.',
              ),
            const SizedBox(height: 16),
            const CalendarSectionTitle('CALENDAR EVIDENCE'),
            const SizedBox(height: 8),
            if (hasEventCoverage)
              CalendarRecapStrip(items: _eventItems(recap))
            else
              const CalendarStatusPanel(
                icon: Icons.history_toggle_off_rounded,
                title: 'Lifetime event states are not enumerated here',
                subtitle:
                    'Financial and work-time totals are source-derived. Calendar does not run an unbounded event scan or present a partial event count as lifetime truth.',
              ),
            const SizedBox(height: 16),
            CalendarStatusPanel(
              icon: Icons.verified_user_rounded,
              title: 'Source-derived recap',
              subtitle:
                  'Changing a dated receipt, payment, invoice, or work-time record updates this recap from that business date forward. Net cash flow is not profit.',
            ),
          ],
        ),
      ),
    );
  }

  List<CalendarProjectionEvent> _eventsForRange(
    BuildContext context,
    CalendarRecapDateRange range,
  ) {
    final start = range.start!;
    final events = <CalendarProjectionEvent>[];
    for (
      var day = start;
      !day.isAfter(range.end);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      events.addAll(
        CalendarMonthProjectionReader.eventsForDay(context, widget.source, day),
      );
    }
    return CalendarProjectionTimeline.normalize(events);
  }

  bool get _includesExpenses =>
      widget.source == CalendarFlowSource.dashboard ||
      widget.source == CalendarFlowSource.contractor ||
      widget.source == CalendarFlowSource.expenses;

  bool get _includesInvoices =>
      widget.source == CalendarFlowSource.dashboard ||
      widget.source == CalendarFlowSource.contractor ||
      widget.source == CalendarFlowSource.invoices;

  bool get _hasRangeTotals => widget.source != CalendarFlowSource.maintenance;

  Iterable<EmployeeWorkTimeRecord> _workTimeFor(BuildContext context) {
    final records = EmployeeWorkTimeScope.maybeOf(context)?.records ?? const [];
    if (widget.source != CalendarFlowSource.employee) return records;
    final employeeId = widget.employeeId?.trim() ?? '';
    return employeeId.isEmpty
        ? const []
        : records.where((record) => record.employeeId == employeeId);
  }
}

List<CalendarRecapItem> _financialItems(CalendarCrossModuleRecap recap) => [
  CalendarRecapItem(
    label: 'Cash received',
    value: _money(recap.paymentReceived),
  ),
  CalendarRecapItem(
    label: 'Business spend',
    value: _money(recap.businessExpense),
  ),
  CalendarRecapItem(label: 'Net cash flow', value: _money(recap.netCashFlow)),
  CalendarRecapItem(
    label: 'Approved hours',
    value: recap.approvedWorkHours.toStringAsFixed(2),
  ),
  CalendarRecapItem(
    label: 'Pending hours',
    value: recap.pendingWorkHours.toStringAsFixed(2),
  ),
  CalendarRecapItem(
    label: 'Invoices billed',
    value: _money(recap.invoiceBilled),
  ),
];

List<CalendarRecapItem> _eventItems(CalendarCrossModuleRecap recap) => [
  CalendarRecapItem(label: 'Events', value: '${recap.eventCount}'),
  CalendarRecapItem(label: 'Confirmed', value: '${recap.confirmedCount}'),
  CalendarRecapItem(label: 'Needs review', value: '${recap.needsReviewCount}'),
  CalendarRecapItem(label: 'Incomplete', value: '${recap.incompleteCount}'),
];

String _money(double amount) => '\$${amount.toStringAsFixed(2)}';

String _rangeLabel(CalendarRecapDateRange range) {
  final start = range.start;
  if (start == null) {
    return 'All retained source records through ${_date(range.end)}';
  }
  return '${_date(start)} through ${_date(range.end)}';
}

String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';

String _recapTitle(CalendarFlowSource source) => switch (source) {
  CalendarFlowSource.expenses => 'Expense Calendar',
  CalendarFlowSource.maintenance => 'Maintenance Calendar',
  CalendarFlowSource.contractor => 'Contractor Calendar',
  CalendarFlowSource.jobs => 'Jobs Calendar',
  CalendarFlowSource.materials => 'Materials Calendar',
  CalendarFlowSource.employee => 'Employee Calendar',
  _ => 'Calendar',
};
