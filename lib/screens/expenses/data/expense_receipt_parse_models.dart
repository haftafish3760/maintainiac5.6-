part of 'expense_receipt_parser.dart';

class ExpenseReceiptParseDiagnostics {
  const ExpenseReceiptParseDiagnostics({
    this.parserDepth = ReceiptParserDepth.inventoryMatching,
    this.maxCatalogCandidates = 80,
    this.detectedLineCount = 0,
    this.reviewLineCount = 0,
    this.catalogMatchedLineCount = 0,
    this.materialLineCount = 0,
    this.unmatchedMaterialLineCount = 0,
    this.negativeLineCount = 0,
    this.adjustmentLineCount = 0,
    this.lineSubtotal = 0,
    this.expectedSubtotalOrTotal,
    this.reconciliationDifference,
    this.taxMathDifference,
    this.reconciled = false,
    this.taxMathReconciled = false,
    this.hasExplicitSubtotal = false,
    this.hasExplicitTax = false,
    this.hasExplicitTotal = false,
    this.parserLineRoleCounts = const {},
    this.parserTaskCounts = const {},
    this.parserDuplicateOverlapSourceLabels = const [],
    this.parserDuplicateOverlapWindowLabels = const [],
    this.parserDuplicateOverlapConfidenceLabels = const [],
    this.parserCategoryCounts = const {},
    this.parserCategoryHealthCounts = const {},
    this.parserItemExpenseFamilyStatus = 'no_item_families',
    this.parserItemExpenseFamilySummaryLabel = '',
    this.parserItemExpenseFamilyCounts = const {},
    this.parserRequiredFieldStatusCounts = const {},
    this.parserRequiredFieldStatusLabel = '',
    this.parserDownstreamReadinessStatus = 'unknown',
    this.parserDownstreamReadinessCounts = const {},
    this.ocrParserLineCount = 0,
    this.ocrItemCandidateLineCount = 0,
    this.ocrPricedLineCount = 0,
    this.ocrParserReadyLineCount = 0,
    this.ocrParserReviewSignalCount = 0,
    this.ocrParserReadinessStatus = 'unknown',
    this.ocrDownstreamReadinessStatus = 'unknown',
    this.ocrDownstreamReadinessCounts = const {},
    this.ocrLeanLocalReadinessStatus = 'unknown',
    this.ocrLeanLocalReadinessCounts = const {},
    this.ocrLeanLocalReadinessLabel = '',
    this.ocrHighConfidenceItemLineCount = 0,
    this.ocrReviewItemLineCount = 0,
    this.ocrQuantitySignalItemLineCount = 0,
    this.ocrSkuSignalItemLineCount = 0,
    this.ocrGenericItemLineCount = 0,
    this.ocrInventoryPrepLineIdCount = 0,
    this.ocrParserReadyFieldCount = 0,
    this.ocrParserReviewFieldCount = 0,
    this.ocrSummaryMathStatus = 'incomplete',
    this.ocrSummaryMathReconciled = false,
    this.ocrLineSequenceStatus = 'unknown',
    this.ocrSourceSectionContinuityStatus = 'unknown',
    this.ocrSourceSectionCount = 0,
    this.ocrSourceSectionContinuityReviewNeeded = false,
    this.ocrReceiptStructureStatus = 'unknown',
    this.ocrSubtotalCandidateLineCount = 0,
    this.ocrTaxCandidateLineCount = 0,
    this.ocrTotalCandidateLineCount = 0,
    this.ocrTenderCandidateLineCount = 0,
    this.ocrMetadataCandidateLineCount = 0,
    this.ocrParserLineRoleCounts = const {},
    this.ocrDominantParserLineRole = '',
    this.ocrStableLineIdCount = 0,
    this.ocrParserReadyItemLineIdCount = 0,
    this.ocrReviewItemLineIdCount = 0,
    this.ocrLineIdsByRole = const {},
    this.ocrRoleByLineId = const {},
    this.ocrParserBucketByLineId = const {},
    this.ocrOrderedParserReadyLineIds = const [],
    this.ocrOrderedParserReviewLineIds = const [],
    this.ocrParserBucketCounts = const {},
    this.ocrParserTaskCounts = const {},
    this.ocrItemExpenseFamilyStatus = 'no_item_families',
    this.ocrItemExpenseFamilySummaryLabel = '',
    this.ocrItemExpenseFamilyCounts = const {},
    this.ocrSourceHandoffStatus = 'unknown',
    this.ocrSourceHandoffSignalCounts = const {},
    this.ocrSourceReviewDepthSignalCounts = const {},
    this.ocrSourceReviewDepthStatus = '',
    this.ocrSourceStitchSignalCounts = const {},
    this.ocrSourceScannerDecisionCounts = const {},
    this.ocrSourceCaptureSourceSignalCounts = const {},
    this.ocrSourceCoverageSignalCounts = const {},
    this.ocrSourceContinuationSignalCounts = const {},
    this.ocrSourcePhotoQualityRiskCounts = const {},
    this.ocrSourceQualityReviewStatus = '',
    this.ocrSourceQualityReviewAction = '',
    this.missingBottomTotalsEvidenceCode = '',
    this.missingBottomTotalsEvidenceLabel = '',
    this.missingBottomTotalsEvidenceFamilyCount = 0,
    this.receiptBrainLowStorageDownloadRiskCounts = const {},
    this.receiptBrainFullOfflineMustStayOptionalCounts = const {},
    this.receiptBrainFullOfflineExceedsBaseGuardrailCounts = const {},
    this.receiptInstallRequiredSegmentCounts = const {},
    this.receiptInstallFullOfflineSegmentCounts = const {},
    this.receiptInstallLowStorageImpactCounts = const {},
    this.receiptInstallRecommendedDistributionCounts = const {},
    this.receiptInstallCameraShellParserFreeCounts = const {},
    this.receiptInstallBaseUsefulOnTinyPhonesCounts = const {},
    this.receiptInstallOptionalPacksRequireConsentCounts = const {},
    this.genericReceiptStructureStatus = 'unknown',
    this.genericReceiptStructureSummary = '',
    this.genericReceiptZoneCounts = const {},
    this.genericReceiptSignalCounts = const {},
    this.genericReceiptParserLineNumbers = const [],
    this.genericReceiptClientProofLineNumbers = const [],
    this.genericReceiptRedactionAnchorCount = 0,
    this.clientProofRedactionStatus = 'no_receipt_lines',
    this.clientProofVisibilityCounts = const {},
    this.ocrFieldReadinessCounts = const {},
    this.ocrRequiredFieldStatusCounts = const {},
    this.ocrRequiredFieldStatusLabel = '',
    this.fieldConfidences = const {},
  });

