import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../navigation/app_page_routes.dart';
import 'calendar_day_flow.dart';
import 'calendar_flow_models.dart';
import 'month_year_picker.dart';

part 'app_month_calendar_widgets.dart';

class AppMonthCalendar extends StatefulWidget {
  const AppMonthCalendar({
    super.key,
    this.source = CalendarFlowSource.dashboard,
    this.dayEntryCounts = const <DateTime, int>{},
  });

  final CalendarFlowSource source;
  final Map<DateTime, int> dayEntryCounts;

  @override
  State<AppMonthCalendar> createState() => _AppMonthCalendarState();
}

class _AppMonthCalendarState extends State<AppMonthCalendar> {
  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _scheduledDays = <DateTime>{
    DateTime.utc(2026, 5, 18),
    DateTime.utc(2026, 5, 23),
    DateTime.utc(2026, 5, 30),
  };

  final _completedDays = <DateTime>{
    DateTime.utc(2026, 5, 12),
    DateTime.utc(2026, 5, 15),
    DateTime.utc(2026, 5, 16),
  };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CalendarPanelPainter(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF111517), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TableCalendar<void>(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          headerVisible: true,
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          sixWeekMonthsEnforced: true,
          rowHeight: 70,
          daysOfWeekHeight: 26,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (date, locale) {
              final selected = _selectedDay;
              if (selected != null) {
                return calendarFullDateLabel(selected);
              }
              return calendarMonthYearLabel(date);
            },
            titleTextStyle: const TextStyle(
              color: Color(0xFFF7FAF4),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                Shadow(
                  color: Color(0xAA000000),
                  blurRadius: 5,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            weekendStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
            tablePadding: EdgeInsets.zero,
            tableBorder: TableBorder(
              horizontalInside: BorderSide(
                color: Color(0xFF111517),
                width: 1.2,
              ),
              verticalInside: BorderSide(color: Color(0xFF111517), width: 1.2),
              top: BorderSide(color: Color(0xFF111517), width: 1.2),
              bottom: BorderSide(color: Color(0xFF111517), width: 1.2),
              left: BorderSide(color: Color(0xFF111517), width: 1.2),
              right: BorderSide(color: Color(0xFF111517), width: 1.2),
            ),
            markersMaxCount: 0,
            markerSize: 0,
            defaultTextStyle: TextStyle(
              color: Color(0xFF111517),
              fontWeight: FontWeight.w800,
            ),
            weekendTextStyle: TextStyle(
              color: Color(0xFF111517),
              fontWeight: FontWeight.w800,
            ),
            todayDecoration: BoxDecoration(),
            selectedDecoration: BoxDecoration(),
            defaultDecoration: BoxDecoration(),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
            });
            _openCalendarDay(context, selectedDay);
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          onHeaderTapped: (_) => _openMonthYearPicker(context),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: _calendarDayBuilder,
            todayBuilder: _calendarDayBuilder,
            selectedBuilder: _calendarDayBuilder,
            outsideBuilder: _calendarOutsideDayBuilder,
          ),
        ),
      ),
    );
  }

  void _openCalendarDay(BuildContext context, DateTime day) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarDayFlowScreen(day: day, source: widget.source),
      ),
    );
  }

  Future<void> _openMonthYearPicker(BuildContext context) async {
    final selection = await showCalendarMonthYearPicker(
      context: context,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
    );
    if (!mounted || selection == null) {
      return;
    }
    setState(() {
      _focusedDay = selection.focusedMonth;
      if (selection.selectedDate != null) {
        _selectedDay = selection.selectedDate;
      }
    });
  }

  Widget? _calendarDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    final showDemoMarkers = widget.source != CalendarFlowSource.maintenance;
    final hasScheduled = showDemoMarkers && _scheduledDays.contains(normalized);
    final hasCompleted = showDemoMarkers && _completedDays.contains(normalized);
    final isSelected = isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);
    final entryCount = widget.dayEntryCounts[normalized] ?? 0;

    return _CalendarDayCell(
      day: day,
      hasScheduled: hasScheduled,
      hasCompleted: hasCompleted,
      isSelected: isSelected,
      isToday: isToday,
      entryCount: entryCount,
    );
  }

  Widget? _calendarOutsideDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final isSelected = isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);

    return _CalendarDayCell(
      day: day,
      hasScheduled: false,
      hasCompleted: false,
      isSelected: isSelected,
      isToday: isToday,
      entryCount: 0,
      isOutsideMonth: true,
    );
  }
}
