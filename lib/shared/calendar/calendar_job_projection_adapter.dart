// Job-to-calendar projection adapter. Jobs remain the source of truth; this
// adapter only exposes scheduled job records for a selected business day.

import '../../shared/jobs/maintainiac_job_store.dart';
import '../../shared/jobs/maintainiac_job_schedule_exception.dart';
import 'calendar_projection_contract.dart';
import 'calendar_schedule_recurrence_contract.dart';

class CalendarJobProjectionAdapter {
  const CalendarJobProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    MaintainiacJobController jobs,
    DateTime day,
  ) {
    final target = DateTime(day.year, day.month, day.day);
    final projected = <CalendarProjectionEvent>[];
    for (final job in jobs.activeJobs) {
      for (final occurrence in _occurrencesForDay(job, target)) {
        projected.add(
          fromJob(
            job,
            occurrenceAt: occurrence.start,
            scheduledEndAt: occurrence.end,
            isScheduleOverride: occurrence.isOverride,
            continuesFromPreviousDay: !_isSameDay(occurrence.start, target),
          ),
        );
      }
    }
    return CalendarProjectionTimeline.normalize(projected);
  }

  static CalendarProjectionEvent fromJob(
    MaintainiacJobRecord job, {
    DateTime? occurrenceAt,
    DateTime? scheduledEndAt,
    bool isScheduleOverride = false,
    bool continuesFromPreviousDay = false,
  }) {
    final scheduledAt = occurrenceAt ?? job.scheduledStart!;
    final effectiveEnd = _validEnd(
      scheduledEndAt ?? _scheduledEndAt(job, scheduledAt),
      scheduledAt,
    );
    final recurring = job.repeatRule != 'none';
    return CalendarProjectionEvent(
      eventId: recurring
          ? 'job:${job.id}:${_dayKey(scheduledAt)}'
          : 'job:${job.id}',
      source: CalendarProjectionSource.job,
      sourceRecordId: job.id,
      timing: CalendarProjectionTiming(
        eventDate: scheduledAt,
        recordedAt: job.updatedAt,
        scheduledAt: scheduledAt,
        scheduledEndAt: effectiveEnd,
        timeSource: CalendarTimeSource.scheduled,
      ),
      title: job.name,
      conciseDetail: _jobDetail(
        job,
        isScheduleOverride: isScheduleOverride,
        continuesFromPreviousDay: continuesFromPreviousDay,
      ),
      state: CalendarProjectionState.confirmed,
      sourceRecordStatus: 'scheduled',
      revision: _revisionFor(job),
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.jobDetail,
        sourceRecordId: job.id,
      ),
      vehicleIds: job.vehicleIds,
      workProfileId: _emptyToNull(job.workProfileId),
      participantIds: job.assignedMemberIds,
      customerId: _emptyToNull(job.customerId),
      evidence: CalendarProjectionEvidence(
        summary: _evidenceSummary(
          job,
          isScheduleOverride: isScheduleOverride,
          continuesFromPreviousDay: continuesFromPreviousDay,
        ),
        strength: 'User-scheduled job',
        explanation:
            'This is a scheduled appointment. Arrival evidence does not complete the job.',
      ),
      auditReference:
          'Updated ${job.updatedAt.toIso8601String()}${isScheduleOverride ? ' · one-time schedule override' : ''}${continuesFromPreviousDay ? ' · continuing from previous day' : ''}',
    );
  }
}

DateTime? _scheduledEndAt(MaintainiacJobRecord job, DateTime occurrenceStart) {
  final originalStart = job.scheduledStart;
  final originalEnd = job.scheduledEnd;
  if (originalStart == null ||
      originalEnd == null ||
      !originalEnd.isAfter(originalStart)) {
    return null;
  }
  return occurrenceStart.add(originalEnd.difference(originalStart));
}

