import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_schedule_recurrence_contract.dart';

void main() {
  test('weekly schedule supports exceptions and retained time windows', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'job-1',
      start: DateTime(2026, 7, 6, 8),
      end: DateTime(2026, 7, 6, 10),
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.weekly,
      ),
      rangeStart: DateTime(2026, 7, 1),
      rangeEnd: DateTime(2026, 7, 31),
      exceptions: [
        CalendarScheduleException(day: DateTime(2026, 7, 13), cancelled: true),
        CalendarScheduleException(
          day: DateTime(2026, 7, 20),
          startOverride: DateTime(2026, 7, 20, 9),
        ),
      ],
    );
    expect(occurrences.map((value) => value.id), [
      'job-1:20260706',
      'job-1:20260720',
      'job-1:20260727',
    ]);
    expect(occurrences[1].start, DateTime(2026, 7, 20, 9));
    expect(occurrences[1].end, DateTime(2026, 7, 20, 11));
    expect(occurrences[1].isOverride, isTrue);
  });

  test('does not create an occurrence for a reversed query range', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'job-1',
      start: DateTime(2026, 7, 6, 8),
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.daily,
      ),
      rangeStart: DateTime(2026, 7, 31),
      rangeEnd: DateTime(2026, 7, 1),
    );

    expect(occurrences, isEmpty);
  });

  test('monthly schedules retain a month-end appointment', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'job-1',
      start: DateTime(2026, 1, 31, 9),
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.monthly,
      ),
      rangeStart: DateTime(2026, 2, 1),
      rangeEnd: DateTime(2026, 2, 28),
    );

    expect(occurrences.single.start, DateTime(2026, 2, 28, 9));
  });

  test('custom weekday schedules keep only selected days in each interval', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'route-1',
      start: DateTime(2026, 7, 6, 8), // Monday
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.customDays,
        weekdays: {DateTime.monday, DateTime.wednesday},
      ),
      rangeStart: DateTime(2026, 7, 6),
      rangeEnd: DateTime(2026, 7, 12),
    );

    expect(occurrences.map((value) => value.start), [
      DateTime(2026, 7, 6, 8),
      DateTime(2026, 7, 8, 8),
    ]);
  });

  test('custom weekday schedules retain their first source appointment', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'route-1',
      start: DateTime(2026, 7, 6, 8), // Monday
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.customDays,
        weekdays: {DateTime.wednesday},
      ),
      rangeStart: DateTime(2026, 7, 6),
      rangeEnd: DateTime(2026, 7, 12),
    );

    expect(occurrences.map((value) => value.start), [
      DateTime(2026, 7, 6, 8),
      DateTime(2026, 7, 8, 8),
    ]);
  });

  test('daily schedules preserve local appointment time across DST dates', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'route-1',
      start: DateTime(2026, 3, 7, 8, 30),
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.daily,
      ),
      rangeStart: DateTime(2026, 3, 7),
      rangeEnd: DateTime(2026, 3, 10),
    );

    expect(occurrences.map((value) => value.start.hour), everyElement(8));
    expect(occurrences.map((value) => value.start.minute), everyElement(30));
  });

  test('rejects ambiguous exceptions and invalid weekday values', () {
    expect(
      () => CalendarScheduleRecurrence.occurrencesForRange(
        sourceRecordId: 'job-1',
        start: DateTime(2026, 7, 6, 8),
        rule: const CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.weekly,
        ),
        rangeStart: DateTime(2026, 7, 6),
        rangeEnd: DateTime(2026, 7, 6),
        exceptions: [
          CalendarScheduleException(day: DateTime(2026, 7, 6)),
          CalendarScheduleException(day: DateTime(2026, 7, 6)),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => CalendarScheduleRecurrence.occurrencesForRange(
        sourceRecordId: 'job-1',
        start: DateTime(2026, 7, 6, 8),
        rule: const CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.customDays,
          weekdays: {0},
        ),
        rangeStart: DateTime(2026, 7, 6),
        rangeEnd: DateTime(2026, 7, 6),
      ),
      throwsArgumentError,
    );
  });

  test('does not emit after a recurrence end date', () {
    final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
      sourceRecordId: 'job-1',
      start: DateTime(2026, 7, 6, 8),
      rule: CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.weekly,
        until: DateTime(2026, 7, 20),
      ),
      rangeStart: DateTime(2026, 7, 6),
      rangeEnd: DateTime(2026, 7, 31),
    );

    expect(occurrences.map((value) => value.start.day), [6, 13, 20]);
  });

  test('rejects an override end before the effective appointment start', () {
    expect(
      () => CalendarScheduleRecurrence.occurrencesForRange(
        sourceRecordId: 'job-1',
        start: DateTime(2026, 7, 6, 8),
        end: DateTime(2026, 7, 6, 10),
        rule: const CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.weekly,
        ),
        rangeStart: DateTime(2026, 7, 13),
        rangeEnd: DateTime(2026, 7, 13),
        exceptions: [
          CalendarScheduleException(
            day: DateTime(2026, 7, 13),
            endOverride: DateTime(2026, 7, 13, 7),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
