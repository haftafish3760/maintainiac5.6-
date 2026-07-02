import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('ocr diagnostics combines missing totals with bottom coverage risk', () {
    final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'ocr-source-1',
        path: '/tmp/receipt-top.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 30),
        documentSignals: const [
          'receipt_coverage_bottom_edge_and_totals_missing_together',
          'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
          'receipt_coverage_rationale_edge_missing_and_totals_text_missing',
          'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap',
          'receipt_continuation_missing_bottom_edge_and_totals',
          'receipt_continuation_ocr_missing_bottom_totals',
          'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'receipt_continuation_handoff_ghost_repeat_target_repeat_3_to_5_readable_lines',
          'receipt_continuation_handoff_ghost_placement_top_ghost_slice',
          'receipt_continuation_handoff_ghost_match_target_subtotal_total_and_final_lines',
        ],
        riskFlags: const [
          'ocr_source_continuation_missing_bottom_totals_review',
          'ocr_source_continuation_bottom_overlap_ghost_policy',
        ],
      ),
    ]);
    final result = ReceiptOcrResult(
      rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
''',
      parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
''',
      textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      sourceHandoffSummary: sourceHandoff,
    );

    final diagnostics = result.diagnostics;
    final coverageEvidence =
        diagnostics.receiptTotalsCoverageEvidenceDiagnostics;

    expect(sourceHandoff.hasMissingBottomEdgeAndTotalsEvidence, isTrue);
    expect(
      sourceHandoff
          .continuationSignalCounts['receipt_continuation_missing_bottom_edge_and_totals'],
      1,
    );
    expect(
      sourceHandoff
          .continuationSignalCounts['receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines'],
      1,
    );
    expect(sourceHandoff.coverageSignalCounts, {
      'receipt_coverage_bottom_edge_and_totals_missing_together': 1,
      'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing':
          1,
      'receipt_coverage_rationale_edge_missing_and_totals_text_missing': 1,
      'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap':
          1,
    });
    expect(diagnostics.ocrSourceCoverageSignalCounts, {
      'receipt_coverage_bottom_edge_and_totals_missing_together': 1,
      'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing':
          1,
      'receipt_coverage_rationale_edge_missing_and_totals_text_missing': 1,
      'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap':
          1,
    });
    expect(diagnostics.receiptTotalsTextEvidenceStatus, 'missing');
    expect(diagnostics.receiptMayNeedBottomSection, isTrue);
    expect(diagnostics.ocrSourceBottomCoverageRiskDetected, isTrue);
    expect(diagnostics.receiptMissingBottomEdgeAndTotals, isTrue);
    expect(
      diagnostics.receiptBottomTotalsEvidenceLabel,
      'bottom_edge_and_totals_missing',
    );
    expect(
      diagnostics.parserTaskCounts['receipt_totals_text_missing_review'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_possible_lower_section_missing'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_missing_bottom_edge_and_totals'],
      1,
    );
    expect(
      diagnostics
          .parserTaskCounts['receipt_bottom_section_continuation_needed'],
      1,
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('bottom section continuation needed'),
    );
    expect(
      diagnostics.parserTaskCounts.containsKey(
        'receipt_missing_totals_manual_review',
      ),
      isFalse,
    );
    expect(
      diagnostics.receiptCompletionReviewReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(
      diagnostics.receiptCompletionReviewActionLabel,
      'Add the bottom receipt section with the top ghost-slice guide',
    );
    expect(
      diagnostics.receiptPostCaptureRouteStatus,
      'add_next_receipt_section',
    );
    expect(
      diagnostics.receiptPostCaptureRouteLabel,
      'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice.',
    );
    expect(diagnostics.ocrSourceContinuationSignalCounts, {
      'receipt_continuation_missing_bottom_edge_and_totals': 1,
      'receipt_continuation_ocr_missing_bottom_totals': 1,
      'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines':
          1,
      'receipt_continuation_handoff_ghost_repeat_target_repeat_3_to_5_readable_lines':
          1,
      'receipt_continuation_handoff_ghost_placement_top_ghost_slice': 1,
      'receipt_continuation_handoff_ghost_match_target_subtotal_total_and_final_lines':
          1,
      'ocr_source_continuation_missing_bottom_totals_review': 1,
      'ocr_source_continuation_bottom_overlap_ghost_policy': 1,
    });
    expect(
      diagnostics.ocrSourceHandoffContract['ghostSliceAlignmentStatus'],
      'top_ghost_slice_repeat_3_to_5_lines_match_subtotal_total_final',
    );
    expect(
      diagnostics.ocrSourceHandoffContract['missingBottomTotalsEvidenceCode'],
      'bottom_edge_totals_multi_signal',
    );
    expect(
      diagnostics.ocrSourceHandoffContract['missingBottomTotalsEvidenceLabel'],
      contains('multiple local evidence families'),
    );
    expect(
      diagnostics
          .ocrSourceHandoffContract['missingBottomTotalsEvidenceFamilyCount'],
      greaterThanOrEqualTo(2),
    );
    expect(
      diagnostics.ocrSourceHandoffContract['ghostSlicePlacement'],
      'top_ghost_slice',
    );
    expect(
      diagnostics.ocrSourceHandoffContract['ghostSliceRepeatTarget'],
      'repeat_3_to_5_readable_lines',
    );
    expect(
      diagnostics.ocrSourceHandoffContract['ghostSliceMatchTarget'],
      'subtotal_total_and_final_lines',
    );
    expect(
      diagnostics.ocrSourceGhostSliceAlignmentStatus,
      'top_ghost_slice_repeat_3_to_5_lines_match_subtotal_total_final',
    );
    expect(
      diagnostics.ocrSourceGhostSliceReviewInstruction,
      contains('Repeat 3-5 readable lines in the top ghost slice'),
    );
    expect(coverageEvidence['receiptMissingBottomEdgeAndTotals'], isTrue);
    expect(
      coverageEvidence['receiptBottomTotalsEvidenceLabel'],
      'bottom_edge_and_totals_missing',
    );
    expect(
      coverageEvidence['missingBottomTotalsEvidenceCode'],
      'bottom_edge_totals_multi_signal',
    );
    expect(
      coverageEvidence['missingBottomTotalsEvidenceLabel'],
      contains('multiple local evidence families'),
    );
    expect(
      coverageEvidence['missingBottomTotalsEvidenceFamilyCount'],
      greaterThanOrEqualTo(2),
    );
    expect(coverageEvidence['ocrSourceBottomCoverageRiskDetected'], isTrue);
    expect(
      coverageEvidence['receiptCompletionReviewReasonCode'],
      'missing_bottom_edge_and_totals',
    );
    expect(
      coverageEvidence['receiptCompletionReviewActionLabel'],
      'Add the bottom receipt section with the top ghost-slice guide',
    );
    expect(
      coverageEvidence['receiptPostCaptureRouteStatus'],
      'add_next_receipt_section',
    );
    expect(coverageEvidence['ocrSourceContinuationSignalCounts'], {
      'receipt_continuation_missing_bottom_edge_and_totals': 1,
      'receipt_continuation_ocr_missing_bottom_totals': 1,
      'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines':
          1,
      'receipt_continuation_handoff_ghost_repeat_target_repeat_3_to_5_readable_lines':
          1,
      'receipt_continuation_handoff_ghost_placement_top_ghost_slice': 1,
      'receipt_continuation_handoff_ghost_match_target_subtotal_total_and_final_lines':
          1,
      'ocr_source_continuation_missing_bottom_totals_review': 1,
      'ocr_source_continuation_bottom_overlap_ghost_policy': 1,
    });
    expect(
      coverageEvidence['ocrSourceGhostSliceAlignmentStatus'],
      'top_ghost_slice_repeat_3_to_5_lines_match_subtotal_total_final',
    );
    expect(
      coverageEvidence['ocrSourceGhostSliceReviewInstruction'],
      contains('subtotal, total, and final lines can be matched'),
    );
  });
}
