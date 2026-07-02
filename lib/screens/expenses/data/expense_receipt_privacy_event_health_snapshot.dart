part of 'expense_receipt_privacy_event_store.dart';

class ReceiptPrivacyEventHealthSnapshot {
  const ReceiptPrivacyEventHealthSnapshot({
    required this.generatedAtUtc,
    required this.totalEventCount,
    required this.pendingUploadCount,
    required this.uploadedEventCount,
    required this.firstEventAtUtc,
    required this.lastEventAtUtc,
    required this.eventCounts,
    required this.featureAreaCounts,
    required this.ocrSeverityCounts,
    required this.parseQualityCounts,
    required this.parserTrustCounts,
    required this.parserReviewCauseCounts,
    required this.totalsMathStatusCounts,
    required this.fieldReviewKeyCounts,
    required this.capabilityTierCounts,
    required this.captureModeCounts,
    required this.captureOutcomeCounts,
    required this.focusBucketCounts,
    required this.readabilityBucketCounts,
    required this.errorKindCounts,
    required this.warningKindCounts,
    required this.reviewOrProblemCount,
    required this.blockedOcrCount,
    required this.totalsMismatchCount,
    required this.taxMathMismatchCount,
    required this.heavyReviewCount,
    required this.catalogWeakMatchCount,
    required this.duplicateOrOverlapCount,
    required this.unmatchedMaterialLineCount,
    required this.catalogMatchedLineCount,
    required this.detectedLineCount,
    required this.parserLineCount,
    required this.ocrItemCandidateLineCount,
    required this.ocrPricedLineCount,
    required this.ocrParserReadyLineCount,
    required this.ocrParserReviewSignalCount,
    required this.ocrParserReadinessStatusCounts,
    required this.ocrDownstreamReadinessStatusCounts,
    required this.ocrDownstreamReadinessCounts,
    required this.ocrHighConfidenceItemLineCount,
    required this.ocrReviewItemLineCount,
    required this.ocrQuantitySignalItemLineCount,
    required this.ocrSkuSignalItemLineCount,
    required this.ocrGenericItemLineCount,
    required this.ocrInventoryPrepLineIdCount,
    required this.parserLineRoleCounts,
    required this.parserTaskCounts,
    required this.parserCategoryCounts,
    required this.parserCategoryHealthCounts,
    required this.parserCategoryReviewActionCounts,
    required this.parserRequiredFieldStatusCounts,
    required this.parserDownstreamReadinessStatusCounts,
    required this.parserDownstreamReadinessCounts,
    required this.localReceiptParserRoutingCounts,
    required this.localReceiptParserKeptLocalCount,
    required this.localReceiptParserOptionalPackOfferCount,
    required this.ocrParserReadyFieldCount,
    required this.ocrParserReviewFieldCount,
    required this.ocrSummaryMathStatusCounts,
    required this.ocrSummaryMathMismatchCount,
    required this.ocrLineSequenceStatusCounts,
    required this.ocrLineSequenceReviewCount,
    required this.ocrReceiptStructureStatusCounts,
    required this.ocrReceiptStructureReviewCount,
    required this.ocrSourceSectionContinuityStatusCounts,
    required this.ocrSourceSectionReviewCount,
    required this.ocrSourceSectionCount,
    required this.ocrSubtotalCandidateLineCount,
    required this.ocrTaxCandidateLineCount,
    required this.ocrTotalCandidateLineCount,
    required this.ocrTenderCandidateLineCount,
    required this.ocrMetadataCandidateLineCount,
    required this.ocrParserLineRoleCounts,
    required this.ocrDominantParserLineRoleCounts,
    required this.ocrStableLineIdCount,
    required this.ocrParserReadyItemLineIdCount,
    required this.ocrReviewItemLineIdCount,
    required this.ocrParserBucketCounts,
    required this.ocrParserTaskCounts,
    required this.clientProofRedactionStatusCounts,
    required this.clientProofVisibilityCounts,
    required this.selectedReceiptLinePurposeCounts,
    required this.selectedReceiptLineCount,
    required this.excludedReceiptLineCount,
    required this.clientProofReviewLineCount,
    required this.redactedReceiptLineCount,
    required this.clientProofRedactionPlanStatusCounts,
    required this.clientProofVisibleLineCount,
    required this.clientProofHiddenLineCount,
    required this.clientProofPlanReviewLineCount,
    required this.clientProofImageReviewStatusCounts,
    required this.clientProofImageSectionCount,
    required this.clientProofImageVisibleSectionCount,
    required this.clientProofImageHiddenSectionCount,
    required this.clientProofImageReviewSectionCount,
    required this.clientProofImageUnassignedLineCount,
    required this.clientProofImageUnassignedHiddenLineCount,
    required this.clientProofImageUnassignedReviewLineCount,
    required this.ocrFieldReadinessCounts,
    required this.pdfPagesRequested,
    required this.photoSectionCount,
    required this.retakeCount,
    required this.captureDurationMs,
  });

