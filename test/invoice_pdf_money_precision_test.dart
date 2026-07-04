import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_template_renderer.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invoice money math uses cent-safe rounding', () {
    final now = DateTime(2026, 7, 4);
    final record = InvoiceRecord(
      id: 'invoice-money-precision',
      documentType: InvoiceDocumentType.invoice,
      invoiceNumber: 'INV-MONEY-001',
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      issueDate: now,
      company: const InvoicePartySnapshot(companyName: 'Maintainiac Repairs'),
      client: const InvoicePartySnapshot(displayName: 'Confirmed Customer'),
      lines: const [
        InvoiceLineItemRecord(
          id: 'decimal-quantity',
          name: 'Decimal quantity',
          quantity: 3,
          unit: 'ea',
          unitPrice: 0.1,
          taxRate: 0,
        ),
        InvoiceLineItemRecord(
          id: 'taxed-material',
          name: 'Taxed material',
          quantity: 3,
          unit: 'ea',
          unitPrice: 19.99,
          taxRate: 6.25,
        ),
        InvoiceLineItemRecord(
          id: 'refund',
          name: 'Returned part credit',
          quantity: -1,
          unit: 'ea',
          unitPrice: 5.55,
          taxRate: 6.25,
        ),
      ],
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.percent,
        value: 10,
      ),
      payments: [
        InvoicePaymentRecord(id: 'payment-1', amount: 10.10, paidAt: now),
        InvoicePaymentRecord(id: 'payment-2', amount: 0.20, paidAt: now),
      ],
      meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
    );

    expect(record.subtotalCents, 5472);
    expect(record.taxTotalCents, 340);
    expect(record.discountAmountCents, 547);
    expect(record.totalCents, 5265);
    expect(record.paidTotalCents, 1030);
    expect(record.balanceDueCents, 4235);
    expect(record.subtotal, 54.72);
    expect(record.taxTotal, 3.40);
    expect(record.discountAmount, 5.47);
    expect(record.balanceDue, 42.35);
  });

  test(
    'invoice PDF renders cent-safe totals with refunds and decimals',
    () async {
      final now = DateTime(2026, 7, 4);
      final record = InvoiceRecord(
        id: 'invoice-money-render',
        documentType: InvoiceDocumentType.invoice,
        invoiceNumber: 'INV-MONEY-002',
        numberMode: InvoiceNumberMode.automatic,
        status: InvoiceRecordStatus.draft,
        issueDate: now,
        company: const InvoicePartySnapshot(companyName: 'Maintainiac Repairs'),
        client: const InvoicePartySnapshot(displayName: 'Confirmed Customer'),
        lines: const [
          InvoiceLineItemRecord(
            id: 'small-decimal',
            name: 'Small decimal',
            quantity: 3,
            unit: 'ea',
            unitPrice: 0.1,
            taxRate: 0,
          ),
          InvoiceLineItemRecord(
            id: 'taxed-material',
            name: 'Taxed material',
            quantity: 3,
            unit: 'ea',
            unitPrice: 19.99,
            taxRate: 6.25,
          ),
        ],
        discount: const InvoiceDiscountRecord(
          type: InvoiceDiscountType.amount,
          value: 0.10,
        ),
        payments: [
          InvoicePaymentRecord(id: 'payment', amount: 10, paidAt: now),
        ],
        meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
      );

      final bytes = await const InvoicePdfTemplateRenderer()
          .buildRecordDocumentBytes(
            record: record,
            template: InvoiceTemplateCatalog.byId('structured-logo'),
          );

      expect(record.subtotalCents, 6027);
      expect(record.taxTotalCents, 375);
      expect(record.balanceDueCents, 5392);
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
  );
}
