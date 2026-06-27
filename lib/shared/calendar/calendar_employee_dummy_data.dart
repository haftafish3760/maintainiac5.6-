part of 'calendar_dummy_data.dart';

List<CalendarTimelineEntry> _employeeEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 7,
      minute: 45,
      type: CalendarEntryType.tripEntry,
      status: CalendarEntryStatus.completed,
      title: 'Clocked into assigned vehicle',
      source: 'Employee',
      summary: 'Work Truck 1 / start-of-day mileage captured',
      details: [
        'Vehicle: Work Truck 1',
        'Business miles: 42',
        'Personal miles: 0',
      ],
    ),
    _entry(
      day: day,
      hour: 9,
      minute: 10,
      type: CalendarEntryType.invoiceEstimate,
      status: CalendarEntryStatus.completed,
      title: 'Rough-in job',
      source: 'Jobs',
      summary: '4.5 hours logged',
      details: ['Job: 124 Maple Ave', 'Role: Technician', 'Hours: 4.5'],
    ),
    _entry(
      day: day,
      hour: 14,
      minute: 0,
      type: CalendarEntryType.expense,
      status: CalendarEntryStatus.needsAttention,
      title: 'Material receipt',
      source: 'Expenses',
      summary: r"Lowe's - $86.24",
      details: [
        'Receipt attached',
        'Needs job link review',
        'Submitted by employee',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _employeeTodayEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 8,
      minute: 0,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Assigned service call',
      source: 'Jobs',
      summary: 'Scheduled job and vehicle assignment',
      details: [
        'Vehicle: Work Truck 1',
        'Expected hours: 3.0',
        'Materials: review after receipt upload',
      ],
    ),
    _entry(
      day: day,
      hour: 10,
      minute: 45,
      type: CalendarEntryType.materials,
      status: CalendarEntryStatus.completed,
      title: 'Used materials',
      source: 'Inventory',
      summary: '3 line items pulled from truck stock',
      details: [
        'Inventory source: assigned vehicle',
        'Job linked',
        'Cost review pending owner approval',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _employeeFutureEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 8,
      minute: 30,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Planned employee assignment',
      source: 'Schedule',
      summary: 'Job, vehicle, and helper plan',
      details: [
        'Assign vehicle before dispatch',
        'Confirm job scope',
        'Planned hours feed the employee profile calendar',
      ],
    ),
  ];
}
