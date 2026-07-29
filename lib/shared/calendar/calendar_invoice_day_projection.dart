// Daily financial calendar recap derived from the source-owned Invoice Ledger.

import '../../screens/invoices/data/invoice_ledger_store.dart';
import 'calendar_flow_models.dart';
import 'calendar_invoice_projection_adapter.dart';

class CalendarInvoiceDayProjection {
  const CalendarInvoiceDayProjection._();

  static CalendarDayData forDay(InvoiceLedgerStore ledger, DateTime day) {
    final records = ledger.records;
    final events = CalendarInvoiceProjectionAdapter.eventsForDay(
      records,
      day,
    ).toList(growable: false);
    final documents = records.where(
      (record) => _sameDay(record.issueDate, day),
    );
    final paymentCount = records.fold<int>(0, (sum, record) {
      return sum +
          record.payments
              .where((payment) => _sameDay(payment.paidAt, day))
              .length;
    });
    final received = records.fold<double>(0, (sum, record) {
      return sum +
          record.payments
              .where((payment) => _sameDay(payment.paidAt, day))
              .fold<double>(
                0,
                (paymentSum, payment) => paymentSum + payment.amount,
              );
    });
    return CalendarDayData(
      recapItems: [
        CalendarRecapItem(label: 'Documents', value: '${documents.length}'),
        CalendarRecapItem(label: 'Payments', value: '$paymentCount'),
        CalendarRecapItem(label: 'Received', value: _money(received)),
        CalendarRecapItem(
          label: 'Needs review',
          value:
              '${events.where((event) => event.state.name == 'needsReview').length}',
        ),
      ],
      entries: [
        for (final event in events) CalendarTimelineEntry.fromProjection(event),
      ],
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _money(double value) => '\$${value.toStringAsFixed(2)}';
