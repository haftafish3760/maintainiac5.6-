// Shared schedule recurrence contract. Source owners persist plans; Calendar
// and other presentation layers deterministically expand them without copying.

enum CalendarScheduleFrequency {
  once,
  daily,
  weekly,
  biweekly,
  monthly,
  customDays,
}

class CalendarScheduleRule {
  const CalendarScheduleRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.weekdays = const <int>{},
  }) : assert(interval > 0);

  final CalendarScheduleFrequency frequency;
  final int interval;
  final DateTime? until;
  final Set<int> weekdays;
}

class CalendarScheduleException {
  CalendarScheduleException({
    required this.day,
    this.cancelled = false,
    this.startOverride,
    this.endOverride,
  }) : assert(
         startOverride == null ||
             endOverride == null ||
             !endOverride.isBefore(startOverride),
       );

  final DateTime day;
  final bool cancelled;
  final DateTime? startOverride;
  final DateTime? endOverride;
}

class CalendarScheduleOccurrence {
  CalendarScheduleOccurrence({
    required this.id,
    required this.start,
    this.end,
    required this.isOverride,
  }) : assert(end == null || !end.isBefore(start));
  final String id;
  final DateTime start;
  final DateTime? end;
  final bool isOverride;
}

class CalendarScheduleRecurrence {
  const CalendarScheduleRecurrence._();

  static List<CalendarScheduleOccurrence> occurrencesForRange({
    required String sourceRecordId,
    required DateTime start,
    DateTime? end,
    required CalendarScheduleRule rule,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    Iterable<CalendarScheduleException> exceptions = const [],
  }) {
    if (rangeEnd.isBefore(rangeStart)) return const [];
    if (end != null && end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'must not be before start');
    }
    if (rule.weekdays.any(
      (weekday) => weekday < DateTime.monday || weekday > DateTime.sunday,
    )) {
      throw ArgumentError.value(
        rule.weekdays,
        'rule.weekdays',
        'must contain only DateTime weekday values',
      );
    }
    final result = <CalendarScheduleOccurrence>[];
    final exceptionsByDay = <String, CalendarScheduleException>{};
    for (final exception in exceptions) {
      final key = _dayKey(exception.day);
      if (exceptionsByDay.containsKey(key)) {
        throw ArgumentError.value(
          exception.day,
          'exceptions',
          'contains more than one exception for $key',
        );
      }
      exceptionsByDay[key] = exception;
    }
    for (
      var day = _dateOnly(rangeStart);
      !day.isAfter(_dateOnly(rangeEnd));
      day = _nextCalendarDay(day)
    ) {
      if (!_matches(start, day, rule)) continue;
      if (rule.until != null && day.isAfter(_dateOnly(rule.until!))) continue;
      final exception = exceptionsByDay[_dayKey(day)];
      if (exception?.cancelled == true) continue;
      final occurrenceStart = exception?.startOverride ?? _atDay(start, day);
      final duration = end?.difference(start);
      final occurrenceEnd =
          exception?.endOverride ??
          (duration == null ? null : occurrenceStart.add(duration));
      if (occurrenceEnd != null && occurrenceEnd.isBefore(occurrenceStart)) {
        throw ArgumentError.value(
          exception?.endOverride,
          'exceptions',
          'cannot end before its effective occurrence start',
        );
      }
      result.add(
        CalendarScheduleOccurrence(
          id: '$sourceRecordId:${_dayKey(day)}',
          start: occurrenceStart,
          end: occurrenceEnd,
          isOverride: exception != null,
        ),
      );
    }
    return result;
  }
}

bool _matches(DateTime start, DateTime day, CalendarScheduleRule rule) {
  final first = _dateOnly(start);
  if (day.isBefore(first)) return false;
  final delta = day.difference(first).inDays;
  return switch (rule.frequency) {
    CalendarScheduleFrequency.once => delta == 0,
    CalendarScheduleFrequency.daily => delta % rule.interval == 0,
    CalendarScheduleFrequency.customDays => _matchesCustomDays(
      day,
      delta,
      rule,
    ),
    CalendarScheduleFrequency.weekly || CalendarScheduleFrequency.biweekly =>
      (rule.weekdays.isEmpty
              ? day.weekday == start.weekday
              : rule.weekdays.contains(day.weekday)) &&
          (delta ~/ 7) %
                  (rule.frequency == CalendarScheduleFrequency.biweekly
                      ? 2 * rule.interval
                      : rule.interval) ==
              0,
    CalendarScheduleFrequency.monthly => _matchesMonthly(start, day, rule),
  };
}

bool _matchesCustomDays(DateTime day, int delta, CalendarScheduleRule rule) {
  if (delta == 0) return true;
  if (rule.weekdays.isEmpty) return delta % rule.interval == 0;
  return rule.weekdays.contains(day.weekday) &&
      (delta ~/ 7) % rule.interval == 0;
}

bool _matchesMonthly(DateTime start, DateTime day, CalendarScheduleRule rule) {
  final months = (day.year - start.year) * 12 + day.month - start.month;
  if (months < 0 || months % rule.interval != 0) return false;
  return _sameDay(_addMonths(start, months), day);
}

DateTime _addMonths(DateTime value, int months) {
  final monthIndex = value.month - 1 + months;
  final year = value.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, value.day.clamp(1, lastDay).toInt());
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _nextCalendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day + 1);

DateTime _atDay(DateTime source, DateTime day) => DateTime(
  day.year,
  day.month,
  day.day,
  source.hour,
  source.minute,
  source.second,
  source.millisecond,
  source.microsecond,
);
String _dayKey(DateTime value) =>
    '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';
