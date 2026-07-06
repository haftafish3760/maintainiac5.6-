part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryReadHandoffMetadata
    on _ExpenseReceiptEntryScreenState {
  Map<String, Object> _ocrCompletionReviewMetadata(
    ReceiptOcrDiagnostics diagnostics,
  ) {
    final sourceQualityReviewStatus = diagnostics
        .ocrSourceHandoffContract['sourceQualityReviewStatus']
        ?.toString()
        .trim();
    final sourceQualityReviewAction = diagnostics
        .ocrSourceHandoffContract['sourceQualityReviewAction']
        ?.toString()
        .trim();
    final sectionOrderReviewStatus = diagnostics
        .ocrSourceHandoffContract['sectionOrderReviewStatus']
        ?.toString()
        .trim();
    final sectionOrderFailedPairStatus = diagnostics
        .ocrSourceHandoffContract['sectionOrderFailedPairStatus']
        ?.toString()
        .trim();
    return {
      'receiptCompletionReviewReasonCode':
          diagnostics.receiptCompletionReviewReasonCode,
      'receiptCompletionReviewActionLabel':
          diagnostics.receiptCompletionReviewActionLabel,
      'receiptPostCaptureRouteStatus':
          diagnostics.receiptPostCaptureRouteStatus,
      'receiptPostCaptureRouteLabel': diagnostics.receiptPostCaptureRouteLabel,
      'receiptMayNeedBottomSection': diagnostics.receiptMayNeedBottomSection,
      'receiptMissingBottomEdgeAndTotals':
          diagnostics.receiptMissingBottomEdgeAndTotals,
      'receiptBottomTotalsEvidenceLabel':
          diagnostics.receiptBottomTotalsEvidenceLabel,
      'ocrSourceBottomCoverageRiskDetected':
          diagnostics.ocrSourceBottomCoverageRiskDetected,
      if (sourceQualityReviewStatus != null &&
          sourceQualityReviewStatus.isNotEmpty)
        'ocrSourceQualityReviewStatus': sourceQualityReviewStatus,
      if (sourceQualityReviewAction != null &&
          sourceQualityReviewAction.isNotEmpty)
        'ocrSourceQualityReviewAction': sourceQualityReviewAction,
      if (sectionOrderReviewStatus != null &&
          sectionOrderReviewStatus.isNotEmpty)
        'ocrSourceSectionOrderReviewStatus': sectionOrderReviewStatus,
      if (sectionOrderFailedPairStatus != null &&
          sectionOrderFailedPairStatus.isNotEmpty)
        'ocrSourceSectionOrderFailedPairStatus': sectionOrderFailedPairStatus,
      if (diagnostics.ocrSourceCoverageSignalCounts.isNotEmpty)
        'ocrSourceCoverageSignalCounts':
            diagnostics.ocrSourceCoverageSignalCounts,
      if (diagnostics.ocrSourceContinuationSignalCounts.isNotEmpty)
        'ocrSourceContinuationSignalCounts':
            diagnostics.ocrSourceContinuationSignalCounts,
      if (diagnostics.ocrSourceSectionOrderSignalCounts.isNotEmpty)
        'ocrSourceSectionOrderSignalCounts':
            diagnostics.ocrSourceSectionOrderSignalCounts,
      'receiptTotalsTextEvidenceStatus':
          diagnostics.receiptTotalsTextEvidenceStatus,
      'receiptSubtotalCandidateLineCount':
          diagnostics.subtotalCandidateLineCount,
      'receiptTotalCandidateLineCount': diagnostics.totalCandidateLineCount,
      'receiptTaxCandidateLineCount': diagnostics.taxCandidateLineCount,
      'receiptSummaryLineCount': diagnostics.receiptSummaryLineCount,
    };
  }
}
