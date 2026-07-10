import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('removed section metadata records later section shifts', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        warning: 'Review remaining receipt sections after removal.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/bottom.jpg': {
          'receiptRemoveOriginalSectionNumber': 2,
          'receiptRemoveFinalSectionNumber': 2,
          'receiptRemoveFinalSectionCount': 2,
          'receiptRemoveRemainingSectionOriginalNumber': 3,
          'receiptRemoveSectionShifted': true,
          'receiptRemoveOrderPolicy':
              'remove_selected_section_preserve_remaining_order',
        },
      },
    );

    expect(result.receiptSectionOrderCounts['remove_original_section_2'], 1);
    expect(result.receiptSectionOrderCounts['remove_final_section_2'], 1);
    expect(result.receiptSectionOrderCounts['remove_final_section_count_2'], 1);
    expect(result.receiptSectionOrderCounts['remove_section_shifted'], 1);
    expect(
      result.receiptSectionOrderCounts['remove_remaining_original_section_3'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_remove_section_shifted'],
      1,
    );
    expect(result.receiptSectionOrderOutcome, 'remove_order_preserved');
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_removed_section_then_continue',
    );
  });

  test('malformed removal shift metadata requires review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/bottom-ocr.jpg'],
        warning: 'Review removed receipt section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/bottom.jpg': {
          'receiptRemoveOriginalSectionNumber': 2,
          'receiptRemoveFinalSectionNumber': 2,
          'receiptRemoveRemainingSectionOriginalNumber': 3,
          'receiptRemoveSectionShifted': false,
        },
      },
    );

    expect(
      result.receiptSectionOrderCounts['remove_invalid_shift_flag_mismatch'],
      1,
    );
    expect(result.receiptSectionOrderOutcome, 'remove_order_invalid');
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_removed_section_order_before_ocr',
    );
    expect(result.receiptSectionOrderNeedsReview, isTrue);
    expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
  });

  test('removal metadata with an impossible final section requires review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/bottom-ocr.jpg'],
        warning: 'Review removed receipt section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/bottom.jpg': {
          'receiptRemoveOriginalSectionNumber': 2,
          'receiptRemoveFinalSectionNumber': 3,
          'receiptRemoveFinalSectionCount': 2,
          'receiptRemoveRemainingSectionOriginalNumber': 3,
          'receiptRemoveSectionShifted': true,
        },
      },
    );

    expect(
      result
          .receiptSectionOrderCounts['remove_invalid_final_section_out_of_range'],
      1,
    );
    expect(result.receiptSectionOrderOutcome, 'remove_order_invalid');
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_removed_section_order_before_ocr',
    );
    expect(result.receiptSectionOrderNeedsReview, isTrue);
    expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
  });

  test('removal metadata with duplicate remaining sections requires review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/middle.jpg', '/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/middle-ocr.jpg', '/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/middle-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        warning: 'Review removed receipt section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle.jpg': {
          'receiptRemoveOriginalSectionNumber': 2,
          'receiptRemoveFinalSectionNumber': 1,
          'receiptRemoveFinalSectionCount': 2,
          'receiptRemoveRemainingSectionOriginalNumber': 1,
          'receiptRemoveSectionShifted': true,
        },
        '/tmp/bottom.jpg': {
          'receiptRemoveOriginalSectionNumber': 2,
          'receiptRemoveFinalSectionNumber': 2,
          'receiptRemoveFinalSectionCount': 3,
          'receiptRemoveRemainingSectionOriginalNumber': 1,
          'receiptRemoveSectionShifted': true,
        },
      },
    );

    expect(
      result
          .receiptSectionOrderCounts['remove_invalid_duplicate_remaining_original_section'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['remove_invalid_inconsistent_final_section_count'],
      1,
    );
    expect(result.receiptSectionOrderOutcome, 'remove_order_invalid');
    expect(result.receiptSectionOrderNeedsReview, isTrue);
  });
}
