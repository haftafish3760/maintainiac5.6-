part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsReadiness
    on ExpenseReceiptParseDiagnostics {
  bool get hasLines => detectedLineCount > 0;
  bool get hasCatalogMatches => catalogMatchedLineCount > 0;
  bool get hasUnmatchedMaterials => unmatchedMaterialLineCount > 0;
  bool get hasAdjustments => adjustmentLineCount > 0;
  bool get hasCompleteExplicitTotals =>
      hasExplicitSubtotal && hasExplicitTax && hasExplicitTotal;
  bool get hasOcrParserSignals => ocrParserLineCount > 0;
  bool get hasOcrItemSignals => ocrItemCandidateLineCount > 0;
  bool get hasOcrParserReadyLines => ocrParserReadyLineCount > 0;
  bool get hasOcrParserReviewSignals => ocrParserReviewSignalCount > 0;
  bool get hasOcrParserReadyStatus =>
      ocrParserReadinessStatus == 'receipt_ready' ||
      ocrParserReadinessStatus == 'inventory_ready';
  bool get hasOcrDownstreamReadyStatus =>
      ocrDownstreamReadinessStatus == 'expense_lines_ready' ||
      ocrDownstreamReadinessStatus == 'inventory_material_ready' ||
      ocrDownstreamReadinessStatus == 'material_expense_ready' ||
      ocrDownstreamReadinessStatus == 'vehicle_cost_ready';
  bool get hasOcrDownstreamReviewStatus =>
      ocrDownstreamReadinessStatus == 'proof_needs_review' ||
      ocrDownstreamReadinessStatus == 'proof_total_only' ||
      ocrDownstreamReadinessStatus == 'expense_lines_need_review';
  bool get hasOcrLeanLocalTotalsReady =>
      ocrLeanLocalReadinessStatus == 'proof_totals_ready_lines_deferred' ||
      ocrLeanLocalReadinessStatus == 'proof_totals_ready_lines_need_review' ||
      ocrLeanLocalReadinessStatus == 'line_items_ready';
  bool get hasOcrLeanLocalLineReview =>
      ocrLeanLocalReadinessStatus == 'proof_totals_ready_lines_deferred' ||
      ocrLeanLocalReadinessStatus == 'proof_totals_ready_lines_need_review';
  int ocrLeanLocalReadinessCount(String bucket) =>
      ocrLeanLocalReadinessCounts[bucket] ?? 0;
  bool get hasOcrItemReviewSignals => ocrReviewItemLineCount > 0;
  bool get hasOcrInventoryPrepSignals =>
      ocrQuantitySignalItemLineCount > 0 ||
      ocrSkuSignalItemLineCount > 0 ||
      ocrInventoryPrepLineIdCount > 0;
  bool get hasOcrGenericItemSignals => ocrGenericItemLineCount > 0;
  bool get hasOcrParserReadyFields => ocrParserReadyFieldCount > 0;
  bool get hasOcrParserReviewFields => ocrParserReviewFieldCount > 0;
  bool get hasOcrCompleteSummaryMath => ocrSummaryMathStatus != 'incomplete';
  bool get hasOcrSummaryMathMismatch =>
      hasOcrCompleteSummaryMath && !ocrSummaryMathReconciled;
  bool get hasOcrExpectedLineSequence =>
      ocrLineSequenceStatus == 'expected_order';
  bool get hasOcrLineSequenceReview =>
      ocrLineSequenceStatus != 'unknown' &&
      ocrLineSequenceStatus != 'empty' &&
      !hasOcrExpectedLineSequence;
  bool get hasOcrSourceSectionReview =>
      ocrSourceSectionContinuityReviewNeeded ||
      (ocrSourceSectionContinuityStatus != 'unknown' &&
          ocrSourceSectionContinuityStatus != 'no_text' &&
          ocrSourceSectionContinuityStatus != 'no_source_sections' &&
          ocrSourceSectionContinuityStatus != 'single_section' &&
          ocrSourceSectionContinuityStatus != 'continuous_sections');
  String get ocrSourceSectionReviewLabel {
    final count = ocrSourceSectionCount;
    final sectionWord = count == 1 ? 'section' : 'sections';
    return switch (ocrSourceSectionContinuityStatus) {
      'continuous_sections' when count > 1 =>
        '$count OCR $sectionWord in order',
      'single_section' => 'Single OCR section',
      'no_source_sections' => 'No OCR sections reported',
      'missing_section_gap' => '$count OCR $sectionWord with a gap',
      'out_of_order_sections' => '$count OCR $sectionWord out of order',
      'duplicate_sections' => '$count OCR $sectionWord with duplicates',
      'unknown' when count > 0 => '$count OCR $sectionWord',
      'no_text' => 'No OCR text sections',
      _ when count > 0 => '$count OCR $sectionWord need review',
      _ => 'OCR section order not reported',
    };
  }

  String get ocrSourceSectionReviewInstruction {
    return switch (ocrSourceSectionContinuityStatus) {
      'continuous_sections' =>
        'OCR section order looks continuous. Continue if the receipt proof visibly includes the subtotal, total, and final lines.',
      'single_section' =>
        'Only one OCR section reached review. If this is a long receipt and subtotal or total is lower down, add the next bottom section.',
      'no_source_sections' =>
        'No OCR section anchors reached review. Continue only if the receipt proof is visibly complete.',
      'missing_section_gap' =>
        'OCR section numbers show a gap. Add or retake the missing middle or bottom section before trusting line totals.',
      'out_of_order_sections' =>
        'OCR sections appear out of order. Review the receipt photos from top to bottom before saving.',
      'duplicate_sections' =>
        'OCR sections may contain duplicate overlap. Check repeated lines before saving.',
      'no_text' =>
        'OCR did not find receipt text sections. Retake or enter the receipt manually.',
      _ =>
        'OCR section order needs review. If subtotal, total, or final lines are missing, add the next bottom receipt section.',
    };
  }

  bool get hasOcrReceiptStructureReview =>
      ocrReceiptStructureStatus != 'unknown' &&
      ocrReceiptStructureStatus != 'ready_for_parser';
  bool get hasOcrTotalSignals =>
      ocrSubtotalCandidateLineCount > 0 ||
      ocrTaxCandidateLineCount > 0 ||
      ocrTotalCandidateLineCount > 0;
  bool get hasOcrSummaryTotalSignals =>
      ocrSubtotalCandidateLineCount > 0 || ocrTotalCandidateLineCount > 0;
  bool get hasParserFooterSeenTotalsMissingReview =>
      parserTaskCount('receipt_footer_seen_totals_missing_review') > 0 ||
      parserTaskCount('receipt_footer_seen_final_total_missing_review') > 0;
  bool get hasParserSplitTenderVisibleTotalReview =>
      parserTaskCount('receipt_split_tender_matches_visible_lines_review') > 0;
  bool get hasParserPossibleLowerSectionMissing =>
      parserTaskCount('receipt_possible_lower_section_missing') > 0 ||
      (!hasParserFooterSeenTotalsMissingReview &&
          !hasParserSplitTenderVisibleTotalReview &&
          (parserTaskCount('receipt_final_total_missing_review') > 0 ||
              parserTaskCount('receipt_partial_totals_review') > 0 ||
              parserTaskCount('receipt_missing_totals_manual_review') > 0 ||
              parserTaskCount('receipt_totals_text_missing_review') > 0));
  bool get shouldSuggestLowerReceiptSection {
    if (hasOcrSourceMissingBottomCoverageEvidence ||
        hasOcrSourceBottomOverlapGhostContinuation ||
        hasParserPossibleLowerSectionMissing) {
      return true;
    }
    if (ocrParserLineCount <= 0 || hasOcrSummaryTotalSignals) return false;
    return ocrSourceSectionCount <= 1 ||
        ocrSourceSectionContinuityStatus == 'single_section' ||
        ocrSourceSectionContinuityStatus == 'no_source_sections' ||
        ocrSourceSectionContinuityStatus == 'unknown';
  }

  String get lowerReceiptSectionReviewLabel {
    if (hasOcrSourceMissingBottomCoverageEvidence) {
      return 'Bottom edge and totals missing';
    }
    if (hasOcrSourceBottomOverlapGhostContinuation) {
      return 'Bottom continuation needed';
    }
    if (shouldSuggestLowerReceiptSection) {
      return 'Totals may be lower down';
    }
    return 'Receipt lower section not needed';
  }

  String get lowerReceiptSectionReviewInstruction {
    if (hasOcrSourceMissingBottomCoverageEvidence ||
        hasOcrSourceBottomOverlapGhostContinuation) {
      return ocrSourceCoverageReviewInstruction;
    }
    if (shouldSuggestLowerReceiptSection) {
      return 'OCR found receipt text but no subtotal or total lines. If this is a long receipt, add the lower section before final review; otherwise continue and enter the total manually.';
    }
    return 'OCR found enough summary evidence for normal receipt review.';
  }

  bool get hasOcrNonItemSignals =>
      ocrTenderCandidateLineCount > 0 || ocrMetadataCandidateLineCount > 0;
  bool get hasParserLineRoleCounts => parserLineRoleCounts.isNotEmpty;
  int parserLineRoleCount(String role) => parserLineRoleCounts[role] ?? 0;
  bool get hasParserTaskCounts => parserTaskCounts.isNotEmpty;
  int parserTaskCount(String task) => parserTaskCounts[task] ?? 0;
  bool get hasParserCategoryCounts => parserCategoryCounts.isNotEmpty;
  int parserCategoryCount(String categoryToken) =>
      parserCategoryCounts[categoryToken] ?? 0;
  bool get hasParserCategoryHealthCounts =>
      parserCategoryHealthCounts.isNotEmpty;
  int parserCategoryHealthCount(String bucket) =>
      parserCategoryHealthCounts[bucket] ?? 0;
  bool get hasParserCategoryReview =>
      parserCategoryHealthCount('category_needs_review_total') > 0;
  bool get hasParserCategoryReady =>
      parserCategoryHealthCount('category_ready_total') > 0;
  bool get hasParserCategoryPackLimits =>
      parserCategoryHealthCount('category_pack_limited_total') > 0;
}
