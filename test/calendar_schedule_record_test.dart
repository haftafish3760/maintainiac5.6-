import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_month_projection_reader.dart';
import 'package:maintaniac/shared/calendar/calendar_schedule_editor_screen.dart';
import 'package:maintaniac/shared/calendar/calendar_schedule_record.dart';
import 'package:maintaniac/shared/scheduling/schedule_recurrence_contract.dart';

void main() {
  test(
    'calendar schedule persists recurrence, context, and exceptions',
    () async {
      final controller = CalendarScheduleController.memory();
      final record = CalendarScheduleRecord(
        id: 'weekly-route',
        title: 'Jones Lawn Care',
        startsAt: DateTime(2026, 7, 29, 8),
        endsAt: DateTime(2026, 7, 29, 10),
        recordedAt: DateTime(2026, 7, 28, 18),
        vehicleId: 'truck-1',
        workProfileId: 'lawn-care',
        employeeId: 'employee-a',
        screenScope: 'jobs',
        rule: CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.weekly,
          weekdays: const {DateTime.wednesday},
        ),
        exceptions: [
          CalendarScheduleException(day: DateTime(2026, 8, 5), cancelled: true),
        ],
      );

      await controller.save(record);

      final saved = controller.records.single;
      expect(saved.title, 'Jones Lawn Care');
      expect(saved.vehicleId, 'truck-1');
      expect(saved.workProfileId, 'lawn-care');
      expect(saved.employeeId, 'employee-a');
      expect(saved.screenScope, 'jobs');
      expect(saved.rule.frequency, CalendarScheduleFrequency.weekly);
      expect(saved.exceptions.single.cancelled, isTrue);
    },
  );

  testWidgets('employee schedules are isolated to their employee calendar', (
    tester,
  ) async {
    final controller = CalendarScheduleController.memory();
    final day = DateTime(2026, 7, 29);
    for (final employeeId in const ['employee-a', 'employee-b']) {
      await controller.save(
        CalendarScheduleRecord(
          id: 'schedule-$employeeId',
          title: 'Route for $employeeId',
          startsAt: DateTime(2026, 7, 29, 8),
          recordedAt: DateTime(2026, 7, 28),
          employeeId: employeeId,
          screenScope: CalendarFlowSource.employee.name,
          rule: const CalendarScheduleRule(
            frequency: CalendarScheduleFrequency.once,
          ),
        ),
      );
    }
    final projectedIds = <String>[];

    await tester.pumpWidget(
      CalendarScheduleScope(
        controller: controller,
        child: Builder(
          builder: (context) {
            projectedIds.addAll(
              CalendarMonthProjectionReader.calendarScheduleEventsForDay(
                context,
                CalendarFlowSource.employee,
                day,
                employeeId: 'employee-a',
              ).map((event) => event.sourceRecordId),
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(projectedIds, ['schedule-employee-a']);
  });

  testWidgets('Dashboard editing does not re-home an employee schedule', (
    tester,
  ) async {
    final controller = CalendarScheduleController.memory();
    final record = CalendarScheduleRecord(
      id: 'employee-route',
      title: 'Employee route',
      startsAt: DateTime(2026, 7, 29, 8),
      recordedAt: DateTime(2026, 7, 28),
      employeeId: 'employee-a',
      screenScope: CalendarFlowSource.employee.name,
      rule: const CalendarScheduleRule(
        frequency: CalendarScheduleFrequency.once,
      ),
    );
    await controller.save(record);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScheduleScope(
          controller: controller,
          child: CalendarScheduleEditorScreen(
            day: record.startsAt,
            source: CalendarFlowSource.dashboard,
            record: record,
          ),
        ),
      ),
    );
    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, -1200),
      1800,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save schedule'));
    await tester.pumpAndSettle();

    final saved = controller.records.single;
    expect(saved.screenScope, CalendarFlowSource.employee.name);
    expect(saved.employeeId, 'employee-a');
  });

  test('removing a schedule soft-deletes it from active projections', () async {
    final controller = CalendarScheduleController.memory();
    await controller.save(
      CalendarScheduleRecord(
        id: 'remove-me',
        title: 'Temporary route',
        startsAt: DateTime(2026, 7, 29, 8),
        recordedAt: DateTime(2026, 7, 29, 7),
        rule: const CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.once,
        ),
      ),
    );

    await controller.remove('remove-me');

    expect(controller.records, isEmpty);
  });

  test(
    'schedule rejects an end time that is not after its start time',
    () async {
      final controller = CalendarScheduleController.memory();
      final start = DateTime(2026, 7, 29, 9);

      await expectLater(
        controller.save(
          CalendarScheduleRecord(
            id: 'invalid-time-window',
            title: 'Invalid appointment',
            startsAt: start,
            endsAt: start,
            recordedAt: start,
            rule: const CalendarScheduleRule(
              frequency: CalendarScheduleFrequency.once,
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(controller.records, isEmpty);
    },
  );

  test(
    'one-time changes retain schedule context and replace one date only',
    () {
      final record = CalendarScheduleRecord(
        id: 'route',
        title: 'Weekly route',
        startsAt: DateTime(2026, 7, 6, 8),
        recordedAt: DateTime(2026, 7, 1),
        vehicleId: 'truck-1',
        workProfileId: 'delivery',
        rule: const CalendarScheduleRule(
          frequency: CalendarScheduleFrequency.weekly,
        ),
      );

      final changed = record.copyWith(
        exceptions: [
          CalendarScheduleException(
            day: DateTime(2026, 7, 13),
            startOverride: DateTime(2026, 7, 13, 10),
            endOverride: DateTime(2026, 7, 13, 11),
          ),
        ],
      );

      expect(changed.vehicleId, 'truck-1');
      expect(changed.workProfileId, 'delivery');
      expect(
        changed.exceptions.single.startOverride,
        DateTime(2026, 7, 13, 10),
      );
    },
  );
}
