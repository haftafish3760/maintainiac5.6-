import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_work_time_projection_adapter.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';

void main() {
  test(
    'submitted manual time stays review-required and not actual clock time',
    () {
      final event = CalendarWorkTimeProjectionAdapter.fromRecord(
        EmployeeWorkTimeRecord(
          id: 'time-1',
          employeeId: 'employee-1',
          workDate: DateTime(2026, 7, 22),
          recordedAt: DateTime(2026, 7, 28, 9),
          status: EmployeeWorkTimeStatus.submitted,
          revision: 2,
          manualPaidMinutes: 480,
        ),
      );

      expect(event.state, CalendarProjectionState.needsReview);
      expect(event.timing.timeSource, CalendarTimeSource.unknown);
      expect(event.deepLink.target, CalendarDeepLinkTarget.workTimeDetail);
      expect(event.participantIds, ['employee-1']);
    },
  );

  test('locked clocked time is confirmed and keeps actual clock-in time', () {
    final event = CalendarWorkTimeProjectionAdapter.fromRecord(
      EmployeeWorkTimeRecord(
        id: 'time-2',
        employeeId: 'employee-1',
        workDate: DateTime(2026, 7, 22),
        recordedAt: DateTime(2026, 7, 22, 8),
        status: EmployeeWorkTimeStatus.locked,
        revision: 1,
        clockInAt: DateTime(2026, 7, 22, 8),
        clockOutAt: DateTime(2026, 7, 22, 16),
      ),
    );

    expect(event.state, CalendarProjectionState.confirmed);
    expect(event.timing.actualAt, DateTime(2026, 7, 22, 8));
  });

  test(
    'overnight clocked work remains visible on the following calendar day',
    () {
      final record = EmployeeWorkTimeRecord(
        id: 'time-overnight',
        employeeId: 'employee-1',
        workDate: DateTime(2026, 7, 22),
        recordedAt: DateTime(2026, 7, 22, 22),
        status: EmployeeWorkTimeStatus.approved,
        revision: 1,
        clockInAt: DateTime(2026, 7, 22, 22),
        clockOutAt: DateTime(2026, 7, 23, 6),
      );

      final events = CalendarWorkTimeProjectionAdapter.eventsForDay([
        record,
      ], DateTime(2026, 7, 23));

      expect(events, hasLength(1));
      expect(events.single.timing.actualAt, DateTime(2026, 7, 22, 22));
      expect(
        events.single.conciseDetail,
        contains('Continues from previous day'),
      );
    },
  );
}
