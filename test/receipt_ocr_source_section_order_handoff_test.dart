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

  test(
    'ocr source handoff reports multi-section fallback review action',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'multi-section-fallback-review',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 7, 8),
              importedText: 'STORE\nTOTAL 9.99',
              documentSignals: const [
                'receipt_ocr_source_photo',
                'receipt_section_order_multi_section_order_tracked',
                'receipt_section_order_action_review_multi_section_order',
                'multiple_ocr_sources_fallback',
                'stitch_ocr_source_contract_review_required',
              ],
              riskFlags: const [
                'ocr_stitch_fallback_multiple_sources',
                'ocr_source_stitch_contract_fallback_overlap_untrusted_sources',
              ],
            ),
          ]);

      final summary = result.sourceHandoffSummary;
      final diagnostics = result.diagnostics;

      expect(
        summary.sectionOrderReviewStatus,
        'receipt_section_order_action_review_multi_section_order',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sectionOrderReviewStatus'],
        'receipt_section_order_action_review_multi_section_order',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sourceQualityReviewStatus'],
        'stitch_contract_review_required',
      );
      expect(
        diagnostics.ocrSourceHandoffContract['sourceQualityReviewAction'],
        'review_receipt_stitch_sources',
      );
      expect(
        diagnostics.ocrSourcePhotoQualityRiskCounts,
        isNot(
          contains(
            'ocr_source_section_order_action_review_multi_section_order',
          ),
        ),
      );
    },
  );

  test(
    'ocr source handoff treats action-only section order as review risk',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'action-only-section-order',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 7, 8),
              importedText: 'STORE\nTOTAL 9.99',
              documentSignals: const [
                'receipt_ocr_source_photo',
                'receipt_section_order_action_review_multi_section_order',
              ],
            ),
          ]);

      final diagnostics = result.diagnostics;

      expect(
        diagnostics.ocrSourceHandoffContract['sectionOrderReviewStatus'],
        'receipt_section_order_action_review_multi_section_order',
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
    },
  );
}
