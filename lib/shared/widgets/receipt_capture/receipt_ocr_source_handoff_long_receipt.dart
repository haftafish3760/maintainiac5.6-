part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrSourceHandoffLongReceipt on ReceiptOcrSourceHandoffSummary {
  bool get hasTopGhostSlicePlacement {
    return _countLongReceiptHandoffKeys(continuationSignalCounts, const [
          'receipt_continuation_handoff_ghost_placement_top_ghost_slice',
          'receipt_continuation_ghost_placement_top_ghost_slice',
          'ghost_placement_top_ghost_slice',
        ]) >
        0;
  }

  bool get hasRepeatLineGhostTarget {
    return _countLongReceiptHandoffKeys(continuationSignalCounts, const [
          'receipt_continuation_handoff_ghost_repeat_target_repeat_3_to_5_readable_lines',
          'receipt_continuation_ghost_repeat_target_repeat_3_to_5_readable_lines',
          'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'receipt_continuation_handoff_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'ocr_source_continuation_bottom_overlap_ghost_policy',
          'ghost_repeat_target_repeat_3_to_5_readable_lines',
        ]) >
        0;
  }

  bool get hasSubtotalTotalFinalLineMatchTarget {
    return _countLongReceiptHandoffKeys(continuationSignalCounts, const [
          'receipt_continuation_handoff_ghost_match_target_subtotal_total_and_final_lines',
          'receipt_continuation_ghost_match_target_subtotal_total_and_final_lines',
          'ghost_match_target_subtotal_total_and_final_lines',
        ]) >
        0;
  }

  bool get hasGhostSliceAlignmentContract =>
      hasMissingBottomEdgeAndTotalsEvidence &&
      (hasTopGhostSlicePlacement ||
          hasRepeatLineGhostTarget ||
          hasSubtotalTotalFinalLineMatchTarget);

  int get missingBottomTotalsEvidenceFamilyCount {
    var count = 0;
    if (_countLongReceiptHandoffKeys(coverageSignalCounts, const [
          'receipt_coverage_bottom_edge_and_totals_missing_together',
          'receipt_coverage_evidence_bottom_edge_missing_plus_totals_words_and_amount_missing',
          'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
          'receipt_coverage_rationale_edge_missing_and_totals_words_amount_missing',
          'receipt_coverage_rationale_edge_missing_and_totals_text_missing',
          'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap',
        ]) >
        0) {
      count++;
    }
    if (_countLongReceiptHandoffKeys(continuationSignalCounts, const [
          'receipt_continuation_missing_bottom_edge_and_totals',
          'receipt_continuation_ocr_missing_bottom_totals',
          'ocr_source_continuation_missing_bottom_totals_review',
        ]) >
        0) {
      count++;
    }
    if (_countLongReceiptHandoffKeys(handoffSignalCounts, const [
          'receipt_handoff_possible_partial_receipt',
        ]) >
        0) {
      count++;
    }
    if (_countLongReceiptHandoffKeys(photoQualityRiskCounts, const [
          'ocr_source_possible_cutoff',
        ]) >
        0) {
      count++;
    }
    return count;
  }

  String get missingBottomTotalsEvidenceCode {
    if (!hasMissingBottomEdgeAndTotalsEvidence) return 'not_detected';
    if (missingBottomTotalsEvidenceFamilyCount >= 2) {
      return 'bottom_edge_totals_multi_signal';
    }
    if (coverageSignalCounts.isNotEmpty) {
      return 'bottom_edge_totals_coverage_signal';
    }
    if (continuationSignalCounts.isNotEmpty) {
      return 'bottom_edge_totals_continuation_signal';
    }
    if (handoffSignalCounts.isNotEmpty) {
      return 'bottom_edge_totals_handoff_signal';
    }
    return 'bottom_edge_totals_quality_signal';
  }

  String get missingBottomTotalsEvidenceLabel {
    return switch (missingBottomTotalsEvidenceCode) {
      'bottom_edge_totals_multi_signal' =>
        'Bottom edge and totals are missing across multiple local evidence families.',
      'bottom_edge_totals_coverage_signal' =>
        'Local coverage evidence says bottom edge and subtotal/total are missing together.',
      'bottom_edge_totals_continuation_signal' =>
        'Local continuation evidence says the bottom section is still needed.',
      'bottom_edge_totals_handoff_signal' =>
        'Receipt handoff says this may be a partial receipt.',
      'bottom_edge_totals_quality_signal' =>
        'Local quality evidence says the receipt may be cut off.',
      _ => 'No local missing-bottom/totals evidence was reported.',
    };
  }

  String get ghostSliceAlignmentStatus {
    if (!hasGhostSliceAlignmentContract) return 'not_requested';
    if (hasTopGhostSlicePlacement &&
        hasRepeatLineGhostTarget &&
        hasSubtotalTotalFinalLineMatchTarget) {
      return 'top_ghost_slice_repeat_3_to_5_lines_match_subtotal_total_final';
    }
    if (hasTopGhostSlicePlacement && hasRepeatLineGhostTarget) {
      return 'top_ghost_slice_repeat_3_to_5_lines';
    }
    return 'ghost_slice_alignment_partial';
  }

  String get ghostSliceReviewInstruction {
    if (!hasGhostSliceAlignmentContract) return '';
    if (hasSubtotalTotalFinalLineMatchTarget) {
      return 'Repeat 3-5 readable lines in the top ghost slice so subtotal, total, and final lines can be matched.';
    }
    return 'Repeat 3-5 readable lines in the top ghost slice so receipt sections can be matched.';
  }

  bool get hasMissingBottomEdgeAndTotalsEvidence {
    return (continuationSignalCounts['receipt_continuation_missing_bottom_edge_and_totals'] ??
                0) >
            0 ||
        (continuationSignalCounts['receipt_continuation_ocr_missing_bottom_totals'] ??
                0) >
            0 ||
        (continuationSignalCounts['ocr_source_continuation_missing_bottom_totals_review'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_bottom_edge_and_totals_missing_together'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_evidence_bottom_edge_missing_plus_totals_words_and_amount_missing'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_rationale_edge_missing_and_totals_text_missing'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_rationale_edge_missing_and_totals_words_amount_missing'] ??
                0) >
            0 ||
        (coverageSignalCounts['receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap'] ??
                0) >
            0 ||
        (handoffSignalCounts['receipt_handoff_possible_partial_receipt'] ?? 0) >
            0 ||
        (photoQualityRiskCounts['ocr_source_possible_cutoff'] ?? 0) > 0;
  }

  bool get hasUserConfirmedCompleteAfterPrompt {
    return (completionSignalCounts['receipt_completion_user_confirmed_complete_after_prompt'] ??
                0) >
            0 ||
        (completionSignalCounts['receipt_completion_continue_anyway'] ?? 0) >
            0 ||
        (completionSignalCounts['ocr_source_completion_continue_anyway_review'] ??
                0) >
            0;
  }
}

int _countLongReceiptHandoffKeys(Map<String, int> counts, List<String> keys) {
  var total = 0;
  for (final key in keys) {
    total += counts[key] ?? 0;
  }
  return total;
}
