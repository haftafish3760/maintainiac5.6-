part of 'expense_receipt_entry_screen.dart';

_ReceiptAssistedReviewGuidance _receiptAssistedReviewGuidanceFrom({
  required _ReceiptDetailEntryMode detailMode,
  required int lineCount,
  required int unreviewedLineCount,
  required ReceiptOcrDiagnostics? diagnostics,
  required ExpenseReceiptParseDiagnostics? parseDiagnostics,
  required bool hasWarnings,
}) {
  final hasLines = lineCount > 0;
  final hasReview = unreviewedLineCount > 0 || hasWarnings;
  final parserReady =
      diagnostics?.parserReadinessStatus == 'receipt_ready' ||
      diagnostics?.parserReadinessStatus == 'inventory_ready' ||
      parseDiagnostics?.hasParserDownstreamReadyStatus == true;
  final inventoryReady =
      diagnostics?.parserReadinessStatus == 'inventory_ready' ||
      parseDiagnostics?.parserDownstreamReadinessStatus ==
          'inventory_material_ready';
  final parserPricedLineCount =
      parseDiagnostics?.parserDownstreamReadinessCount('priced_line_ready') ??
      0;
  final parserReviewLineCount =
      parseDiagnostics?.parserDownstreamReadinessCount('line_needs_review') ??
      0;
  final hasItemSignals =
      (diagnostics?.itemCandidateLineCount ?? 0) > 0 ||
      (parseDiagnostics?.detectedLineCount ?? 0) > 0;
  final hasPriceSignals =
      (diagnostics?.pricedLineCount ?? 0) > 0 || parserPricedLineCount > 0;
  final hasSummarySignals =
      (diagnostics?.subtotalCandidateLineCount ?? 0) > 0 ||
      (diagnostics?.taxCandidateLineCount ?? 0) > 0 ||
      (diagnostics?.totalCandidateLineCount ?? 0) > 0 ||
      (parseDiagnostics?.hasMixedReceiptMathBasis ?? false);
  final readyLineCount = diagnostics?.parserReadyLineCount ?? 0;
  final effectiveReadyLineCount = readyLineCount > 0
      ? readyLineCount
      : parserPricedLineCount;
  final reviewLineCount = diagnostics?.parserReviewSignalCount ?? 0;
  final effectiveReviewLineCount = reviewLineCount > 0
      ? reviewLineCount
      : parserReviewLineCount;
  final orderedParserLineCount = diagnostics?.parserLineCount ?? 0;
  final effectiveOrderedParserLineCount = orderedParserLineCount > 0
      ? orderedParserLineCount
      : parseDiagnostics?.detectedLineCount ?? 0;
  final fieldStatusChips = _fieldStatusChipsFor(diagnostics);
  final canClassifyLines = hasLines && (parserReady || hasPriceSignals);
  final reviewLabel = !hasLines
      ? 'Totals fallback'
      : detailMode == _ReceiptDetailEntryMode.basicReceipt
      ? 'Review the core receipt fields before saving.'
      : detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Price-first review'
      : 'Full-line review';
  final reviewIcon = !hasLines
      ? Icons.add_card_rounded
      : detailMode == _ReceiptDetailEntryMode.basicReceipt
      ? Icons.receipt_outlined
      : detailMode == _ReceiptDetailEntryMode.quickClassify
      ? Icons.price_check_rounded
      : Icons.view_list_rounded;
  final reviewColor = !hasLines
      ? const Color(0xFFFFD166)
      : hasReview
      ? const Color(0xFFFFD166)
      : const Color(0xFF8EF6A4);
  final classificationLabel = canClassifyLines
      ? 'Business/Personal/Mixed ready'
      : hasSummarySignals
      ? 'Classify receipt total'
      : 'Classify manually';
  final classificationIcon = canClassifyLines
      ? Icons.account_tree_rounded
      : Icons.edit_note_rounded;
  final classificationColor = canClassifyLines
      ? const Color(0xFF8EF6A4)
      : const Color(0xFFFFD166);
  final materialPrepLabel = inventoryReady
      ? 'Material review ready'
      : hasItemSignals
      ? 'Item signals found'
      : '';
  final readyLineLabel = effectiveReadyLineCount <= 0
      ? ''
      : '$effectiveReadyLineCount ready ${effectiveReadyLineCount == 1 ? 'line' : 'lines'}';
  final reviewLineLabel = effectiveReviewLineCount <= 0
      ? ''
      : '$effectiveReviewLineCount ${effectiveReviewLineCount == 1 ? 'line' : 'lines'} to check';
  final lineMapLabel = effectiveOrderedParserLineCount <= 0
      ? ''
      : '$effectiveOrderedParserLineCount ordered ${effectiveOrderedParserLineCount == 1 ? 'line' : 'lines'}';
  final parserTaskSummaryLabel =
      parseDiagnostics == null || !parseDiagnostics.hasOcrParserTaskCounts
      ? ''
      : parseDiagnostics.parserTaskSummaryLabel;
  final parserMathReviewLabel = parseDiagnostics?.parserMathReviewLabel ?? '';
  final parserOverlapReviewLabel =
      parseDiagnostics?.parserDuplicateOverlapReviewLabel ?? '';
  final parserOverlapReviewInstruction =
      parseDiagnostics?.parserDuplicateOverlapReviewInstruction ?? '';
  final parserRootCauseCode = parseDiagnostics?.parserReviewRootCauseCode ?? '';
  final parserRootCauseLabel =
      parseDiagnostics == null ||
          parserRootCauseCode == 'parser_ready' ||
          parserRootCauseCode == 'parser_review_not_classified'
      ? ''
      : parseDiagnostics.parserReviewRootCauseLabel;
  final parserRootCauseInstruction =
      parseDiagnostics == null ||
          parserRootCauseCode == 'parser_ready' ||
          parserRootCauseCode == 'parser_review_not_classified'
      ? ''
      : parseDiagnostics.parserReviewRootCauseInstruction;
  final lowerSectionReviewLabel =
      parseDiagnostics?.hasParserPossibleLowerSectionMissing == true
      ? parseDiagnostics!.lowerReceiptSectionReviewLabel
      : '';
  final photoQualityActionLabel =
      parseDiagnostics?.ocrPhotoQualityActionReviewLabel ?? '';
  final photoQualityActionInstruction =
      parseDiagnostics?.ocrPhotoQualityActionReviewInstruction ?? '';
  final receiptBrainLimitLabel =
      parseDiagnostics?.receiptBrainParserLimitSummaryLabel ?? '';
  final receiptBrainLimitAction =
      parseDiagnostics?.receiptBrainParserLimitActionLabel ?? '';
  final receiptBrainLimitColor =
      receiptBrainLimitLabel.isEmpty ||
          parseDiagnostics?.receiptBrainParserLimitOutcome ==
              'optional_receipt_brain_user_choice_required'
      ? const Color(0xFF34A9E8)
      : const Color(0xFFFFD166);
  final downstreamReadinessLabel = parseDiagnostics == null
      ? ''
      : parseDiagnostics.downstreamReadinessSummaryLabel;
  final downstreamReadinessColor =
      parseDiagnostics != null &&
          (parseDiagnostics.hasOcrDownstreamReadyStatus ||
              parseDiagnostics.hasParserDownstreamReadyStatus)
      ? const Color(0xFF8EF6A4)
      : const Color(0xFFFFD166);
  final ocrClassificationReadinessLabel =
      diagnostics?.mixedClassificationEvidenceLabel ?? '';
  final classificationReadinessLabel =
      parseDiagnostics?.receiptClassificationSummaryLabel ??
      ocrClassificationReadinessLabel;
  final classificationReadinessColor = parseDiagnostics == null
      ? diagnostics?.mixedClassificationReadinessStatus == 'ready'
            ? const Color(0xFF8EF6A4)
            : const Color(0xFFFFD166)
      : parseDiagnostics.reviewLineCount == 0 &&
            parseDiagnostics.hasMixedReceiptMathBasis
      ? const Color(0xFF8EF6A4)
      : const Color(0xFFFFD166);
  final ocrItemExpenseFamilySummaryLabel =
      parseDiagnostics?.ocrItemExpenseFamilySummaryLabel ?? '';
  final parserItemExpenseFamilySummaryLabel =
      parseDiagnostics?.parserItemExpenseFamilySummaryLabel ?? '';
  final itemFamilyReviewLabel = [
    parserItemExpenseFamilySummaryLabel,
    ocrItemExpenseFamilySummaryLabel,
  ].where((label) => label.trim().isNotEmpty).join(' | ');
  final effectiveItemFamilyReviewLabel = itemFamilyReviewLabel.isNotEmpty
      ? itemFamilyReviewLabel
      : parseDiagnostics?.mixedItemFamilyReviewLabel ?? '';
  final hasMixedItemFamilies =
      parseDiagnostics?.hasAnyMixedItemExpenseFamilies == true;
  final mixedItemFamilyNextStepLabel =
      parseDiagnostics?.mixedItemFamilyNextStepLabel ?? '';
  final mixedItemFamilyActionLabel =
      parseDiagnostics?.mixedItemFamilyReviewActionLabel ?? '';
  final itemFamilyReviewIcon = hasMixedItemFamilies
      ? Icons.call_split_rounded
      : Icons.category_rounded;
  final itemFamilyReviewColor = effectiveItemFamilyReviewLabel.isEmpty
      ? const Color(0xFF34A9E8)
      : hasMixedItemFamilies
      ? const Color(0xFFFFD166)
      : const Color(0xFF8EF6A4);
  final lineIdentityLabel =
      parseDiagnostics == null || !parseDiagnostics.hasOcrStableLineIds
      ? ''
      : parseDiagnostics.ocrLineIdentitySummaryLabel;
  final lineIdentityColor =
      parseDiagnostics != null &&
          parseDiagnostics.ocrOrderedParserReviewLineIds.isEmpty &&
          parseDiagnostics.ocrOrderedParserReadyLineIds.isNotEmpty
      ? const Color(0xFF8EF6A4)
      : const Color(0xFFFFD166);
  final hasOcrGhostContinuation =
      diagnostics?.hasOcrSourceGhostSliceContinuation == true;
  final coverageReviewLabel =
      parseDiagnostics == null ||
          (!parseDiagnostics.hasOcrSourceCoverageSignals &&
              !parseDiagnostics.hasOcrSourceContinuationSignals)
      ? hasOcrGhostContinuation
            ? 'Bottom continuation uses top ghost slice'
            : ''
      : parseDiagnostics.hasOcrSourceBottomOverlapGhostContinuation
      ? parseDiagnostics.ocrSourceContinuationReviewLabel
      : parseDiagnostics.ocrSourceCoverageReviewLabel;
  final coverageReviewColor =
      parseDiagnostics?.hasOcrSourceMissingBottomCoverageEvidence == true ||
          parseDiagnostics?.hasOcrSourceBottomOverlapGhostContinuation == true
      ? const Color(0xFFFFD166)
      : const Color(0xFF8EF6A4);
  final needsBottomSectionFirst =
      parseDiagnostics?.shouldSuggestLowerReceiptSection == true ||
      parseDiagnostics?.hasOcrSourceMissingBottomCoverageEvidence == true ||
      parseDiagnostics?.hasOcrSourceBottomOverlapGhostContinuation == true ||
      diagnostics?.receiptMayNeedBottomSection == true;
  final needsPhotoQualityAction =
      !needsBottomSectionFirst &&
      parseDiagnostics?.hasOcrPhotoQualityActionReview == true;
  final primaryNextStepLabel = needsBottomSectionFirst
      ? 'Next: add the bottom receipt section before final classification.'
      : needsPhotoQualityAction
      ? 'Next: ${parseDiagnostics!.ocrPhotoQualityActionReviewActionLabel}, then review the filled receipt details.'
      : !hasLines && hasSummarySignals
      ? 'Next: use the receipt total as Business or Personal, or add line items manually.'
      : !hasLines
      ? 'Next: add receipt lines manually or retake/add a clearer receipt photo.'
      : mixedItemFamilyNextStepLabel.isNotEmpty
      ? mixedItemFamilyNextStepLabel
      : hasReview
      ? 'Next: choose All Business, All Personal, or Mixed, then check highlighted lines.'
      : 'Next: choose All Business, All Personal, or Mixed, then save when totals look right.';
  final primaryNextStepIcon = needsBottomSectionFirst
      ? Icons.add_photo_alternate_rounded
      : needsPhotoQualityAction
      ? Icons.photo_camera_back_rounded
      : !hasLines
      ? Icons.edit_note_rounded
      : Icons.call_split_rounded;
  final primaryNextStepColor =
      needsBottomSectionFirst ||
          needsPhotoQualityAction ||
          !hasLines ||
          hasReview
      ? const Color(0xFFFFD166)
      : const Color(0xFF8EF6A4);
  final detailText = _receiptAssistedReviewDetailText(
    detailMode: detailMode,
    hasLines: hasLines,
    diagnostics: diagnostics,
    parseDiagnostics: parseDiagnostics,
    hasOcrGhostContinuation: hasOcrGhostContinuation,
    photoQualityActionInstruction: photoQualityActionInstruction,
    parserMathReviewLabel: parserMathReviewLabel,
    parserOverlapReviewLabel: parserOverlapReviewLabel,
    parserOverlapReviewInstruction: parserOverlapReviewInstruction,
    receiptBrainLimitAction: receiptBrainLimitAction,
    parserRootCauseInstruction: parserRootCauseInstruction,
    parserTaskSummaryLabel: parserTaskSummaryLabel,
    hasMixedItemFamilies: hasMixedItemFamilies,
    mixedItemFamilyActionLabel: mixedItemFamilyActionLabel,
    effectiveItemFamilyReviewLabel: effectiveItemFamilyReviewLabel,
  );
  return _ReceiptAssistedReviewGuidance(
    reviewLabel: reviewLabel,
    reviewIcon: reviewIcon,
    reviewColor: reviewColor,
    classificationLabel: classificationLabel,
    classificationIcon: classificationIcon,
    classificationColor: classificationColor,
    materialPrepLabel: materialPrepLabel,
    readyLineLabel: readyLineLabel,
    reviewLineLabel: reviewLineLabel,
    lineMapLabel: lineMapLabel,
    parserTaskSummaryLabel: parserMathReviewLabel.isNotEmpty
        ? parserMathReviewLabel
        : parserOverlapReviewLabel.isNotEmpty
        ? parserOverlapReviewLabel
        : lowerSectionReviewLabel.isNotEmpty
        ? lowerSectionReviewLabel
        : photoQualityActionLabel.isNotEmpty
        ? photoQualityActionLabel
        : parserRootCauseLabel.isNotEmpty
        ? parserRootCauseLabel
        : parserTaskSummaryLabel,
    receiptBrainLimitLabel: receiptBrainLimitLabel,
    receiptBrainLimitColor: receiptBrainLimitColor,
    downstreamReadinessLabel: downstreamReadinessLabel,
    downstreamReadinessColor: downstreamReadinessColor,
    classificationReadinessLabel: classificationReadinessLabel,
    classificationReadinessColor: classificationReadinessColor,
    itemFamilyReviewLabel: effectiveItemFamilyReviewLabel,
    itemFamilyReviewIcon: itemFamilyReviewIcon,
    itemFamilyReviewColor: itemFamilyReviewColor,
    lineIdentityLabel: lineIdentityLabel,
    lineIdentityColor: lineIdentityColor,
    coverageReviewLabel: coverageReviewLabel,
    coverageReviewColor: coverageReviewColor,
    primaryNextStepLabel: primaryNextStepLabel,
    primaryNextStepIcon: primaryNextStepIcon,
    primaryNextStepColor: primaryNextStepColor,
    fieldStatusChips: fieldStatusChips,
    detailText: detailText,
  );
}
