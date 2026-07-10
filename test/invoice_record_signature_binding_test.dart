import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_preview_factory.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';

void main() {
  test('customer signature binds to the invoice content revision', () {
    final record = _record();
    final signed = record.copyWith(
      customerSignature: InvoiceSignatureSnapshot(
        role: 'customer',
        signedAt: DateTime(2026, 7, 9),
        signatureHashSha256: record.documentRevisionHashSha256,
      ),
    );

    expect(signed.customerSignatureIsValid, isTrue);
  });

  test('changing a line item invalidates the bound customer signature', () {
    final record = _record();
    final signed = record.copyWith(
      customerSignature: InvoiceSignatureSnapshot(
        role: 'customer',
        signedAt: DateTime(2026, 7, 9),
        signatureHashSha256: record.documentRevisionHashSha256,
      ),
    );
    final changed = signed.copyWith(
      lines: [
        const InvoiceLineItemRecord(
          id: 'line-1',
          name: 'Labor',
          quantity: 2,
          unit: 'hour',
          unitPrice: 125,
          taxRate: 5,
        ),
      ],
    );

    expect(changed.customerSignatureIsValid, isFalse);
    expect(
      changed.documentRevisionHashSha256,
      isNot(record.documentRevisionHashSha256),
    );
  });

  test('invoice PDF metadata exposes the current signature state', () async {
    final record = _record();
    final document = await const InvoicePdfPreviewFactory().buildRecordPreview(
      record: record,
    );

    expect(document.signatureState, AppGeneratedPdfSignatureState.unsigned);
    expect(document.requiresCustomerSignature, isTrue);
    expect(
      document.documentRevisionHashSha256,
      record.documentRevisionHashSha256,
    );
  });
}

InvoiceRecord _record() {
  final now = DateTime(2026, 7, 9);
  return InvoiceRecord(
    id: 'invoice-signature',
    documentType: InvoiceDocumentType.invoice,
    invoiceNumber: 'INV-1001',
    numberMode: InvoiceNumberMode.automatic,
    status: InvoiceRecordStatus.draft,
    issueDate: now,
    meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
    lines: const [
      InvoiceLineItemRecord(
        id: 'line-1',
        name: 'Labor',
        quantity: 1,
        unit: 'hour',
        unitPrice: 125,
        taxRate: 5,
      ),
    ],
  );
}
