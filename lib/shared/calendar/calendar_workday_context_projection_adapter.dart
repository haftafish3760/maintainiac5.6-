// Active-workday context Calendar projection. Dashboard owns user-confirmed
// vehicle/profile handoffs; Calendar only renders the resulting boundaries.

import '../../screens/dashboard/data/active_workday_store.dart';
import '../../screens/dashboard/data/active_workday_context_segment.dart';
import 'calendar_projection_contract.dart';

class CalendarWorkdayContextProjectionAdapter {
  const CalendarWorkdayContextProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<ActiveWorkdaySessionRecord> sessions,
    DateTime day,
  ) => CalendarProjectionTimeline.normalize(
    sessions.expand((session) {
      final segments = session.resolvedContextSegments;
      return <CalendarProjectionEvent>[
        for (var index = 1; index < segments.length; index++)
          if (_sameDay(_calendarTime(segments[index].startedAt), day))
            fromHandoff(
              session: session,
              previous: segments[index - 1],
              current: segments[index],
            ),
      ];
    }),
  );

  static CalendarProjectionEvent fromHandoff({
    required ActiveWorkdaySessionRecord session,
    required ActiveWorkdayContextSegment previous,
    required ActiveWorkdayContextSegment current,
  }) {
    final startedAt = _calendarTime(current.startedAt);
    final vehicleChanged = previous.vehicleId != current.vehicleId;
    final profileChanged = previous.workProfileId != current.workProfileId;
    if (!vehicleChanged && !profileChanged) {
      throw ArgumentError(
        'A Calendar handoff must change vehicle or work profile.',
      );
    }
    return CalendarProjectionEvent(
      eventId: 'workday-context:${session.id}:${current.id}',
      source: CalendarProjectionSource.vehicleProfile,
      sourceRecordId: session.id,
      timing: CalendarProjectionTiming(
        eventDate: startedAt,
        actualAt: startedAt,
        recordedAt: startedAt,
        timeSource: CalendarTimeSource.actual,
      ),
      title: _titleFor(
        vehicleChanged: vehicleChanged,
        profileChanged: profileChanged,
      ),
      conciseDetail: _detailFor(
        previous: previous,
        current: current,
        vehicleChanged: vehicleChanged,
        profileChanged: profileChanged,
      ),
      state: CalendarProjectionState.confirmed,
      sourceRecordStatus: 'user-confirmed active-workday handoff',
      revision: 0,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.vehicleProfileDetail,
        sourceRecordId: session.id,
        argumentId: current.id,
      ),
      vehicleIds: [current.vehicleId],
      workProfileId: current.workProfileId,
      evidence: const CalendarProjectionEvidence(
        strength: 'user-confirmed active-workday handoff',
        explanation:
            'This records when the active work context changed; it does not rewrite earlier workday activity.',
      ),
      auditReference: 'Context segment ${current.id}',
    );
  }
}

String _titleFor({
  required bool vehicleChanged,
  required bool profileChanged,
}) => vehicleChanged && profileChanged
    ? 'Vehicle and work-profile handoff'
    : vehicleChanged
    ? 'Vehicle handoff'
    : 'Work-profile handoff';

String _detailFor({
  required ActiveWorkdayContextSegment previous,
  required ActiveWorkdayContextSegment current,
  required bool vehicleChanged,
  required bool profileChanged,
}) => [
  if (vehicleChanged) '${previous.vehicleLabel} → ${current.vehicleLabel}',
  if (profileChanged) '${previous.workProfileId} → ${current.workProfileId}',
].join(' · ');

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

DateTime _calendarTime(DateTime value) => value.isUtc ? value.toLocal() : value;
