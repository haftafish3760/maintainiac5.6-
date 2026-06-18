part of 'calendar_dummy_data.dart';

List<CalendarTimelineEntry> _contractorEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 7,
      minute: 45,
      type: CalendarEntryType.tripEntry,
      status: CalendarEntryStatus.completed,
      title: 'Crew dispatched',
      source: 'Contractor Dashboard',
      summary: 'Truck 1 assigned to Oak Street repair',
      details: [
        'Vehicle: Truck 1',
        'Assigned helper: Not assigned yet',
        'Starting odometer recorded',
      ],
    ),
    _entry(
      day: day,
      hour: 9,
      minute: 20,
      type: CalendarEntryType.materials,
      status: CalendarEntryStatus.completed,
      title: 'Materials used',
      source: 'Materials',
      summary: r'Plumbing fittings - $86.40 cost basis',
      details: [
        'Job: Oak Street repair',
        'Inventory source: Truck 1',
        'Receipt proof: Available when linked',
      ],
    ),
    _entry(
      day: day,
      hour: 12,
      minute: 10,
      type: CalendarEntryType.expense,
      status: CalendarEntryStatus.needsAttention,
      title: 'Supplier receipt needs review',
      source: 'Expenses',
      summary: r'Supply house - $214.18',
      details: [
        'Needs receipt line review',
        'Can be split between inventory and job cost',
        'Cloud backup follows user setting',
      ],
    ),
    _entry(
      day: day,
      hour: 15,
      minute: 35,
      type: CalendarEntryType.invoiceEstimate,
      status: CalendarEntryStatus.completed,
      title: 'Invoice drafted',
      source: 'Invoices',
      summary: r'Oak Street repair - $725.00',
      details: [
        'Customer signature: Not captured',
        'Contractor signature: Ready',
        'Payment status: Unpaid',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _contractorTodayEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 8,
      minute: 0,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Morning job review',
      source: 'Contractor Dashboard',
      summary: 'Check assigned vehicle, job notes, and material needs',
      details: [
        'Vehicles, jobs, invoices, expenses, and inventory roll into this day.',
        'Future build: crew assignments and customer updates.',
      ],
    ),
    _entry(
      day: day,
      hour: 10,
      minute: 30,
      type: CalendarEntryType.invoiceEstimate,
      status: CalendarEntryStatus.planned,
      title: 'Estimate appointment',
      source: 'Jobs',
      summary: 'Kitchen repair estimate',
      details: [
        'Job status: Planned',
        'Estimate draft can be created from this date.',
      ],
    ),
    _entry(
      day: day,
      hour: 13,
      minute: 15,
      type: CalendarEntryType.materials,
      status: CalendarEntryStatus.needsAttention,
      title: 'Low truck stock',
      source: 'Materials',
      summary: 'Restock review needed before afternoon call',
      details: [
        'Inventory location: Truck 1',
        'Future build: low-stock reminders per vehicle.',
      ],
    ),
  ];
}

List<CalendarTimelineEntry> _contractorFutureEntries(DateTime day) {
  return [
    _entry(
      day: day,
      hour: 9,
      minute: 0,
      type: CalendarEntryType.reminderSchedule,
      status: CalendarEntryStatus.planned,
      title: 'Scheduled service call',
      source: 'Jobs',
      summary: 'Customer job placeholder',
      details: [
        'Assign vehicle and helper when job scheduling is built.',
        'Invoices, materials, mileage, and expenses will link back here.',
      ],
    ),
    _entry(
      day: day,
      hour: 16,
      minute: 0,
      type: CalendarEntryType.invoiceEstimate,
      status: CalendarEntryStatus.planned,
      title: 'Follow up on estimate',
      source: 'Invoices',
      summary: 'Reminder to check customer response',
      details: ['Future build: customer portal status and signature link.'],
    ),
  ];
}
