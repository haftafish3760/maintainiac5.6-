import 'invoice_home_models.dart';

List<InvoiceStatusMetric> invoiceMetricsFor(InvoiceWorkspaceMode mode) {
  if (mode == InvoiceWorkspaceMode.estimates) {
    return const [
      InvoiceStatusMetric(
        label: 'All',
        value: '8',
        detail: 'this month',
        filter: InvoiceStatusFilter.all,
      ),
      InvoiceStatusMetric(
        label: 'Draft',
        value: '3',
        detail: 'need review',
        filter: InvoiceStatusFilter.draft,
      ),
      InvoiceStatusMetric(
        label: 'Sent',
        value: '4',
        detail: 'waiting',
        filter: InvoiceStatusFilter.sent,
      ),
      InvoiceStatusMetric(
        label: 'Approved',
        value: '1',
        detail: 'ready to invoice',
        filter: InvoiceStatusFilter.approved,
      ),
    ];
  }
  return const [
    InvoiceStatusMetric(
      label: 'Total Paid',
      value: r'$4,280',
      detail: 'received',
      filter: InvoiceStatusFilter.paid,
    ),
    InvoiceStatusMetric(
      label: 'Total Unpaid',
      value: r'$2,145',
      detail: 'open invoices',
      filter: InvoiceStatusFilter.unpaid,
    ),
    InvoiceStatusMetric(
      label: 'Total Overdue',
      value: r'$612',
      detail: 'needs action',
      filter: InvoiceStatusFilter.overdue,
    ),
    InvoiceStatusMetric(
      label: 'Upcoming',
      value: '3',
      detail: 'due soon',
      filter: InvoiceStatusFilter.upcoming,
    ),
    InvoiceStatusMetric(
      label: 'All Invoices',
      value: '12',
      detail: 'show all',
      filter: InvoiceStatusFilter.all,
    ),
  ];
}

List<InvoiceTimelineEntry> invoiceEntriesFor(InvoiceWorkspaceMode mode) {
  if (mode == InvoiceWorkspaceMode.estimates) {
    return [
      InvoiceTimelineEntry(
        title: 'Smith kitchen repair',
        subtitle: 'Time & materials | sent for approval',
        amount: r'$937.74',
        status: 'Sent',
        day: DateTime(2026, 6, 15),
        filter: InvoiceStatusFilter.sent,
      ),
      InvoiceTimelineEntry(
        title: 'Hill lawn cleanup',
        subtitle: 'Flat rate | approved',
        amount: r'$420.00',
        status: 'Approved',
        day: DateTime(2026, 6, 12),
        filter: InvoiceStatusFilter.approved,
      ),
      InvoiceTimelineEntry(
        title: 'Brown plumbing rough-in',
        subtitle: 'Inventory items still being priced',
        amount: r'$1,850.00',
        status: 'Draft',
        day: DateTime(2026, 6, 10),
        filter: InvoiceStatusFilter.draft,
      ),
    ];
  }
  return [
    InvoiceTimelineEntry(
      title: 'Smith kitchen repair',
      subtitle: 'Invoice INV-2409 | due Jul 15',
      amount: r'$937.74',
      status: 'Unpaid',
      day: DateTime(2026, 6, 15),
      filter: InvoiceStatusFilter.unpaid,
    ),
    InvoiceTimelineEntry(
      title: 'Davis service call',
      subtitle: 'Paid by card',
      amount: r'$185.00',
      status: 'Paid',
      day: DateTime(2026, 6, 14),
      filter: InvoiceStatusFilter.paid,
    ),
    InvoiceTimelineEntry(
      title: 'Baker driveway repair',
      subtitle: 'Invoice INV-2411 | due Jun 28',
      amount: r'$410.00',
      status: 'Upcoming',
      day: DateTime(2026, 6, 22),
      filter: InvoiceStatusFilter.upcoming,
    ),
    InvoiceTimelineEntry(
      title: 'Oak Street repair',
      subtitle: 'Invoice INV-2404 | 9 days late',
      amount: r'$612.50',
      status: 'Overdue',
      day: DateTime(2026, 6, 4),
      filter: InvoiceStatusFilter.overdue,
    ),
  ];
}
