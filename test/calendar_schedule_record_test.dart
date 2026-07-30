import 'package:flutter_test/flutter_test.dart';
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
      expect(saved.screenScope, 'jobs');
      expect(saved.rule.frequency, CalendarScheduleFrequency.weekly);
      expect(saved.exceptions.single.cancelled, isTrue);
    },
  );

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
