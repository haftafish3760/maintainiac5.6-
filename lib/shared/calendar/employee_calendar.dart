// Employee Calendar presentation. Employee and work-time owners retain all
// profile/payroll data; this widget only projects the configured pay period.

import 'package:flutter/material.dart';

import '../profiles/employee_directory_models.dart';
import '../profiles/employee_work_time_contract.dart';
import '../profiles/employee_work_time_store.dart';
import 'app_month_calendar.dart';
import 'calendar_employee_pay_period_projection.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';

class EmployeeCalendar extends StatefulWidget {
  const EmployeeCalendar({super.key, required this.employee});

  final EmployeeDirectoryRecord employee;

  @override
  State<EmployeeCalendar> createState() => _EmployeeCalendarState();
}

class _EmployeeCalendarState extends State<EmployeeCalendar> {
  late DateTime _recapDate;

  @override
  void initState() {
    super.initState();
    _recapDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final records =
        EmployeeWorkTimeScope.maybeOf(
          context,
        )?.recordsForEmployee(widget.employee.id) ??
        const <EmployeeWorkTimeRecord>[];
    final recap = CalendarEmployeePayPeriodProjection.forDate(
      records: records,
      schedule: _payScheduleFor(widget.employee, _recapDate),
      date: _recapDate,
      hourlyRateCents: _hourlyRateCents(widget.employee),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarStatusPanel(
          icon: Icons.payments_rounded,
          title: '${_frequencyLabel(recap.frequency)} pay period',
          subtitle:
              '${_date(recap.period.start)}–${_date(recap.period.end)} · approved time only is included in gross pay.',
        ),
        const SizedBox(height: 8),
        CalendarRecapStrip(
          items: [
            CalendarRecapItem(
              label: 'Approved hours',
              value: recap.approvedHours.toStringAsFixed(2),
            ),
            CalendarRecapItem(
              label: 'Pending hours',
              value: recap.pendingHours.toStringAsFixed(2),
            ),
            CalendarRecapItem(
              label: _payValueLabel(widget.employee),
              value: _payValue(widget.employee, recap),
            ),
            CalendarRecapItem(
              label: 'Pay setting',
              value: widget.employee.payType == 'hourly'
                  ? 'Hourly'
                  : 'Not hourly',
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppMonthCalendar(
          source: CalendarFlowSource.employee,
          employeeId: widget.employee.id,
          onDaySelected: (day) => setState(() => _recapDate = day),
        ),
      ],
    );
  }
}

EmployeePayFrequency _frequencyFor(String value) => switch (value) {
  'biweekly' => EmployeePayFrequency.biweekly,
  'semimonthly' => EmployeePayFrequency.semimonthly,
  'monthly' => EmployeePayFrequency.monthly,
  _ => EmployeePayFrequency.weekly,
};

int? _hourlyRateCents(EmployeeDirectoryRecord employee) {
  if (employee.payType != 'hourly') return null;
  return employeePayRateCents(employee.grossRate);
}

String _payValueLabel(EmployeeDirectoryRecord employee) =>
    employee.payType == 'salary' ? 'Configured salary' : 'Gross pay';

String _payValue(
  EmployeeDirectoryRecord employee,
  CalendarEmployeePayPeriodRecap recap,
) {
  if (employee.payType == 'salary') {
    final cents = employeePayRateCents(employee.grossRate);
    return cents == null
        ? 'Rate unavailable'
        : '\$${(cents / 100).toStringAsFixed(2)} / period';
  }
  return recap.grossPay == null
      ? 'Rate unavailable'
      : '\$${recap.grossPay!.toStringAsFixed(2)}';
}

EmployeePayPeriodSchedule _payScheduleFor(
  EmployeeDirectoryRecord employee,
  DateTime referenceDate,
) {
  final frequency = _frequencyFor(employee.payFrequency);
  final anchor = employee.payPeriodAnchorDate;
  if (anchor != null) {
    return EmployeePayPeriodSchedule(
      frequency: frequency,
      anchorStartDate: anchor,
    );
  }
  return EmployeePayPeriodSchedule.fromWeekStart(
    frequency: frequency,
    weekStart: employee.payPeriodStartDay,
    referenceDate: referenceDate,
  );
}

String _frequencyLabel(EmployeePayFrequency value) => switch (value) {
  EmployeePayFrequency.weekly => 'Weekly',
  EmployeePayFrequency.biweekly => 'Biweekly',
  EmployeePayFrequency.semimonthly => 'Semimonthly',
  EmployeePayFrequency.monthly => 'Monthly',
};

String _date(DateTime value) => '${value.month}/${value.day}';
