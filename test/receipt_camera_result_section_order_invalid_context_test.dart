import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('retake context flag mismatches require order review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/middle-new.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/middle-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/middle-ocr.jpg'],
        warning: 'Review retaken section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-new.jpg': {
          'receiptRetakePreservedOriginalSlot': true,
          'receiptRetakeOriginalSectionNumber': 2,
          'receiptRetakeFinalSectionNumber': 2,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeHasTwoSidedAlignmentContext': true,
          'receiptRetakePreviousContextSectionNumber': 2,
          'receiptRetakeNextContextSectionNumber': 4,
          'receiptLineText': 'private context line should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'retake_order_invalid');
    expect(
      result.receiptSectionOrderCounts['retake_invalid_two_sided_flags'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_invalid_previous_context_order'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_invalid_next_context_gap'],
      1,
    );
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Review the retaken receipt section order before OCR reads the receipt.',
    );
    final metadata = result.privacySafeReceiptReaderHandoffMetadata.toString();
    expect(metadata, contains('review_retaken_section_order_before_ocr'));
    expect(metadata, isNot(contains('/tmp/')));
    expect(metadata, isNot(contains('private context line')));
  });

  test('top retake with previous-section ghost metadata is invalid', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-new.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg'],
        warning: 'Review retaken top section.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/top-new.jpg': {
          'receiptRetakeOriginalSectionNumber': 1,
          'receiptRetakeFinalSectionNumber': 1,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeHasPreviousAlignmentContext': true,
          'receiptRetakePreviousContextSectionNumber': 1,
          'previousSectionGhostGuideVisible': true,
          'previousSectionReasonCode': 'retake_previous_context',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'retake_order_invalid');
    expect(
      result
          .receiptSectionOrderCounts['retake_invalid_ghost_previous_after_target'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['retake_invalid_guidance_for_top_section'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['retake_invalid_previous_guide_for_top_section'],
      1,
    );
    expect(result.receiptSectionOrderNeedsReview, true);
  });

  test('normal long receipt ghost guide is not treated as retake metadata', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        warning: 'Review ordered sections.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/bottom.jpg': {
          'receiptSectionCount': 2,
          'nextReceiptSectionNumber': 2,
          'receiptSectionOrderPolicy': 'top_to_bottom_numbered_sections',
          'previousSectionGhostGuideVisible': true,
          'previousSectionGhostGuidePolicy':
              'show_previous_bottom_slice_at_top',
        },
      },
    );

    expect(
      result.receiptSectionOrderOutcome,
      'numbered_sections_with_ghost_guide',
    );
    expect(result.receiptSectionOrderNeedsReview, false);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_long_receipt_order_with_ghost_guide',
    );
  });

  test('retake extra-section offset mismatches require order review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/middle-extra.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/middle-extra-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/middle-extra-ocr.jpg'],
        warning: 'Review retaken section insertion.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-extra.jpg': {
          'receiptRetakeOriginalSectionNumber': 2,
          'receiptRetakeFinalSectionNumber': 3,
          'receiptRetakeInsertedExtraSection': true,
          'receiptRetakeReplacementOffset': 3,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeHasPreviousAlignmentContext': true,
          'receiptRetakeHasNextAlignmentContext': true,
          'receiptRetakeHasTwoSidedAlignmentContext': true,
          'receiptRetakePreviousContextSectionNumber': 1,
          'receiptRetakeNextContextSectionNumber': 3,
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'retake_order_invalid');
    expect(
      result.receiptSectionOrderCounts['retake_invalid_offset_final_mismatch'],
      1,
    );
    expect(result.receiptSectionOrderNeedsReview, true);
  });

  test('insert-after offset mismatches require order review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/extra.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/extra-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/extra-ocr.jpg'],
        warning: 'Review inserted section.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/extra.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 2,
          'receiptInsertAfterOffset': 2,
          'receiptInsertFinalSectionNumber': 3,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_invalid');
    expect(
      result.receiptSectionOrderCounts['insert_invalid_offset_final_mismatch'],
      1,
    );
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Review the inserted receipt section order before OCR reads the receipt.',
    );
  });
}
