// Calendar ownership: Work Supplies supplies source events and markers; the
// shared Calendar owns the responsive month-tile presentation and navigation.

import 'package:flutter/material.dart';

import '../../../shared/calendar/app_month_calendar.dart';
import '../../../shared/calendar/calendar_flow_models.dart';
import '../../../shared/calendar/calendar_month_event_badge.dart';
import '../../../shared/calendar/calendar_projection_contract.dart';

class WorkSupplyCalendarMarker {
  const WorkSupplyCalendarMarker({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;
}

class WorkSupplyCalendarPanel extends StatelessWidget {
  const WorkSupplyCalendarPanel({
    super.key,
    required this.markersByDay,
    required this.onDaySelected,
    required this.calendarSource,
    this.openCalendarDay = false,
    this.dayEventsForDay,
    this.sourceEventDetailBuilder,
  });

  final Map<DateTime, List<WorkSupplyCalendarMarker>> markersByDay;
  final ValueChanged<DateTime> onDaySelected;
  final CalendarFlowSource calendarSource;
  final bool openCalendarDay;
  final List<CalendarProjectionEvent> Function(DateTime day)? dayEventsForDay;
  final CalendarSourceEventDetailBuilder? sourceEventDetailBuilder;

  @override
  Widget build(BuildContext context) => AppMonthCalendar(
    source: calendarSource,
    onDaySelected: onDaySelected,
    dayBadges: _sharedBadges(),
    openCalendarDay: openCalendarDay,
    dayEventsForDay: dayEventsForDay,
    sourceEventDetailBuilder: sourceEventDetailBuilder,
  );

  Map<DateTime, CalendarMonthEventBadge> _sharedBadges() => {
    for (final entry in markersByDay.entries)
      DateTime.utc(
        entry.key.year,
        entry.key.month,
        entry.key.day,
      ): CalendarMonthEventBadge(
        entryCount: entry.value.fold(
          0,
          (total, marker) => total + marker.count,
        ),
        plannedEntryCount: 0,
        confirmedEntryCount: entry.value.fold(
          0,
          (total, marker) => total + marker.count,
        ),
        reviewRequiredEntryCount: 0,
        hasScheduled: false,
        hasCompleted: entry.value.isNotEmpty,
      ),
  };
}
