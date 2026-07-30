import 'package:flutter/material.dart';

import '../../../shared/calendar/calendar_flow_models.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/work_supply_inventory_recap.dart';
import '../data/work_supply_models.dart';
import 'work_supply_calendar_panel.dart';

part 'work_supply_inventory_calendar_sections.dart';

class WorkSupplyInventoryCalendarScreen extends StatefulWidget {
  const WorkSupplyInventoryCalendarScreen({super.key, required this.records});

  final List<WorkSupplyInventoryRecord> records;

  @override
  State<WorkSupplyInventoryCalendarScreen> createState() =>
      _WorkSupplyInventoryCalendarScreenState();
}

class _WorkSupplyInventoryCalendarScreenState
    extends State<WorkSupplyInventoryCalendarScreen> {
  late DateTime _selectedDay = _dayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final selectedRecords = _recordsForDay(_selectedDay);
    final selectedEvents = [
      for (final record in selectedRecords)
        WorkSupplyInventoryActivity.fromRecord(record),
    ];
    final monthRecap = buildWorkSupplyMonthRecap(
      records: widget.records,
      month: _selectedDay,
    );
    return AppScreenShell(
      section: AppSection.materials,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _CalendarTitle(),
                const SizedBox(height: 10),
                WorkSupplyCalendarPanel(
                  markersByDay: _inventoryMarkers(widget.records),
                  onDaySelected: (day) {
                    setState(() => _selectedDay = _dayKey(day));
                  },
                  calendarSource: CalendarFlowSource.materials,
                ),
                const SizedBox(height: 10),
                _InventoryMonthRecapPanel(recap: monthRecap),
                const SizedBox(height: 10),
                _InventoryDayPanel(
                  day: _selectedDay,
                  records: selectedRecords,
                  events: selectedEvents,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<WorkSupplyInventoryRecord> _recordsForDay(DateTime day) {
    return widget.records.where((record) {
      final loggedAt = record.loggedAt;
      if (loggedAt == null) return false;
      return _dayKey(loggedAt) == day;
    }).toList();
  }
}
