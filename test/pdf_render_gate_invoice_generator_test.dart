import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_template_renderer.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes real invoice renderer sample for PDF render gate', () async {
    final outputPath =
        Platform.environment['PDF_RENDER_GATE_INVOICE_OUTPUT'] ??
        '${Directory.systemTemp.path}/maintainiac_real_invoice_render_gate.pdf';
    final now = DateTime(2026, 7, 4, 10, 30);
    final record = InvoiceRecord(
      id: 'render-smoke-invoice',
      documentType: InvoiceDocumentType.invoice,
      invoiceNumber: 'INV-2409',
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      title: 'Panel Replacement And Service Visit',
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      company: const InvoicePartySnapshot(
        companyName: 'Maintainiac Field Services',
        street: '100 Service Plaza',
        city: 'Columbus',
        state: 'OH',
        postalCode: '43004',
        phone: '(555) 010-2409',
        email: 'billing@example.com',
      ),
      client: const InvoicePartySnapshot(
        displayName: 'Sample Customer',
        street: '42 Customer Way',
        city: 'Dayton',
        state: 'OH',
        postalCode: '45402',
        phone: '(555) 010-1017',
        email: 'customer@example.com',
      ),
      lines: [
        for (var index = 1; index <= 42; index++)
          InvoiceLineItemRecord(
            id: 'render-line-$index',
            name: 'Service line item $index',
            details:
                'Confirmed labor, material handling, and job notes for section $index',
            quantity: index.isEven ? 1.5 : 2,
            unit: index.isEven ? 'hr' : 'ea',
            unitPrice: index.isEven ? 82.75 : 18.49,
            taxRate: index.isEven ? 0 : 6.25,
            taxable: !index.isEven,
          ),
      ],
      discount: const InvoiceDiscountRecord(
        type: InvoiceDiscountType.amount,
        value: 25,
      ),
      payments: [
        InvoicePaymentRecord(
          id: 'render-payment-1',
          amount: 150,
          paidAt: now.add(const Duration(hours: 2)),
          method: 'Cash',
        ),
      ],
      terms: 'Payment due within 30 days. Thank you for your business.',
      meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
    );

    final bytes = await const InvoicePdfTemplateRenderer()
        .buildRecordDocumentBytes(
          record: record,
          template: InvoiceTemplateCatalog.byId('structured-logo'),
        );
    final output = File(outputPath);
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes, flush: true);

    expect(output.existsSync(), isTrue);
    expect(output.lengthSync(), greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(invoicePdfPageCountForRecord(record), greaterThan(1));
  });
}
