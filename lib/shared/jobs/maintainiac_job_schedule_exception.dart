// Source-owned Job schedule exceptions. Jobs persist skipped or rescheduled
// occurrences; Calendar only reads these values into its projection.

import '../scheduling/schedule_recurrence_contract.dart';

class MaintainiacJobScheduleException {
  const MaintainiacJobScheduleException({
    required this.day,
    this.cancelled = false,
    this.startOverride,
    this.endOverride,
  });

  factory MaintainiacJobScheduleException.fromMap(Map<dynamic, dynamic> map) {
    return MaintainiacJobScheduleException(
      day: _date(map['day']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      cancelled: map['cancelled'] == true,
      startOverride: _date(map['startOverride']),
      endOverride: _date(map['endOverride']),
    );
  }

  final DateTime day;
  final bool cancelled;
  final DateTime? startOverride;
  final DateTime? endOverride;

  Map<String, Object?> toMap() => {
    'day': day.toIso8601String(),
    'cancelled': cancelled,
    'startOverride': startOverride?.toIso8601String(),
    'endOverride': endOverride?.toIso8601String(),
  };
}

List<MaintainiacJobScheduleException>
maintainiacJobScheduleExceptionsFromStorage(dynamic value) {
  if (value is! Iterable) return const [];
  final result = <MaintainiacJobScheduleException>[];
  for (final item in value) {
    if (item is! Map) continue;
    final exception = MaintainiacJobScheduleException.fromMap(item);
    if (exception.day.millisecondsSinceEpoch == 0) continue;
    result.add(exception);
  }
  return result;
}

List<MaintainiacJobScheduleException> normalizeMaintainiacJobScheduleExceptions(
  Iterable<MaintainiacJobScheduleException> values,
) => values.toList()..sort((left, right) => left.day.compareTo(right.day));

List<MaintainiacJobScheduleException> replaceMaintainiacJobScheduleException(
  Iterable<MaintainiacJobScheduleException> existing,
  MaintainiacJobScheduleException replacement,
) => normalizeMaintainiacJobScheduleExceptions([
  for (final value in existing)
    if (!_sameDay(value.day, replacement.day)) value,
  replacement,
]);

void validateMaintainiacJobScheduleExceptions({
  required DateTime? scheduledStart,
  required String repeatRule,
  required List<int> repeatWeekdays,
  required DateTime? repeatUntil,
  required Iterable<MaintainiacJobScheduleException> exceptions,
}) {
  final start = scheduledStart;
  final seenDays = <String>{};
  for (final exception in exceptions) {
    final day = _dateOnly(exception.day);
    if (!seenDays.add(_dayKey(day))) {
      throw ArgumentError('Only one schedule exception is allowed per day.');
    }
    if (start == null) {
      throw ArgumentError('Schedule exceptions require a scheduled job.');
    }
    if (day.isBefore(_dateOnly(start))) {
      throw ArgumentError(
        'A schedule exception cannot precede the first job date.',
      );
    }
    if (!maintainiacJobScheduleHasOccurrenceOn(
      sourceRecordId: 'validation',
      scheduledStart: start,
      repeatRule: repeatRule,
      repeatWeekdays: repeatWeekdays,
      repeatUntil: repeatUntil,
      day: day,
    )) {
      throw ArgumentError(
        'A schedule exception must match a planned occurrence.',
      );
    }
    if (exception.cancelled &&
        (exception.startOverride != null || exception.endOverride != null)) {
      throw ArgumentError('A skipped occurrence cannot also be rescheduled.');
    }
    final overrideStart = exception.startOverride;
    final overrideEnd = exception.endOverride;
    if (overrideStart != null && !_sameDay(overrideStart, day)) {
      throw ArgumentError(
        'A rescheduled start must remain on its exception day.',
      );
    }
    if (overrideEnd != null && !_sameDay(overrideEnd, day)) {
      throw ArgumentError(
        'A rescheduled end must remain on its exception day.',
      );
    }
    final effectiveStart = overrideStart ?? _atDay(start, day);
    if (overrideEnd != null && !overrideEnd.isAfter(effectiveStart)) {
      throw ArgumentError('A rescheduled end must be after its start.');
    }
  }
}

CalendarScheduleRule? maintainiacJobScheduleRuleFor({
  required String repeatRule,
  required List<int> repeatWeekdays,
  required DateTime? repeatUntil,
}) {
  final weekdays = repeatWeekdays.toSet();
  return switch (repeatRule.trim()) {
    'none' => const CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.once,
    ),
    'daily' => CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.daily,
      until: repeatUntil,
    ),
    'weekly' => CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.weekly,
      until: repeatUntil,
    ),
    'everyTwoWeeks' => CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.biweekly,
      until: repeatUntil,
    ),
    'monthly' => CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.monthly,
      until: repeatUntil,
    ),
    'selectedWeekdays' when weekdays.isNotEmpty => CalendarScheduleRule(
      frequency: CalendarScheduleFrequency.customDays,
      weekdays: weekdays,
      until: repeatUntil,
    ),
    _ => null,
  };
}

bool maintainiacJobScheduleHasOccurrenceOn({
  required String sourceRecordId,
  required DateTime scheduledStart,
  required String repeatRule,
  required List<int> repeatWeekdays,
  required DateTime? repeatUntil,
  required DateTime day,
}) {
  final rule = maintainiacJobScheduleRuleFor(
    repeatRule: repeatRule,
    repeatWeekdays: repeatWeekdays,
    repeatUntil: repeatUntil,
  );
  if (rule == null) return false;
  return CalendarScheduleRecurrence.occurrencesForRange(
    sourceRecordId: sourceRecordId,
    start: scheduledStart,
    rule: rule,
    rangeStart: day,
    rangeEnd: day,
  ).isNotEmpty;
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
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
