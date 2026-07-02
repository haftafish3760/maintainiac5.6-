part of 'expense_receipt_parser.dart';

const _bottomReceiptGhostSliceGuideAction =
    'Add the bottom receipt section with the top ghost-slice guide';

extension ExpenseReceiptParseDiagnosticsOcrSourceReview
    on ExpenseReceiptParseDiagnostics {
  String get missingBottomTotalsLocalEvidenceReviewLabel {
    final label = missingBottomTotalsEvidenceLabel.trim();
    if (hasMissingBottomTotalsLocalEvidence && label.isNotEmpty) {
      return label;
    }
    if (hasOcrSourceMissingBottomCoverageEvidence) {
      return 'Local evidence says the bottom edge and subtotal/total are missing together.';
    }
    return '';
  }

  bool get hasOcrSourceCoverageSignals =>
      ocrSourceCoverageSignalCounts.isNotEmpty;
  int ocrSourceCoverageSignalCount(String signal) =>
      ocrSourceCoverageSignalCounts[signal] ?? 0;
  bool get hasOcrSourceMissingBottomCoverageEvidence =>
      ocrSourceCoverageSignalCount(
            'receipt_coverage_bottom_edge_and_totals_missing_together',
          ) >
          0 ||
      ocrSourceCoverageSignalCount(
            'receipt_coverage_evidence_bottom_edge_missing_plus_totals_words_and_amount_missing',
          ) >
          0 ||
      ocrSourceCoverageSignalCount(
            'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
          ) >
          0 ||
      ocrSourceCoverageSignalCount(
            'receipt_coverage_rationale_edge_missing_and_totals_words_amount_missing',
          ) >
          0 ||
      ocrSourceCoverageSignalCount(
            'receipt_coverage_rationale_edge_missing_and_totals_text_missing',
          ) >
          0 ||
      ocrSourceCoverageSignalCount(
            'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap',
          ) >
          0;
  String get ocrSourceCoverageReviewCode {
    if (hasOcrSourceMissingBottomCoverageEvidence) {
      return 'missing_bottom_edge_and_totals_use_ghost_overlap';
    }
    if (ocrSourceCoverageSignalCount(
          'receipt_coverage_contract_totals_missing_add_lower_section',
        ) >
        0) {
      return 'totals_missing_add_lower_section';
    }
    if (hasOcrSourceCoverageSignals) return 'coverage_checked';
    return 'coverage_not_reported';
  }

  String get ocrSourceCoverageReviewLabel {
    return switch (ocrSourceCoverageReviewCode) {
      'missing_bottom_edge_and_totals_use_ghost_overlap' =>
        'Bottom edge and totals missing',
      'totals_missing_add_lower_section' => 'Totals may need lower section',
      'coverage_checked' => 'Receipt coverage checked',
      _ => 'Receipt coverage not reported',
    };
  }

  String get ocrSourceCoverageReviewInstruction {
    final evidenceLabel = missingBottomTotalsLocalEvidenceReviewLabel;
    final evidencePrefix = evidenceLabel.isEmpty ? '' : '$evidenceLabel ';
    return switch (ocrSourceCoverageReviewCode) {
      'missing_bottom_edge_and_totals_use_ghost_overlap' =>
        '$evidencePrefix$_bottomReceiptGhostSliceGuideAction because the bottom edge and subtotal/total lines were not found together. Repeat 3-5 readable lines so subtotal, total, and final lines can be matched.',
      'totals_missing_add_lower_section' =>
        'Check whether this is the full receipt. If the subtotal or total is lower down, add the next receipt section before saving.',
      'coverage_checked' =>
        'Coverage signals were carried from capture into local OCR and parser review.',
      _ =>
        'No capture coverage evidence reached this parser review. Continue only if the receipt proof is visibly complete.',
    };
  }

  String get ocrSourceCoverageReviewActionLabel {
    return switch (ocrSourceCoverageReviewCode) {
      'missing_bottom_edge_and_totals_use_ghost_overlap' =>
        'Add next receipt section',
      'totals_missing_add_lower_section' => 'Check lower receipt section',
      'coverage_checked' => 'Review filled receipt',
      _ => 'Confirm receipt proof',
    };
  }

  bool get hasOcrSourceContinuationSignals =>
      ocrSourceContinuationSignalCounts.isNotEmpty;
  int ocrSourceContinuationSignalCount(String signal) =>
      ocrSourceContinuationSignalCounts[signal] ?? 0;
  bool get hasOcrSourceBottomOverlapGhostContinuation =>
      ocrSourceContinuationSignalCount(
            'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          ) >
          0 ||
      ocrSourceContinuationSignalCount(
            'ocr_source_continuation_bottom_overlap_ghost_policy',
          ) >
          0 ||
      ocrSourceContinuationSignalCount(
            'receipt_continuation_missing_bottom_edge_and_totals',
          ) >
          0 ||
      ocrSourceContinuationSignalCount(
            'receipt_continuation_ocr_missing_bottom_totals',
          ) >
          0;

  String get ocrSourceContinuationReviewCode {
    if (hasOcrSourceBottomOverlapGhostContinuation) {
      return 'bottom_overlap_ghost_continuation';
    }
    if (hasOcrSourceContinuationSignals) return 'continuation_photos_present';
    return 'no_continuation_photos';
  }

  String get ocrSourceContinuationReviewLabel {
    return switch (ocrSourceContinuationReviewCode) {
      'bottom_overlap_ghost_continuation' =>
        'Bottom continuation uses top ghost slice',
      'continuation_photos_present' => 'Continuation photos attached',
      _ => 'No continuation photos reported',
    };
  }

  String get ocrSourceContinuationReviewInstruction {
    return switch (ocrSourceContinuationReviewCode) {
      'bottom_overlap_ghost_continuation' =>
        'The capture handoff says the bottom edge and subtotal/total evidence were not found together, so the next photo should repeat 3-5 readable lines in the top ghost slice.',
      'continuation_photos_present' =>
        'The receipt was reviewed as a multi-photo capture. Check the stitched line order before saving.',
      _ =>
        'No continuation-photo handoff reached this parser review. Continue only if the visible receipt proof is complete.',
    };
  }

  String get ocrSourceContinuationReviewActionLabel {
    return switch (ocrSourceContinuationReviewCode) {
      'bottom_overlap_ghost_continuation' => 'Add bottom with top ghost slice',
      'continuation_photos_present' => 'Review joined receipt',
      _ => 'Confirm receipt proof',
    };
  }
}
