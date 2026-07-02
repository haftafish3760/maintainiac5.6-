import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

void main() {
  test('PDF viewer preview is capped without changing saved proof', () {
    expect(receiptPdfPreviewPageLimit(null), 10);
    expect(receiptPdfPreviewPageLimit(1), 1);
    expect(receiptPdfPreviewPageLimit(10), 10);
    expect(receiptPdfPreviewPageLimit(11), 10);
    expect(
      receiptPdfPreviewPageLimit(
        ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 1,
      ),
      5,
    );
    expect(receiptPdfPreviewPageLimit(75), 5);
    expect(
      receiptPdfPreviewPageLimit(ReceiptPdfLimits.hardPdfPageLimit + 1),
      3,
    );
  });

  test('PDF viewer preview plan reduces work for long documents', () {
    final normal = receiptPdfPreviewPlanForPageCount(3);
    final long = receiptPdfPreviewPlanForPageCount(
      ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 1,
    );
    final huge = receiptPdfPreviewPlanForPageCount(
      ReceiptPdfLimits.hardPdfPageLimit + 1,
    );

    expect(normal.isReduced, isFalse);
    expect(normal.dpi, 150);
    expect(long.isReduced, isTrue);
    expect(long.pageLimit, 5);
    expect(long.dpi, 132);
    expect(huge.isReduced, isTrue);
    expect(huge.pageLimit, 3);
    expect(huge.dpi, 120);
  });

  test('PDF preview failure states explain saved proof clearly', () {
    expect(ReceiptPdfPreviewStatus.missing.message, contains('reattached'));
    expect(
      ReceiptPdfPreviewStatus.unreadable.message,
      contains('not editable'),
    );
    expect(
      ReceiptPdfPreviewStatus.renderFailed.message,
      contains('saved as read-only proof'),
    );
    expect(
      ReceiptPdfPreviewStatus.tooLargeForPreview.message,
      contains('too large to preview automatically'),
    );
    expect(
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped.message,
      contains('skipped automatic preview'),
    );
    expect(
      ReceiptPdfPreviewStatus.noPreviewPages.message,
      contains('saved as read-only proof'),
    );
  });

  test('PDF viewer summary keeps proof read-only and shows read limits', () {
    const inspection = ReceiptPdfInspection(
      path: '/tmp/long.pdf',
      exists: true,
      byteSize: 2048,
      pageCount: ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 4,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
    );

    final summary = ReceiptPdfViewerSummary.fromInspection(inspection);

    const pageCount = ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 4;
    const readLimit = ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater;
    expect(summary.detailLabels, contains('2.0 KB'));
    expect(summary.detailLabels, contains('$pageCount pages'));
    expect(summary.detailLabels, contains('read-only proof'));
    expect(summary.detailLabels, contains('no PDF editing'));
    expect(summary.detailLabels, contains('reads first $readLimit pages'));
    expect(summary.warning, contains('page count is estimated'));
    expect(summary.warning, contains('only read the first $readLimit pages'));
  });

  test('PDF viewer summary marks encrypted PDFs as proof only', () {
    const inspection = ReceiptPdfInspection(
      path: '/tmp/encrypted.pdf',
      exists: true,
      byteSize: 4096,
      pageCount: 1,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
      riskFlags: [ReceiptPdfInspector.encryptionRiskFlag],
    );

    final summary = ReceiptPdfViewerSummary.fromInspection(inspection);

    expect(summary.detailLabels, contains('Save as proof only'));
    expect(summary.detailLabels, contains('proof only'));
    expect(summary.detailLabels, contains('no PDF editing'));
    expect(summary.warning, contains('password security'));
  });
}
