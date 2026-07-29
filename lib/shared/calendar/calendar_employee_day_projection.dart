// Employee-specific calendar projection. The caller must pass the employee's
// own source records; it does not fall back to team-wide sample data.

import '../profiles/employee_work_time_contract.dart';
import 'calendar_flow_models.dart';
import 'calendar_work_time_projection_adapter.dart';

class CalendarEmployeeDayProjection {
  const CalendarEmployeeDayProjection._();

  static CalendarDayData forDay(
    Iterable<EmployeeWorkTimeRecord> records,
    DateTime day,
  ) {
    final dayRecords = records
        .where(
          (record) =>
              record.workDate.year == day.year &&
              record.workDate.month == day.month &&
              record.workDate.day == day.day,
        )
        .toList(growable: false);
    final totalMinutes = dayRecords.fold<int>(
      0,
      (sum, record) => sum + record.paidMinutes,
    );
    final approved = dayRecords
        .where((record) => record.countsTowardGrossPay)
        .fold<int>(0, (sum, record) => sum + record.paidMinutes);
    final awaitingReview = dayRecords
        .where(
          (record) =>
              !record.countsTowardGrossPay &&
              record.status != EmployeeWorkTimeStatus.rejected,
        )
        .length;
    return CalendarDayData(
      recapItems: [
        CalendarRecapItem(label: 'Hours', value: _hours(totalMinutes)),
        CalendarRecapItem(label: 'Approved', value: _hours(approved)),
        CalendarRecapItem(label: 'Entries', value: '${dayRecords.length}'),
        CalendarRecapItem(label: 'Needs review', value: '$awaitingReview'),
      ],
      entries: [
        for (final event in CalendarWorkTimeProjectionAdapter.eventsForDay(
          records,
          day,
        ))
          CalendarTimelineEntry.fromProjection(event),
      ],
    );
  }
}

String _hours(int minutes) => (minutes / 60).toStringAsFixed(2);
