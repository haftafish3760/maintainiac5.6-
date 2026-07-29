// Active Workday projection. The dashboard/workday store owns session records;
// Calendar exposes their timeline without confirming advisory evidence.

import '../../screens/dashboard/data/active_workday_store.dart';
import '../../screens/dashboard/data/active_workday_context_segment.dart';
import 'calendar_projection_contract.dart';

class CalendarActiveWorkdayProjectionAdapter {
  const CalendarActiveWorkdayProjectionAdapter._();

  static Iterable<CalendarProjectionEvent> eventsForDay(
    Iterable<ActiveWorkdaySessionRecord> sessions,
    DateTime day,
  ) sync* {
    for (final session in sessions) {
      if (!session.hasValidIdentity) continue;
      if (_sameDay(_calendarTime(session.startedAt), day)) {
        yield _sessionEvent(session);
      }
      for (final event in session.events) {
        if (!event.hasValidIdentity ||
            event.type == ActiveWorkdayEventType.contextChanged ||
            !_sameDay(_calendarTime(event.occurredAt), day)) {
          continue;
        }
        yield _event(session, event);
      }
    }
  }

  static CalendarProjectionEvent _sessionEvent(
    ActiveWorkdaySessionRecord session,
  ) {
    final startedAt = _calendarTime(session.startedAt);
    final initialContext = session.resolvedContextSegments.first;
    return CalendarProjectionEvent(
      eventId: 'workday:${session.id}',
      source: CalendarProjectionSource.activeWorkday,
      sourceRecordId: session.id,
      timing: CalendarProjectionTiming(
        eventDate: startedAt,
        actualAt: startedAt,
        recordedAt: startedAt,
        timeSource: CalendarTimeSource.actual,
      ),
      title: 'Workday · ${initialContext.vehicleLabel}',
      conciseDetail: '${session.status.name} · ${initialContext.workProfileId}',
      state: switch (session.status) {
        ActiveWorkdayStatus.ended => CalendarProjectionState.confirmed,
        ActiveWorkdayStatus.paused => CalendarProjectionState.needsReview,
        ActiveWorkdayStatus.active => CalendarProjectionState.incomplete,
      },
      sourceRecordStatus: session.status.name,
      revision: session.events.length + session.resolvedContextSegments.length,
      vehicleIds: initialContext.vehicleId.isEmpty
          ? const []
          : [initialContext.vehicleId],
      workProfileId: initialContext.workProfileId.isEmpty
          ? null
          : initialContext.workProfileId,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.activeWorkday,
        sourceRecordId: session.id,
      ),
    );
  }

  static CalendarProjectionEvent _event(
    ActiveWorkdaySessionRecord session,
    ActiveWorkdayEvent event,
  ) {
    final occurredAt = _calendarTime(event.occurredAt);
    final context = _contextForEvent(session, event);
    return CalendarProjectionEvent(
      eventId: 'workday-event:${session.id}:${event.id}',
      source: _sourceFor(event.type),
      sourceRecordId: session.id,
      timing: CalendarProjectionTiming(
        eventDate: occurredAt,
        actualAt: occurredAt,
        recordedAt: occurredAt,
        timeSource: CalendarTimeSource.actual,
      ),
      title: event.label,
      conciseDetail: event.displayText,
      state: CalendarProjectionState.confirmed,
      sourceRecordStatus: event.type.name,
      revision: session.events.length,
      vehicleIds: context.vehicleId.isEmpty ? const [] : [context.vehicleId],
      workProfileId: context.workProfileId.isEmpty
          ? null
          : context.workProfileId,
      evidence: CalendarProjectionEvidence(summary: event.sourceType),
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.activeWorkday,
        sourceRecordId: session.id,
      ),
    );
  }

  static CalendarProjectionSource _sourceFor(ActiveWorkdayEventType type) =>
      switch (type) {
        ActiveWorkdayEventType.stop => CalendarProjectionSource.stop,
        ActiveWorkdayEventType.fuel ||
        ActiveWorkdayEventType.expense => CalendarProjectionSource.expense,
        _ => CalendarProjectionSource.activeWorkday,
      };
}

ActiveWorkdayContextSegment _contextForEvent(
  ActiveWorkdaySessionRecord session,
  ActiveWorkdayEvent event,
) {
  final contexts = session.resolvedContextSegments;
  final contextId = event.contextSegmentId;
  if (contextId != null) {
    for (final context in contexts) {
      if (context.id == contextId) return context;
    }
  }
  return contexts.first;
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

/// Active-workday records are persisted in UTC. Calendar day selection is a
/// local civil-date operation, so preserve an in-memory local value and
/// convert a reloaded UTC value only at this presentation boundary.
DateTime _calendarTime(DateTime value) => value.isUtc ? value.toLocal() : value;