List<CalendarScheduleOccurrence> _occurrencesForDay(
  MaintainiacJobRecord job,
  DateTime day,
) {
  final scheduled = job.scheduledStart;
  if (scheduled == null || job.archived) return const [];
  final target = DateTime(day.year, day.month, day.day);
  final rule = maintainiacJobScheduleRuleFor(
    repeatRule: job.repeatRule,
    repeatWeekdays: job.repeatWeekdays,
    repeatUntil: job.repeatUntil,
  );
  if (rule == null) return const [];
  final occurrences = CalendarScheduleRecurrence.occurrencesForRange(
    sourceRecordId: job.id,
    start: scheduled,
    end: job.scheduledEnd,
    rule: rule,
    exceptions: [
      for (final exception in job.scheduleExceptions)
        CalendarScheduleException(
          day: exception.day,
          cancelled: exception.cancelled,
          startOverride: exception.startOverride,
          endOverride: exception.endOverride,
        ),
    ],
    rangeStart: target.subtract(_maximumOccurrenceDuration(job)),
    rangeEnd: target,
  );
  final targetEnd = DateTime(target.year, target.month, target.day + 1);
  return occurrences
      .where(
        (occurrence) =>
            occurrence.start.isBefore(targetEnd) &&
            (occurrence.end == null || occurrence.end!.isAfter(target)),
      )
      .toList(growable: false);
}

Duration _maximumOccurrenceDuration(MaintainiacJobRecord job) {
  var longest = _durationBetween(job.scheduledStart, job.scheduledEnd);
  for (final exception in job.scheduleExceptions) {
    final originalStart = job.scheduledStart!;
    final effectiveStart =
        exception.startOverride ??
        DateTime(
          exception.day.year,
          exception.day.month,
          exception.day.day,
          originalStart.hour,
          originalStart.minute,
          originalStart.second,
          originalStart.millisecond,
          originalStart.microsecond,
        );
    final candidate = _durationBetween(effectiveStart, exception.endOverride);
    if (candidate > longest) longest = candidate;
  }
  return longest;
}

Duration _durationBetween(DateTime? start, DateTime? end) =>
    start == null || end == null || !end.isAfter(start)
    ? Duration.zero
    : end.difference(start);

DateTime? _validEnd(DateTime? value, DateTime start) =>
    value != null && value.isAfter(start) ? value : null;

String _dayKey(DateTime value) =>
    '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

String _jobDetail(
  MaintainiacJobRecord job, {
  required bool isScheduleOverride,
  required bool continuesFromPreviousDay,
}) {
  final customer = job.customerReference.trim();
  final address = job.address.trim();
  final detail = customer.isNotEmpty && address.isNotEmpty
      ? '$customer · $address'
      : customer.isNotEmpty
      ? customer
      : address.isNotEmpty
      ? address
      : 'Scheduled job';
  final modifiers = [
    if (isScheduleOverride) 'One-time schedule change',
    if (continuesFromPreviousDay) 'Continues from previous day',
  ];
  return modifiers.isEmpty ? detail : '$detail · ${modifiers.join(' · ')}';
}

String _evidenceSummary(
  MaintainiacJobRecord job, {
  required bool isScheduleOverride,
  required bool continuesFromPreviousDay,
}) {
  final reminders = <String>[
    if (job.inAppReminder) 'in-app',
    if (job.pushReminder) 'phone',
    if (job.soundReminder) 'sound',
  ];
  final summary = reminders.isEmpty
      ? 'User-scheduled; no reminder enabled.'
      : 'User-scheduled; reminder: ${reminders.join(', ')}.';
  final modifiers = [
    if (isScheduleOverride) 'One-time schedule change.',
    if (continuesFromPreviousDay) 'Continues from previous day.',
  ];
  return modifiers.isEmpty ? summary : '$summary ${modifiers.join(' ')}';
}

bool _isSameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _revisionFor(MaintainiacJobRecord job) =>
    job.updatedAt.microsecondsSinceEpoch < 0
    ? 0
    : job.updatedAt.microsecondsSinceEpoch;
