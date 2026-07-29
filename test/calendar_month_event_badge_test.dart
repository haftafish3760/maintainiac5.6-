import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_month_event_badge.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('month badge distinguishes scheduled and completed projections', () {
    final badge = CalendarMonthEventBadge.fromEvents([
      _event(
        id: 'scheduled',
        state: CalendarProjectionState.proposed,
        timeSource: CalendarTimeSource.scheduled,
      ),
      _event(
        id: 'completed',
        state: CalendarProjectionState.confirmed,
        timeSource: CalendarTimeSource.actual,
      ),
    ]);

    expect(badge.entryCount, 2);
    expect(badge.hasScheduled, isTrue);
    expect(badge.hasCompleted, isTrue);
  });

  test('month badge does not present a needs-review item as completed', () {
    final badge = CalendarMonthEventBadge.fromEvents([
      _event(
        id: 'review',
        state: CalendarProjectionState.needsReview,
        timeSource: CalendarTimeSource.unknown,
      ),
    ]);

    expect(badge.entryCount, 1);
    expect(badge.hasScheduled, isFalse);
    expect(badge.hasCompleted, isFalse);
  });
}

CalendarProjectionEvent _event({
  required String id,
  required CalendarProjectionState state,
  required CalendarTimeSource timeSource,
}) => CalendarProjectionEvent(
  eventId: id,
  source: CalendarProjectionSource.job,
  sourceRecordId: id,
  timing: CalendarProjectionTiming(
    eventDate: DateTime(2026, 7, 29),
    recordedAt: DateTime(2026, 7, 29),
    scheduledAt: timeSource == CalendarTimeSource.scheduled
        ? DateTime(2026, 7, 29, 8)
        : null,
    actualAt: timeSource == CalendarTimeSource.actual
        ? DateTime(2026, 7, 29, 8)
        : null,
    timeSource: timeSource,
  ),
  title: id,
  conciseDetail: id,
  state: state,
  sourceRecordStatus: state.name,
  revision: 1,
  evidence: const CalendarProjectionEvidence(),
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.jobDetail,
    sourceRecordId: id,
  ),
);
