part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrDiagnosticsCoverage on ReceiptOcrDiagnostics {
  bool get receiptSubtotalDetected => subtotalCandidateLineCount > 0;
  bool get receiptTotalDetected => totalCandidateLineCount > 0;
  bool get receiptTotalAmountDetected =>
      subtotalCandidateLineCount > 0 ||
      totalCandidateLineCount > 0 ||
      taxCandidateLineCount > 0 ||
      ocrSummaryMathStatus != 'incomplete';

  int get receiptSummaryLineCount =>
      subtotalCandidateLineCount +
      totalCandidateLineCount +
      taxCandidateLineCount;

  String get receiptTotalsTextEvidenceStatus {
    if (!hasText) return 'no_text';
    if (totalCandidateLineCount > 0 && subtotalCandidateLineCount > 0) {
      return 'subtotal_and_total_found';
    }
    if (totalCandidateLineCount > 0) return 'total_found';
    if (subtotalCandidateLineCount > 0 || taxCandidateLineCount > 0) {
      return 'summary_partial_found';
    }
    return 'missing';
  }

  bool get receiptMayNeedBottomSection =>
      receiptTotalsTextEvidenceStatus == 'missing';

  bool get receiptMissingBottomEdgeAndTotals =>
      receiptMayNeedBottomSection && ocrSourceBottomCoverageRiskDetected;

  bool get hasOcrSourceGhostSliceContinuation =>
      (ocrSourceHandoffContract['ghostSliceAlignmentStatus']?.toString() ?? '')
          .trim()
          .isNotEmpty &&
      ocrSourceHandoffContract['ghostSliceAlignmentStatus'] != 'not_requested';

  String get ocrSourceGhostSliceAlignmentStatus {
    final value = ocrSourceHandoffContract['ghostSliceAlignmentStatus']
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) return 'not_requested';
    return value;
  }

  String get ocrSourceGhostSliceReviewInstruction {
    final value = ocrSourceHandoffContract['ghostSliceReviewInstruction']
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) return '';
    return value;
  }

  String get receiptBottomTotalsEvidenceLabel {
    if (receiptMissingBottomEdgeAndTotals) {
      return 'bottom_edge_and_totals_missing';
    }
    if (receiptMayNeedBottomSection) return 'totals_missing_edge_ok';
    if (ocrSourceBottomCoverageRiskDetected) return 'totals_ready_edge_risk';
    if (receiptTotalsTextEvidenceStatus == 'summary_partial_found') {
      return 'partial_totals_evidence';
    }
    if (receiptTotalsTextEvidenceStatus == 'no_text') return 'no_text';
    return 'totals_ready_edge_ok';
  }

  String get itemExpenseFamilyStatus {
    final value = parserHandoffContract['itemExpenseFamilyStatus']
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) return 'no_item_families';
    return value;
  }

  String get itemExpenseFamilySummaryLabel {
    final value = parserHandoffContract['itemExpenseFamilySummaryLabel']
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) return '';
    return value;
  }

  Map<String, int> get itemExpenseFamilyCounts {
    final diagnostics = parserHandoffContract['itemExpenseFamilyDiagnostics'];
    if (diagnostics is! Map) return const {};
    final counts = diagnostics['expenseFamilyCounts'];
    if (counts is! Map) return const {};
    return Map<String, int>.unmodifiable({
      for (final entry in counts.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).toInt(),
    });
  }

  bool get receiptCompletionUserConfirmedComplete =>
      (ocrSourceCompletionSignalCounts['receipt_completion_user_confirmed_complete_after_prompt'] ??
              0) >
          0 ||
      (ocrSourceCompletionSignalCounts['receipt_completion_continue_anyway'] ??
              0) >
          0 ||
      (ocrSourceCompletionSignalCounts['ocr_source_completion_continue_anyway_review'] ??
              0) >
          0;

  String get receiptCompletionReviewReasonCode {
    if (!hasText) return 'no_readable_text';
    if (receiptCompletionUserConfirmedComplete &&
        receiptMissingBottomEdgeAndTotals) {
      return 'user_confirmed_complete_missing_bottom_review';
    }
    if (receiptCompletionUserConfirmedComplete && receiptMayNeedBottomSection) {
      return 'user_confirmed_complete_totals_review';
    }
    if (receiptMissingBottomEdgeAndTotals) {
      return 'missing_bottom_edge_and_totals';
    }
    if (receiptMayNeedBottomSection) return 'possible_missing_bottom_totals';
    if (receiptTotalsTextEvidenceStatus == 'summary_partial_found') {
      return 'partial_totals_evidence';
    }
    return 'summary_evidence_present';
  }

  String get receiptCompletionReviewActionLabel {
    if (receiptCompletionUserConfirmedComplete &&
        receiptMissingBottomEdgeAndTotals) {
      return 'Review user-confirmed receipt totals';
    }
    if (receiptCompletionUserConfirmedComplete && receiptMayNeedBottomSection) {
      return 'Check user-confirmed receipt total';
    }
    if (receiptMissingBottomEdgeAndTotals) {
      return 'If the receipt continues, add another photo with the top ghost-slice guide';
    }
    if (receiptMayNeedBottomSection) {
      return 'Check bottom section or enter total manually';
    }
    if (receiptTotalsTextEvidenceStatus == 'summary_partial_found') {
      return 'Review subtotal, tax, and total';
    }
    if (!hasText) return 'Retake or enter receipt manually';
    return 'Review parsed receipt details';
  }

  String get receiptPostCaptureRouteStatus {
    if (!hasText) return 'retake_or_manual_entry';
    if (receiptCompletionUserConfirmedComplete) {
      return 'parsed_receipt_review_user_confirmed_complete';
    }
    if (receiptMissingBottomEdgeAndTotals) {
      return 'add_next_receipt_section';
    }
    if (receiptMayNeedBottomSection) return 'parsed_receipt_review_check_total';
    if (parserReadinessStatus == 'needs_vendor_review') {
      return 'parsed_receipt_review_check_vendor';
    }
    if (parserReadinessStatus == 'missing_vendor' ||
        parserReadinessStatus == 'missing_total' ||
        parserReadinessStatus == 'no_item_lines' ||
        parserReadinessStatus == 'no_parser_ready_items') {
      return 'parsed_receipt_review_manual_check';
    }
    return 'parsed_receipt_review';
  }

  String get receiptPostCaptureRouteLabel {
    return switch (receiptPostCaptureRouteStatus) {
      'retake_or_manual_entry' => 'Retake or enter receipt manually.',
      'parsed_receipt_review_user_confirmed_complete' =>
        'Continue to receipt review and check the user-confirmed totals.',
      'add_next_receipt_section' =>
        'If the receipt continues, add another photo and repeat 3-5 readable lines in the top ghost slice.',
      'parsed_receipt_review_check_total' =>
        'Continue to receipt review and check the missing total.',
      'parsed_receipt_review_check_vendor' =>
        'Continue to receipt review and check the store name.',
      'parsed_receipt_review_manual_check' =>
        'Continue to receipt review with manual field checks.',
      _ => 'Continue to parsed receipt review.',
    };
  }

  Map<String, Object?> get receiptTotalsCoverageEvidenceDiagnostics {
    return Map.unmodifiable({
      ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected:
          receiptSubtotalDetected,
      ReceiptCaptureDiagnosticKeys.receiptTotalDetected: receiptTotalDetected,
      ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected:
          receiptTotalAmountDetected,
      ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus:
          receiptTotalsTextEvidenceStatus,
      'subtotalCandidateLineCount': subtotalCandidateLineCount,
      'totalCandidateLineCount': totalCandidateLineCount,
      'taxCandidateLineCount': taxCandidateLineCount,
      'receiptSummaryLineCount': receiptSummaryLineCount,
      'receiptMayNeedBottomSection': receiptMayNeedBottomSection,
      'receiptMissingBottomEdgeAndTotals': receiptMissingBottomEdgeAndTotals,
      'receiptBottomTotalsEvidenceLabel': receiptBottomTotalsEvidenceLabel,
      'receiptCompletionUserConfirmedComplete':
          receiptCompletionUserConfirmedComplete,
      'ocrSourceBottomCoverageRiskDetected':
          ocrSourceBottomCoverageRiskDetected,
      if (ocrSourceContinuationSignalCounts.isNotEmpty)
        'ocrSourceContinuationSignalCounts': ocrSourceContinuationSignalCounts,
      if (ocrSourceHandoffContract['missingBottomTotalsEvidenceCode'] != null)
        'missingBottomTotalsEvidenceCode':
            ocrSourceHandoffContract['missingBottomTotalsEvidenceCode'],
      if (ocrSourceHandoffContract['missingBottomTotalsEvidenceLabel'] != null)
        'missingBottomTotalsEvidenceLabel':
            ocrSourceHandoffContract['missingBottomTotalsEvidenceLabel'],
      if (ocrSourceHandoffContract['missingBottomTotalsEvidenceFamilyCount'] !=
          null)
        'missingBottomTotalsEvidenceFamilyCount':
            ocrSourceHandoffContract['missingBottomTotalsEvidenceFamilyCount'],
      if (hasOcrSourceGhostSliceContinuation)
        'ocrSourceGhostSliceAlignmentStatus':
            ocrSourceGhostSliceAlignmentStatus,
      if (hasOcrSourceGhostSliceContinuation)
        'ocrSourceGhostSliceReviewInstruction':
            ocrSourceGhostSliceReviewInstruction,
      if (ocrSourceCoverageSignalCounts.isNotEmpty)
        'ocrSourceCoverageSignalCounts': ocrSourceCoverageSignalCounts,
      if (ocrSourceCompletionSignalCounts.isNotEmpty)
        'ocrSourceCompletionSignalCounts': ocrSourceCompletionSignalCounts,
      'receiptCompletionReviewReasonCode': receiptCompletionReviewReasonCode,
      'receiptCompletionReviewActionLabel': receiptCompletionReviewActionLabel,
      'receiptPostCaptureRouteStatus': receiptPostCaptureRouteStatus,
      'receiptPostCaptureRouteLabel': receiptPostCaptureRouteLabel,
      'headerRecoveryStatus': headerRecoveryStatus,
      'headerRecoveryLabel': headerRecoveryLabel,
      'headerRecoveryDiagnostics': headerRecoveryDiagnostics,
      'vendorReviewStatus': vendorReviewStatus,
      'vendorReviewLabel': vendorReviewLabel,
      'vendorReviewDiagnostics': vendorReviewDiagnostics,
      'merchantIndependentStructureStatus': merchantIndependentStructureStatus,
      'merchantIndependentStructureLabel': merchantIndependentStructureLabel,
      'merchantIndependentStructureDiagnostics':
          merchantIndependentStructureDiagnostics,
      'mixedClassificationReadinessStatus': mixedClassificationReadinessStatus,
      'mixedClassificationEvidenceLabel': mixedClassificationEvidenceLabel,
      'mixedClassificationEvidenceDiagnostics':
          mixedClassificationEvidenceDiagnostics,
    });
  }
}
