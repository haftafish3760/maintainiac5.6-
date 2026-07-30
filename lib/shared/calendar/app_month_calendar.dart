import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../navigation/app_page_routes.dart';
import 'calendar_day_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_month_event_badge.dart';
import 'calendar_month_projection_reader.dart';
import 'month_year_picker.dart';

part 'app_month_calendar_widgets.dart';

class AppMonthCalendar extends StatefulWidget {
  const AppMonthCalendar({
    super.key,
    this.source = CalendarFlowSource.dashboard,
    this.dayEntryCounts = const <DateTime, int>{},
    this.dayBadges = const <DateTime, CalendarMonthEventBadge>{},
    this.employeeId,
    this.onDaySelected,
    this.openCalendarDay = true,
  });

  final CalendarFlowSource source;
  final Map<DateTime, int> dayEntryCounts;
  final Map<DateTime, CalendarMonthEventBadge> dayBadges;
  final String? employeeId;
  final ValueChanged<DateTime>? onDaySelected;
  final bool openCalendarDay;

  @override
  State<AppMonthCalendar> createState() => _AppMonthCalendarState();
}

class _AppMonthCalendarState extends State<AppMonthCalendar> {
  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
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
            firstDay: DateTime.utc(1900),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerVisible: true,
            // Preserve the 5.6 large, always-month tile presentation. Day and
            // month navigation remain available without collapsing this shared
            // landing Calendar into a week layout.
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            sixWeekMonthsEnforced: true,
            rowHeight: _rowHeightFor(constraints.maxWidth),
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
                verticalInside: BorderSide(
                  color: Color(0xFF111517),
                  width: 1.2,
                ),
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
                _focusedDay = focusedDay;
              });
              widget.onDaySelected?.call(selectedDay);
              if (widget.openCalendarDay) {
                _openCalendarDay(context, selectedDay);
              }
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
      ),
    );
  }

  double _rowHeightFor(double width) {
    if (width >= 960) return 92;
    if (width >= 680) return 80;
    return 70;
  }

  void _openCalendarDay(BuildContext context, DateTime day) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarDayFlowScreen(
          day: day,
          source: widget.source,
          employeeId: widget.employeeId,
        ),
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
    final projectedBadge = CalendarMonthEventBadge.fromEvents(
      CalendarMonthProjectionReader.eventsForDay(
        context,
        widget.source,
        day,
        employeeId: widget.employeeId,
      ),
    );
    final badge = projectedBadge.entryCount > 0
        ? projectedBadge
        : widget.dayBadges[normalized] ?? projectedBadge;
    final isSelected = isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);
    final entryCount = badge.entryCount > 0
        ? badge.entryCount
        : widget.dayEntryCounts[normalized] ?? 0;

    return _CalendarDayCell(
      day: day,
      hasScheduled: badge.hasScheduled,
      hasCompleted: badge.hasCompleted,
      plannedEntryCount: badge.plannedEntryCount,
      confirmedEntryCount: badge.confirmedEntryCount,
      reviewRequiredEntryCount: badge.reviewRequiredEntryCount,
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
      plannedEntryCount: 0,
      confirmedEntryCount: 0,
      reviewRequiredEntryCount: 0,
      isSelected: isSelected,
      isToday: isToday,
      entryCount: 0,
      isOutsideMonth: true,
    );
  }
}

String calendarDayAccessibilityLabel({
  required DateTime day,
  required int entryCount,
  required bool hasScheduled,
  required bool hasCompleted,
  int plannedEntryCount = 0,
  int confirmedEntryCount = 0,
  int reviewRequiredEntryCount = 0,
  required bool isOutsideMonth,
}) {
  final details = <String>[
    '${day.month}/${day.day}/${day.year}',
    if (isOutsideMonth) 'outside the selected month',
    if (!isOutsideMonth && entryCount == 0) 'no calendar entries',
    if (!isOutsideMonth && entryCount == 1) '1 calendar entry',
    if (!isOutsideMonth && entryCount > 1) '$entryCount calendar entries',
    if (hasScheduled) 'scheduled work',
    if (plannedEntryCount > 0) '$plannedEntryCount planned entries',
    if (hasCompleted) '$confirmedEntryCount confirmed or historical records',
    if (reviewRequiredEntryCount > 0)
      '$reviewRequiredEntryCount entries need review',
  ];
  return details.join('. ');
}
