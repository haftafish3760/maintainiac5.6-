part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsReview
    on ExpenseReceiptParseDiagnostics {
  double get reviewRatio {
    if (detectedLineCount == 0) return 0;
    return reviewLineCount / detectedLineCount;
  }

  bool get needsHeavyReview {
    return !reconciled ||
        (hasCompleteExplicitTotals && !taxMathReconciled) ||
        reviewRatio > .5 ||
        hasUnmatchedMaterials;
  }

  String get lineSummaryLabel {
    if (detectedLineCount == 0) return 'No line items parsed';
    final review = reviewLineCount == 0
        ? 'none need review'
        : '$reviewLineCount need review';
    return '$detectedLineCount parsed, $review';
  }

  int get classificationReadyLineCount {
    final ready = detectedLineCount - reviewLineCount;
    return ready < 0 ? 0 : ready;
  }

  bool get hasClassificationReadyLines => classificationReadyLineCount > 0;

  bool get hasMixedReceiptMathBasis {
    return expectedSubtotalOrTotal != null || hasExplicitTotal;
  }

  String get mixedItemFamilyReviewLabel {
    if (!hasAnyMixedItemExpenseFamilies) return '';
    final label = parserItemExpenseFamilySummaryLabel.isNotEmpty
        ? parserItemExpenseFamilySummaryLabel
        : ocrItemExpenseFamilySummaryLabel;
    if (label.isNotEmpty) return label;
    return 'Mixed receipt families found';
  }

  String get mixedItemFamilyReviewActionLabel {
    if (!hasAnyMixedItemExpenseFamilies) return '';
    return 'Review this as Mixed if any item family belongs to a different business or personal purpose.';
  }

  String get mixedItemFamilyNextStepLabel {
    if (!hasAnyMixedItemExpenseFamilies) return '';
    return 'Next: review the mixed item families, choose Mixed if needed, then classify each line.';
  }

  String get receiptClassificationSummaryLabel {
    if (detectedLineCount == 0) {
      if (hasMixedReceiptMathBasis) return 'Receipt total ready to classify';
      return 'Classification needs manual receipt total';
    }
    final ready = classificationReadyLineCount;
    final review = reviewLineCount;
    final lineText = review == 0
        ? '$ready priced ${ready == 1 ? 'line' : 'lines'} ready'
        : '$ready ready, $review ${review == 1 ? 'line' : 'lines'} to check';
    if (hasExplicitTax && hasMixedReceiptMathBasis) {
      return '$lineText; tax ready for mixed split';
    }
    if (hasMixedReceiptMathBasis) {
      return '$lineText; total ready for classification';
    }
    return '$lineText; receipt math needs review';
  }

  String get catalogSummaryLabel {
    if (parserDepth != ReceiptParserDepth.inventoryMatching) {
      return 'Catalog matching skipped';
    }
    if (materialLineCount == 0) return 'No material lines';
    return '$catalogMatchedLineCount of $materialLineCount material lines matched';
  }

  String get reconciliationLabel {
    final expected = expectedSubtotalOrTotal;
    if (expected == null || detectedLineCount == 0) {
      return 'No subtotal reconciliation';
    }
    final diff = reconciliationDifference ?? 0;
    if (reconciled) return 'Line total matches receipt total';
    return 'Line total differs by \$${diff.abs().toStringAsFixed(2)}';
  }

  String get totalsMathLabel {
    if (!hasCompleteExplicitTotals) return 'Receipt total math incomplete';
    final diff = taxMathDifference ?? 0;
    if (taxMathReconciled) return 'Subtotal plus tax matches total';
    return 'Subtotal plus tax differs by \$${diff.abs().toStringAsFixed(2)}';
  }

  String get parserMathReviewLabel {
    if (detectedLineCount > 0 &&
        expectedSubtotalOrTotal != null &&
        !reconciled) {
      return 'Check missing, duplicate, return, discount, fee, or skipped long-receipt lines';
    }
    if (hasCompleteExplicitTotals && !taxMathReconciled) {
      return 'Check subtotal, tax, fees, discounts, and receipt total math';
    }
    if (!hasCompleteExplicitTotals && hasMixedReceiptMathBasis) {
      return 'Receipt total can be reviewed, but subtotal or tax was inferred';
    }
    return '';
  }

  String get receiptSequenceReviewStatus {
    if (hasParserDuplicateOverlapReview) return 'overlap_review_needed';
    if (hasOcrSourceSectionReview) return 'section_order_review_needed';
    if (shouldSuggestLowerReceiptSection) return 'lower_section_may_be_missing';
    if (hasOcrExpectedLineSequence ||
        ocrSourceSectionContinuityStatus == 'continuous_sections' ||
        ocrSourceSectionContinuityStatus == 'single_section' ||
        parserDownstreamReadinessStatus == 'expense_lines_ready' ||
        parserDownstreamReadinessStatus == 'inventory_material_ready' ||
        parserDownstreamReadinessStatus == 'vehicle_cost_ready') {
      return 'sequence_ready';
    }
    if (detectedLineCount > 0 || ocrParserLineCount > 0) {
      return 'sequence_evidence_needs_review';
    }
    return 'sequence_not_available';
  }

  String get receiptSequenceReviewLabel {
    return switch (receiptSequenceReviewStatus) {
      'overlap_review_needed' => 'Check repeated receipt overlap',
      'section_order_review_needed' => 'Check receipt photo order',
      'lower_section_may_be_missing' => 'Check lower receipt section',
      'sequence_ready' => 'Receipt line order ready',
      'sequence_evidence_needs_review' => 'Receipt line order needs review',
      _ => 'Receipt line order not available',
    };
  }

  String get receiptSequenceReviewInstruction {
    return switch (receiptSequenceReviewStatus) {
      'overlap_review_needed' => parserDuplicateOverlapReviewInstruction,
      'section_order_review_needed' => ocrSourceSectionReviewInstruction,
      'lower_section_may_be_missing' => lowerReceiptSectionReviewInstruction,
      'sequence_ready' =>
        'Receipt line order has enough local evidence for review. Continue only if the visible proof matches the parsed lines.',
      'sequence_evidence_needs_review' =>
        'Review the receipt line order before saving, especially around photo joins, totals, and repeated item lines.',
      _ =>
        'No receipt line-order evidence reached parser review. Retake, add a photo, or enter the receipt manually.',
    };
  }

  String get parserReviewRootCauseCode {
    if (hasOcrSourceMissingBottomCoverageEvidence ||
        hasOcrSourceBottomOverlapGhostContinuation ||
        hasOcrSourceSectionReview ||
        shouldSuggestLowerReceiptSection) {
      return 'capture_coverage_or_long_receipt';
    }
    if (hasOcrPhotoQualityActionReview ||
        ocrSourceQualityReviewStatus.trim().isNotEmpty ||
        ocrSourceQualityReviewAction.trim().isNotEmpty) {
      return 'camera_source_quality';
    }
    if (hasParserDuplicateOverlapReview) return 'multi_photo_overlap';
    if (parserMathReviewLabel.isNotEmpty || hasOcrSummaryMathMismatch) {
      return 'receipt_math_review';
    }
    if (hasOcrRequiredFieldMissing || hasOcrRequiredFieldReview) {
      return 'ocr_required_fields';
    }
    if (hasParserCategoryPackLimits) return 'parser_optional_pack_limit';
    if (hasParserCategoryReview) return 'parser_category_confidence';
    if (hasParserCategoryReady || hasReadableOcrParserEvidence) {
      return 'parser_ready';
    }
    return 'parser_review_not_classified';
  }

  String get parserReviewRootCauseLabel {
    return switch (parserReviewRootCauseCode) {
      'capture_coverage_or_long_receipt' =>
        'Capture coverage or long receipt section',
      'camera_source_quality' => 'Camera/source photo quality',
      'multi_photo_overlap' => 'Multi-photo overlap review',
      'receipt_math_review' => 'Receipt math review',
      'ocr_required_fields' => 'OCR required fields',
      'parser_optional_pack_limit' => 'Optional parser pack limit',
      'parser_category_confidence' => 'Parser category confidence',
      'parser_ready' => 'Parser ready',
      _ => 'Parser review not classified',
    };
  }

  String get parserReviewRootCauseActionLabel {
    return switch (parserReviewRootCauseCode) {
      'capture_coverage_or_long_receipt' =>
        hasOcrSourceBottomOverlapGhostContinuation
            ? 'Add bottom with top ghost slice'
            : hasOcrSourceSectionReview
            ? 'Check receipt photo order'
            : 'Check lower receipt section',
      'camera_source_quality' => ocrPhotoQualityActionReviewActionLabel,
      'multi_photo_overlap' => 'Check repeated lines',
      'receipt_math_review' => 'Check totals math',
      'ocr_required_fields' => 'Fill missing receipt fields',
      'parser_optional_pack_limit' => 'Review parser pack choice',
      'parser_category_confidence' => 'Confirm category',
      'parser_ready' => 'Review and classify',
      _ => 'Review receipt',
    };
  }

  String get parserReviewRootCauseInstruction {
    return switch (parserReviewRootCauseCode) {
      'capture_coverage_or_long_receipt' =>
        hasOcrSourceSectionReview
            ? ocrSourceSectionReviewInstruction
            : lowerReceiptSectionReviewInstruction,
      'camera_source_quality' => ocrPhotoQualityActionReviewInstruction,
      'multi_photo_overlap' => parserDuplicateOverlapReviewInstruction,
      'receipt_math_review' =>
        '$parserMathReviewLabel before saving. Confirm subtotal, tax, fees, discounts, and total against the saved receipt proof.',
      'ocr_required_fields' =>
        'The receipt text was read, but ${ocrRequiredFieldIssueSummaryLabel.isEmpty ? 'one or more required fields still need help' : ocrRequiredFieldIssueSummaryLabel}. Check the saved proof before saving.',
      'parser_optional_pack_limit' =>
        'The local parser can continue, but an optional parser pack may improve category or item recognition later. Do not block saving if the receipt proof is readable.',
      'parser_category_confidence' =>
        'The parser needs a category check. Confirm whether the receipt belongs to fuel, materials, vehicle cost, business expense, personal, or mixed.',
      'parser_ready' =>
        'The parser has enough local evidence for review. Confirm Business, Personal, or Mixed before saving.',
      _ =>
        'Review the filled receipt against the saved proof before saving. Retake or add a photo if required fields are not readable.',
    };
  }

  String get parserTaskSummaryLabel {
    if (!hasOcrParserTaskCounts) return 'No OCR parser task evidence';
    final photoActionLabel = ocrPhotoQualityActionReviewLabel;
    if (photoActionLabel.isNotEmpty) return photoActionLabel;
    final parts = <String>[
      if (hasOcrVendorTaskEvidence) 'vendor',
      if (hasOcrDateTaskEvidence) 'date',
      if (hasOcrSubtotalTaskEvidence) 'subtotal',
      if (hasOcrTaxTaskEvidence) 'tax',
      if (hasOcrTotalTaskEvidence) 'total',
      if (hasOcrItemPriceTaskEvidence) 'item prices',
      if (hasOcrFuelTaskEvidence) 'fuel ready',
      if (hasOcrMaterialPrepTaskEvidence) 'material candidates',
      if (parserItemExpenseFamilySummaryLabel.isNotEmpty)
        parserItemExpenseFamilySummaryLabel,
      if (ocrItemExpenseFamilySummaryLabel.isNotEmpty)
        ocrItemExpenseFamilySummaryLabel,
    ];
    if (parts.isEmpty) return 'OCR parser task evidence needs review';
    return 'OCR prepared ${parts.join(', ')}';
  }

  String get downstreamReadinessSummaryLabel {
    if (hasParserGenericFuelReceiptReady) return 'Fuel receipt review ready';
    final status = ocrDownstreamReadinessStatus == 'unknown'
        ? parserDownstreamReadinessStatus
        : ocrDownstreamReadinessStatus;
    return switch (status) {
      'inventory_material_ready' => 'Inventory/material review ready',
      'material_expense_ready' => 'Material expense review ready',
      'vehicle_cost_ready' => 'Vehicle cost review ready',
      'expense_lines_ready' => 'Expense line review ready',
      'expense_lines_need_review' => 'Expense lines need review',
      'proof_total_only' =>
        parserDownstreamReadinessCount('totals_found_no_safe_lines') > 0
            ? 'Receipt total ready; line detail missing'
            : 'Receipt total only',
      'proof_needs_review' => 'Receipt proof needs review',
      'no_text' => 'No OCR text ready',
      _ => '',
    };
  }

  String get trustLabel {
    if (detectedLineCount == 0) return 'Totals only';
    if (!needsHeavyReview) return 'Ready to review';
    if (!reconciled || (hasCompleteExplicitTotals && !taxMathReconciled)) {
      return 'Needs receipt math review';
    }
    if (reviewRatio > .5) return 'Needs line review';
    if (hasUnmatchedMaterials) return 'Needs catalog review';
    return 'Needs review';
  }
}
