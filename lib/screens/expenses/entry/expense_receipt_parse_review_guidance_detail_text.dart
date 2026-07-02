part of 'expense_receipt_entry_screen.dart';

String _receiptAssistedReviewDetailText({
  required _ReceiptDetailEntryMode detailMode,
  required bool hasLines,
  required ReceiptOcrDiagnostics? diagnostics,
  required ExpenseReceiptParseDiagnostics? parseDiagnostics,
  required bool hasOcrGhostContinuation,
  required String photoQualityActionInstruction,
  required String parserMathReviewLabel,
  required String parserOverlapReviewLabel,
  required String parserOverlapReviewInstruction,
  required String receiptBrainLimitAction,
  required String parserRootCauseInstruction,
  required String parserTaskSummaryLabel,
  required bool hasMixedItemFamilies,
  required String mixedItemFamilyActionLabel,
  required String effectiveItemFamilyReviewLabel,
}) {
  final continueReviewInstruction =
      detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Then continue with price-first Business, Personal, or Mixed review.'
      : 'Then continue with detailed line-by-line receipt review.';
  final simpleReviewInstruction =
      detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Simple review shows prices first for fast Business, Personal, or '
            'Mixed classification.'
      : 'Detailed review keeps descriptions, prices, tax, and totals visible '
            'for line-by-line checking.';
  final simpleOverlapReviewInstruction =
      detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Simple review still shows prices first for fast Business, Personal, '
            'or Mixed classification.'
      : 'Detailed review keeps the repeated lines visible so duplicates are not counted twice.';
  final simpleBrainLimitInstruction =
      detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Simple review still shows prices first for fast Business, Personal, '
            'or Mixed classification.'
      : 'Detailed review keeps available descriptions, prices, tax, and totals '
            'visible for checking.';
  if (!hasLines && receiptBrainLimitAction.isNotEmpty) {
    return '$receiptBrainLimitAction The saved proof is still kept, and the receipt can be filled manually or with core fields.';
  }
  if (parseDiagnostics?.hasOcrSourceBottomOverlapGhostContinuation == true) {
    return '${parseDiagnostics!.ocrSourceContinuationReviewInstruction} '
        '$continueReviewInstruction';
  }
  if (hasOcrGhostContinuation) {
    return '${diagnostics!.ocrSourceGhostSliceReviewInstruction} '
        '$continueReviewInstruction';
  }
  if (parseDiagnostics?.hasOcrSourceMissingBottomCoverageEvidence == true) {
    return '${parseDiagnostics!.ocrSourceCoverageReviewInstruction} '
        '$continueReviewInstruction';
  }
  if (parseDiagnostics?.shouldSuggestLowerReceiptSection == true) {
    return '${parseDiagnostics!.lowerReceiptSectionReviewInstruction} '
        '$continueReviewInstruction';
  }
  if (photoQualityActionInstruction.isNotEmpty) {
    return '$photoQualityActionInstruction $continueReviewInstruction';
  }
  if (!hasLines) {
    return 'The app did not build safe line items. Use the receipt total if that is enough, add lines manually, or retake/add a clearer photo.';
  }
  if (parserMathReviewLabel.isNotEmpty) {
    return '$parserMathReviewLabel. $simpleReviewInstruction';
  }
  if (parserOverlapReviewLabel.isNotEmpty) {
    final overlapInstruction = parserOverlapReviewInstruction.isEmpty
        ? '$parserOverlapReviewLabel before saving.'
        : parserOverlapReviewInstruction;
    return '$overlapInstruction $simpleOverlapReviewInstruction';
  }
  if (receiptBrainLimitAction.isNotEmpty) {
    return '$receiptBrainLimitAction $simpleBrainLimitInstruction';
  }
  if (parserRootCauseInstruction.isNotEmpty) {
    return '$parserRootCauseInstruction $simpleReviewInstruction';
  }
  if (parserTaskSummaryLabel.isNotEmpty) {
    return '$parserTaskSummaryLabel. $simpleReviewInstruction';
  }
  if (hasMixedItemFamilies) {
    return mixedItemFamilyActionLabel.isNotEmpty
        ? mixedItemFamilyActionLabel
        : 'The receipt has more than one local item family. Use Mixed if any lines belong to different business or personal purposes.';
  }
  if (effectiveItemFamilyReviewLabel.isNotEmpty) {
    return '$effectiveItemFamilyReviewLabel. Review whether the whole receipt is Business, Personal, or Mixed before saving.';
  }
  return detailMode == _ReceiptDetailEntryMode.quickClassify
      ? 'Simple review shows prices first for fast Business, Personal, or Mixed classification. Switch to detailed review if item descriptions matter.'
      : 'Detailed review keeps descriptions, prices, tax, and totals visible so each line can be checked before Business, Personal, or Mixed classification.';
}
