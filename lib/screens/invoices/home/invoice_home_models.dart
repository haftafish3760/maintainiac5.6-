enum InvoiceWorkspaceMode { invoices, estimates }

enum InvoiceStatusFilter {
  all,
  paid,
  unpaid,
  overdue,
  upcoming,
  draft,
  sent,
  approved,
}

class InvoiceStatusMetric {
  const InvoiceStatusMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.filter,
  });

  final String label;
  final String value;
  final String detail;
  final InvoiceStatusFilter filter;
}

class InvoiceTimelineEntry {
  const InvoiceTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.day,
    required this.filter,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final DateTime day;
  final InvoiceStatusFilter filter;
}

class InvoiceQuickAction {
  const InvoiceQuickAction({
    required this.label,
    required this.iconName,
    required this.action,
  });

  final String label;
  final String iconName;
  final InvoiceQuickActionType action;
}

enum InvoiceQuickActionType {
  myInfo,
  clientInfo,
  recordPayment,
  createEstimate,
  createInvoice,
}
