// Calendar ownership: turns Calendar-owned appointments into read-only
// chronological events. It never manufactures Jobs, Expenses, or Trips.

import 'calendar_projection_contract.dart';
import 'calendar_schedule_record.dart';
import 'calendar_schedule_recurrence_contract.dart';

class CalendarScheduleProjectionAdapter {
  const CalendarScheduleProjectionAdapter._();

  static Iterable<CalendarProjectionEvent> eventsForDay(
    Iterable<CalendarScheduleRecord> schedules,
    DateTime day,
  ) sync* {
    for (final schedule in schedules) {
      if (!schedule.active) continue;
      final targetStart = DateTime(day.year, day.month, day.day);
      final targetEnd = DateTime(day.year, day.month, day.day + 1);
      final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
        sourceRecordId: schedule.id,
        start: schedule.startsAt,
        end: schedule.endsAt,
        rule: schedule.rule,
        exceptions: schedule.exceptions,
        rangeStart: targetStart.subtract(_maximumDuration(schedule)),
        rangeEnd: targetStart,
      );
      for (final occurrence in occurrences.where(
        (value) =>
            value.start.isBefore(targetEnd) &&
            (value.end == null || value.end!.isAfter(targetStart)),
      )) {
        yield CalendarProjectionEvent(
          eventId: 'calendar-schedule:${occurrence.id}',
          source: CalendarProjectionSource.calendarSchedule,
          sourceRecordId: schedule.id,
          timing: CalendarProjectionTiming(
            eventDate: occurrence.start,
            recordedAt: schedule.recordedAt,
            scheduledAt: occurrence.start,
            scheduledEndAt: occurrence.end,
            timezoneId: schedule.timezoneId,
            recordedTimezoneOffsetMinutes:
                schedule.recordedAt.timeZoneOffset.inMinutes,
            scheduledTimezoneOffsetMinutes:
                occurrence.start.timeZoneOffset.inMinutes,
            timeSource: CalendarTimeSource.scheduled,
          ),
          title: schedule.title,
          conciseDetail: _detail(schedule, occurrence.isOverride),
          state: CalendarProjectionState.confirmed,
          sourceRecordStatus: 'scheduled',
          revision: schedule.recordedAt.microsecondsSinceEpoch,
          deepLink: CalendarProjectionDeepLink(
            target: CalendarDeepLinkTarget.calendarScheduleDetail,
            sourceRecordId: schedule.id,
          ),
          vehicleIds: _idList(schedule.vehicleId),
          workProfileId: _blankToNull(schedule.workProfileId),
          evidence: CalendarProjectionEvidence(
            strength: 'User-scheduled',
            explanation:
                'This appointment was created in Calendar. It does not prove work was completed.',
          ),
          auditReference: 'Scheduled ${schedule.recordedAt.toIso8601String()}',
        );
      }
    }
  }
}

Duration _maximumDuration(CalendarScheduleRecord schedule) {
  var result = _duration(schedule.startsAt, schedule.endsAt);
  for (final exception in schedule.exceptions) {
    final start =
        exception.startOverride ??
        DateTime(
          exception.day.year,
          exception.day.month,
          exception.day.day,
          schedule.startsAt.hour,
          schedule.startsAt.minute,
        );
    final duration = _duration(start, exception.endOverride);
    if (duration > result) result = duration;
  }
  return result;
}

Duration _duration(DateTime start, DateTime? end) =>
    end == null || !end.isAfter(start) ? Duration.zero : end.difference(start);

String _detail(CalendarScheduleRecord schedule, bool isOverride) {
  final labels = <String>[
    'Calendar appointment',
    if (schedule.rule.frequency != CalendarScheduleFrequency.once)
      schedule.rule.frequency.name,
    if (isOverride) 'One-time change',
    if (schedule.details.trim().isNotEmpty) schedule.details.trim(),
  ];
  return labels.join(' · ');
}

List<String> _idList(String value) =>
    value.trim().isEmpty ? const [] : [value.trim()];
String? _blankToNull(String value) =>
    value.trim().isEmpty ? null : value.trim();
