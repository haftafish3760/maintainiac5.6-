import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_preview_factory.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_template_renderer.dart';
import 'package:maintaniac/screens/invoices/data/invoice_template_catalog.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/signatures/app_signature_models.dart';

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

  test('share delivery text identifies unsigned and stale documents', () {
    final base = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-1001',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 9),
      shareText: 'Review this invoice.',
      signatureState: AppGeneratedPdfSignatureState.unsigned,
    );
    expect(
      base.shareTextForDelivery,
      contains('Customer signature is still required'),
    );
    final stale = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-1001',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 9),
      shareText: 'Review this invoice.',
      signatureState: AppGeneratedPdfSignatureState.stale,
    );
    expect(
      stale.shareTextForDelivery,
      contains('previous customer signature is no longer valid'),
    );
  });

  test(
    'signature ink persists with the invoice and renders as vector PDF art',
    () async {
      final record = _record();
      final ownerInk = AppSignatureResult(
        role: AppSignatureRole.owner,
        signedAt: DateTime(2026, 7, 9, 10),
        strokes: const [
          AppSignatureStroke([Offset(2, 14), Offset(28, 4), Offset(50, 18)]),
        ],
      );
      final ownerSnapshot = InvoiceSignatureSnapshot(
        role: 'owner',
        signedAt: ownerInk.signedAt,
        signature: ownerInk,
      );
      final restored = InvoiceSignatureSnapshot.fromMap(ownerSnapshot.toMap());
      final signedRecord = record.copyWith(ownerSignature: restored);

      expect(restored.hasInk, isTrue);
      expect(restored.signature!.strokes.single.points, hasLength(3));
      expect(invoiceSignatureSvg(restored.signature!), contains('<path'));
      final bytes = await const InvoicePdfTemplateRenderer()
          .buildRecordDocumentBytes(
            record: signedRecord,
            template: InvoiceTemplateCatalog.byId(signedRecord.templateId),
          );
      expect(bytes.take(5), '%PDF-'.codeUnits);
    },
  );
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
