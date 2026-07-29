import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/calendar/calendar_invoice_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test(
    'invoice issue and back-dated payment remain distinct calendar events',
    () {
      final issueDate = DateTime(2026, 7, 21);
      final paidAt = DateTime(2026, 7, 24, 14, 30);
      final record = InvoiceRecord(
        id: 'invoice-1',
        documentType: InvoiceDocumentType.invoice,
        invoiceNumber: 'INV-100',
        numberMode: InvoiceNumberMode.automatic,
        status: InvoiceRecordStatus.paid,
        issueDate: issueDate,
        title: 'Jones Tree Work',
        payments: [
          InvoicePaymentRecord(
            id: 'payment-1',
            amount: 1000,
            paidAt: paidAt,
            method: 'Card',
          ),
        ],
        meta: InvoiceSyncMetadata(
          createdAt: DateTime(2026, 7, 21, 9),
          updatedAt: DateTime(2026, 7, 29, 10),
          revision: 4,
        ),
      );

      final issueEvents = CalendarInvoiceProjectionAdapter.eventsForDay([
        record,
      ], issueDate).toList();
      final paymentEvents = CalendarInvoiceProjectionAdapter.eventsForDay([
        record,
      ], paidAt).toList();

      expect(issueEvents, hasLength(1));
      expect(issueEvents.single.source, CalendarProjectionSource.invoice);
      expect(issueEvents.single.timing.timeSource, CalendarTimeSource.unknown);
      expect(issueEvents.single.timing.recordedAt, DateTime(2026, 7, 29, 10));
      expect(paymentEvents, hasLength(1));
      expect(paymentEvents.single.source, CalendarProjectionSource.payment);
      expect(paymentEvents.single.timing.actualAt, paidAt);
      expect(
        paymentEvents.single.deepLink.target,
        CalendarDeepLinkTarget.paymentDetail,
      );
    },
  );
}
