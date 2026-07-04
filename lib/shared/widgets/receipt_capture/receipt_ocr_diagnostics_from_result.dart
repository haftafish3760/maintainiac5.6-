part of '../../receipts/receipt_ocr_contract.dart';

ReceiptOcrDiagnostics _receiptOcrDiagnosticsFromResult(
  ReceiptOcrResult result,
) {
  final rawLineCount = _countReceiptTextLines(result.rawText);
  final parserLineCount = _countReceiptTextLines(result.parserText);
  final structuredWarnings = result.structuredWarnings;
  final duplicateOrOverlap = structuredWarnings.any(
    (warning) =>
        warning.kind == ReceiptOcrWarningKind.duplicateText ||
        warning.kind == ReceiptOcrWarningKind.probableOverlap ||
        warning.kind == ReceiptOcrWarningKind.sectionGap,
  );
  final severity = _severityFor(
    hasText: result.hasText,
    warnings: structuredWarnings,
    stats: result.stats,
    duplicateOrOverlap: duplicateOrOverlap,
  );
  final primaryWarning = result.primaryWarning;
  final parserTaskCounts = _parserTaskCountsWithReceiptCoverage(
    _parserTaskCountsWithWarnings(
      result.parserHandoff.parserTaskCounts,
      structuredWarnings,
    ),
    result,
  );
  return ReceiptOcrDiagnostics(
    severity: severity,
    source: result.source,
    attachmentsRead: result.stats.attachmentsRead,
    attachmentsSkipped: result.stats.attachmentsSkipped,
    rawLineCount: rawLineCount,
    parserLineCount: parserLineCount,
    warningCount: result.warnings.length,
    usedLocalOcr: result.stats.usedLocalOcr,
    hasText: result.hasText,
    hadDuplicateOrOverlapText: duplicateOrOverlap,
    pdfPagesRequested: result.stats.pdfPagesRequested,
    blockingWarningCount: structuredWarnings
        .where((warning) => warning.isBlocking)
        .length,
    partialWarningCount: structuredWarnings
        .where((warning) => warning.isPartial)
        .length,
    reviewWarningCount: structuredWarnings
        .where((warning) => warning.needsReview)
        .length,
    warningKindCounts: Map.unmodifiable(_warningKindCounts(structuredWarnings)),
    primaryWarningKind: primaryWarning?.kind.name ?? '',
    primaryWarningLabel: primaryWarning?.label ?? '',
    primaryWarningTargetLabel: primaryWarning?.reviewTargetLabel ?? '',
    primaryWarningTargetInstruction:
        primaryWarning?.reviewTargetInstruction ?? '',
    vendorCandidateLineCount: result.vendorCandidateLines.length,
    dateCandidateLineCount: result.dateCandidateLines.length,
    itemCandidateLineCount: result.itemCandidateLines.length,
    pricedLineCount: result.parserHandoff.pricedLineCount,
    parserReadyLineCount: result.parserHandoff.parserReadyLineCount,
    parserReviewSignalCount: result.parserHandoff.parserReviewSignalCount,
    parserReadinessStatus: result.parserHandoff.parserReadinessStatus,
    highConfidenceItemCandidateLineCount:
        result.parserHandoff.highConfidenceItemLineCount,
    reviewItemCandidateLineCount: result.parserHandoff.reviewItemLineCount,
    quantitySignalItemCandidateLineCount:
        result.parserHandoff.quantitySignalItemLineCount,
    skuSignalItemCandidateLineCount:
        result.parserHandoff.skuSignalItemLineCount,
    genericItemCandidateLineCount: result.parserHandoff.genericItemLineCount,
    inventoryPrepLineCount: result.parserHandoff.inventoryPrepLineCount,
    parserReadyFieldCount: result.parserHandoff.parserReadyFieldCount,
    parserReviewFieldCount: result.parserHandoff.parserReviewFieldCount,
    parserTaskCounts: parserTaskCounts,
    parserHandoffContract:
        result.parserHandoff.privacySafeParserHandoffContract,
    ocrSourceHandoffContract: result.sourceHandoffSummary.privacySafeContract,
    ocrSourceHandoffStatus: result.sourceHandoffSummary.status,
    ocrSourceHandoffSignalCounts:
        result.sourceHandoffSummary.handoffSignalCounts,
    ocrSourceHandoffWarningProfileCounts:
        result.sourceHandoffSummary.handoffWarningProfileCounts,
    ocrSourceReviewDepthSignalCounts:
        result.sourceHandoffSummary.reviewDepthSignalCounts,
    ocrSourceReviewDepthStatus: result.sourceHandoffSummary.reviewDepthStatus,
    ocrSourceStitchSignalCounts: result.sourceHandoffSummary.stitchSignalCounts,
    ocrSourceScannerDecisionCounts:
        result.sourceHandoffSummary.scannerDecisionCounts,
    ocrSourceCaptureSourceSignalCounts:
        result.sourceHandoffSummary.captureSourceSignalCounts,
    ocrSourceCoverageSignalCounts:
        result.sourceHandoffSummary.coverageSignalCounts,
    ocrSourceContinuationSignalCounts:
        result.sourceHandoffSummary.continuationSignalCounts,
    ocrSourceCompletionSignalCounts:
        result.sourceHandoffSummary.completionSignalCounts,
    ocrSourcePhotoQualityRiskCounts:
        result.sourceHandoffSummary.photoQualityRiskCounts,
    ocrSourceBottomCoverageRiskDetected:
        result.sourceHandoffSummary.hasMissingBottomEdgeAndTotalsEvidence,
    clientProofRedactionStatus: result.parserHandoff.clientProofRedactionStatus,
    clientProofVisibilityCounts:
        result.parserHandoff.clientProofVisibilityCounts,
    fieldReadinessCounts: result.parserHandoff.fieldReadinessCounts,
    requiredParserFieldStatusCounts:
        result.parserHandoff.requiredParserFieldStatusCounts,
    requiredParserFieldStatusLabel:
        result.parserHandoff.requiredParserFieldStatusLabel,
    headerRecoveryStatus: result.parserHandoff.headerRecoveryStatus,
    headerRecoveryLabel: result.parserHandoff.headerRecoveryLabel,
    headerRecoveryDiagnostics: result.parserHandoff.headerRecoveryDiagnostics,
    vendorReviewStatus: result.parserHandoff.vendorReviewStatus,
    vendorReviewLabel: result.parserHandoff.vendorReviewLabel,
    vendorReviewDiagnostics: result.parserHandoff.vendorReviewDiagnostics,
    merchantIndependentStructureStatus:
        result.parserHandoff.merchantIndependentStructureStatus,
    merchantIndependentStructureLabel:
        result.parserHandoff.merchantIndependentStructureLabel,
    merchantIndependentStructureDiagnostics:
        result.parserHandoff.merchantIndependentStructureDiagnostics,
    mixedClassificationReadinessStatus:
        result.parserHandoff.mixedClassificationReadinessStatus,
    mixedClassificationEvidenceLabel:
        result.parserHandoff.mixedClassificationEvidenceLabel,
    mixedClassificationEvidenceDiagnostics:
        result.parserHandoff.mixedClassificationEvidenceDiagnostics,
    parserLineRoleCounts: result.parserHandoff.lineRoleCounts,
    dominantParserLineRole: result.parserHandoff.dominantLineRole,
    ocrSummaryMathStatus: result.parserHandoff.summaryMathStatus,
    ocrSummaryMathReconciled: result.parserHandoff.summaryMathReconciled,
    ocrLineSequenceStatus: result.parserHandoff.lineSequenceStatus,
    ocrSourceSectionContinuityStatus:
        result.parserHandoff.sourceSectionContinuityStatus,
    ocrSourceSectionCount: result.parserHandoff.sourceSectionCount,
    ocrSourceSectionContinuityReviewNeeded:
        result.parserHandoff.needsSourceSectionContinuityReview,
    ocrReceiptStructureStatus: result.parserHandoff.receiptStructureStatus,
    priceCandidateLineCount: result.priceCandidateLines.length,
    subtotalCandidateLineCount: result.subtotalCandidateLines.length,
    totalCandidateLineCount: result.totalCandidateLines.length,
    taxCandidateLineCount: result.taxCandidateLines.length,
    tenderCandidateLineCount: result.tenderCandidateLines.length,
    metadataCandidateLineCount: result.metadataCandidateLines.length,
  );
}
