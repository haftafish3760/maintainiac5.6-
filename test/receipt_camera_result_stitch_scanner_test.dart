import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('section order helper lists are frozen before handoff', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_review_result_section_order_helpers.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('return codes;')));
    expect(source, contains('return List.unmodifiable(codes);'));
  });

  test('receipt reader handoff diagnostics are frozen before flow handoff', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
    ).readAsStringSync();

    expect(source, contains('return Map<String, Object?>.unmodifiable({'));
    expect(
      source,
      isNot(contains("return {\n    'receiptReaderHandoffIntegrity'")),
    );
  });

  test('photo review result explains stitched and fallback handoffs', () {
    final stitched = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/stitched.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult(
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
      stitchResult: ReceiptStitchResult.fallback(
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
    final duplicateFallback = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/top-proof-copy.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/top-ocr-copy.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: const ['/tmp/top-ocr.jpg', '/tmp/top-ocr-copy.jpg'],
        warning:
            'Two receipt photos appear to show the same section. Receipt details will use the photos separately.',
        fallbackReasonCode: 'duplicate_section_image',
        failedPairIndex: 0,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 0,
            confidence: 1,
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
      'Accepted long receipt as one combined image.',
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
    expect(stitched.ocrSourceCountLabel, '1 clear combined receipt image');
    expect(
      stitched.nextReviewHandoffLabel,
      'Receipt details open from one combined receipt image. Automatic match accepted.',
    );
    expect(
      stitched.nextReviewDiagnosticLabel,
      'stitched:stitched:coverage_ok:1:details_ready',
    );
    expect(
      stitched.stitchResult.ocrHandoffSafetyCode,
      {'stitched_overlap_verified'}.single,
    );
    expect(
      stitched.stitchResult.privacySafeOcrHandoffSafety,
      containsPair('stitchOcrHandoffUsesCombinedImage', true),
    );

    expect(fallback.nextReviewUsesCombinedReceiptImage, isFalse);
    expect(
      fallback.receiptPhotoReviewHandoffPath,
      'accepted_ordered_sections_fallback',
    );
    expect(
      fallback.receiptPhotoReviewHandoffPathLabel,
      'Accepted long receipt as ordered sections after the combined-image fallback.',
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['ocr_source_ordered_sections_stitch_fallback'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['ocr_source_review_risk_ocr_source_ready'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['ocr_source_review_requirement_standard_user_confirmation_required'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['stitch_ocr_source_contract_fallback_ordered_sources_ready'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['stitch_assisted_readiness_ordered_sections_ready'],
      1,
    );
    expect(
      fallback
          .receiptReaderHandoffCounts['stitch_ready_for_assisted_read_without_extra_review'],
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
      'Photo match fallback: ordered receipt sections will be read top to bottom, and Photo 1 to 2 needs review.',
    );
    expect(fallback.nextReviewSourceLabel, '2 ordered receipt sections');
    expect(fallback.ocrSourceCountLabel, '2 clear ordered receipt sections');
    expect(
      fallback.nextReviewHandoffLabel,
      'Receipt details open from 2 ordered receipt sections in top-to-bottom order. Photo 1 to 2 needs adjustment. Stitch not trusted.',
    );
    expect(
      fallback.nextReviewDiagnosticLabel,
      'fallback:overlap_confidence_low:coverage_ok:2:details_ready',
    );
    expect(
      fallback.stitchResult.ocrHandoffSafetyCode,
      'ordered_sections_after_overlap_confidence_low_fallback',
    );
    expect(
      fallback.stitchResult.requiresOcrSourceReviewBeforeAssistedRead,
      isFalse,
    );
    expect(
      fallback.stitchResult.assistedReadinessCode,
      'ordered_sections_ready',
    );
    expect(fallback.stitchResult.hasValidOcrSourceContract, isTrue);
    expect(
      fallback.stitchResult.ocrSourceContractCode,
      'fallback_ordered_sources_ready',
    );
    expect(
      fallback.ocrSourceReviewRiskCode,
      'ocr_source_ready',
    );
    expect(
      fallback.ocrSourceReviewRequirement,
      'standard_user_confirmation_required',
    );
    expect(
      fallback.stitchResult.ocrHandoffSafetyLabel,
      'OCR will read ordered sections because stitching was not trusted.',
    );
    expect(duplicateFallback.nextReviewUsesOrderedSections, isTrue);
    expect(
      duplicateFallback
          .receiptReaderHandoffCounts['stitch_ocr_source_contract_fallback_duplicate_section_image'],
      1,
    );
    expect(
      duplicateFallback
          .stitchPairDiagnosticCounts['overlap_fallback_pair_1_to_2'],
      1,
    );
    expect(
      duplicateFallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchOcrHandoffSafetyCode',
        'ordered_sections_after_duplicate_section_image_fallback',
      ),
    );
    expect(
      duplicateFallback.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/top-ocr')),
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
        'Photo match fallback: ordered receipt sections will be read top to bottom, and Photo 1 to 2 needs review.',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nextReviewRequiresOcrSourceReviewBeforeAssist', false),
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
      stitched.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchInputSourceCount', 2),
    );
    expect(
      stitched.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchOcrSourceCount', 1),
    );
    expect(
      stitched.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchOverlapPixelTotal', 240),
    );
    expect(
      stitched.privacySafeReceiptReaderHandoffMetadata.toString(),
      isNot(contains('/tmp/stitched.jpg')),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchOverlapCoverageCode', 'fallback_pair_1_to_2'),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchMissingPairCount', 1),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchOcrHandoffSafetyCode',
        'ordered_sections_after_overlap_confidence_low_fallback',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'ocrSourceReviewRiskCode',
        'ocr_source_ready',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'ocrSourceReviewRequirement',
        'standard_user_confirmation_required',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchOcrHandoffUsesOrderedSections', true),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'stitchAssistedReadinessCode',
        'ordered_sections_ready',
      ),
    );
    expect(
      fallback.privacySafeReceiptReaderHandoffMetadata,
      containsPair('stitchRequiresOcrSourceReviewBeforeAssistedRead', false),
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
}
