import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('duplicate section fallback stays in ordered review handoff lane', () {
    final duplicateFallback = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/dup-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/dup-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/dup-ocr.jpg'],
        warning: 'Duplicate receipt section detected.',
        fallbackReasonCode: 'duplicate_section_image',
        failedPairIndex: 0,
      ),
    );

    expect(
      duplicateFallback.receiptPhotoReviewHandoffPath,
      'accepted_stitch_ocr_source_review_required',
    );
    expect(duplicateFallback.nextReviewUsesOrderedSections, isTrue);
    expect(
      duplicateFallback.nextReviewMatchReadinessOutcome,
      'ocr_source_review_required_before_assist',
    );
    expect(
      duplicateFallback.stitchResult.ocrHandoffSafetyCode,
      'ordered_sections_after_duplicate_section_image_fallback',
    );
    expect(
      duplicateFallback.stitchResult.ocrSourceContractCode,
      'fallback_duplicate_section_image',
    );
    expect(
      duplicateFallback.receiptReaderHandoffCounts,
      containsPair(
        'stitch_ocr_source_contract_fallback_duplicate_section_image',
        1,
      ),
    );
    expect(
      duplicateFallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchOcrHandoffSafetyCode',
        'ordered_sections_after_duplicate_section_image_fallback',
      ),
    );
  });

  test(
    'duplicate later section fallback keeps the failed pair focused in handoff metadata',
    () {
      final duplicateLaterFallback = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/tmp/top-proof.jpg',
          '/tmp/middle-proof.jpg',
          '/tmp/dup-proof.jpg',
        ],
        ocrSourcePhotoPaths: const [
          '/tmp/top-ocr.jpg',
          '/tmp/middle-ocr.jpg',
          '/tmp/dup-ocr.jpg',
        ],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.fallback(
          inputPaths: ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg', '/tmp/dup-ocr.jpg'],
          warning: 'Duplicate receipt section detected.',
          fallbackReasonCode: 'duplicate_section_image',
          failedPairIndex: 1,
        ),
      );

      expect(duplicateLaterFallback.nextReviewUsesOrderedSections, isTrue);
      expect(
        duplicateLaterFallback.stitchResult.failedPairLabel,
        'Photo 2 to 3',
      );
      expect(
        duplicateLaterFallback.nextReviewMatchReadinessLabel,
        'Photo match needs review before app-assisted receipt filling, starting with Photo 2 to 3.',
      );
      expect(
        duplicateLaterFallback.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchFailedPairLabel', 'Photo 2 to 3'),
      );
      expect(
        duplicateLaterFallback.privacySafeReceiptReaderHandoffMetadata,
        containsPair('stitchOverlapCoverageCode', 'fallback_pair_2_to_3'),
      );
      expect(
        duplicateLaterFallback.receiptReaderHandoffCounts,
        containsPair(
          'stitch_ocr_source_contract_fallback_duplicate_section_image',
          1,
        ),
      );

      final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
        duplicateLaterFallback,
        ReceiptCaptureFlowModule.expenses,
      ).first;
      expect(
        attachment.documentSignals,
        contains('stitch_failed_pair_photo_2_to_3'),
      );
      expect(
        attachment.documentSignals,
        contains('stitch_review_focus_pair_photo_2_to_3'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_stitch_failed_pair_photo_2_to_3'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_stitch_review_focus_pair_photo_2_to_3'),
      );
    },
  );

  test('low-confidence stitched preview cannot auto-clear assisted receipt read', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/stitched-low-confidence.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        ocrSourcePaths: ['/tmp/stitched-low-confidence.jpg'],
        stitchedPath: '/tmp/stitched-low-confidence.jpg',
        confidence: .55,
        overlapPixels: [187],
        pairs: [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 187,
            confidence: .55,
          ),
        ],
      ),
    );

    expect(result.stitchResult.didStitch, isTrue);
    expect(result.stitchResult.hasValidOcrSourceContract, isTrue);
    expect(result.stitchResult.hasLowConfidenceAutomaticOverlap, isTrue);
    expect(
      result.stitchResult.requiresOcrSourceReviewBeforeAssistedRead,
      isTrue,
    );
    expect(
      result.stitchResult.assistedReadinessCode,
      'stitched_overlap_review_required',
    );
    expect(
      result.nextReviewMatchReadinessOutcome,
      'ocr_source_review_required_before_assist',
    );
    expect(result.stitchResult.reviewFocusPairLabel, 'Photo 1 to 2');
    expect(
      result.nextReviewMatchReadinessLabel,
      'Photo match needs review before app-assisted receipt filling, starting with Photo 1 to 2.',
    );
    expect(
      result.nextReviewHandoffLabel,
      'Receipt details open from one combined receipt image. Photo 1 to 2 still needs review. OCR will read one stitched image, but overlap evidence still needs review.',
    );
    expect(
      result
          .receiptReaderHandoffCounts['stitch_requires_ocr_source_review_before_assist'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['match_readiness_ocr_source_review_required_before_assist'],
      1,
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchReviewFocusPairLabel', 'Photo 1 to 2'),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchHasLowConfidenceAutomaticOverlap', true),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nextReviewMatchReadinessLabel',
        'Photo match needs review before app-assisted receipt filling, starting with Photo 1 to 2.',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nextReviewRequiresOcrSourceReviewBeforeAssist', true),
    );

    final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    ).single;
    expect(
      attachment.documentSignals,
      contains('stitch_review_focus_pair_photo_1_to_2'),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_stitch_review_focus_pair_photo_1_to_2'),
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
      stitchResult: ReceiptStitchResult.fallback(
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

  test('photo review result summarizes scanner prep concerns', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      preparationDiagnosticsByOcrPath: const {
        '/tmp/ocr.jpg': {
          'scannerDecisionCodes': [
            'crop_skipped_bounds_off_center_x',
            'perspective_skipped_bounds_off_center_x',
            'cleanup_skipped_quality_guard',
            'ocr_source_full_quality_selected_quality_guard',
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
    expect(result.scannerKeptTemporaryFullQualitySourceForQuality, isTrue);
    expect(result.scannerUsedEnhancedOcrSource, isFalse);
    expect(result.scannerNeedsOperatorReview, isTrue);
    expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
    expect(
      result.receiptPhotoReviewHandoffPath,
      'accepted_scanner_preparation_review_required',
    );
    expect(
      result.receiptPhotoReviewHandoffPathLabel,
      'Accepted photo review, but OCR source preparation needs review.',
    );
    expect(
      result.acceptedPhotoHandoffRoute,
      'photo_review_ocr_source_review_required',
    );
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
    expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
    expect(
      result.receiptProofStoragePolicyOutcome,
      'temporary_full_quality_source_guard_review',
    );
    expect(
      result.receiptReaderHandoffCounts['scanner_operator_review_needed'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['scanner_temporary_full_quality_source_guarded'],
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
      contains('ocr_source_ocr_source_full_quality_selected_quality_guard'),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_temporary_full_quality_guard_review'),
    );
    expect(
      result.receiptProofStoragePolicyCounts.keys.join('|'),
      isNot(contains('original_temporarily_kept_for_ocr_quality_guard')),
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('scanner=temporary_full_quality_source_guard'),
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      isNot(contains('scanner=original_quality_guard')),
    );
  });
}
