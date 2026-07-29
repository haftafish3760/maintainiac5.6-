// Employee pay-period calendar projection. It reads approved and pending time
// records and never invents a pay rate, payroll deduction, or pay outcome.

import '../profiles/employee_work_time_contract.dart';

class CalendarEmployeePayPeriodProjection {
  const CalendarEmployeePayPeriodProjection._();

  static CalendarEmployeePayPeriodRecap forDate({
    required Iterable<EmployeeWorkTimeRecord> records,
    required EmployeePayPeriodSchedule schedule,
    required DateTime date,
    int? hourlyRateCents,
  }) {
    if (hourlyRateCents != null && hourlyRateCents < 0) {
      throw ArgumentError.value(hourlyRateCents, 'hourlyRateCents');
    }
    final period = schedule.periodContaining(date);
    var approvedMinutes = 0;
    var pendingMinutes = 0;
    for (final record in records) {
      if (!period.contains(record.workDate)) continue;
      if (record.countsTowardGrossPay) {
        approvedMinutes += record.paidMinutes;
      } else if (record.status != EmployeeWorkTimeStatus.rejected) {
        pendingMinutes += record.paidMinutes;
      }
    }
    final grossPayCents = hourlyRateCents == null
        ? null
        : (approvedMinutes * hourlyRateCents / 60).round();
    return CalendarEmployeePayPeriodRecap(
      period: period,
      frequency: schedule.frequency,
      approvedMinutes: approvedMinutes,
      pendingMinutes: pendingMinutes,
      grossPayCents: grossPayCents,
    );
  }
}

class CalendarEmployeePayPeriodRecap {
  const CalendarEmployeePayPeriodRecap({
    required this.period,
    required this.frequency,
    required this.approvedMinutes,
    required this.pendingMinutes,
    required this.grossPayCents,
  });

  final EmployeePayPeriod period;
  final EmployeePayFrequency frequency;
  final int approvedMinutes;
  final int pendingMinutes;

  /// Null means no explicit hourly rate was supplied; it is not a zero-pay
  /// conclusion and must be shown as unavailable rather than guessed.
  final int? grossPayCents;

  double get approvedHours => approvedMinutes / 60;
  double get pendingHours => pendingMinutes / 60;
  double? get grossPay => grossPayCents == null ? null : grossPayCents! / 100;
}
