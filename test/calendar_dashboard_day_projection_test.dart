import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_dashboard_day_projection.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('dashboard day keeps every source event in chronological order', () {
    final day = DateTime(2026, 7, 29);
    final data = CalendarDashboardDayProjection.fromSources(
      day: day,
      events: [
        _event(
          'job',
          CalendarProjectionSource.job,
          day.add(const Duration(hours: 9)),
        ),
        _event(
          'expense',
          CalendarProjectionSource.expense,
          day.add(const Duration(hours: 8)),
        ),
        _event(
          'workday',
          CalendarProjectionSource.activeWorkday,
          day.add(const Duration(hours: 7)),
        ),
      ],
    );

    expect(data.entries.map((entry) => entry.id), [
      'workday',
      'expense',
      'job',
    ]);
    expect(data.recapItems.map((item) => item.label), [
      'Total entries',
      'Stops',
      'Awaiting review',
      'Cash received',
      'Business spend',
      'Net cash flow',
      'Approved hours',
    ]);
    expect(data.recapItems[0].value, '3');
    expect(data.recapItems[1].value, '0');
    expect(data.recapItems[2].value, '0');
  });

  test('dashboard day reports stop and review counts from event state', () {
    final day = DateTime(2026, 7, 29);
    final data = CalendarDashboardDayProjection.fromSources(
      day: day,
      events: [
        _event(
          'confirmed-stop',
          CalendarProjectionSource.stop,
          day.add(const Duration(hours: 8)),
        ),
        _event(
          'review-stop',
          CalendarProjectionSource.stop,
          day.add(const Duration(hours: 9)),
          state: CalendarProjectionState.needsReview,
        ),
        _event(
          'planned-job',
          CalendarProjectionSource.job,
          day.add(const Duration(hours: 10)),
          state: CalendarProjectionState.proposed,
        ),
      ],
    );

    expect(data.recapItems[0].value, '3');
    expect(data.recapItems[1].value, '2');
    expect(data.recapItems[2].value, '2');
  });
}

CalendarProjectionEvent _event(
  String id,
  CalendarProjectionSource source,
  DateTime at, {
  CalendarProjectionState state = CalendarProjectionState.confirmed,
}) => CalendarProjectionEvent(
  eventId: id,
  source: source,
  sourceRecordId: id,
  timing: CalendarProjectionTiming(
    eventDate: at,
    actualAt: at,
    recordedAt: at,
    timeSource: CalendarTimeSource.actual,
  ),
  title: id,
  conciseDetail: id,
  state: state,
  sourceRecordStatus: 'active',
  revision: 1,
  evidence: const CalendarProjectionEvidence(),
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.activeWorkday,
    sourceRecordId: id,
  ),
);
