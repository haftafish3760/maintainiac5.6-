import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/profiles/employee_work_time_contract.dart';

void main() {
  test(
    'approved time produces gross hourly pay while submitted time stays pending',
    () {
      final period = EmployeePayPeriodSchedule(
        frequency: EmployeePayFrequency.weekly,
        anchorStartDate: DateTime(2026, 7, 6),
      ).periodContaining(DateTime(2026, 7, 8));
      final summary = EmployeeGrossPayCalculator.hourly(
        period: period,
        hourlyRateCents: 2500,
        records: [
          _record(
            id: 'approved',
            day: DateTime(2026, 7, 7),
            status: EmployeeWorkTimeStatus.approved,
            minutes: 480,
          ),
          _record(
            id: 'submitted',
            day: DateTime(2026, 7, 8),
            status: EmployeeWorkTimeStatus.submitted,
            minutes: 60,
          ),
        ],
      );

      expect(summary.approvedHours, 8);
      expect(summary.pendingHours, 1);
      expect(summary.grossPayCents, 20000);
    },
  );

  test('biweekly period remains anchored before the configured start date', () {
    final schedule = EmployeePayPeriodSchedule(
      frequency: EmployeePayFrequency.biweekly,
      anchorStartDate: DateTime(2026, 7, 13),
    );

    final period = schedule.periodContaining(DateTime(2026, 7, 10));

    expect(period.start, DateTime(2026, 6, 29));
    expect(period.end, DateTime(2026, 7, 12));
  });

  test(
    'Monday week start produces the product-default Monday-Sunday period',
    () {
      final schedule = EmployeePayPeriodSchedule.fromWeekStart(
        frequency: EmployeePayFrequency.weekly,
        weekStart: 'monday',
        referenceDate: DateTime(2026, 7, 29),
      );

      final period = schedule.periodContaining(DateTime(2026, 7, 29));
      expect(period.start, DateTime(2026, 7, 27));
      expect(period.end, DateTime(2026, 8, 2));
    },
  );

  test('legacy biweekly fallback remains stable across reference weeks', () {
    final first = EmployeePayPeriodSchedule.fromWeekStart(
      frequency: EmployeePayFrequency.biweekly,
      weekStart: 'monday',
      referenceDate: DateTime(2026, 7, 6),
    );
    final second = EmployeePayPeriodSchedule.fromWeekStart(
      frequency: EmployeePayFrequency.biweekly,
      weekStart: 'monday',
      referenceDate: DateTime(2026, 7, 13),
    );

    expect(
      first.periodContaining(DateTime(2026, 7, 15)).start,
      second.periodContaining(DateTime(2026, 7, 15)).start,
    );
  });

  test('pay-period boundaries remain local calendar midnights across DST', () {
    final period = EmployeePayPeriodSchedule(
      frequency: EmployeePayFrequency.weekly,
      anchorStartDate: DateTime(1970, 1, 5),
    ).periodContaining(DateTime(2026, 7, 29));

    expect(period.start, DateTime(2026, 7, 27));
    expect(period.end, DateTime(2026, 8, 2));
  });

  test('time allocations cannot exceed paid work time', () {
    expect(
      () => EmployeeWorkTimeRecord(
        id: 'time-1',
        employeeId: 'employee-1',
        workDate: DateTime(2026, 7, 7),
        recordedAt: DateTime(2026, 7, 7, 17),
        status: EmployeeWorkTimeStatus.draft,
        revision: 0,
        manualPaidMinutes: 60,
        jobAllocations: const [
          EmployeeWorkTimeAllocation(jobId: 'job-1', paidMinutes: 61),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('corrected time requires a human-readable correction reason', () {
    expect(
      () => _record(
        id: 'corrected',
        day: DateTime(2026, 7, 7),
        status: EmployeeWorkTimeStatus.corrected,
        minutes: 60,
      ),
      throwsArgumentError,
    );
  });
}

EmployeeWorkTimeRecord _record({
  required String id,
  required DateTime day,
  required EmployeeWorkTimeStatus status,
  required int minutes,
}) => EmployeeWorkTimeRecord(
  id: id,
  employeeId: 'employee-1',
  workDate: day,
  recordedAt: day.add(const Duration(hours: 18)),
  status: status,
  revision: 1,
  manualPaidMinutes: minutes,
);
