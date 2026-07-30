import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_schedule_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_schedule_record.dart';
import 'package:maintaniac/shared/scheduling/schedule_recurrence_contract.dart';

void main() {
  test(
    'projects a scoped recurring appointment with honest planned timing',
    () {
      final schedule = CalendarScheduleRecord(
        id: 'jones-route',
        title: 'Jones Tree Work',
        details: 'Bring chipper',
        startsAt: DateTime(2026, 7, 6, 8, 30),
        endsAt: DateTime(2026, 7, 6, 10),
        recordedAt: DateTime(2026, 7, 1, 12),
        vehicleId: 'truck-1',
        workProfileId: 'tree-work',
        screenScope: 'jobs',
        timezoneId: 'America/New_York',
        rule: CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.weekly,
          weekdays: const {DateTime.monday},
        ),
      );

      final event = CalendarScheduleProjectionAdapter.eventsForDay([
        schedule,
      ], DateTime(2026, 7, 13)).single;

      expect(event.source, CalendarProjectionSource.calendarSchedule);
      expect(event.state, CalendarProjectionState.confirmed);
      expect(event.timing.timeSource, CalendarTimeSource.scheduled);
      expect(event.timing.scheduledAt, DateTime(2026, 7, 13, 8, 30));
      expect(event.timing.timezoneId, 'America/New_York');
      expect(event.vehicleIds, ['truck-1']);
      expect(event.workProfileId, 'tree-work');
      expect(
        event.deepLink.target,
        CalendarDeepLinkTarget.calendarScheduleDetail,
      );
    },
  );

  test('projects an overnight appointment on the day it continues into', () {
    final schedule = CalendarScheduleRecord(
      id: 'overnight',
      title: 'Night delivery route',
      startsAt: DateTime(2026, 7, 10, 23),
      endsAt: DateTime(2026, 7, 11, 2),
      recordedAt: DateTime(2026, 7, 1),
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.once,
      ),
    );

    final event = CalendarScheduleProjectionAdapter.eventsForDay([
      schedule,
    ], DateTime(2026, 7, 11)).single;

    expect(event.title, 'Night delivery route');
    expect(event.timing.scheduledEndAt, DateTime(2026, 7, 11, 2));
  });
}
