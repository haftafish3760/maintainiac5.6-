// Work-time-to-calendar projection adapter. Profiles owns time records and
// Calendar only renders their status, timing, assignments, and source route.

import '../profiles/employee_work_time_contract.dart';
import 'calendar_projection_contract.dart';

class CalendarWorkTimeProjectionAdapter {
  const CalendarWorkTimeProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<EmployeeWorkTimeRecord> records,
    DateTime day,
  ) {
    final target = DateTime(day.year, day.month, day.day);
    return CalendarProjectionTimeline.normalize(
      records
          .where((record) => _occursOnDay(record, target))
          .map(
            (record) => fromRecord(
              record,
              continuesFromPreviousDay: !_sameDay(record.workDate, target),
            ),
          ),
    );
  }

  static CalendarProjectionEvent fromRecord(
    EmployeeWorkTimeRecord record, {
    bool continuesFromPreviousDay = false,
  }) {
    final actualAt = record.clockInAt;
    return CalendarProjectionEvent(
      eventId: 'work-time:${record.id}',
      source: CalendarProjectionSource.workTime,
      sourceRecordId: record.id,
      timing: CalendarProjectionTiming(
        eventDate: record.workDate,
        recordedAt: record.recordedAt,
        actualAt: actualAt,
        timeSource: actualAt == null
            ? CalendarTimeSource.unknown
            : CalendarTimeSource.actual,
        timezoneId: record.timezoneId,
      ),
      title: 'Work time',
      conciseDetail:
          '${_hours(record.paidMinutes)} hours · ${_statusLabel(record.status)}${continuesFromPreviousDay ? ' · Continues from previous day' : ''}',
      state: _stateFor(record.status),
      sourceRecordStatus: record.status.name,
      revision: record.revision,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.workTimeDetail,
        sourceRecordId: record.id,
      ),
      vehicleIds: record.vehicleIds,
      workProfileId: record.workProfileId,
      participantIds: [record.employeeId],
      evidence: CalendarProjectionEvidence(
        summary: record.jobAllocations.isEmpty
            ? 'No job allocation recorded.'
            : '${record.jobAllocations.length} job allocation(s) recorded.',
        strength: record.clockInAt == null
            ? 'manual time entry'
            : 'clocked time entry',
        explanation: _statusExplanation(record.status),
      ),
      auditReference: record.auditReference,
    );
  }
}

bool _occursOnDay(EmployeeWorkTimeRecord record, DateTime target) {
  if (_sameDay(record.workDate, target)) return true;
  final start = record.clockInAt;
  final end = record.clockOutAt;
  if (start == null || end == null || !end.isAfter(start)) return false;
  final targetEnd = DateTime(target.year, target.month, target.day + 1);
  return start.isBefore(targetEnd) && end.isAfter(target);
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

CalendarProjectionState _stateFor(EmployeeWorkTimeStatus status) =>
    switch (status) {
      EmployeeWorkTimeStatus.approved ||
      EmployeeWorkTimeStatus.locked => CalendarProjectionState.confirmed,
      EmployeeWorkTimeStatus.submitted ||
      EmployeeWorkTimeStatus.corrected => CalendarProjectionState.needsReview,
      EmployeeWorkTimeStatus.draft => CalendarProjectionState.incomplete,
      EmployeeWorkTimeStatus.rejected => CalendarProjectionState.rejected,
    };

String _hours(int minutes) => (minutes / 60).toStringAsFixed(2);
String _statusLabel(EmployeeWorkTimeStatus status) => switch (status) {
  EmployeeWorkTimeStatus.draft => 'Draft',
  EmployeeWorkTimeStatus.submitted => 'Submitted',
  EmployeeWorkTimeStatus.approved => 'Approved',
  EmployeeWorkTimeStatus.corrected => 'Corrected',
  EmployeeWorkTimeStatus.rejected => 'Rejected',
  EmployeeWorkTimeStatus.locked => 'Locked',
};

String _statusExplanation(EmployeeWorkTimeStatus status) => switch (status) {
  EmployeeWorkTimeStatus.draft =>
    'Draft time does not contribute to gross pay.',
  EmployeeWorkTimeStatus.submitted => 'Submitted time awaits approval.',
  EmployeeWorkTimeStatus.approved => 'Approved time contributes to gross pay.',
  EmployeeWorkTimeStatus.corrected =>
    'Corrected time requires review before approval.',
  EmployeeWorkTimeStatus.rejected =>
    'Rejected time does not contribute to gross pay.',
  EmployeeWorkTimeStatus.locked =>
    'Locked time contributes to gross pay and requires a correction to change.',
};
