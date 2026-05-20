import 'calendar_flow_models.dart';

CalendarDayData calendarDummyDataFor(DateTime day, CalendarDayMode mode) {
  final normalized = DateTime(day.year, day.month, day.day);

  return CalendarDayData(
    recapItems: switch (mode) {
      CalendarDayMode.future => const [],
      CalendarDayMode.past || CalendarDayMode.today => const [
        CalendarRecapItem(label: 'Gross', value: r'$1,850'),
        CalendarRecapItem(label: 'Expenses', value: r'$610'),
        CalendarRecapItem(label: 'Profit', value: r'$1,240'),
        CalendarRecapItem(label: 'Miles', value: '128'),
      ],
    },
    entries: switch (mode) {
      CalendarDayMode.past => _pastEntries(normalized),
      CalendarDayMode.today => _todayEntries(normalized),
      CalendarDayMode.future => _futureEntries(normalized),
    },
  );
}

List<CalendarTimelineEntry> _pastEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 7,
      minute: 25,
      type: CalendarEntryType.tripEntry,
      status: CalendarEntryStatus.completed,
      title: 'Day started',
      source: 'Dashboard',
      summary: 'Start odometer 298,150',
      details: [
        'Vehicle: Default',
        'Starting odometer: 298,150',
        'Added from dashboard start button',
      ],
    ),
    _entry(
      day: day,
      hour: 8,
      minute: 10,
      type: CalendarEntryType.stop,
      status: CalendarEntryStatus.completed,
      title: 'Arrived at first stop',
      source: 'Trip log',
      summary: '18 miles from start',
      details: [
        'Stop type: Job site',
        'Distance from day start: 18 miles',
        'Arrival confirmed manually',
      ],
    ),
    _entry(
      day: day,
      hour: 8,
      minute: 42,
      type: CalendarEntryType.pickup,
      status: CalendarEntryStatus.completed,
      title: 'Pickup completed',
      source: 'Trip log',
      summary: 'Materials picked up for invoice draft',
      details: [
        'Linked item: Invoice draft #1042',
        'Pickup location: Supplier counter',
        'Materials count: 4',
      ],
    ),
    _entry(
      day: day,
      hour: 10,
      minute: 15,
      type: CalendarEntryType.expense,
      status: CalendarEntryStatus.needsAttention,
      title: 'Fuel expense',
      source: 'Expenses',
      summary: r'$45.00, receipt photo missing',
      details: [
        'Category: Fuel',
        r'Amount: $45.00',
        'Needs receipt photo attached',
      ],
    ),
    _entry(
      day: day,
      hour: 11,
      minute: 30,
      type: CalendarEntryType.delivery,
      status: CalendarEntryStatus.completed,
      title: 'Drop-off completed',
      source: 'Trip log',
      summary: '25 miles logged',
      details: [
        'Delivery status: Completed',
        'Distance: 25 miles',
        'Customer confirmation needed later',
      ],
    ),
    _entry(
      day: day,
      hour: 13,
      minute: 5,
      type: CalendarEntryType.payment,
      status: CalendarEntryStatus.completed,
      title: 'Payment logged',
      source: 'Invoices',
      summary: r'$450.00 applied to invoice',
      details: [
        'Payment method: Card',
        'Linked invoice: #1042',
        r'Amount received: $450.00',
      ],
    ),
    _entry(
      day: day,
      hour: 16,
      minute: 50,
      type: CalendarEntryType.maintenance,
      status: CalendarEntryStatus.completed,
      title: 'Tire pressure checked',
      source: 'Maintenance',
      summary: 'All tires adjusted',
      details: [
        'Front left: 36 PSI',
        'Front right: 36 PSI',
        'Rear tires: 38 PSI',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _todayEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 9,
      minute: 0,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Pickup window',
      source: 'Schedule',
      summary: '2:30 PM to 4:00 PM',
      details: [
        'Customer: Demo customer',
        'Address: 123 Worksite Road',
        'Phone: (555) 010-1200',
      ],
    ),
    _entry(
      day: day,
      hour: 9,
      minute: 15,
      type: CalendarEntryType.tripEntry,
      status: CalendarEntryStatus.completed,
      title: 'Day started',
      source: 'Dashboard',
      summary: 'Active shift in progress',
      details: [
        'Shift timer running',
        'Start odometer captured',
        'Current-day edits allowed',
      ],
    ),
    _entry(
      day: day,
      hour: 10,
      minute: 10,
      type: CalendarEntryType.expense,
      status: CalendarEntryStatus.needsAttention,
      title: 'Fuel expense',
      source: 'Expenses',
      summary: r'$45.00, receipt needed',
      details: [
        'Category: Fuel',
        r'Amount: $45.00',
        'Receipt photo not attached yet',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _futureEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 8,
      minute: 30,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Scheduled job',
      source: 'Schedule',
      summary: 'Customer, address, phone, and notes ready',
      details: [
        'Customer: Demo customer',
        'Address: 123 Worksite Road',
        'Phone: (555) 010-1200',
      ],
    ),
    _entry(
      day: day,
      hour: 11,
      minute: 0,
      type: CalendarEntryType.maintenance,
      status: CalendarEntryStatus.planned,
      title: 'Oil service reminder',
      source: 'Maintenance',
      summary: 'Service due soon',
      details: [
        'Vehicle: Default',
        'Reminder threshold: Orange',
        'Can link supplies later',
      ],
    ),
  ];
}

CalendarTimelineEntry _entry({
  required DateTime day,
  required int hour,
  required int minute,
  required CalendarEntryType type,
  required CalendarEntryStatus status,
  required String title,
  required String source,
  required String summary,
  required List<String> details,
}) {
  final timestamp = DateTime(day.year, day.month, day.day, hour, minute);

  return CalendarTimelineEntry(
    id: '${day.year}-${day.month}-${day.day}-$hour-$minute-${type.name}',
    timestamp: timestamp,
    type: type,
    status: status,
    title: title,
    source: source,
    summary: summary,
    details: details,
  );
}
