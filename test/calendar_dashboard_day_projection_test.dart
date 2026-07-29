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
      'Cash received',
      'Business spend',
      'Net cash flow',
      'Approved hours',
    ]);
  });
}

CalendarProjectionEvent _event(
  String id,
  CalendarProjectionSource source,
  DateTime at,
) => CalendarProjectionEvent(
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
  state: CalendarProjectionState.confirmed,
  sourceRecordStatus: 'active',
  revision: 1,
  evidence: const CalendarProjectionEvidence(),
  deepLink: CalendarProjectionDeepLink(
    target: CalendarDeepLinkTarget.activeWorkday,
    sourceRecordId: id,
  ),
);
