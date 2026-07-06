import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_export_verifier.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';
import 'package:maintaniac/shared/pdf/app_pdf_security_policy.dart';

import 'helpers/invoice_document_engine_fixture_factory.dart';

void main() {
  test('invoice PDF export verifier separates blocking and QA issues', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final bytes = _pdfWithText(
      'Invoice ${record.invoiceNumber}\n'
      'Subtotal Total Balance ${_moneyText(record.balanceDue)}\n',
    );

    final blockingIssues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: bytes,
    );
    final allIssues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: bytes,
    );

    expect(blockingIssues, isEmpty);
    expect(allIssues, isEmpty);
  });

  test('invoice PDF export verifier reports missing searchable text', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(''),
    );

    expect(issues, contains(InvoicePdfExportVerifier.missingPdfTextLayer));
    expect(
      InvoicePdfExportVerifier.blockingIssueCodesForExport(
        record: record,
        template: template,
        bytes: _pdfWithText(''),
      ),
      isEmpty,
    );
  });

  test('invoice PDF export verifier reports missing invoice number', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice Subtotal Total Balance ${record.balanceDue}',
      ),
    );

    expect(issues, contains(InvoicePdfExportVerifier.missingInvoiceNumber));
  });

  test('invoice PDF export verifier reports missing document label', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        '${record.invoiceNumber} Subtotal Total Balance ${record.balanceDue}',
      ),
    );

    expect(issues, contains(InvoicePdfExportVerifier.missingDocumentLabel));
  });

  test('invoice PDF export verifier reports missing money total', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText('Invoice ${record.invoiceNumber} Subtotal Total'),
    );

    expect(issues, contains(InvoicePdfExportVerifier.missingBalanceDue));
  });

  test('invoice PDF export verifier accepts estimate label', () {
    final record = InvoiceDocumentEngineFixtureFactory.estimate(lineCount: 2);
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Estimate ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)}',
      ),
    );

    expect(issues, isEmpty);
  });

  test('invoice PDF export verifier reports wrong estimate label', () {
    final record = InvoiceDocumentEngineFixtureFactory.estimate(lineCount: 2);
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.issueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)}',
      ),
    );

    expect(issues, contains(InvoicePdfExportVerifier.missingDocumentLabel));
    expect(issues, contains(InvoicePdfExportVerifier.wrongDocumentLabel));
  });

  test('invoice PDF export verifier blocks active PDF content', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final bytes = _pdfWithText(
      'Invoice ${record.invoiceNumber} Subtotal Total Balance '
      '${_moneyText(record.balanceDue)} /OpenAction /S /JavaScript',
    );
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: bytes,
    );

    expect(issues, contains(AppPdfSecurityPolicy.activeJavaScript));
    expect(issues, contains(AppPdfSecurityPolicy.autoOpenAction));
    expect(issues, contains(InvoicePdfExportVerifier.unsafeGeneratedPdf));
  });

  test('invoice PDF export verifier blocks private invoice metadata', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(title: 'Invoice for VIN 1HGCM82633A004352');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)}',
      ),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.vin));
  });

  test('invoice PDF export verifier blocks internal line and payment IDs', () {
    final record =
        InvoiceDocumentEngineFixtureFactory.standardInvoice(
          lineCount: 2,
        ).copyWith(
          lines: const [
            InvoiceLineItemRecord(
              id: 'line-internal-123456',
              name: 'Service labor',
              quantity: 1,
              unitPrice: 85,
            ),
          ],
          payments: [
            InvoicePaymentRecord(
              id: 'payment-internal-123456',
              amount: 50,
              paidAt: InvoiceDocumentEngineFixtureFactory.fixedNow,
              method: 'Card',
            ),
          ],
        );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)} '
        'line-internal-123456 payment-internal-123456',
      ),
    );

    expect(issues, contains(InvoicePdfExportVerifier.internalRecordIdExported));
  });

  test('invoice PDF export verifier allows normal visible line labels', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      id: 'invoice-standard-fixture',
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)} '
        'Material and service item 1 Labor task 2 Confirmed business line',
      ),
    );

    expect(issues, isEmpty);
  });

  test('invoice PDF export verifier blocks passenger invoice metadata', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(title: 'Passenger name: Alex Rider');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _validInvoiceBytes(record),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.passengerData));
  });

  test('invoice PDF export verifier blocks patient invoice metadata', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(title: 'Patient name: Clinic Customer');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _validInvoiceBytes(record),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.patientData));
  });

  test('invoice PDF export verifier blocks payment fragments', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(paymentMethod: 'Visa ending 4242');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _validInvoiceBytes(record),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.paymentFragment));
  });

  test('invoice PDF export verifier blocks private source paths', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(terms: 'Stored at /Users/rbbie/private/invoice.pdf');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _validInvoiceBytes(record),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.privateSourcePath));
  });

  test('invoice PDF export verifier blocks unconfirmed OCR suggestions', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    ).copyWith(terms: 'Raw OCR suggestion should not export.');
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _validInvoiceBytes(record),
    );

    expect(issues, contains(AppPdfPrivacyPolicy.unconfirmedOcrSuggestion));
  });

  test('invoice PDF export verifier blocks embedded file actions', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)} /EmbeddedFile /Filespec',
      ),
    );

    expect(issues, contains(AppPdfSecurityPolicy.embeddedFile));
    expect(issues, contains(InvoicePdfExportVerifier.unsafeGeneratedPdf));
  });

  test('invoice PDF export verifier blocks external URI actions', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: _pdfWithText(
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)} /S /URI /URI (https://example.com)',
      ),
    );

    expect(issues, contains(AppPdfSecurityPolicy.externalLinks));
    expect(issues, contains(InvoicePdfExportVerifier.unsafeGeneratedPdf));
  });

  test('invoice PDF export verifier blocks incomplete generated PDFs', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: latin1.encode(
        '%PDF-1.7\n'
        'Invoice ${record.invoiceNumber} Subtotal Total Balance '
        '${_moneyText(record.balanceDue)}',
      ),
    );

    expect(issues, contains('missing_pdf_end_marker'));
    expect(issues, contains(InvoicePdfExportVerifier.unsafeGeneratedPdf));
  });

  test('invoice PDF export verifier does not block QA-only text findings', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final bytes = _pdfWithText('Invoice Subtotal Total');

    expect(
      InvoicePdfExportVerifier.issueCodesForExport(
        record: record,
        template: template,
        bytes: bytes,
      ),
      containsAll([
        InvoicePdfExportVerifier.missingInvoiceNumber,
        InvoicePdfExportVerifier.missingBalanceDue,
      ]),
    );
    expect(
      InvoicePdfExportVerifier.blockingIssueCodesForExport(
        record: record,
        template: template,
        bytes: bytes,
      ),
      isEmpty,
    );
  });

  test('invoice PDF export verifier blocks internal record id leaks', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      id: 'invoice-internal-leak-123',
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final bytes = _pdfWithText(
      'Invoice ${record.invoiceNumber} Subtotal Total Balance '
      '${_moneyText(record.balanceDue)} invoice-internal-leak-123',
    );
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: bytes,
    );

    expect(issues, contains(InvoicePdfExportVerifier.internalRecordIdExported));
    expect(
      () => InvoicePdfExportVerifier.ensureSafeExport(
        record: record,
        template: template,
        bytes: bytes,
      ),
      throwsA(isA<InvoicePdfExportVerificationException>()),
    );
  });

  test('invoice PDF export verifier blocks malformed generated PDFs', () {
    final record = InvoiceDocumentEngineFixtureFactory.standardInvoice(
      lineCount: 2,
    );
    final template = InvoiceTemplateCatalog.byId(record.templateId);
    final issues = InvoicePdfExportVerifier.blockingIssueCodesForExport(
      record: record,
      template: template,
      bytes: latin1.encode('not a pdf'),
    );

    expect(issues, contains('missing_pdf_header'));
    expect(issues, contains('missing_pdf_end_marker'));
    expect(issues, contains(InvoicePdfExportVerifier.unsafeGeneratedPdf));
  });
}

List<int> _pdfWithText(String text) {
  return latin1.encode('%PDF-1.7\n$text\n%%EOF');
}

List<int> _validInvoiceBytes(InvoiceRecord record) {
  return _pdfWithText(
    'Invoice ${record.invoiceNumber} Subtotal Total Balance '
    '${_moneyText(record.balanceDue)}',
  );
}

String _moneyText(num value) {
  final fixed = value.toStringAsFixed(2);
  return value < 0 ? '-\$${fixed.substring(1)}' : '\$$fixed';
}
