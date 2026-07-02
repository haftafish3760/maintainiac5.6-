part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsCopy on ExpenseReceiptParseDiagnostics {
  ExpenseReceiptParseDiagnostics copyWith({
    Map<String, ExpenseReceiptFieldConfidence>? fieldConfidences,
    Map<String, int>? parserLineRoleCounts,
    Map<String, int>? parserTaskCounts,
    List<String>? parserDuplicateOverlapSourceLabels,
    List<String>? parserDuplicateOverlapWindowLabels,
    List<String>? parserDuplicateOverlapConfidenceLabels,
    Map<String, int>? parserCategoryCounts,
    Map<String, int>? parserCategoryHealthCounts,
    String? parserItemExpenseFamilyStatus,
    String? parserItemExpenseFamilySummaryLabel,
    Map<String, int>? parserItemExpenseFamilyCounts,
    Map<String, int>? parserRequiredFieldStatusCounts,
    String? parserRequiredFieldStatusLabel,
    String? parserDownstreamReadinessStatus,
    Map<String, int>? parserDownstreamReadinessCounts,
    int? ocrParserLineCount,
    int? ocrItemCandidateLineCount,
    int? ocrPricedLineCount,
    int? ocrParserReadyLineCount,
    int? ocrParserReviewSignalCount,
    String? ocrParserReadinessStatus,
    String? ocrDownstreamReadinessStatus,
    Map<String, int>? ocrDownstreamReadinessCounts,
    String? ocrLeanLocalReadinessStatus,
    Map<String, int>? ocrLeanLocalReadinessCounts,
    String? ocrLeanLocalReadinessLabel,
    int? ocrHighConfidenceItemLineCount,
    int? ocrReviewItemLineCount,
    int? ocrQuantitySignalItemLineCount,
    int? ocrSkuSignalItemLineCount,
    int? ocrGenericItemLineCount,
    int? ocrInventoryPrepLineIdCount,
    int? ocrParserReadyFieldCount,
    int? ocrParserReviewFieldCount,
    String? ocrSummaryMathStatus,
    bool? ocrSummaryMathReconciled,
    String? ocrLineSequenceStatus,
    String? ocrSourceSectionContinuityStatus,
    int? ocrSourceSectionCount,
    bool? ocrSourceSectionContinuityReviewNeeded,
    String? ocrReceiptStructureStatus,
    int? ocrSubtotalCandidateLineCount,
    int? ocrTaxCandidateLineCount,
    int? ocrTotalCandidateLineCount,
    int? ocrTenderCandidateLineCount,
    int? ocrMetadataCandidateLineCount,
    Map<String, int>? ocrParserLineRoleCounts,
    String? ocrDominantParserLineRole,
    int? ocrStableLineIdCount,
    int? ocrParserReadyItemLineIdCount,
    int? ocrReviewItemLineIdCount,
    Map<String, List<String>>? ocrLineIdsByRole,
    Map<String, String>? ocrRoleByLineId,
    Map<String, String>? ocrParserBucketByLineId,
    List<String>? ocrOrderedParserReadyLineIds,
    List<String>? ocrOrderedParserReviewLineIds,
    Map<String, int>? ocrParserBucketCounts,
    Map<String, int>? ocrParserTaskCounts,
    String? ocrItemExpenseFamilyStatus,
    String? ocrItemExpenseFamilySummaryLabel,
    Map<String, int>? ocrItemExpenseFamilyCounts,
    String? ocrSourceHandoffStatus,
    Map<String, int>? ocrSourceHandoffSignalCounts,
    Map<String, int>? ocrSourceStitchSignalCounts,
    Map<String, int>? ocrSourceScannerDecisionCounts,
    Map<String, int>? ocrSourceCaptureSourceSignalCounts,
    Map<String, int>? ocrSourceCoverageSignalCounts,
    Map<String, int>? ocrSourceContinuationSignalCounts,
    Map<String, int>? ocrSourcePhotoQualityRiskCounts,
    String? ocrSourceQualityReviewStatus,
    String? ocrSourceQualityReviewAction,
    String? missingBottomTotalsEvidenceCode,
    String? missingBottomTotalsEvidenceLabel,
    int? missingBottomTotalsEvidenceFamilyCount,
    Map<String, int>? receiptBrainLowStorageDownloadRiskCounts,
    Map<String, int>? receiptBrainFullOfflineMustStayOptionalCounts,
    Map<String, int>? receiptBrainFullOfflineExceedsBaseGuardrailCounts,
    Map<String, int>? receiptInstallRequiredSegmentCounts,
    Map<String, int>? receiptInstallFullOfflineSegmentCounts,
    Map<String, int>? receiptInstallLowStorageImpactCounts,
    Map<String, int>? receiptInstallRecommendedDistributionCounts,
    Map<String, int>? receiptInstallCameraShellParserFreeCounts,
    Map<String, int>? receiptInstallBaseUsefulOnTinyPhonesCounts,
    Map<String, int>? receiptInstallOptionalPacksRequireConsentCounts,
    String? genericReceiptStructureStatus,
    String? genericReceiptStructureSummary,
    Map<String, int>? genericReceiptZoneCounts,
    Map<String, int>? genericReceiptSignalCounts,
    List<int>? genericReceiptParserLineNumbers,
    List<int>? genericReceiptClientProofLineNumbers,
    int? genericReceiptRedactionAnchorCount,
    String? clientProofRedactionStatus,
    Map<String, int>? clientProofVisibilityCounts,
    Map<String, int>? ocrFieldReadinessCounts,
    Map<String, int>? ocrRequiredFieldStatusCounts,
    String? ocrRequiredFieldStatusLabel,
  }) {
    return ExpenseReceiptParseDiagnostics(
      parserDepth: parserDepth,
      maxCatalogCandidates: maxCatalogCandidates,
      detectedLineCount: detectedLineCount,
      reviewLineCount: reviewLineCount,
      catalogMatchedLineCount: catalogMatchedLineCount,
      materialLineCount: materialLineCount,
      unmatchedMaterialLineCount: unmatchedMaterialLineCount,
      negativeLineCount: negativeLineCount,
      adjustmentLineCount: adjustmentLineCount,
      lineSubtotal: lineSubtotal,
      expectedSubtotalOrTotal: expectedSubtotalOrTotal,
      reconciliationDifference: reconciliationDifference,
      taxMathDifference: taxMathDifference,
      reconciled: reconciled,
      taxMathReconciled: taxMathReconciled,
      hasExplicitSubtotal: hasExplicitSubtotal,
      hasExplicitTax: hasExplicitTax,
      hasExplicitTotal: hasExplicitTotal,
      parserLineRoleCounts: parserLineRoleCounts ?? this.parserLineRoleCounts,
      parserTaskCounts: parserTaskCounts ?? this.parserTaskCounts,
      parserDuplicateOverlapSourceLabels:
          parserDuplicateOverlapSourceLabels ??
          this.parserDuplicateOverlapSourceLabels,
      parserDuplicateOverlapWindowLabels:
          parserDuplicateOverlapWindowLabels ??
          this.parserDuplicateOverlapWindowLabels,
      parserDuplicateOverlapConfidenceLabels:
          parserDuplicateOverlapConfidenceLabels ??
          this.parserDuplicateOverlapConfidenceLabels,
      parserCategoryCounts: parserCategoryCounts ?? this.parserCategoryCounts,
      parserCategoryHealthCounts:
          parserCategoryHealthCounts ?? this.parserCategoryHealthCounts,
      parserItemExpenseFamilyStatus:
          parserItemExpenseFamilyStatus ?? this.parserItemExpenseFamilyStatus,
      parserItemExpenseFamilySummaryLabel:
          parserItemExpenseFamilySummaryLabel ??
          this.parserItemExpenseFamilySummaryLabel,
      parserItemExpenseFamilyCounts:
          parserItemExpenseFamilyCounts ?? this.parserItemExpenseFamilyCounts,
      parserRequiredFieldStatusCounts:
          parserRequiredFieldStatusCounts ??
          this.parserRequiredFieldStatusCounts,
      parserRequiredFieldStatusLabel:
          parserRequiredFieldStatusLabel ?? this.parserRequiredFieldStatusLabel,
      parserDownstreamReadinessStatus:
          parserDownstreamReadinessStatus ??
          this.parserDownstreamReadinessStatus,
      parserDownstreamReadinessCounts:
          parserDownstreamReadinessCounts ??
          this.parserDownstreamReadinessCounts,
      ocrParserLineCount: ocrParserLineCount ?? this.ocrParserLineCount,
      ocrItemCandidateLineCount:
          ocrItemCandidateLineCount ?? this.ocrItemCandidateLineCount,
      ocrPricedLineCount: ocrPricedLineCount ?? this.ocrPricedLineCount,
      ocrParserReadyLineCount:
          ocrParserReadyLineCount ?? this.ocrParserReadyLineCount,
      ocrParserReviewSignalCount:
          ocrParserReviewSignalCount ?? this.ocrParserReviewSignalCount,
      ocrParserReadinessStatus:
          ocrParserReadinessStatus ?? this.ocrParserReadinessStatus,
      ocrDownstreamReadinessStatus:
          ocrDownstreamReadinessStatus ?? this.ocrDownstreamReadinessStatus,
      ocrDownstreamReadinessCounts:
          ocrDownstreamReadinessCounts ?? this.ocrDownstreamReadinessCounts,
      ocrLeanLocalReadinessStatus:
          ocrLeanLocalReadinessStatus ?? this.ocrLeanLocalReadinessStatus,
      ocrLeanLocalReadinessCounts:
          ocrLeanLocalReadinessCounts ?? this.ocrLeanLocalReadinessCounts,
      ocrLeanLocalReadinessLabel:
          ocrLeanLocalReadinessLabel ?? this.ocrLeanLocalReadinessLabel,
      ocrHighConfidenceItemLineCount:
          ocrHighConfidenceItemLineCount ?? this.ocrHighConfidenceItemLineCount,
      ocrReviewItemLineCount:
          ocrReviewItemLineCount ?? this.ocrReviewItemLineCount,
      ocrQuantitySignalItemLineCount:
          ocrQuantitySignalItemLineCount ?? this.ocrQuantitySignalItemLineCount,
      ocrSkuSignalItemLineCount:
          ocrSkuSignalItemLineCount ?? this.ocrSkuSignalItemLineCount,
      ocrGenericItemLineCount:
          ocrGenericItemLineCount ?? this.ocrGenericItemLineCount,
      ocrInventoryPrepLineIdCount:
          ocrInventoryPrepLineIdCount ?? this.ocrInventoryPrepLineIdCount,
      ocrParserReadyFieldCount:
          ocrParserReadyFieldCount ?? this.ocrParserReadyFieldCount,
      ocrParserReviewFieldCount:
          ocrParserReviewFieldCount ?? this.ocrParserReviewFieldCount,
      ocrSummaryMathStatus: ocrSummaryMathStatus ?? this.ocrSummaryMathStatus,
      ocrSummaryMathReconciled:
          ocrSummaryMathReconciled ?? this.ocrSummaryMathReconciled,
      ocrLineSequenceStatus:
          ocrLineSequenceStatus ?? this.ocrLineSequenceStatus,
      ocrSourceSectionContinuityStatus:
          ocrSourceSectionContinuityStatus ??
          this.ocrSourceSectionContinuityStatus,
      ocrSourceSectionCount:
          ocrSourceSectionCount ?? this.ocrSourceSectionCount,
      ocrSourceSectionContinuityReviewNeeded:
          ocrSourceSectionContinuityReviewNeeded ??
          this.ocrSourceSectionContinuityReviewNeeded,
      ocrReceiptStructureStatus:
          ocrReceiptStructureStatus ?? this.ocrReceiptStructureStatus,
      ocrSubtotalCandidateLineCount:
          ocrSubtotalCandidateLineCount ?? this.ocrSubtotalCandidateLineCount,
      ocrTaxCandidateLineCount:
          ocrTaxCandidateLineCount ?? this.ocrTaxCandidateLineCount,
      ocrTotalCandidateLineCount:
          ocrTotalCandidateLineCount ?? this.ocrTotalCandidateLineCount,
      ocrTenderCandidateLineCount:
          ocrTenderCandidateLineCount ?? this.ocrTenderCandidateLineCount,
      ocrMetadataCandidateLineCount:
          ocrMetadataCandidateLineCount ?? this.ocrMetadataCandidateLineCount,
      ocrParserLineRoleCounts:
          ocrParserLineRoleCounts ?? this.ocrParserLineRoleCounts,
      ocrDominantParserLineRole:
          ocrDominantParserLineRole ?? this.ocrDominantParserLineRole,
      ocrStableLineIdCount: ocrStableLineIdCount ?? this.ocrStableLineIdCount,
      ocrParserReadyItemLineIdCount:
          ocrParserReadyItemLineIdCount ?? this.ocrParserReadyItemLineIdCount,
      ocrReviewItemLineIdCount:
          ocrReviewItemLineIdCount ?? this.ocrReviewItemLineIdCount,
      ocrLineIdsByRole: ocrLineIdsByRole ?? this.ocrLineIdsByRole,
      ocrRoleByLineId: ocrRoleByLineId ?? this.ocrRoleByLineId,
      ocrParserBucketByLineId:
          ocrParserBucketByLineId ?? this.ocrParserBucketByLineId,
      ocrOrderedParserReadyLineIds:
          ocrOrderedParserReadyLineIds ?? this.ocrOrderedParserReadyLineIds,
      ocrOrderedParserReviewLineIds:
          ocrOrderedParserReviewLineIds ?? this.ocrOrderedParserReviewLineIds,
      ocrParserBucketCounts:
          ocrParserBucketCounts ?? this.ocrParserBucketCounts,
      ocrParserTaskCounts: ocrParserTaskCounts ?? this.ocrParserTaskCounts,
      ocrItemExpenseFamilyStatus:
          ocrItemExpenseFamilyStatus ?? this.ocrItemExpenseFamilyStatus,
      ocrItemExpenseFamilySummaryLabel:
          ocrItemExpenseFamilySummaryLabel ??
          this.ocrItemExpenseFamilySummaryLabel,
      ocrItemExpenseFamilyCounts:
          ocrItemExpenseFamilyCounts ?? this.ocrItemExpenseFamilyCounts,
      ocrSourceHandoffStatus:
          ocrSourceHandoffStatus ?? this.ocrSourceHandoffStatus,
      ocrSourceHandoffSignalCounts:
          ocrSourceHandoffSignalCounts ?? this.ocrSourceHandoffSignalCounts,
      ocrSourceStitchSignalCounts:
          ocrSourceStitchSignalCounts ?? this.ocrSourceStitchSignalCounts,
      ocrSourceScannerDecisionCounts:
          ocrSourceScannerDecisionCounts ?? this.ocrSourceScannerDecisionCounts,
      ocrSourceCaptureSourceSignalCounts:
          ocrSourceCaptureSourceSignalCounts ??
          this.ocrSourceCaptureSourceSignalCounts,
      ocrSourceCoverageSignalCounts:
          ocrSourceCoverageSignalCounts ?? this.ocrSourceCoverageSignalCounts,
      ocrSourceContinuationSignalCounts:
          ocrSourceContinuationSignalCounts ??
          this.ocrSourceContinuationSignalCounts,
      ocrSourcePhotoQualityRiskCounts:
          ocrSourcePhotoQualityRiskCounts ??
          this.ocrSourcePhotoQualityRiskCounts,
      ocrSourceQualityReviewStatus:
          ocrSourceQualityReviewStatus ?? this.ocrSourceQualityReviewStatus,
      ocrSourceQualityReviewAction:
          ocrSourceQualityReviewAction ?? this.ocrSourceQualityReviewAction,
      missingBottomTotalsEvidenceCode:
          missingBottomTotalsEvidenceCode ??
          this.missingBottomTotalsEvidenceCode,
      missingBottomTotalsEvidenceLabel:
          missingBottomTotalsEvidenceLabel ??
          this.missingBottomTotalsEvidenceLabel,
      missingBottomTotalsEvidenceFamilyCount:
          missingBottomTotalsEvidenceFamilyCount ??
          this.missingBottomTotalsEvidenceFamilyCount,
      receiptBrainLowStorageDownloadRiskCounts:
          receiptBrainLowStorageDownloadRiskCounts ??
          this.receiptBrainLowStorageDownloadRiskCounts,
      receiptBrainFullOfflineMustStayOptionalCounts:
          receiptBrainFullOfflineMustStayOptionalCounts ??
          this.receiptBrainFullOfflineMustStayOptionalCounts,
      receiptBrainFullOfflineExceedsBaseGuardrailCounts:
          receiptBrainFullOfflineExceedsBaseGuardrailCounts ??
          this.receiptBrainFullOfflineExceedsBaseGuardrailCounts,
      receiptInstallRequiredSegmentCounts:
          receiptInstallRequiredSegmentCounts ??
          this.receiptInstallRequiredSegmentCounts,
      receiptInstallFullOfflineSegmentCounts:
          receiptInstallFullOfflineSegmentCounts ??
          this.receiptInstallFullOfflineSegmentCounts,
      receiptInstallLowStorageImpactCounts:
          receiptInstallLowStorageImpactCounts ??
          this.receiptInstallLowStorageImpactCounts,
      receiptInstallRecommendedDistributionCounts:
          receiptInstallRecommendedDistributionCounts ??
          this.receiptInstallRecommendedDistributionCounts,
      receiptInstallCameraShellParserFreeCounts:
          receiptInstallCameraShellParserFreeCounts ??
          this.receiptInstallCameraShellParserFreeCounts,
      receiptInstallBaseUsefulOnTinyPhonesCounts:
          receiptInstallBaseUsefulOnTinyPhonesCounts ??
          this.receiptInstallBaseUsefulOnTinyPhonesCounts,
      receiptInstallOptionalPacksRequireConsentCounts:
          receiptInstallOptionalPacksRequireConsentCounts ??
          this.receiptInstallOptionalPacksRequireConsentCounts,
      genericReceiptStructureStatus:
          genericReceiptStructureStatus ?? this.genericReceiptStructureStatus,
      genericReceiptStructureSummary:
          genericReceiptStructureSummary ?? this.genericReceiptStructureSummary,
      genericReceiptZoneCounts:
          genericReceiptZoneCounts ?? this.genericReceiptZoneCounts,
      genericReceiptSignalCounts:
          genericReceiptSignalCounts ?? this.genericReceiptSignalCounts,
      genericReceiptParserLineNumbers:
          genericReceiptParserLineNumbers ??
          this.genericReceiptParserLineNumbers,
      genericReceiptClientProofLineNumbers:
          genericReceiptClientProofLineNumbers ??
          this.genericReceiptClientProofLineNumbers,
      genericReceiptRedactionAnchorCount:
          genericReceiptRedactionAnchorCount ??
          this.genericReceiptRedactionAnchorCount,
      clientProofRedactionStatus:
          clientProofRedactionStatus ?? this.clientProofRedactionStatus,
      clientProofVisibilityCounts:
          clientProofVisibilityCounts ?? this.clientProofVisibilityCounts,
      ocrFieldReadinessCounts:
          ocrFieldReadinessCounts ?? this.ocrFieldReadinessCounts,
      ocrRequiredFieldStatusCounts:
          ocrRequiredFieldStatusCounts ?? this.ocrRequiredFieldStatusCounts,
      ocrRequiredFieldStatusLabel:
          ocrRequiredFieldStatusLabel ?? this.ocrRequiredFieldStatusLabel,
      fieldConfidences: fieldConfidences ?? this.fieldConfidences,
    );
  }
}
