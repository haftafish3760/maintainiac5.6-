import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('planned end requires a later scheduled start', () {
    expect(
      () => CalendarProjectionTiming(
        eventDate: DateTime(2026, 7, 29),
        recordedAt: DateTime(2026, 7, 29),
        scheduledAt: DateTime(2026, 7, 29, 9),
        scheduledEndAt: DateTime(2026, 7, 29, 9),
        timeSource: CalendarTimeSource.scheduled,
      ),
      throwsArgumentError,
    );
  });
  test('time-zone-aware actual time keeps its source business date', () {
    final timing = CalendarProjectionTiming(
      eventDate: DateTime(2026, 7, 29),
      actualAt: DateTime.utc(2026, 7, 30, 3, 30),
      recordedAt: DateTime.utc(2026, 7, 30, 4),
      timeSource: CalendarTimeSource.actual,
      timezoneId: 'America/New_York',
    );

    expect(timing.eventDate, DateTime(2026, 7, 29));
    expect(timing.chronologicalTime, DateTime.utc(2026, 7, 30, 3, 30));
    expect(timing.timezoneId, 'America/New_York');
  });
  test('actual and recorded event times remain explicitly distinguishable', () {
    final actual = CalendarProjectionTiming(
      eventDate: DateTime(2026, 7, 22, 13),
      actualAt: DateTime(2026, 7, 22, 9, 15),
      recordedAt: DateTime(2026, 7, 28, 10),
      timeSource: CalendarTimeSource.actual,
      timezoneId: 'America/New_York',
    );
    final recorded = CalendarProjectionTiming(
      eventDate: DateTime(2026, 7, 22),
      recordedAt: DateTime(2026, 7, 28, 10),
      timeSource: CalendarTimeSource.recorded,
    );

    expect(actual.displayTimeLabel, 'Actual time');
    expect(actual.chronologicalTime, DateTime(2026, 7, 22, 9, 15));
    expect(recorded.displayTimeLabel, 'Recorded time');
    expect(recorded.chronologicalTime, DateTime(2026, 7, 28, 10));
    expect(actual.eventDate, DateTime(2026, 7, 22));
  });

  test(
    'newer revision suppresses a stale duplicate event deterministically',
    () {
      final stale = _event(
        id: 'expense-42',
        revision: 2,
        recordedAt: DateTime(2026, 7, 28, 11),
        title: 'Old fuel total',
      );
      final current = _event(
        id: 'expense-42',
        revision: 3,
        recordedAt: DateTime(2026, 7, 28, 11),
        title: 'Corrected fuel total',
      );

      final normalized = CalendarProjectionTimeline.normalize([current, stale]);

      expect(normalized, hasLength(1));
      expect(normalized.single.title, 'Corrected fuel total');
      expect(normalized.single.revision, 3);
    },
  );

  test('identical input order cannot change chronological output', () {
    final early = _event(
      id: 'job-1',
      revision: 1,
      recordedAt: DateTime(2026, 7, 28, 8),
    );
    final late = _event(
      id: 'expense-1',
      revision: 1,
      recordedAt: DateTime(2026, 7, 28, 9),
    );

    expect(
      CalendarProjectionTimeline.normalize([
        late,
        early,
      ]).map((event) => event.eventId),
      ['job-1', 'expense-1'],
    );
  });

  test('a calendar event cannot deep-link to a different source record', () {
    expect(
      () => CalendarProjectionEvent(
        eventId: 'expense-event',
        source: CalendarProjectionSource.expense,
        sourceRecordId: 'expense-1',
        timing: CalendarProjectionTiming(
          eventDate: DateTime(2026, 7, 22),
          recordedAt: DateTime(2026, 7, 22, 10),
          timeSource: CalendarTimeSource.recorded,
        ),
        title: 'Fuel',
        conciseDetail: r'$50',
        state: CalendarProjectionState.confirmed,
        sourceRecordStatus: 'saved',
        revision: 0,
        deepLink: const CalendarProjectionDeepLink(
          target: CalendarDeepLinkTarget.expenseDetail,
          sourceRecordId: 'expense-2',
        ),
      ),
      throwsArgumentError,
    );
  });
}

CalendarProjectionEvent _event({
  required String id,
  required int revision,
  required DateTime recordedAt,
  String title = 'Job',
}) => CalendarProjectionEvent(
  eventId: id,
  source: CalendarProjectionSource.job,
  sourceRecordId: id,
  timing: CalendarProjectionTiming(
    eventDate: DateTime(2026, 7, 22),
    recordedAt: recordedAt,
    timeSource: CalendarTimeSource.recorded,
  ),
  title: title,
  conciseDetail: 'Source-owned event',
  state: CalendarProjectionState.confirmed,
  sourceRecordStatus: 'saved',
  revision: revision,
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.jobDetail,
    sourceRecordId: id,
  ),
);
