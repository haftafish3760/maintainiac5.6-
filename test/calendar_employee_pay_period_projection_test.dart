import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_employee_pay_period_projection.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';

void main() {
  test('pay-period recap separates approved, pending, and rejected work', () {
    final recap = CalendarEmployeePayPeriodProjection.forDate(
      records: [
        _record('approved', EmployeeWorkTimeStatus.approved, 480),
        _record('submitted', EmployeeWorkTimeStatus.submitted, 60),
        _record('rejected', EmployeeWorkTimeStatus.rejected, 30),
      ],
      schedule: EmployeePayPeriodSchedule.fromWeekStart(
        frequency: EmployeePayFrequency.weekly,
        weekStart: 'monday',
        referenceDate: DateTime(2026, 7, 29),
      ),
      date: DateTime(2026, 7, 29),
      hourlyRateCents: 2500,
    );

    expect(recap.period.start, DateTime(2026, 7, 27));
    expect(recap.period.end, DateTime(2026, 8, 2));
    expect(recap.approvedHours, 8);
    expect(recap.pendingHours, 1);
    expect(recap.grossPayCents, 20000);
  });

  test(
    'missing rate leaves gross pay unavailable instead of assuming zero',
    () {
      final recap = CalendarEmployeePayPeriodProjection.forDate(
        records: [_record('approved', EmployeeWorkTimeStatus.approved, 120)],
        schedule: EmployeePayPeriodSchedule(
          frequency: EmployeePayFrequency.monthly,
          anchorStartDate: DateTime(2026, 1, 1),
        ),
        date: DateTime(2026, 7, 29),
      );

      expect(recap.approvedHours, 2);
      expect(recap.grossPayCents, isNull);
      expect(recap.grossPay, isNull);
    },
  );
}

EmployeeWorkTimeRecord _record(
  String id,
  EmployeeWorkTimeStatus status,
  int minutes,
) => EmployeeWorkTimeRecord(
  id: id,
  employeeId: 'employee-1',
  workDate: DateTime(2026, 7, 29),
  recordedAt: DateTime(2026, 7, 29),
  status: status,
  revision: 1,
  manualPaidMinutes: minutes,
);
