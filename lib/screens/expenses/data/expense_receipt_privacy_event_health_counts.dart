part of 'expense_receipt_privacy_event_store.dart';

class _ReceiptPrivacyEventHealthCounts {
  final eventCounts = <String, int>{};
  final featureAreaCounts = <String, int>{};
  final ocrSeverityCounts = <String, int>{};
  final parseQualityCounts = <String, int>{};
  final parserTrustCounts = <String, int>{};
  final parserReviewCauseCounts = <String, int>{};
  final totalsMathStatusCounts = <String, int>{};
  final fieldReviewKeyCounts = <String, int>{};
  final capabilityTierCounts = <String, int>{};
  final captureModeCounts = <String, int>{};
  final captureOutcomeCounts = <String, int>{};
  final focusBucketCounts = <String, int>{};
  final readabilityBucketCounts = <String, int>{};
  final errorKindCounts = <String, int>{};
  final warningKindCounts = <String, int>{};
  final parserLineRoleCounts = <String, int>{};
  final parserTaskCounts = <String, int>{};
  final parserCategoryCounts = <String, int>{};
  final parserCategoryHealthCounts = <String, int>{};
  final parserCategoryReviewActionCounts = <String, int>{};
  final parserRequiredFieldStatusCounts = <String, int>{};
  final parserDownstreamReadinessStatusCounts = <String, int>{};
  final parserDownstreamReadinessCounts = <String, int>{};
  final localReceiptParserRoutingCounts = <String, int>{};
  final ocrSummaryMathStatusCounts = <String, int>{};
  final ocrParserReadinessStatusCounts = <String, int>{};
  final ocrDownstreamReadinessStatusCounts = <String, int>{};
  final ocrDownstreamReadinessCounts = <String, int>{};
  final ocrParserLineRoleCounts = <String, int>{};
  final ocrDominantParserLineRoleCounts = <String, int>{};
  final ocrParserBucketCounts = <String, int>{};
  final ocrParserTaskCounts = <String, int>{};
  final clientProofRedactionStatusCounts = <String, int>{};
  final clientProofVisibilityCounts = <String, int>{};
  final selectedReceiptLinePurposeCounts = <String, int>{};
  final clientProofRedactionPlanStatusCounts = <String, int>{};
  final clientProofImageReviewStatusCounts = <String, int>{};
  final ocrFieldReadinessCounts = <String, int>{};
  final ocrLineSequenceStatusCounts = <String, int>{};
  final ocrReceiptStructureStatusCounts = <String, int>{};
  final ocrSourceSectionContinuityStatusCounts = <String, int>{};

  var pendingUploadCount = 0;
  var uploadedEventCount = 0;
  var reviewOrProblemCount = 0;
  var blockedOcrCount = 0;
  var totalsMismatchCount = 0;
  var taxMathMismatchCount = 0;
  var heavyReviewCount = 0;
  var catalogWeakMatchCount = 0;
  var duplicateOrOverlapCount = 0;
  var unmatchedMaterialLineCount = 0;
  var catalogMatchedLineCount = 0;
  var detectedLineCount = 0;
  var parserLineCount = 0;
  var ocrItemCandidateLineCount = 0;
  var ocrPricedLineCount = 0;
  var ocrParserReadyLineCount = 0;
  var ocrParserReviewSignalCount = 0;
  var ocrHighConfidenceItemLineCount = 0;
  var ocrReviewItemLineCount = 0;
  var ocrQuantitySignalItemLineCount = 0;
  var ocrSkuSignalItemLineCount = 0;
  var ocrGenericItemLineCount = 0;
  var ocrInventoryPrepLineIdCount = 0;
  var ocrParserReadyFieldCount = 0;
  var ocrParserReviewFieldCount = 0;
  var ocrSummaryMathMismatchCount = 0;
  var ocrLineSequenceReviewCount = 0;
  var ocrReceiptStructureReviewCount = 0;
  var ocrSourceSectionReviewCount = 0;
  var ocrSourceSectionCount = 0;
  var localReceiptParserKeptLocalCount = 0;
  var localReceiptParserOptionalPackOfferCount = 0;
  var ocrSubtotalCandidateLineCount = 0;
  var ocrTaxCandidateLineCount = 0;
  var ocrTotalCandidateLineCount = 0;
  var ocrTenderCandidateLineCount = 0;
  var ocrMetadataCandidateLineCount = 0;
  var ocrStableLineIdCount = 0;
  var ocrParserReadyItemLineIdCount = 0;
  var ocrReviewItemLineIdCount = 0;
  var selectedReceiptLineCount = 0;
  var excludedReceiptLineCount = 0;
  var clientProofReviewLineCount = 0;
  var redactedReceiptLineCount = 0;
  var clientProofVisibleLineCount = 0;
  var clientProofHiddenLineCount = 0;
  var clientProofPlanReviewLineCount = 0;
  var clientProofImageSectionCount = 0;
  var clientProofImageVisibleSectionCount = 0;
  var clientProofImageHiddenSectionCount = 0;
  var clientProofImageReviewSectionCount = 0;
  var clientProofImageUnassignedLineCount = 0;
  var clientProofImageUnassignedHiddenLineCount = 0;
  var clientProofImageUnassignedReviewLineCount = 0;
  var pdfPagesRequested = 0;
  var photoSectionCount = 0;
  var retakeCount = 0;
  var captureDurationMs = 0;

