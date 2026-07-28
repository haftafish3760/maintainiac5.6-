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
  // Parser-line analysis is the expensive part of diagnostics. Build it once
  // per result and reuse it instead of reconstructing every OCR line dozens
  // of times through repeated computed getters.
  final parserHandoff = result.parserHandoff;
  final parserTaskCounts = _parserTaskCountsWithReceiptCoverage(
    _parserTaskCountsWithWarnings(
      parserHandoff.parserTaskCounts,
      structuredWarnings,
    ),
    result,
    parserHandoff,
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
    vendorCandidateLineCount: parserHandoff.vendorLines.length,
    dateCandidateLineCount: parserHandoff.dateLines.length,
    itemCandidateLineCount: parserHandoff.itemLines.length,
    pricedLineCount: parserHandoff.pricedLineCount,
    parserReadyLineCount: parserHandoff.parserReadyLineCount,
    parserReviewSignalCount: parserHandoff.parserReviewSignalCount,
    parserReadinessStatus: parserHandoff.parserReadinessStatus,
    highConfidenceItemCandidateLineCount:
        parserHandoff.highConfidenceItemLineCount,
    reviewItemCandidateLineCount: parserHandoff.reviewItemLineCount,
    quantitySignalItemCandidateLineCount:
        parserHandoff.quantitySignalItemLineCount,
    skuSignalItemCandidateLineCount: parserHandoff.skuSignalItemLineCount,
    genericItemCandidateLineCount: parserHandoff.genericItemLineCount,
    inventoryPrepLineCount: parserHandoff.inventoryPrepLineCount,
    parserReadyFieldCount: parserHandoff.parserReadyFieldCount,
    parserReviewFieldCount: parserHandoff.parserReviewFieldCount,
    parserTaskCounts: parserTaskCounts,
    parserHandoffContract: parserHandoff.privacySafeParserHandoffContract,
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
    ocrSourceSectionOrderSignalCounts:
        result.sourceHandoffSummary.sectionOrderSignalCounts,
    ocrSourcePhotoQualityRiskCounts:
        result.sourceHandoffSummary.photoQualityRiskCounts,
    ocrSourceBottomCoverageRiskDetected:
        result.sourceHandoffSummary.hasMissingBottomEdgeAndTotalsEvidence,
    clientProofRedactionStatus: parserHandoff.clientProofRedactionStatus,
    clientProofVisibilityCounts: parserHandoff.clientProofVisibilityCounts,
    fieldReadinessCounts: parserHandoff.fieldReadinessCounts,
    requiredParserFieldStatusCounts:
        parserHandoff.requiredParserFieldStatusCounts,
    requiredParserFieldStatusLabel:
        parserHandoff.requiredParserFieldStatusLabel,
    headerRecoveryStatus: parserHandoff.headerRecoveryStatus,
    headerRecoveryLabel: parserHandoff.headerRecoveryLabel,
    headerRecoveryDiagnostics: parserHandoff.headerRecoveryDiagnostics,
    vendorReviewStatus: parserHandoff.vendorReviewStatus,
    vendorReviewLabel: parserHandoff.vendorReviewLabel,
    vendorReviewDiagnostics: parserHandoff.vendorReviewDiagnostics,
    merchantIndependentStructureStatus:
        parserHandoff.merchantIndependentStructureStatus,
    merchantIndependentStructureLabel:
        parserHandoff.merchantIndependentStructureLabel,
    merchantIndependentStructureDiagnostics:
        parserHandoff.merchantIndependentStructureDiagnostics,
    mixedClassificationReadinessStatus:
        parserHandoff.mixedClassificationReadinessStatus,
    mixedClassificationEvidenceLabel:
        parserHandoff.mixedClassificationEvidenceLabel,
    mixedClassificationEvidenceDiagnostics:
        parserHandoff.mixedClassificationEvidenceDiagnostics,
    parserLineRoleCounts: parserHandoff.lineRoleCounts,
    dominantParserLineRole: parserHandoff.dominantLineRole,
    ocrSummaryMathStatus: parserHandoff.summaryMathStatus,
    ocrSummaryMathReconciled: parserHandoff.summaryMathReconciled,
    ocrLineSequenceStatus: parserHandoff.lineSequenceStatus,
    ocrSourceSectionContinuityStatus:
        parserHandoff.sourceSectionContinuityStatus,
    ocrSourceSectionCount: parserHandoff.sourceSectionCount,
    ocrSourceSectionContinuityReviewNeeded:
        parserHandoff.needsSourceSectionContinuityReview,
    ocrReceiptStructureStatus: parserHandoff.receiptStructureStatus,
    priceCandidateLineCount: parserHandoff.pricedLineCount,
    subtotalCandidateLineCount: parserHandoff.lines
        .where(
          (line) => line.kind == ReceiptOcrParserLineKind.subtotalCandidate,
        )
        .length,
    totalCandidateLineCount: parserHandoff.lines
        .where((line) => line.kind == ReceiptOcrParserLineKind.totalCandidate)
        .length,
    taxCandidateLineCount: parserHandoff.lines
        .where((line) => line.kind == ReceiptOcrParserLineKind.taxCandidate)
        .length,
    tenderCandidateLineCount: parserHandoff.tenderLines.length,
    metadataCandidateLineCount: parserHandoff.metadataLines.length,
  );
}