  final ReceiptParserDepth parserDepth;
  final int maxCatalogCandidates;
  final int detectedLineCount;
  final int reviewLineCount;
  final int catalogMatchedLineCount;
  final int materialLineCount;
  final int unmatchedMaterialLineCount;
  final int negativeLineCount;
  final int adjustmentLineCount;
  final double lineSubtotal;
  final double? expectedSubtotalOrTotal;
  final double? reconciliationDifference;
  final double? taxMathDifference;
  final bool reconciled;
  final bool taxMathReconciled;
  final bool hasExplicitSubtotal;
  final bool hasExplicitTax;
  final bool hasExplicitTotal;
  final Map<String, int> parserLineRoleCounts;
  final Map<String, int> parserTaskCounts;
  final List<String> parserDuplicateOverlapSourceLabels;
  final List<String> parserDuplicateOverlapWindowLabels;
  final List<String> parserDuplicateOverlapConfidenceLabels;
  final Map<String, int> parserCategoryCounts;
  final Map<String, int> parserCategoryHealthCounts;
  final String parserItemExpenseFamilyStatus;
  final String parserItemExpenseFamilySummaryLabel;
  final Map<String, int> parserItemExpenseFamilyCounts;
  final Map<String, int> parserRequiredFieldStatusCounts;
  final String parserRequiredFieldStatusLabel;
  final String parserDownstreamReadinessStatus;
  final Map<String, int> parserDownstreamReadinessCounts;
  final int ocrParserLineCount;
  final int ocrItemCandidateLineCount;
  final int ocrPricedLineCount;
  final int ocrParserReadyLineCount;
  final int ocrParserReviewSignalCount;
  final String ocrParserReadinessStatus;
  final String ocrDownstreamReadinessStatus;
  final Map<String, int> ocrDownstreamReadinessCounts;
  final String ocrLeanLocalReadinessStatus;
  final Map<String, int> ocrLeanLocalReadinessCounts;
  final String ocrLeanLocalReadinessLabel;
  final int ocrHighConfidenceItemLineCount;
  final int ocrReviewItemLineCount;
  final int ocrQuantitySignalItemLineCount;
  final int ocrSkuSignalItemLineCount;
  final int ocrGenericItemLineCount;
  final int ocrInventoryPrepLineIdCount;
  final int ocrParserReadyFieldCount;
  final int ocrParserReviewFieldCount;
  final String ocrSummaryMathStatus;
  final bool ocrSummaryMathReconciled;
  final String ocrLineSequenceStatus;
  final String ocrSourceSectionContinuityStatus;
  final int ocrSourceSectionCount;
  final bool ocrSourceSectionContinuityReviewNeeded;
  final String ocrReceiptStructureStatus;
  final int ocrSubtotalCandidateLineCount;
  final int ocrTaxCandidateLineCount;
  final int ocrTotalCandidateLineCount;
  final int ocrTenderCandidateLineCount;
  final int ocrMetadataCandidateLineCount;
  final Map<String, int> ocrParserLineRoleCounts;
  final String ocrDominantParserLineRole;
  final int ocrStableLineIdCount;
  final int ocrParserReadyItemLineIdCount;
  final int ocrReviewItemLineIdCount;
  final Map<String, List<String>> ocrLineIdsByRole;
  final Map<String, String> ocrRoleByLineId;
  final Map<String, String> ocrParserBucketByLineId;
  final List<String> ocrOrderedParserReadyLineIds;
  final List<String> ocrOrderedParserReviewLineIds;
  final Map<String, int> ocrParserBucketCounts;
  final Map<String, int> ocrParserTaskCounts;
  final String ocrItemExpenseFamilyStatus;
  final String ocrItemExpenseFamilySummaryLabel;
  final Map<String, int> ocrItemExpenseFamilyCounts;
  final String ocrSourceHandoffStatus;
  final Map<String, int> ocrSourceHandoffSignalCounts;
  final Map<String, int> ocrSourceReviewDepthSignalCounts;
  final String ocrSourceReviewDepthStatus;
  final Map<String, int> ocrSourceStitchSignalCounts;
  final Map<String, int> ocrSourceScannerDecisionCounts;
  final Map<String, int> ocrSourceCaptureSourceSignalCounts;
  final Map<String, int> ocrSourceCoverageSignalCounts;
  final Map<String, int> ocrSourceContinuationSignalCounts;
  final Map<String, int> ocrSourcePhotoQualityRiskCounts;
  final String ocrSourceQualityReviewStatus;
  final String ocrSourceQualityReviewAction;
  final String missingBottomTotalsEvidenceCode;
  final String missingBottomTotalsEvidenceLabel;
  final int missingBottomTotalsEvidenceFamilyCount;
  final Map<String, int> receiptBrainLowStorageDownloadRiskCounts;
  final Map<String, int> receiptBrainFullOfflineMustStayOptionalCounts;
  final Map<String, int> receiptBrainFullOfflineExceedsBaseGuardrailCounts;
  final Map<String, int> receiptInstallRequiredSegmentCounts;
  final Map<String, int> receiptInstallFullOfflineSegmentCounts;
  final Map<String, int> receiptInstallLowStorageImpactCounts;
  final Map<String, int> receiptInstallRecommendedDistributionCounts;
  final Map<String, int> receiptInstallCameraShellParserFreeCounts;
  final Map<String, int> receiptInstallBaseUsefulOnTinyPhonesCounts;
  final Map<String, int> receiptInstallOptionalPacksRequireConsentCounts;
  final String genericReceiptStructureStatus;
  final String genericReceiptStructureSummary;
  final Map<String, int> genericReceiptZoneCounts;
  final Map<String, int> genericReceiptSignalCounts;
  final List<int> genericReceiptParserLineNumbers;
  final List<int> genericReceiptClientProofLineNumbers;
  final int genericReceiptRedactionAnchorCount;
  final String clientProofRedactionStatus;
  final Map<String, int> clientProofVisibilityCounts;
  final Map<String, int> ocrFieldReadinessCounts;
  final Map<String, int> ocrRequiredFieldStatusCounts;
  final String ocrRequiredFieldStatusLabel;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
}