  factory ReceiptPrivacyEventHealthSnapshot.fromRecords(
    Iterable<PrivacySafeReceiptEventRecord> records, {
    DateTime? generatedAtUtc,
  }) {
    return _buildReceiptPrivacyEventHealthSnapshot(
      records,
      generatedAtUtc: generatedAtUtc,
    );
  }
  final DateTime generatedAtUtc;
  final int totalEventCount;
  final int pendingUploadCount;
  final int uploadedEventCount;
  final DateTime? firstEventAtUtc;
  final DateTime? lastEventAtUtc;
  final Map<String, int> eventCounts;
  final Map<String, int> featureAreaCounts;
  final Map<String, int> ocrSeverityCounts;
  final Map<String, int> parseQualityCounts;
  final Map<String, int> parserTrustCounts;
  final Map<String, int> parserReviewCauseCounts;
  final Map<String, int> totalsMathStatusCounts;
  final Map<String, int> fieldReviewKeyCounts;
  final Map<String, int> capabilityTierCounts;
  final Map<String, int> captureModeCounts;
  final Map<String, int> captureOutcomeCounts;
  final Map<String, int> focusBucketCounts;
  final Map<String, int> readabilityBucketCounts;
  final Map<String, int> errorKindCounts;
  final Map<String, int> warningKindCounts;
  final Map<String, int> parserLineRoleCounts;
  final Map<String, int> parserTaskCounts;
  final Map<String, int> parserCategoryCounts;
  final Map<String, int> parserCategoryHealthCounts;
  final Map<String, int> parserCategoryReviewActionCounts;
  final Map<String, int> parserRequiredFieldStatusCounts;
  final Map<String, int> parserDownstreamReadinessStatusCounts;
  final Map<String, int> parserDownstreamReadinessCounts;
  final Map<String, int> localReceiptParserRoutingCounts;
  final int localReceiptParserKeptLocalCount;
  final int localReceiptParserOptionalPackOfferCount;
  final int reviewOrProblemCount;
  final int blockedOcrCount;
  final int totalsMismatchCount;
  final int taxMathMismatchCount;
  final int heavyReviewCount;
  final int catalogWeakMatchCount;
  final int duplicateOrOverlapCount;
  final int unmatchedMaterialLineCount;
  final int catalogMatchedLineCount;
  final int detectedLineCount;
  final int parserLineCount;
  final int ocrItemCandidateLineCount;
  final int ocrPricedLineCount;
  final int ocrParserReadyLineCount;
  final int ocrParserReviewSignalCount;
  final Map<String, int> ocrParserReadinessStatusCounts;
  final Map<String, int> ocrDownstreamReadinessStatusCounts;
  final Map<String, int> ocrDownstreamReadinessCounts;
  final Map<String, int> ocrParserLineRoleCounts;
  final Map<String, int> ocrDominantParserLineRoleCounts;
  final int ocrStableLineIdCount;
  final int ocrParserReadyItemLineIdCount;
  final int ocrReviewItemLineIdCount;
  final Map<String, int> ocrParserBucketCounts;
  final Map<String, int> ocrParserTaskCounts;
  final Map<String, int> clientProofRedactionStatusCounts;
  final Map<String, int> clientProofVisibilityCounts;
  final Map<String, int> selectedReceiptLinePurposeCounts;
  final int selectedReceiptLineCount;
  final int excludedReceiptLineCount;
  final int clientProofReviewLineCount;
  final int redactedReceiptLineCount;
  final Map<String, int> clientProofRedactionPlanStatusCounts;
  final int clientProofVisibleLineCount;
  final int clientProofHiddenLineCount;
  final int clientProofPlanReviewLineCount;
  final Map<String, int> clientProofImageReviewStatusCounts;
  final int clientProofImageSectionCount;
  final int clientProofImageVisibleSectionCount;
  final int clientProofImageHiddenSectionCount;
  final int clientProofImageReviewSectionCount;
  final int clientProofImageUnassignedLineCount;
  final int clientProofImageUnassignedHiddenLineCount;
  final int clientProofImageUnassignedReviewLineCount;
  final Map<String, int> ocrFieldReadinessCounts;
  final int ocrHighConfidenceItemLineCount;
  final int ocrReviewItemLineCount;
  final int ocrQuantitySignalItemLineCount;
  final int ocrSkuSignalItemLineCount;
  final int ocrGenericItemLineCount;
  final int ocrInventoryPrepLineIdCount;
  final int ocrParserReadyFieldCount;
  final int ocrParserReviewFieldCount;
  final Map<String, int> ocrSummaryMathStatusCounts;
  final int ocrSummaryMathMismatchCount;
  final Map<String, int> ocrLineSequenceStatusCounts;
  final int ocrLineSequenceReviewCount;
  final Map<String, int> ocrReceiptStructureStatusCounts;
  final int ocrReceiptStructureReviewCount;
  final Map<String, int> ocrSourceSectionContinuityStatusCounts;
  final int ocrSourceSectionReviewCount;
  final int ocrSourceSectionCount;
  final int ocrSubtotalCandidateLineCount;
  final int ocrTaxCandidateLineCount;
  final int ocrTotalCandidateLineCount;
  final int ocrTenderCandidateLineCount;
  final int ocrMetadataCandidateLineCount;
  final int pdfPagesRequested;
  final int photoSectionCount;
  final int retakeCount;
  final int captureDurationMs;

  Map<String, Object?> toCommandCenterMap() {
    return _receiptPrivacyEventHealthCommandCenterMap(this);
  }

  int _eventCount(PrivacySafeReceiptEventType type) {
    return eventCounts[type.name] ?? 0;
  }
}
