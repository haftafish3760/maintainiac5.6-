import 'dart:convert';

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

  test('templates fall back to generated previews without artwork assets', () {
    final template = InvoiceTemplateCatalog.byId('plumbing-watermark');

    expect(template.previewAssetPath, isNull);
    expect(template.assetForPage(continuation: false), isNull);
    expect(template.assetForPage(continuation: true), isNull);
  });
}
