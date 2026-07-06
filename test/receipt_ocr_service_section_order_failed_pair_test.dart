import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('source handoff preserves failed section-order stitch pair tokens', () async {
    final result = await const ReceiptOcrService().recognizeTextFromAttachments([
      ReceiptAttachmentRecord(
        id: 'section-order-failed-pair',
        path: '',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 6),
        importedText: 'TOTAL 8.40',
        documentSignals: const [
          'receipt_ocr_source_photo',
          'receipt_handoff_needs_review_before_ocr',
          'receipt_section_order_retake_order_invalid',
          'receipt_section_order_action_review_retaken_section_order_before_ocr',
          'receipt_section_order_review_required',
          'receipt_section_order_failed_pair_photo_2_to_3',
        ],
        riskFlags: const [
          'ocr_source_section_order_review_required',
          'ocr_source_section_order_action_review_retaken_section_order_before_ocr',
          'ocr_source_section_order_failed_pair_photo_2_to_3',
        ],
      ),
    ]);

    final summary = result.sourceHandoffSummary;

    expect(
      summary.sectionOrderSignalCounts,
      containsPair('receipt_section_order_failed_pair_photo_2_to_3', 1),
    );
    expect(
      summary.sectionOrderReviewStatus,
      'receipt_section_order_action_review_retaken_section_order_before_ocr',
    );
    expect(
      summary.sectionOrderFailedPairStatus,
      'ocr_source_section_order_failed_pair_photo_2_to_3',
    );
    expect(
      summary.riskFlagCounts,
      containsPair('ocr_source_section_order_failed_pair_photo_2_to_3', 1),
    );
    expect(
      summary.privacySafeContract['sectionOrderReviewStatus'],
      'receipt_section_order_action_review_retaken_section_order_before_ocr',
    );
    expect(
      summary.privacySafeContract['sectionOrderFailedPairStatus'],
      'ocr_source_section_order_failed_pair_photo_2_to_3',
    );
  });
}
