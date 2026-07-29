import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_employee_day_projection.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';

void main() {
  test('employee day projection reports paid and review hours honestly', () {
    final day = DateTime(2026, 7, 29);
    final data = CalendarEmployeeDayProjection.forDay([
      _record(
        id: 'approved',
        employeeId: 'employee-a',
        day: day,
        status: EmployeeWorkTimeStatus.approved,
        startHour: 8,
        endHour: 12,
      ),
      _record(
        id: 'review',
        employeeId: 'employee-a',
        day: day,
        status: EmployeeWorkTimeStatus.submitted,
        startHour: 13,
        endHour: 15,
      ),
      _record(
        id: 'other-day',
        employeeId: 'employee-a',
        day: day.add(const Duration(days: 1)),
        status: EmployeeWorkTimeStatus.approved,
        startHour: 8,
        endHour: 17,
      ),
    ], day);

    expect(data.recapItems.map((item) => item.value), [
      '6.00',
      '4.00',
      '2',
      '1',
    ]);
    expect(data.entries, hasLength(2));
    expect(
      data.entries.map((entry) => entry.status),
      containsAll(<CalendarEntryStatus>[
        CalendarEntryStatus.completed,
        CalendarEntryStatus.needsAttention,
      ]),
    );
  });

  test(
    'overnight time is visible next day without adding payroll hours twice',
    () {
      final overnight = EmployeeWorkTimeRecord(
        id: 'overnight',
        employeeId: 'employee-a',
        workDate: DateTime(2026, 7, 29),
        clockInAt: DateTime(2026, 7, 29, 22),
        clockOutAt: DateTime(2026, 7, 30, 6),
        status: EmployeeWorkTimeStatus.approved,
        recordedAt: DateTime(2026, 7, 29, 22),
        revision: 1,
      );

      final nextDay = CalendarEmployeeDayProjection.forDay([
        overnight,
      ], DateTime(2026, 7, 30));

      expect(nextDay.entries, hasLength(1));
      expect(
        nextDay.entries.single.summary,
        contains('Continues from previous day'),
      );
      expect(nextDay.recapItems.first.value, '0.00');
      expect(nextDay.recapItems[2].value, '0');
    },
  );
}

EmployeeWorkTimeRecord _record({
  required String id,
  required String employeeId,
  required DateTime day,
  required EmployeeWorkTimeStatus status,
  required int startHour,
  required int endHour,
}) => EmployeeWorkTimeRecord(
  id: id,
  employeeId: employeeId,
  workDate: day,
  clockInAt: DateTime(day.year, day.month, day.day, startHour),
  clockOutAt: DateTime(day.year, day.month, day.day, endHour),
  status: status,
  recordedAt: day,
  revision: 1,
);
