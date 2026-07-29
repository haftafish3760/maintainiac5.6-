import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_job_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_store.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_schedule_exception.dart';

void main() {
  test(
    'only active jobs scheduled for the selected day project to calendar',
    () {
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          _job(id: 'today', when: DateTime(2026, 7, 22, 8)),
          _job(id: 'tomorrow', when: DateTime(2026, 7, 23, 8)),
          _job(id: 'archived', when: DateTime(2026, 7, 22, 9), archived: true),
        ],
      );

      final events = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 7, 22),
      );

      expect(events, hasLength(1));
      expect(events.single.eventId, 'job:today');
      expect(events.single.timing.timeSource, CalendarTimeSource.scheduled);
      expect(events.single.deepLink.target, CalendarDeepLinkTarget.jobDetail);
      expect(events.single.participantIds, ['employee-1']);
    },
  );

  test('selected weekday jobs stop after their source-owned end date', () {
    final jobs = MaintainiacJobController.memory(
      initialJobs: [
        _job(
          id: 'route',
          when: DateTime(2026, 7, 27, 8, 30),
          repeatRule: 'selectedWeekdays',
          repeatWeekdays: const [DateTime.monday, DateTime.wednesday],
          repeatUntil: DateTime(2026, 8, 5),
        ),
      ],
    );

    final monday = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 3),
    );
    final wednesday = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 5),
    );
    final afterEnd = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 10),
    );

    expect(monday.single.timing.scheduledAt, DateTime(2026, 8, 3, 8, 30));
    expect(wednesday.single.timing.scheduledAt, DateTime(2026, 8, 5, 8, 30));
    expect(afterEnd, isEmpty);
  });

  test('source-owned job exceptions skip and reschedule one occurrence', () {
    final jobs = MaintainiacJobController.memory(
      initialJobs: [
        _job(
          id: 'route',
          when: DateTime(2026, 7, 27, 8),
          endsAt: DateTime(2026, 7, 27, 10),
          repeatRule: 'weekly',
          scheduleExceptions: [
            MaintainiacJobScheduleException(
              day: DateTime(2026, 8, 3),
              startOverride: DateTime(2026, 8, 3, 9),
              endOverride: DateTime(2026, 8, 3, 12),
            ),
            MaintainiacJobScheduleException(
              day: DateTime(2026, 8, 10),
              cancelled: true,
            ),
          ],
        ),
      ],
    );

    final rescheduled = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 3),
    ).single;
    final skipped = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 10),
    );

    expect(rescheduled.timing.scheduledAt, DateTime(2026, 8, 3, 9));
    expect(rescheduled.timing.scheduledEndAt, DateTime(2026, 8, 3, 12));
    expect(rescheduled.conciseDetail, contains('One-time schedule change'));
    expect(rescheduled.evidence.summary, contains('One-time schedule change'));
    expect(rescheduled.auditReference, contains('one-time schedule override'));
    expect(skipped, isEmpty);
  });

  test(
    'weekly and month-end recurring jobs retain scheduled occurrence time',
    () {
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          _job(id: 'daily', when: DateTime(2026, 7, 1, 7), repeatRule: 'daily'),
          _job(
            id: 'weekly',
            when: DateTime(2026, 7, 1, 8, 30),
            endsAt: DateTime(2026, 7, 1, 10),
            repeatRule: 'weekly',
          ),
          _job(
            id: 'monthly',
            when: DateTime(2026, 1, 31, 9),
            repeatRule: 'monthly',
          ),
        ],
      );

      final weekly = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 7, 15),
      ).where((event) => event.sourceRecordId == 'weekly').single;
      final monthly = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 2, 28),
      );

      final daily = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 7, 15),
      ).where((event) => event.sourceRecordId == 'daily').single;

      expect(daily.timing.scheduledAt, DateTime(2026, 7, 15, 7));
      expect(weekly.timing.scheduledAt, DateTime(2026, 7, 15, 8, 30));
      expect(weekly.timing.scheduledEndAt, DateTime(2026, 7, 15, 10));
      expect(weekly.eventId, 'job:weekly:20260715');
      expect(monthly.single.timing.scheduledAt, DateTime(2026, 2, 28, 9));
    },
  );

  test(
    'biweekly route projects only on its source-owned alternating weeks',
    () {
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          _job(
            id: 'biweekly-route',
            when: DateTime(2026, 7, 1, 8, 15),
            repeatRule: 'everyTwoWeeks',
          ),
        ],
      );

      final skippedWeek = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 7, 8),
      );
      final nextOccurrence = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 7, 15),
      );

      expect(skippedWeek, isEmpty);
      expect(
        nextOccurrence.single.timing.scheduledAt,
        DateTime(2026, 7, 15, 8, 15),
      );
    },
  );

  test('recurring overnight jobs retain their full cross-day duration', () {
    final jobs = MaintainiacJobController.memory(
      initialJobs: [
        _job(
          id: 'overnight-route',
          when: DateTime(2026, 7, 27, 22),
          endsAt: DateTime(2026, 7, 28, 2),
          repeatRule: 'weekly',
        ),
      ],
    );

    final event = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 8, 3),
    ).single;

    expect(event.timing.scheduledAt, DateTime(2026, 8, 3, 22));
    expect(event.timing.scheduledEndAt, DateTime(2026, 8, 4, 2));
  });

  test(
    'overnight jobs remain visible on the calendar day they continue into',
    () {
      final jobs = MaintainiacJobController.memory(
        initialJobs: [
          _job(
            id: 'overnight-route',
            when: DateTime(2026, 7, 27, 22),
            endsAt: DateTime(2026, 7, 28, 2),
            repeatRule: 'weekly',
          ),
        ],
      );

      final event = CalendarJobProjectionAdapter.eventsForDay(
        jobs,
        DateTime(2026, 8, 4),
      ).single;

      expect(event.timing.scheduledAt, DateTime(2026, 8, 3, 22));
      expect(event.timing.scheduledEndAt, DateTime(2026, 8, 4, 2));
      expect(event.conciseDetail, contains('Continues from previous day'));
    },
  );

  test('late DST-fallback appointment remains on its full calendar day', () {
    final jobs = MaintainiacJobController.memory(
      initialJobs: [
        _job(
          id: 'dst-late-visit',
          when: DateTime(2026, 11, 1, 23, 30),
          endsAt: DateTime(2026, 11, 2, 0, 30),
        ),
      ],
    );

    final events = CalendarJobProjectionAdapter.eventsForDay(
      jobs,
      DateTime(2026, 11, 1),
    );

    expect(events.single.timing.scheduledAt, DateTime(2026, 11, 1, 23, 30));
  });
}

MaintainiacJobRecord _job({
  required String id,
  required DateTime when,
  DateTime? endsAt,
  bool archived = false,
  String repeatRule = 'none',
  List<int> repeatWeekdays = const [],
  DateTime? repeatUntil,
  List<MaintainiacJobScheduleException> scheduleExceptions = const [],
}) => MaintainiacJobRecord(
  id: id,
  number: id,
  name: 'Jones Plumbing',
  customerReference: 'Jones',
  address: '1 Main Street',
  scheduledStart: when,
  scheduledEnd: endsAt,
  vehicleIds: const ['truck-1'],
  assignedMemberIds: const ['employee-1'],
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 20),
  archived: archived,
  repeatRule: repeatRule,
  repeatWeekdays: repeatWeekdays,
  repeatUntil: repeatUntil,
  scheduleExceptions: scheduleExceptions,
);
