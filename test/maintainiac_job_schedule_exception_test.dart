import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/jobs/maintainiac_job_schedule_exception.dart';

void main() {
  test('replacing one exception preserves other occurrence changes', () {
    final replaced = replaceMaintainiacJobScheduleException(
      [
        MaintainiacJobScheduleException(
          day: DateTime(2026, 8, 3),
          cancelled: true,
        ),
        MaintainiacJobScheduleException(
          day: DateTime(2026, 8, 10),
          cancelled: true,
        ),
      ],
      MaintainiacJobScheduleException(
        day: DateTime(2026, 8, 3),
        startOverride: DateTime(2026, 8, 3, 9),
        endOverride: DateTime(2026, 8, 3, 11),
      ),
    );

    expect(replaced, hasLength(2));
    expect(replaced.first.cancelled, isFalse);
    expect(replaced.first.startOverride, DateTime(2026, 8, 3, 9));
    expect(replaced.last.cancelled, isTrue);
  });

  test(
    'source schedule occurrence check uses the same weekly cadence as Calendar',
    () {
      expect(
        maintainiacJobScheduleHasOccurrenceOn(
          sourceRecordId: 'JOB-1',
          scheduledStart: DateTime(2026, 7, 27, 8), // Monday
          repeatRule: 'weekly',
          repeatWeekdays: const [],
          repeatUntil: null,
          day: DateTime(2026, 8, 3),
        ),
        isTrue,
      );
      expect(
        maintainiacJobScheduleHasOccurrenceOn(
          sourceRecordId: 'JOB-1',
          scheduledStart: DateTime(2026, 7, 27, 8),
          repeatRule: 'weekly',
          repeatWeekdays: const [],
          repeatUntil: null,
          day: DateTime(2026, 8, 4),
        ),
        isFalse,
      );
    },
  );
}
