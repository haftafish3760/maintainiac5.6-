import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('manual reorder metadata is summarized without leaking paths', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg', '/tmp/middle.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/bottom-ocr.jpg',
        '/tmp/middle-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/bottom-ocr.jpg',
          '/tmp/middle-ocr.jpg',
        ],
        warning: 'Review manual section order.',
        fallbackReasonCode: 'manual_order_review',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle.jpg': {
          'receiptManualReorderOriginalSectionNumber': 2,
          'receiptManualReorderFinalSectionNumber': 3,
          'receiptManualReorderDirection': 'later',
          'receiptManualReorderSectionCount': 3,
          'receiptManualReorderPreservedPhotoPath': true,
          'receiptManualReorderPolicy':
              'user_reordered_sections_preserve_paths',
          'receiptLineText': 'private reordered line should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'manual_reorder_preserved');
    expect(result.receiptSectionOrderNeedsReview, false);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_reordered_sections_then_continue',
    );
    expect(
      result.receiptSectionOrderCounts['manual_reorder_original_section_2'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['manual_reorder_final_section_3'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['manual_reorder_section_count_3'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['manual_reorder_direction_later'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['manual_reorder_policy_user_reordered_sections_preserve_paths'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['manual_reorder_preserved_photo_path'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_manual_reorder_preserved_photo_path'],
      1,
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=manual_reorder_preserved;'
      'multi_section_photos=0;ghost_unknown;manual_reorder_preserved',
    );
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Confirm the manual receipt section order before continuing.',
    );
    expect(
      result.acceptedPhotoHandoffUserAction,
      'confirm_reordered_section_order_then_continue',
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/')),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('private reordered line')),
    );
  });

  test('malformed manual reorder metadata is counted safely', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/middle.jpg', '/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/middle-ocr.jpg',
        '/tmp/bottom-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/middle-ocr.jpg',
          '/tmp/bottom-ocr.jpg',
        ],
        warning: 'Review malformed manual section order.',
        fallbackReasonCode: 'manual_order_review',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle.jpg': {
          'receiptManualReorderOriginalSectionNumber': 2,
          'receiptManualReorderFinalSectionNumber': 5,
          'receiptManualReorderDirection': 'later',
          'receiptManualReorderPreservedPhotoPath': true,
          'receiptManualReorderPolicy':
              'user_reordered_sections_preserve_paths',
          'receiptLineText': 'private malformed reorder should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'manual_reorder_invalid');
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_manual_section_order_before_ocr',
    );
    expect(
      result
          .receiptSectionOrderCounts['manual_reorder_invalid_non_adjacent_move'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_manual_reorder_invalid_non_adjacent_move'],
      1,
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=manual_reorder_invalid;'
      'multi_section_photos=0;ghost_unknown;manual_reorder_invalid',
    );
    final metadata = result.privacySafeReceiptReaderHandoffMetadata.toString();
    expect(metadata, contains('manual_reorder_invalid_non_adjacent_move'));
    expect(metadata, isNot(contains('/tmp/')));
    expect(metadata, isNot(contains('private malformed reorder')));
  });
}
