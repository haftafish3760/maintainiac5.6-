import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

void main() {
  test('PDF viewer preflight skips preview for proof-only files', () {
    const encrypted = ReceiptPdfInspection(
      path: '/tmp/encrypted.pdf',
      exists: true,
      byteSize: 4096,
      pageCount: 1,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
      riskFlags: [ReceiptPdfInspector.encryptionRiskFlag],
    );
    const invalid = ReceiptPdfInspection(
      path: '/tmp/invalid.pdf',
      exists: true,
      byteSize: 128,
      pageCount: null,
      hasPdfHeader: false,
      pageCountStatus: ReceiptPdfPageCountStatus.failed,
      validationStatus: ReceiptPdfValidationStatus.invalidHeader,
    );
    const ready = ReceiptPdfInspection(
      path: '/tmp/receipt.pdf',
      exists: true,
      byteSize: 4096,
      pageCount: 1,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
    );

    expect(
      receiptPdfPreviewStatusForInspection(encrypted),
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped,
    );
    expect(
      receiptPdfPreviewStatusForInspection(invalid),
      ReceiptPdfPreviewStatus.unreadable,
    );
    expect(
      receiptPdfPreviewStatusForInspection(ready),
      ReceiptPdfPreviewStatus.ready,
    );
  });

  test('PDF viewer summary makes proof-only and no-editing state obvious', () {
    const longProof = ReceiptPdfInspection(
      path: '/tmp/long.pdf',
      exists: true,
      byteSize: 4096,
      pageCount: 75,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
    );

    final summary = ReceiptPdfViewerSummary.fromInspection(longProof);

    expect(summary.detailLabels, contains('read-only proof'));
    expect(summary.detailLabels, contains('no PDF editing'));
    expect(
      summary.detailLabels,
      contains(
        'reads first ${ReceiptPdfInspector.localAssistedReadPageLimit} pages',
      ),
    );
    expect(summary.warning, isNotNull);
  });
}
