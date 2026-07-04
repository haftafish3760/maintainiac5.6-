import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('retake section metadata preserves order without leaking paths', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/middle-new.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
        warning: 'Review retaken section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-new.jpg': {
          'receiptRetakePreservedOriginalSlot': true,
          'receiptRetakeOriginalSectionNumber': 2,
          'receiptRetakeReplacementOffset': 0,
          'receiptRetakeFinalSectionNumber': 2,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeHasPreviousAlignmentContext': true,
          'receiptRetakeHasNextAlignmentContext': true,
          'receiptRetakeHasTwoSidedAlignmentContext': true,
          'receiptRetakePreviousContextSectionNumber': 1,
          'receiptRetakeNextContextSectionNumber': 3,
          'receiptRetakeOrderPolicy':
              'preserve_original_slot_insert_extra_sections_after_target',
          'receiptLineText': 'private line should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'retake_order_preserved');
    expect(result.receiptSectionOrderNeedsReview, false);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_retaken_section_then_continue',
    );
    expect(result.receiptSectionOrderCounts['retake_original_section_2'], 1);
    expect(result.receiptSectionOrderCounts['retake_final_section_2'], 1);
    expect(
      result
          .receiptSectionOrderCounts['retake_guidance_retake_middle_with_previous_next_context'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['retake_policy_preserve_original_slot_insert_extra_sections_after_target'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_two_sided_alignment_context'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_previous_context_section_1'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_next_context_section_3'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_preserved_original_slot'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_previous_context_section_1'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_next_context_section_3'],
      1,
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=retake_order_preserved;'
      'multi_section_photos=0;ghost_unknown;retake_preserved',
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/')),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('private line')),
    );
  });

  test('insert-after section metadata preserves order without leaking paths', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/top.jpg',
        '/tmp/middle.jpg',
        '/tmp/middle-extra.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/middle-ocr.jpg',
        '/tmp/middle-extra-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/middle-ocr.jpg',
          '/tmp/middle-extra-ocr.jpg',
        ],
        warning: 'Review inserted section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-extra.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 2,
          'receiptInsertAfterOffset': 0,
          'receiptInsertFinalSectionNumber': 3,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
          'receiptLineText': 'private inserted line should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_preserved');
    expect(result.receiptSectionOrderNeedsReview, false);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_inserted_section_then_continue',
    );
    expect(result.receiptSectionOrderCounts['insert_anchor_section_2'], 1);
    expect(result.receiptSectionOrderCounts['insert_final_section_3'], 1);
    expect(result.receiptSectionOrderCounts['insert_offset_0'], 1);
    expect(
      result
          .receiptSectionOrderCounts['insert_policy_insert_new_sections_after_selected_anchor'],
      1,
    );
    expect(result.receiptSectionOrderCounts['insert_preserved_anchor_slot'], 1);
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_insert_preserved_anchor_slot'],
      1,
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=insert_order_preserved;'
      'multi_section_photos=0;ghost_unknown;insert_preserved',
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/')),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('private inserted line')),
    );
  });

  test('malformed retake section metadata is counted without leaking paths', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/middle-new.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
        warning: 'Review retaken section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-new.jpg': {
          'receiptRetakePreservedOriginalSlot': true,
          'receiptRetakeOriginalSectionNumber': 3,
          'receiptRetakeFinalSectionNumber': 2,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeOrderPolicy':
              'preserve_original_slot_insert_extra_sections_after_target',
          'receiptLineText': 'private malformed line should not leak',
          'sourcePath': '/tmp/private-original.jpg',
        },
      },
    );

    expect(
      result.receiptSectionOrderCounts['retake_invalid_final_before_original'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['retake_invalid_preserved_slot_moved'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_invalid_final_before_original'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_invalid_preserved_slot_moved'],
      1,
    );
    expect(result.receiptSectionOrderOutcome, 'retake_order_invalid');
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_retaken_section_order_before_ocr',
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=retake_order_invalid;'
      'multi_section_photos=0;ghost_unknown;retake_invalid',
    );
    final metadata = result.privacySafeReceiptReaderHandoffMetadata.toString();
    expect(metadata, contains('retake_invalid_final_before_original'));
    expect(metadata, contains('review_retaken_section_order_before_ocr'));
    expect(metadata, isNot(contains('/tmp/')));
    expect(metadata, isNot(contains('private malformed line')));
  });

  test('malformed insert-after section metadata is counted safely', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/middle-extra.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
        warning: 'Review inserted section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-extra.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 3,
          'receiptInsertFinalSectionNumber': 2,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_invalid');
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.receiptSectionOrderReviewActionCode,
      'review_inserted_section_order_before_ocr',
    );
    expect(
      result.receiptSectionOrderCounts['insert_invalid_final_not_after_anchor'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['insert_invalid_preserved_anchor_overlap'],
      1,
    );
    expect(
      result.receiptSectionOrderEvidenceLabel,
      'section_order=insert_order_invalid;'
      'multi_section_photos=0;ghost_unknown;insert_invalid',
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_insert_invalid_final_not_after_anchor'],
      1,
    );
  });

  test('manual reorder metadata is summarized without leaking paths', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg', '/tmp/middle.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/bottom-ocr.jpg',
        '/tmp/middle-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
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
      stitchResult: const ReceiptStitchResult.fallback(
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
