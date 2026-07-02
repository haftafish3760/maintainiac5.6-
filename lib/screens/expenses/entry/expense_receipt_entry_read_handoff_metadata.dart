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
      if (diagnostics.ocrSourceCoverageSignalCounts.isNotEmpty)
        'ocrSourceCoverageSignalCounts':
            diagnostics.ocrSourceCoverageSignalCounts,
      if (diagnostics.ocrSourceContinuationSignalCounts.isNotEmpty)
        'ocrSourceContinuationSignalCounts':
            diagnostics.ocrSourceContinuationSignalCounts,
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