  ReceiptPrivacyEventHealthSnapshot toSnapshot({
    required List<PrivacySafeReceiptEventRecord> sorted,
    DateTime? generatedAtUtc,
  }) {
    return ReceiptPrivacyEventHealthSnapshot(
      generatedAtUtc: (generatedAtUtc ?? DateTime.now().toUtc()).toUtc(),
      totalEventCount: sorted.length,
      pendingUploadCount: pendingUploadCount,
      uploadedEventCount: uploadedEventCount,
      firstEventAtUtc: sorted.isEmpty ? null : sorted.first.queuedAtUtc.toUtc(),
      lastEventAtUtc: sorted.isEmpty ? null : sorted.last.queuedAtUtc.toUtc(),
      eventCounts: Map.unmodifiable(eventCounts),
      featureAreaCounts: Map.unmodifiable(featureAreaCounts),
      ocrSeverityCounts: Map.unmodifiable(ocrSeverityCounts),
      parseQualityCounts: Map.unmodifiable(parseQualityCounts),
      parserTrustCounts: Map.unmodifiable(parserTrustCounts),
      parserReviewCauseCounts: Map.unmodifiable(parserReviewCauseCounts),
      totalsMathStatusCounts: Map.unmodifiable(totalsMathStatusCounts),
      fieldReviewKeyCounts: Map.unmodifiable(fieldReviewKeyCounts),
      capabilityTierCounts: Map.unmodifiable(capabilityTierCounts),
      captureModeCounts: Map.unmodifiable(captureModeCounts),
      captureOutcomeCounts: Map.unmodifiable(captureOutcomeCounts),
      focusBucketCounts: Map.unmodifiable(focusBucketCounts),
      readabilityBucketCounts: Map.unmodifiable(readabilityBucketCounts),
      errorKindCounts: Map.unmodifiable(errorKindCounts),
      warningKindCounts: Map.unmodifiable(warningKindCounts),
      parserLineRoleCounts: Map.unmodifiable(parserLineRoleCounts),
      parserTaskCounts: Map.unmodifiable(parserTaskCounts),
      parserCategoryCounts: Map.unmodifiable(parserCategoryCounts),
      parserCategoryHealthCounts: Map.unmodifiable(parserCategoryHealthCounts),
      parserCategoryReviewActionCounts: Map.unmodifiable(
        parserCategoryReviewActionCounts,
      ),
      parserRequiredFieldStatusCounts: Map.unmodifiable(
        parserRequiredFieldStatusCounts,
      ),
      parserDownstreamReadinessStatusCounts: Map.unmodifiable(
        parserDownstreamReadinessStatusCounts,
      ),
      parserDownstreamReadinessCounts: Map.unmodifiable(
        parserDownstreamReadinessCounts,
      ),
      localReceiptParserRoutingCounts: Map.unmodifiable(
        localReceiptParserRoutingCounts,
      ),
      localReceiptParserKeptLocalCount: localReceiptParserKeptLocalCount,
      localReceiptParserOptionalPackOfferCount:
          localReceiptParserOptionalPackOfferCount,
      reviewOrProblemCount: reviewOrProblemCount,
      blockedOcrCount: blockedOcrCount,
      totalsMismatchCount: totalsMismatchCount,
      taxMathMismatchCount: taxMathMismatchCount,
      heavyReviewCount: heavyReviewCount,
      catalogWeakMatchCount: catalogWeakMatchCount,
      duplicateOrOverlapCount: duplicateOrOverlapCount,
      unmatchedMaterialLineCount: unmatchedMaterialLineCount,
      catalogMatchedLineCount: catalogMatchedLineCount,
      detectedLineCount: detectedLineCount,
      parserLineCount: parserLineCount,
      ocrItemCandidateLineCount: ocrItemCandidateLineCount,
      ocrPricedLineCount: ocrPricedLineCount,
      ocrParserReadyLineCount: ocrParserReadyLineCount,
      ocrParserReviewSignalCount: ocrParserReviewSignalCount,
      ocrParserReadinessStatusCounts: Map.unmodifiable(
        ocrParserReadinessStatusCounts,
      ),
      ocrDownstreamReadinessStatusCounts: Map.unmodifiable(
        ocrDownstreamReadinessStatusCounts,
      ),
      ocrDownstreamReadinessCounts: Map.unmodifiable(
        ocrDownstreamReadinessCounts,
      ),
      ocrParserLineRoleCounts: Map.unmodifiable(ocrParserLineRoleCounts),
      ocrDominantParserLineRoleCounts: Map.unmodifiable(
        ocrDominantParserLineRoleCounts,
      ),
      ocrStableLineIdCount: ocrStableLineIdCount,
      ocrParserReadyItemLineIdCount: ocrParserReadyItemLineIdCount,
      ocrReviewItemLineIdCount: ocrReviewItemLineIdCount,
      ocrParserBucketCounts: Map.unmodifiable(ocrParserBucketCounts),
      ocrParserTaskCounts: Map.unmodifiable(ocrParserTaskCounts),
      clientProofRedactionStatusCounts: Map.unmodifiable(
        clientProofRedactionStatusCounts,
      ),
      clientProofVisibilityCounts: Map.unmodifiable(
        clientProofVisibilityCounts,
      ),
      selectedReceiptLinePurposeCounts: Map.unmodifiable(
        selectedReceiptLinePurposeCounts,
      ),
      selectedReceiptLineCount: selectedReceiptLineCount,
      excludedReceiptLineCount: excludedReceiptLineCount,
      clientProofReviewLineCount: clientProofReviewLineCount,
      redactedReceiptLineCount: redactedReceiptLineCount,
      clientProofRedactionPlanStatusCounts: Map.unmodifiable(
        clientProofRedactionPlanStatusCounts,
      ),
      clientProofVisibleLineCount: clientProofVisibleLineCount,
      clientProofHiddenLineCount: clientProofHiddenLineCount,
      clientProofPlanReviewLineCount: clientProofPlanReviewLineCount,
      clientProofImageReviewStatusCounts: Map.unmodifiable(
        clientProofImageReviewStatusCounts,
      ),
      clientProofImageSectionCount: clientProofImageSectionCount,
      clientProofImageVisibleSectionCount: clientProofImageVisibleSectionCount,
      clientProofImageHiddenSectionCount: clientProofImageHiddenSectionCount,
      clientProofImageReviewSectionCount: clientProofImageReviewSectionCount,
      clientProofImageUnassignedLineCount: clientProofImageUnassignedLineCount,
      clientProofImageUnassignedHiddenLineCount:
          clientProofImageUnassignedHiddenLineCount,
      clientProofImageUnassignedReviewLineCount:
          clientProofImageUnassignedReviewLineCount,
      ocrFieldReadinessCounts: Map.unmodifiable(ocrFieldReadinessCounts),
      ocrHighConfidenceItemLineCount: ocrHighConfidenceItemLineCount,
      ocrReviewItemLineCount: ocrReviewItemLineCount,
      ocrQuantitySignalItemLineCount: ocrQuantitySignalItemLineCount,
      ocrSkuSignalItemLineCount: ocrSkuSignalItemLineCount,
      ocrGenericItemLineCount: ocrGenericItemLineCount,
      ocrInventoryPrepLineIdCount: ocrInventoryPrepLineIdCount,
      ocrParserReadyFieldCount: ocrParserReadyFieldCount,
      ocrParserReviewFieldCount: ocrParserReviewFieldCount,
      ocrSummaryMathStatusCounts: Map.unmodifiable(ocrSummaryMathStatusCounts),
      ocrSummaryMathMismatchCount: ocrSummaryMathMismatchCount,
      ocrLineSequenceStatusCounts: Map.unmodifiable(
        ocrLineSequenceStatusCounts,
      ),
      ocrLineSequenceReviewCount: ocrLineSequenceReviewCount,
      ocrReceiptStructureStatusCounts: Map.unmodifiable(
        ocrReceiptStructureStatusCounts,
      ),
      ocrReceiptStructureReviewCount: ocrReceiptStructureReviewCount,
      ocrSourceSectionContinuityStatusCounts: Map.unmodifiable(
        ocrSourceSectionContinuityStatusCounts,
      ),
      ocrSourceSectionReviewCount: ocrSourceSectionReviewCount,
      ocrSourceSectionCount: ocrSourceSectionCount,
      ocrSubtotalCandidateLineCount: ocrSubtotalCandidateLineCount,
      ocrTaxCandidateLineCount: ocrTaxCandidateLineCount,
      ocrTotalCandidateLineCount: ocrTotalCandidateLineCount,
      ocrTenderCandidateLineCount: ocrTenderCandidateLineCount,
      ocrMetadataCandidateLineCount: ocrMetadataCandidateLineCount,
      pdfPagesRequested: pdfPagesRequested,
      photoSectionCount: photoSectionCount,
      retakeCount: retakeCount,
      captureDurationMs: captureDurationMs,
    );
  }
}
