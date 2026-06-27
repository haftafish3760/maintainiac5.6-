import 'package:flutter/material.dart';

import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import '../widgets/app_back_button.dart';
import 'month_year_picker.dart';
import 'calendar_dummy_data.dart';
import 'calendar_entry_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';

class CalendarDayFlowScreen extends StatefulWidget {
  const CalendarDayFlowScreen({
    super.key,
    required this.day,
    this.source = CalendarFlowSource.dashboard,
  });

  final DateTime day;
  final CalendarFlowSource source;

  @override
  State<CalendarDayFlowScreen> createState() => _CalendarDayFlowScreenState();
}

class _CalendarDayFlowScreenState extends State<CalendarDayFlowScreen> {
  late var _selectedDay = DateUtils.dateOnly(widget.day);

  @override
  Widget build(BuildContext context) {
    final mode = calendarModeFor(_selectedDay);
    final profile = calendarModeProfileFor(mode);
    final data = widget.source == CalendarFlowSource.maintenance
        ? _maintenanceDataFor(context, _selectedDay, mode)
        : calendarDummyDataFor(_selectedDay, mode, source: widget.source);

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
            AppScreenHeader(title: _screenTitle()),
            const SizedBox(height: 12),
            _CalendarDayNavigation(
              day: _selectedDay,
              onPreviousDay: () => _shiftDay(-1),
              onNextDay: () => _shiftDay(1),
            ),
            const SizedBox(height: 12),
            CalendarModeHeader(day: _selectedDay, profile: profile),
            const SizedBox(height: 12),
            if (widget.source == CalendarFlowSource.employee ||
                widget.source == CalendarFlowSource.contractor) ...[
              _CalendarDayVehiclePanel(source: widget.source),
              const SizedBox(height: 12),
            ],
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

  List<Widget> _pastDaySections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      const CalendarSectionTitle('COMPLETED DAY RECAP'),
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
    final planned = data.entriesForStatus(CalendarEntryStatus.planned);
    final logged =
        data.entries
            .where((entry) => entry.status != CalendarEntryStatus.planned)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return [
      const CalendarSectionTitle('ACTIVE DAY STATE'),
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
        label: 'PLANNED TODAY',
        actionLabel: 'Add plan',
        onPressed: () => _openEntryDraft(
          context,
          day,
          mode,
          CalendarEntryType.reminderSchedule,
        ),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, planned),
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: 'LOGGED TODAY',
        actionLabel: 'Quick add',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, logged),
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
    if (entries.isEmpty) {
      return const [
        CalendarStatusPanel(
          icon: Icons.inbox_rounded,
          title: 'No entries yet',
          subtitle: 'Use the action button to add something for this date.',
        ),
      ];
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return [
      for (final entry in sortedEntries)
        CalendarTimelineItem(
          entry: entry,
          onTap: () => _openEntryDetail(context, day, mode, entry),
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

  void _openEntryDraft(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarEntryType type,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryDraftScreen(
          day: day,
          mode: mode,
          type: type,
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

  void _shiftDay(int offset) {
    setState(() {
      _selectedDay = DateUtils.dateOnly(
        _selectedDay.add(Duration(days: offset)),
      );
    });
  }

  String _screenTitle() {
    return switch (widget.source) {
      CalendarFlowSource.expenses => 'Expense Calendar',
      CalendarFlowSource.maintenance => 'Maintenance Calendar',
      CalendarFlowSource.contractor => 'Contractor Calendar',
      CalendarFlowSource.employee => 'Employee Calendar',
      _ => 'Calendar',
    };
  }
}

CalendarDayData _maintenanceDataFor(
  BuildContext context,
  DateTime day,
  CalendarDayMode mode,
) {
  if (mode == CalendarDayMode.future) {
    return const CalendarDayData(recapItems: [], entries: []);
  }
  final state = AppStateScope.of(context);
  final normalized = DateUtils.dateOnly(day);
  final events =
      state.maintenanceEvents
          .where((event) => DateUtils.isSameDay(event.serviceDate, normalized))
          .toList()
        ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
  final totalCost = events.fold<double>(
    0,
    (sum, event) => sum + event.totalCost,
  );
  final receiptProofs = events.fold<int>(
    0,
    (sum, event) => sum + event.receiptProofCount,
  );
  final vehicles = events.map((event) => event.vehicleName).toSet().length;
  return CalendarDayData(
    recapItems: [
      CalendarRecapItem(label: 'Services', value: events.length.toString()),
      CalendarRecapItem(label: 'Vehicles', value: vehicles.toString()),
      CalendarRecapItem(label: 'Receipts', value: receiptProofs.toString()),
      CalendarRecapItem(label: 'Cost', value: _moneyLabel(totalCost)),
    ],
    entries: [
      for (var index = 0; index < events.length; index++)
        _maintenanceEntry(events[index], index),
    ],
  );
}

CalendarTimelineEntry _maintenanceEntry(
  MaintenanceServiceEvent event,
  int index,
) {
  return CalendarTimelineEntry(
    id: 'maintenance-${event.vehicleName}-${event.itemName}-$index',
    timestamp: event.serviceDate,
    type: CalendarEntryType.maintenance,
    status: CalendarEntryStatus.completed,
    title: event.itemName,
    source: 'Maintenance',
    summary: '${event.vehicleName} - ${event.odometer} miles',
    details: [
      'Vehicle: ${event.vehicleName}',
      'Odometer: ${event.odometer}',
      if (event.provider.trim().isNotEmpty) 'Provider: ${event.provider}',
      if (event.totalCost > 0) 'Cost: ${_moneyLabel(event.totalCost)}',
      if (event.receiptProofCount > 0)
        'Receipt proof: ${event.receiptProofCount}',
      if (event.notes.trim().isNotEmpty) 'Notes: ${event.notes}',
    ],
  );
}

String _moneyLabel(double amount) {
  if (amount <= 0) return r'$0';
  return '\$${amount.toStringAsFixed(2)}';
}

class _CalendarDayNavigation extends StatelessWidget {
  const _CalendarDayNavigation({
    required this.day,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime day;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPreviousDay,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFE2E8EA),
            ),
          ),
          Expanded(
            child: Text(
              calendarFullDateLabel(day),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: onNextDay,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFE2E8EA),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayVehiclePanel extends StatelessWidget {
  const _CalendarDayVehiclePanel({required this.source});

  final CalendarFlowSource source;

  @override
  Widget build(BuildContext context) {
    final vehicles = source == CalendarFlowSource.employee
        ? const ['Work Truck 1', 'Service Van 2']
        : const ['Active Vehicle', 'Supply Trailer'];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF7CC7FF),
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicles Used',
                  style: TextStyle(
                    color: Color(0xFF9FB0B7),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  vehicles.join(' / '),
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
