// Calendar recap-period contract. It defines date-only reporting windows for
// source-owned records and never stores recap totals or rewrites source data.

enum CalendarRecapPeriod {
  currentWeek,
  currentMonth,
  currentNinetyDays,
  yearToDate,
  previousSevenDays,
  previousThirtyDays,
  previousNinetyDays,
  lifetime,
}

enum CalendarWeekStart {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class CalendarRecapDateRange {
  const CalendarRecapDateRange({required this.start, required this.end});

  /// A null start is an all-history/lifetime query. The source owner decides
  /// the earliest available retained record without inventing a date.
  final DateTime? start;
  final DateTime end;

  bool contains(DateTime value) {
    final day = _dateOnly(value);
    return !day.isAfter(end) && (start == null || !day.isBefore(start!));
  }

  int? get inclusiveDayCount =>
      start == null ? null : end.difference(start!).inDays + 1;
}

extension CalendarRecapPeriodDetails on CalendarRecapPeriod {
  String get label => switch (this) {
    CalendarRecapPeriod.currentWeek => 'Current week',
    CalendarRecapPeriod.currentMonth => 'Current month',
    CalendarRecapPeriod.currentNinetyDays => 'Current 90 days',
    CalendarRecapPeriod.yearToDate => 'Year to date',
    CalendarRecapPeriod.previousSevenDays => 'Previous 7 days',
    CalendarRecapPeriod.previousThirtyDays => 'Previous 30 days',
    CalendarRecapPeriod.previousNinetyDays => 'Previous 90 days',
    CalendarRecapPeriod.lifetime => 'Lifetime',
  };

  CalendarRecapDateRange rangeFor(
    DateTime anchor, {
    CalendarWeekStart weekStart = CalendarWeekStart.monday,
  }) {
    final end = _dateOnly(anchor);
    return switch (this) {
      CalendarRecapPeriod.currentWeek => CalendarRecapDateRange(
        start: _weekStartFor(end, weekStart),
        end: _addCalendarDays(_weekStartFor(end, weekStart), 6),
      ),
      CalendarRecapPeriod.currentMonth => CalendarRecapDateRange(
        start: DateTime(end.year, end.month),
        end: DateTime(end.year, end.month + 1, 0),
      ),
      CalendarRecapPeriod.currentNinetyDays => CalendarRecapDateRange(
        start: _addCalendarDays(end, -89),
        end: end,
      ),
      CalendarRecapPeriod.yearToDate => CalendarRecapDateRange(
        start: DateTime(end.year),
        end: end,
      ),
      CalendarRecapPeriod.previousSevenDays => CalendarRecapDateRange(
        start: _addCalendarDays(end, -7),
        end: _addCalendarDays(end, -1),
      ),
      CalendarRecapPeriod.previousThirtyDays => CalendarRecapDateRange(
        start: _addCalendarDays(end, -30),
        end: _addCalendarDays(end, -1),
      ),
      CalendarRecapPeriod.previousNinetyDays => CalendarRecapDateRange(
        start: _addCalendarDays(end, -90),
        end: _addCalendarDays(end, -1),
      ),
      CalendarRecapPeriod.lifetime => CalendarRecapDateRange(
        start: null,
        end: end,
      ),
    };
  }
}

DateTime _weekStartFor(DateTime day, CalendarWeekStart weekStart) {
  final startWeekday = weekStart.index + DateTime.monday;
  final offset = (day.weekday - startWeekday + 7) % 7;
  return _addCalendarDays(day, -offset);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _addCalendarDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);
