import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('photo review result explains stitched and fallback handoffs', () {
    final stitched = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/stitched.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        ocrSourcePaths: ['/tmp/stitched.jpg'],
        stitchedPath: '/tmp/stitched.jpg',
        confidence: .92,
        overlapPixels: [240],
        pairs: [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 240,
            confidence: .92,
          ),
        ],
      ),
    );
    final fallback = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        warning:
            'Receipt photos did not match clearly enough to stitch safely.',
        fallbackReasonCode: 'overlap_confidence_low',
        confidence: .34,
        failedPairIndex: 0,
        pairs: [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 0,
            confidence: .34,
          ),
        ],
      ),
    );

    expect(stitched.nextReviewUsesCombinedReceiptImage, isTrue);
    expect(
      stitched.receiptPhotoReviewHandoffPath,
      'accepted_stitched_combined_image',
    );
    expect(
      stitched.receiptPhotoReviewHandoffPathLabel,
      'Accepted long receipt as one stitched OCR image.',
    );
    expect(
      stitched.receiptReaderHandoffCounts['ocr_source_combined_stitch'],
      1,
    );
    expect(
      stitched
          .receiptReaderHandoffCounts['match_readiness_combined_receipt_image_ready'],
      1,
    );
    expect(
      stitched
          .stitchPairDiagnosticCounts['overlap_all_pairs_have_overlap_evidence'],
      1,
    );
    expect(
      stitched
          .stitchPairDiagnosticCounts['source_original_sections_preserved_derived_stitched_ocr_artifact'],
      1,
    );
    expect(stitched.nextReviewUsesOrderedSections, isFalse);
    expect(
      stitched.nextReviewMatchReadinessOutcome,
      'combined_receipt_image_ready',
    );
    expect(
      stitched.nextReviewMatchReadinessLabel,
      'Photo match ready: one combined receipt image will be read.',
    );
    expect(stitched.nextReviewSourceLabel, 'one combined receipt image');
    expect(
      stitched.nextReviewHandoffLabel,
      'Next reviews one combined receipt image. Automatic match accepted.',
    );
    expect(
      stitched.nextReviewDiagnosticLabel,
      'stitched:stitched:coverage_ok:1:details_ready',
    );

    expect(fallback.nextReviewUsesCombinedReceiptImage, isFalse);
    expect(
      fallback.receiptPhotoReviewHandoffPath,
      'accepted_ordered_sections_fallback',
    );
    expect(
      fallback.receiptPhotoReviewHandoffPathLabel,
      'Accepted long receipt as ordered OCR sections after stitch fallback.',
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['ocr_source_ordered_sections_stitch_fallback'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['match_readiness_ordered_sections_fallback_ready'],
      1,
    );
    expect(
      fallback.stitchPairDiagnosticCounts['overlap_fallback_pair_1_to_2'],
      1,
    );
    expect(
      fallback
          .stitchPairDiagnosticCounts['source_original_sections_preserved_ordered_ocr_sources'],
      1,
    );
    expect(fallback.nextReviewUsesOrderedSections, isTrue);
    expect(
      fallback.nextReviewMatchReadinessOutcome,
      'ordered_sections_fallback_ready',
    );
    expect(
      fallback.nextReviewMatchReadinessLabel,
      'Photo match fallback: ordered receipt sections will be read top to bottom.',
    );
    expect(fallback.nextReviewSourceLabel, '2 ordered receipt sections');
    expect(
      fallback.nextReviewHandoffLabel,
      'Next reviews 2 ordered receipt sections from top to bottom. Stitch not trusted.',
    );
    expect(
      fallback.nextReviewDiagnosticLabel,
      'fallback:overlap_confidence_low:coverage_ok:2:details_ready',
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nextReviewMatchReadinessOutcome',
        'ordered_sections_fallback_ready',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nextReviewMatchReadinessLabel',
        'Photo match fallback: ordered receipt sections will be read top to bottom.',
      ),
    );
    expect(
      stitched.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchOverlapCoverageCode',
        'all_pairs_have_overlap_evidence',
      ),
    );
    expect(
      stitched.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchSourcePreservationCode',
        'original_sections_preserved_derived_stitched_ocr_artifact',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchOverlapCoverageCode', 'fallback_pair_1_to_2'),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchMissingPairCount', 1),
    );

    final stitchedAttachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      stitched,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      stitchedAttachments.single.documentSignals,
      contains('stitch_overlap_all_pairs_have_overlap_evidence'),
    );
    expect(
      stitchedAttachments.single.documentSignals,
      contains(
        'stitch_source_original_sections_preserved_derived_stitched_ocr_artifact',
      ),
    );
    final fallbackAttachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      fallback,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      fallbackAttachments.first.documentSignals,
      contains('stitch_overlap_fallback_pair_1_to_2'),
    );
    expect(
      fallbackAttachments.first.documentSignals,
      contains('stitch_source_original_sections_preserved_ordered_ocr_sources'),
    );
  });

  test('native section order metadata preserves ghost guide handoff', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/section-1-proof.jpg',
        '/tmp/section-2-proof.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/section-1-ocr.jpg',
        '/tmp/section-2-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/section-1-ocr.jpg', '/tmp/section-2-ocr.jpg'],
        warning: 'Overlap confidence low.',
        fallbackReasonCode: 'overlap_confidence_low',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/section-2-proof.jpg': {
          'receiptSectionCount': 2,
          'nextReceiptSectionNumber': 3,
          'receiptSectionOrderPolicy': 'top_to_bottom_numbered_sections',
          'previousSectionGhostGuidePolicy':
              'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'previousSectionGhostGuideVisible': true,
          'merchantName': 'Lowe private fixture should not leak',
          'receiptLineText': '2.99 private line should not leak',
        },
      },
    );

    expect(
      result.receiptSectionOrderOutcome,
      'numbered_sections_with_ghost_guide',
    );
    expect(result.receiptSectionOrderCounts['multi_section_2_sections'], 1);
    expect(result.receiptSectionOrderCounts['next_section_3'], 1);
    expect(
      result
          .receiptSectionOrderCounts['policy_top_to_bottom_numbered_sections'],
      1,
    );
    expect(
      result
          .receiptSectionOrderCounts['ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines'],
      1,
    );
    expect(result.receiptSectionOrderCounts['ghost_guide_visible'], 1);
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_policy_top_to_bottom_numbered_sections'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['receipt_section_order_ghost_guide_visible'],
      1,
    );

    final metadata = result.privacySafeReceiptReaderHandoffMetadata;
    expect(
      metadata,
      containsPair(
        'receiptSectionOrderOutcome',
        'numbered_sections_with_ghost_guide',
      ),
    );
    expect(
      metadata,
      containsPair(
        'receiptSectionOrderEvidenceLabel',
        'section_order=numbered_sections_with_ghost_guide;'
            'multi_section_photos=1;ghost_visible',
      ),
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('sections=numbered_sections_with_ghost_guide'),
    );
    expect(metadata.toString(), isNot(contains('Lowe private fixture')));
    expect(metadata.toString(), isNot(contains('2.99 private line')));
  });

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
          'receiptRetakeOrderPolicy':
              'preserve_original_slot_insert_extra_sections_after_target',
          'receiptLineText': 'private line should not leak',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'retake_order_preserved');
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
      result
          .receiptReaderHandoffCounts['receipt_section_order_retake_preserved_original_slot'],
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

  test('photo review result summarizes scanner prep concerns', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      preparationDiagnosticsByOcrPath: const {
        '/tmp/ocr.jpg': {
          'scannerDecisionCodes': [
            'crop_skipped_bounds_off_center_x',
            'perspective_skipped_bounds_off_center_x',
            'cleanup_skipped_quality_guard',
            'ocr_source_original_selected_quality_guard',
          ],
        },
      },
    );

    expect(result.scannerDecisionCounts['crop_skipped_bounds_off_center_x'], 1);
    expect(
      result.scannerDecisionCounts['perspective_skipped_bounds_off_center_x'],
      1,
    );
    expect(result.scannerDecisionCounts['cleanup_skipped_quality_guard'], 1);
    expect(result.scannerKeptOriginalForQuality, isTrue);
    expect(result.scannerUsedEnhancedOcrSource, isFalse);
    expect(result.scannerNeedsOperatorReview, isTrue);
    expect(
      result.receiptReaderHandoffCounts['scanner_operator_review_needed'],
      1,
    );
    expect(
      result.receiptReaderHandoffCounts['scanner_original_kept_for_quality'],
      1,
    );
    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(attachments, hasLength(1));
    expect(
      attachments.single.documentSignals,
      contains('scanner_decision_cleanup_skipped_quality_guard'),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_cleanup_skipped_quality_guard'),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_ocr_source_original_selected_quality_guard'),
    );
  });
}
