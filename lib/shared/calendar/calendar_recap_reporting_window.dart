// Calendar recap reporting-window helper. It prevents a current-period recap
// from treating future-dated source records as completed financial activity.

import 'calendar_recap_period_contract.dart';

CalendarRecapDateRange calendarRecapRangeThroughToday(
  CalendarRecapDateRange range, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final start = range.start;
  if (!range.end.isAfter(today) || (start != null && start.isAfter(today))) {
    return range;
  }
  return CalendarRecapDateRange(start: start, end: today);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
