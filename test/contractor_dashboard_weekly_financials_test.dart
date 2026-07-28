import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_weekly_expenses_screen.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_weekly_payments_screen.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';

void main() {
  test('contractor expense week uses Monday through Sunday', () {
    final range = contractorExpenseWeekRange(DateTime(2026, 7, 25));

    expect(range.start, DateTime(2026, 7, 20));
    expect(range.end, DateTime(2026, 7, 26));
    expect(range.inclusiveDayCount, 7);
  });

  test('contractor weekly payments use saved invoice payment dates', () {
    final now = DateTime(2026, 7, 25, 12);
    final records = [
      _invoice(
        id: 'invoice_this_week',
        number: '1042',
        customer: 'Oak Street Client',
        payments: [
          InvoicePaymentRecord(
            id: 'payment_friday',
            amount: 425,
            paidAt: DateTime(2026, 7, 24, 14, 30),
            method: 'Check',
          ),
          InvoicePaymentRecord(
            id: 'payment_prior_week',
            amount: 100,
            paidAt: DateTime(2026, 7, 19, 9),
          ),
        ],
      ),
      _invoice(
        id: 'voided_invoice',
        number: '1043',
        customer: 'Voided Client',
        status: InvoiceRecordStatus.voided,
        payments: [
          InvoicePaymentRecord(
            id: 'voided_payment',
            amount: 999,
            paidAt: DateTime(2026, 7, 23, 10),
          ),
        ],
      ),
    ];

    final payments = contractorPaymentsForWeek(records, now);

    expect(payments, hasLength(1));
    expect(payments.single.invoiceId, 'invoice_this_week');
    expect(payments.single.invoiceLabel, 'Invoice 1042');
    expect(payments.single.customerLabel, 'Oak Street Client');
    expect(payments.single.amount, 425);
    expect(payments.single.method, 'Check');
  });
}

InvoiceRecord _invoice({
  required String id,
  required String number,
  required String customer,
  required List<InvoicePaymentRecord> payments,
  InvoiceRecordStatus status = InvoiceRecordStatus.partlyPaid,
}) {
  final createdAt = DateTime(2026, 7, 1);
  return InvoiceRecord(
    id: id,
    documentType: InvoiceDocumentType.invoice,
    invoiceNumber: number,
    numberMode: InvoiceNumberMode.automatic,
    status: status,
    issueDate: createdAt,
    client: InvoicePartySnapshot(displayName: customer),
    payments: payments,
    meta: InvoiceSyncMetadata(createdAt: createdAt, updatedAt: createdAt),
  );
}
