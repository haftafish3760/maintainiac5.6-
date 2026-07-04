part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrDiagnostics {
  const ReceiptOcrDiagnostics({
    required this.severity,
    required this.source,
    required this.attachmentsRead,
    required this.attachmentsSkipped,
    required this.rawLineCount,
    required this.parserLineCount,
    required this.warningCount,
    required this.usedLocalOcr,
    required this.hasText,
    required this.hadDuplicateOrOverlapText,
    required this.pdfPagesRequested,
    required this.blockingWarningCount,
    required this.partialWarningCount,
    required this.reviewWarningCount,
    required this.warningKindCounts,
    required this.primaryWarningKind,
    required this.primaryWarningLabel,
    required this.primaryWarningTargetLabel,
    required this.primaryWarningTargetInstruction,
    required this.vendorCandidateLineCount,
    required this.dateCandidateLineCount,
    required this.itemCandidateLineCount,
    required this.pricedLineCount,
    required this.parserReadyLineCount,
    required this.parserReviewSignalCount,
    required this.parserReadinessStatus,
    required this.highConfidenceItemCandidateLineCount,
    required this.reviewItemCandidateLineCount,
    required this.quantitySignalItemCandidateLineCount,
    required this.skuSignalItemCandidateLineCount,
    required this.genericItemCandidateLineCount,
    required this.inventoryPrepLineCount,
    required this.parserReadyFieldCount,
    required this.parserReviewFieldCount,
    required this.parserTaskCounts,
    required this.parserHandoffContract,
    required this.ocrSourceHandoffContract,
    required this.ocrSourceHandoffStatus,
    required this.ocrSourceHandoffSignalCounts,
    required this.ocrSourceHandoffWarningProfileCounts,
    required this.ocrSourceReviewDepthSignalCounts,
    required this.ocrSourceReviewDepthStatus,
    required this.ocrSourceStitchSignalCounts,
    required this.ocrSourceScannerDecisionCounts,
    required this.ocrSourceCaptureSourceSignalCounts,
    required this.ocrSourceCoverageSignalCounts,
    required this.ocrSourceContinuationSignalCounts,
    required this.ocrSourceCompletionSignalCounts,
    required this.ocrSourcePhotoQualityRiskCounts,
    required this.ocrSourceBottomCoverageRiskDetected,
    required this.clientProofRedactionStatus,
    required this.clientProofVisibilityCounts,
    required this.fieldReadinessCounts,
    required this.requiredParserFieldStatusCounts,
    required this.requiredParserFieldStatusLabel,
    required this.headerRecoveryStatus,
    required this.headerRecoveryLabel,
    required this.headerRecoveryDiagnostics,
    required this.vendorReviewStatus,
    required this.vendorReviewLabel,
    required this.vendorReviewDiagnostics,
    required this.merchantIndependentStructureStatus,
    required this.merchantIndependentStructureLabel,
    required this.merchantIndependentStructureDiagnostics,
    required this.mixedClassificationReadinessStatus,
    required this.mixedClassificationEvidenceLabel,
    required this.mixedClassificationEvidenceDiagnostics,
    required this.parserLineRoleCounts,
    required this.dominantParserLineRole,
    required this.ocrSummaryMathStatus,
    required this.ocrSummaryMathReconciled,
    required this.ocrLineSequenceStatus,
    required this.ocrSourceSectionContinuityStatus,
    required this.ocrSourceSectionCount,
    required this.ocrSourceSectionContinuityReviewNeeded,
    required this.ocrReceiptStructureStatus,
    required this.priceCandidateLineCount,
    required this.subtotalCandidateLineCount,
    required this.totalCandidateLineCount,
    required this.taxCandidateLineCount,
    required this.tenderCandidateLineCount,
    required this.metadataCandidateLineCount,
  });

  factory ReceiptOcrDiagnostics.fromResult(ReceiptOcrResult result) =>
      _receiptOcrDiagnosticsFromResult(result);

  final ReceiptOcrReviewSeverity severity;
  final ReceiptProcessingSource source;
  final int attachmentsRead;
  final int attachmentsSkipped;
  final int rawLineCount;
  final int parserLineCount;
  final int warningCount;
  final bool usedLocalOcr;
  final bool hasText;
  final bool hadDuplicateOrOverlapText;
  final int pdfPagesRequested;
  final int blockingWarningCount;
  final int partialWarningCount;
  final int reviewWarningCount;
  final Map<ReceiptOcrWarningKind, int> warningKindCounts;
  final String primaryWarningKind;
  final String primaryWarningLabel;
  final String primaryWarningTargetLabel;
  final String primaryWarningTargetInstruction;
  final int vendorCandidateLineCount;
  final int dateCandidateLineCount;
  final int itemCandidateLineCount;
  final int pricedLineCount;
  final int parserReadyLineCount;
  final int parserReviewSignalCount;
  final String parserReadinessStatus;
  final int highConfidenceItemCandidateLineCount;
  final int reviewItemCandidateLineCount;
  final int quantitySignalItemCandidateLineCount;
  final int skuSignalItemCandidateLineCount;
  final int genericItemCandidateLineCount;
  final int inventoryPrepLineCount;
  final int parserReadyFieldCount;
  final int parserReviewFieldCount;
  final Map<String, int> parserTaskCounts;
  final Map<String, Object?> parserHandoffContract;
  final Map<String, Object?> ocrSourceHandoffContract;
  final String ocrSourceHandoffStatus;
  final Map<String, int> ocrSourceHandoffSignalCounts;
  final Map<String, int> ocrSourceHandoffWarningProfileCounts;
  final Map<String, int> ocrSourceReviewDepthSignalCounts;
  final String ocrSourceReviewDepthStatus;
  final Map<String, int> ocrSourceStitchSignalCounts;
  final Map<String, int> ocrSourceScannerDecisionCounts;
  final Map<String, int> ocrSourceCaptureSourceSignalCounts;
  final Map<String, int> ocrSourceCoverageSignalCounts;
  final Map<String, int> ocrSourceContinuationSignalCounts;
  final Map<String, int> ocrSourceCompletionSignalCounts;
  final Map<String, int> ocrSourcePhotoQualityRiskCounts;
  final bool ocrSourceBottomCoverageRiskDetected;
  final String clientProofRedactionStatus;
  final Map<String, int> clientProofVisibilityCounts;
  final Map<String, int> fieldReadinessCounts;
  final Map<String, int> requiredParserFieldStatusCounts;
  final String requiredParserFieldStatusLabel;
  final String headerRecoveryStatus;
  final String headerRecoveryLabel;
  final Map<String, Object?> headerRecoveryDiagnostics;
  final String vendorReviewStatus;
  final String vendorReviewLabel;
  final Map<String, Object?> vendorReviewDiagnostics;
  final String merchantIndependentStructureStatus;
  final String merchantIndependentStructureLabel;
  final Map<String, Object?> merchantIndependentStructureDiagnostics;
  final String mixedClassificationReadinessStatus;
  final String mixedClassificationEvidenceLabel;
  final Map<String, Object?> mixedClassificationEvidenceDiagnostics;
  final Map<String, int> parserLineRoleCounts;
  final String dominantParserLineRole;
  final String ocrSummaryMathStatus;
  final bool ocrSummaryMathReconciled;
  final String ocrLineSequenceStatus;
  final String ocrSourceSectionContinuityStatus;
  final int ocrSourceSectionCount;
  final bool ocrSourceSectionContinuityReviewNeeded;
  final String ocrReceiptStructureStatus;
  final int priceCandidateLineCount;
  final int subtotalCandidateLineCount;
  final int totalCandidateLineCount;
  final int taxCandidateLineCount;
  final int tenderCandidateLineCount;
  final int metadataCandidateLineCount;
}
