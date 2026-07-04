import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_preview_factory.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_template_renderer.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds every invoice template sample as a PDF', () async {
    for (final template in InvoiceTemplateCatalog.templates) {
      final document = await const InvoicePdfPreviewFactory()
          .buildTemplateSamplePreview(template: template);

      expect(document.safeFileName, endsWith('.pdf'));
      expect(document.bytes.length, greaterThan(1000));
      expect(latin1.decode(document.bytes.take(5).toList()), '%PDF-');
      expect(document.title, contains(template.name));
    }
  });

  test('renders long invoice line item lists as a multi-page PDF', () async {
    final now = DateTime(2026, 6, 15);
    final record = InvoiceRecord(
      id: 'invoice-long',
      documentType: InvoiceDocumentType.invoice,
      invoiceNumber: 'INV-0099',
      numberMode: InvoiceNumberMode.automatic,
      status: InvoiceRecordStatus.draft,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      company: const InvoicePartySnapshot(companyName: 'Jane Doe Services'),
      client: const InvoicePartySnapshot(displayName: 'Alex Customer'),
      lines: [
        for (var index = 1; index <= 35; index++)
          InvoiceLineItemRecord(
            id: 'line-$index',
            name: 'Service item $index',
            details: 'Labor, materials, and job notes for item $index',
            quantity: index.toDouble(),
            unit: 'ea',
            unitPrice: 7.5,
            taxRate: 5,
          ),
      ],
      meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
    );

    final bytes = await const InvoicePdfTemplateRenderer()
        .buildRecordDocumentBytes(
          record: record,
          template: InvoiceTemplateCatalog.byId('plumbing-watermark'),
        );

    expect(invoicePdfPageCountForRecord(record), greaterThan(1));
    expect(bytes.length, greaterThan(1000));
    expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
  });

  test(
    'invoice PDF output is deterministic for the same confirmed input',
    () async {
      final now = DateTime(2026, 7, 4, 10, 30);
      final record = InvoiceRecord(
        id: 'invoice-deterministic',
        documentType: InvoiceDocumentType.invoice,
        invoiceNumber: 'INV-DET-100',
        numberMode: InvoiceNumberMode.automatic,
        status: InvoiceRecordStatus.draft,
        issueDate: now,
        dueDate: now.add(const Duration(days: 14)),
        company: const InvoicePartySnapshot(companyName: 'Maintainiac Repairs'),
        client: const InvoicePartySnapshot(displayName: 'Confirmed Customer'),
        lines: const [
          InvoiceLineItemRecord(
            id: 'labor',
            name: 'Labor',
            details: 'Confirmed service labor',
            quantity: 3,
            unit: 'hr',
            unitPrice: 85,
            taxRate: 0,
          ),
          InvoiceLineItemRecord(
            id: 'materials',
            name: 'Materials',
            details: 'Confirmed repair supplies',
            quantity: 2,
            unit: 'ea',
            unitPrice: 19.99,
            taxRate: 6.25,
          ),
        ],
        discount: const InvoiceDiscountRecord(
          type: InvoiceDiscountType.amount,
          value: 12.50,
        ),
        payments: [
          InvoicePaymentRecord(
            id: 'payment-1',
            amount: 50,
            paidAt: DateTime(2026, 7, 4, 12),
          ),
        ],
        terms: 'Payment due on receipt.',
        meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
      );
      const renderer = InvoicePdfTemplateRenderer();
      final template = InvoiceTemplateCatalog.byId('structured-logo');

      final first = await renderer.buildRecordDocumentBytes(
        record: record,
        template: template,
      );
      final second = await renderer.buildRecordDocumentBytes(
        record: record,
        template: template,
      );

      expect(first, second);
      expect(
        sha256.convert(first).toString(),
        sha256.convert(second).toString(),
      );
    },
  );

  test('templates fall back to generated previews without artwork assets', () {
    final template = InvoiceTemplateCatalog.byId('plumbing-watermark');

    expect(template.previewAssetPath, isNull);
    expect(template.assetForPage(continuation: false), isNull);
    expect(template.assetForPage(continuation: true), isNull);
  });
}
