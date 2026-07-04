import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('ocr source handoff reports receipt section-order review', () async {
    final result = await const ReceiptOcrService().recognizeTextFromAttachments([
      ReceiptAttachmentRecord(
        id: 'section-order-review',
        path: '',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 4),
        importedText: 'STORE\nTOTAL 9.99',
        documentSignals: const [
          'receipt_ocr_source_photo',
          'receipt_handoff_needs_review_before_ocr',
          'receipt_section_order_retake_order_invalid',
          'receipt_section_order_action_review_retaken_section_order_before_ocr',
          'receipt_section_order_review_required',
        ],
        riskFlags: const [
          'ocr_source_section_order_review_required',
          'ocr_source_section_order_action_review_retaken_section_order_before_ocr',
        ],
      ),
    ]);

    final summary = result.sourceHandoffSummary;
    final diagnostics = result.diagnostics;
    final expectedCounts = {
      'receipt_section_order_retake_order_invalid': 1,
      'receipt_section_order_action_review_retaken_section_order_before_ocr': 1,
      'receipt_section_order_review_required': 1,
      'ocr_source_section_order_review_required': 1,
      'ocr_source_section_order_action_review_retaken_section_order_before_ocr':
          1,
    };

    expect(summary.status, 'needs_review_before_ocr');
    expect(summary.sectionOrderSignalCounts, expectedCounts);
    expect(diagnostics.ocrSourceSectionOrderSignalCounts, expectedCounts);
    expect(
      diagnostics.ocrSourceHandoffContract['sectionOrderSignalCounts'],
      expectedCounts,
    );
    expect(
      diagnostics.ocrSourceHandoffContract['sourceQualityReviewStatus'],
      'section_order_review_required',
    );
    expect(
      diagnostics.ocrSourceHandoffContract['sourceQualityReviewAction'],
      'review_receipt_section_order',
    );
    expect(diagnostics.ocrSourcePhotoQualityRiskCounts, isEmpty);
  });
}
