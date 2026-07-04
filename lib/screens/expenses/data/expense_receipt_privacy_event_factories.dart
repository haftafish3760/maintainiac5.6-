part of 'expense_receipt_parser.dart';

PrivacySafeReceiptEvent _privacySafeReceiptEventFromCapture({
  required PrivacySafeReceiptEventType type,
  required String featureArea,
  required ReceiptDeviceCapability? capability,
  required String captureMode,
  required String captureOutcome,
  required ReceiptPhotoQualityCheck? quality,
  required int photoSectionCount,
  required int retakeCount,
  required int captureDurationMs,
  required String? errorKind,
}) {
  return PrivacySafeReceiptEvent(
    type: type,
    featureArea: _safeToken(featureArea),
    capabilityTier: capability?.tier.name,
    parserDepth: capability?.parserDepth.name,
    captureMode: _safeToken(captureMode),
    captureOutcome: _safeToken(captureOutcome),
    focusBucket: quality == null ? null : _focusBucket(quality.focusScore),
    readabilityBucket: quality == null
        ? null
        : _readabilityBucket(quality.reviewScore),
    photoSectionCount: photoSectionCount,
    retakeCount: retakeCount,
    captureDurationMs: captureDurationMs,
    errorKind: errorKind == null ? null : _safeToken(errorKind),
  );
}

PrivacySafeReceiptEvent _privacySafeReceiptEventFromOcrResult({
  required ReceiptOcrResult result,
  required String featureArea,
  required ReceiptDeviceCapability? capability,
}) {
  final diagnostics = result.diagnostics;
  final handoff = result.parserHandoff;
  return PrivacySafeReceiptEvent(
    type: _typeForOcrSeverity(diagnostics.severity),
    featureArea: _safeToken(featureArea),
    capabilityTier: capability?.tier.name,
    parserDepth: capability?.parserDepth.name,
    ocrSeverity: diagnostics.severity.name,
    warningKinds: [
      for (final warning in result.structuredWarnings) warning.kind.name,
    ],
    attachmentsRead: diagnostics.attachmentsRead,
    attachmentsSkipped: diagnostics.attachmentsSkipped,
    rawLineCount: diagnostics.rawLineCount,
    parserLineCount: diagnostics.parserLineCount,
    ocrItemCandidateLineCount: diagnostics.itemCandidateLineCount,
    ocrPricedLineCount: diagnostics.pricedLineCount,
    ocrParserReadyLineCount: diagnostics.parserReadyLineCount,
    ocrParserReviewSignalCount: diagnostics.parserReviewSignalCount,
    ocrParserReadinessStatus: diagnostics.parserReadinessStatus,
    ocrDownstreamReadinessStatus: handoff.downstreamReadinessStatus,
    ocrDownstreamReadinessCounts: handoff.downstreamReadinessCounts,
    ocrHighConfidenceItemLineCount:
        diagnostics.highConfidenceItemCandidateLineCount,
    ocrReviewItemLineCount: diagnostics.reviewItemCandidateLineCount,
    ocrQuantitySignalItemLineCount:
        diagnostics.quantitySignalItemCandidateLineCount,
    ocrSkuSignalItemLineCount: diagnostics.skuSignalItemCandidateLineCount,
    ocrGenericItemLineCount: diagnostics.genericItemCandidateLineCount,
    ocrInventoryPrepLineIdCount: handoff.inventoryPrepLineIds.length,
    ocrParserReadyFieldCount: handoff.parserReadyFieldCount,
    ocrParserReviewFieldCount: handoff.parserReviewFieldCount,
    ocrSummaryMathStatus: diagnostics.ocrSummaryMathStatus,
    ocrSummaryMathReconciled: diagnostics.ocrSummaryMathReconciled,
    ocrLineSequenceStatus: diagnostics.ocrLineSequenceStatus,
    ocrReceiptStructureStatus: diagnostics.ocrReceiptStructureStatus,
    ocrSourceSectionContinuityStatus:
        diagnostics.ocrSourceSectionContinuityStatus,
    ocrSourceSectionCount: diagnostics.ocrSourceSectionCount,
    ocrSourceSectionContinuityReviewNeeded:
        diagnostics.ocrSourceSectionContinuityReviewNeeded,
    ocrSubtotalCandidateLineCount: diagnostics.subtotalCandidateLineCount,
    ocrTaxCandidateLineCount: diagnostics.taxCandidateLineCount,
    ocrTotalCandidateLineCount: diagnostics.totalCandidateLineCount,
    ocrTenderCandidateLineCount: diagnostics.tenderCandidateLineCount,
    ocrMetadataCandidateLineCount: diagnostics.metadataCandidateLineCount,
    ocrParserLineRoleCounts: diagnostics.parserLineRoleCounts,
    ocrDominantParserLineRole: diagnostics.dominantParserLineRole,
    ocrStableLineIdCount: handoff.stableLineIds.length,
    ocrParserReadyItemLineIdCount: handoff.parserReadyItemLineIds.length,
    ocrReviewItemLineIdCount: handoff.reviewItemLineIds.length,
    ocrParserBucketCounts: handoff.parserBucketCounts,
    ocrParserTaskCounts: diagnostics.parserTaskCounts,
    ocrSourceHandoffStatus: diagnostics.ocrSourceHandoffStatus,
    ocrSourceHandoffSignalCounts: diagnostics.ocrSourceHandoffSignalCounts,
    ocrSourceReviewDepthSignalCounts:
        diagnostics.ocrSourceReviewDepthSignalCounts,
    ocrSourceReviewDepthStatus: diagnostics.ocrSourceReviewDepthStatus,
    ocrSourceStitchSignalCounts: diagnostics.ocrSourceStitchSignalCounts,
    ocrSourceScannerDecisionCounts: diagnostics.ocrSourceScannerDecisionCounts,
    ocrSourceCaptureSourceSignalCounts:
        diagnostics.ocrSourceCaptureSourceSignalCounts,
    ocrSourcePhotoQualityRiskCounts:
        diagnostics.ocrSourcePhotoQualityRiskCounts,
    clientProofRedactionStatus: diagnostics.clientProofRedactionStatus,
    clientProofVisibilityCounts: diagnostics.clientProofVisibilityCounts,
    ocrFieldReadinessCounts: handoff.fieldReadinessCounts,
    ocrRequiredFieldStatusCounts: diagnostics.requiredParserFieldStatusCounts,
    ocrRequiredFieldStatusLabel: diagnostics.requiredParserFieldStatusLabel,
    pdfPagesRequested: diagnostics.pdfPagesRequested,
    usedLocalOcr: diagnostics.usedLocalOcr,
    hadDuplicateOrOverlapText: diagnostics.hadDuplicateOrOverlapText,
  );
}

PrivacySafeReceiptEvent _privacySafeReceiptEventFromParseResult({
  required ExpenseReceiptParseResult result,
  required String featureArea,
}) {
  final diagnostics = result.diagnostics;
  return PrivacySafeReceiptEvent(
    type: _typeForParseResult(result),
    featureArea: _safeToken(featureArea),
    parserDepth: diagnostics.parserDepth.name,
    parseQuality: _qualityBucket(result.quality.confidence),
    parserTrust: _safeToken(diagnostics.trustLabel),
    parserReviewCause: _parserReviewCause(result),
    totalsMathStatus: _totalsMathStatus(diagnostics),
    fieldReviewKeys: _fieldReviewKeys(result),
    parserLineRoleCounts: diagnostics.parserLineRoleCounts,
    parserTaskCounts: diagnostics.parserTaskCounts,
    parserCategoryCounts: diagnostics.parserCategoryCounts,
    parserCategoryHealthCounts: diagnostics.parserCategoryHealthCounts,
    parserCategoryReviewActionCode: diagnostics.parserCategoryReviewActionCode,
    parserRequiredFieldStatusCounts:
        diagnostics.parserRequiredFieldStatusCounts,
    parserRequiredFieldStatusLabel: diagnostics.parserRequiredFieldStatusLabel,
    parserDownstreamReadinessStatus:
        diagnostics.parserDownstreamReadinessStatus,
    parserDownstreamReadinessCounts:
        diagnostics.parserDownstreamReadinessCounts,
    localReceiptParserRoutingCode: diagnostics.localReceiptParserRoutingCode,
    localReceiptParserRoutingCounts: {
      diagnostics.localReceiptParserRoutingCode: 1,
    },
    localReceiptParserKeptLocalCount: diagnostics.keepsSimpleReceiptLocal
        ? 1
        : 0,
    localReceiptParserOptionalPackOfferCount:
        diagnostics.shouldOfferDetailedParserPack ? 1 : 0,
    detectedLineCount: diagnostics.detectedLineCount,
    parserLineCount: diagnostics.ocrParserLineCount,
    ocrItemCandidateLineCount: diagnostics.ocrItemCandidateLineCount,
    ocrPricedLineCount: diagnostics.ocrPricedLineCount,
    ocrParserReadyLineCount: diagnostics.ocrParserReadyLineCount,
    ocrParserReviewSignalCount: diagnostics.ocrParserReviewSignalCount,
    ocrParserReadinessStatus: diagnostics.ocrParserReadinessStatus,
    ocrDownstreamReadinessStatus: diagnostics.ocrDownstreamReadinessStatus,
    ocrDownstreamReadinessCounts: diagnostics.ocrDownstreamReadinessCounts,
    ocrHighConfidenceItemLineCount: diagnostics.ocrHighConfidenceItemLineCount,
    ocrReviewItemLineCount: diagnostics.ocrReviewItemLineCount,
    ocrQuantitySignalItemLineCount: diagnostics.ocrQuantitySignalItemLineCount,
    ocrSkuSignalItemLineCount: diagnostics.ocrSkuSignalItemLineCount,
    ocrGenericItemLineCount: diagnostics.ocrGenericItemLineCount,
    ocrInventoryPrepLineIdCount: diagnostics.ocrInventoryPrepLineIdCount,
    ocrParserReadyFieldCount: diagnostics.ocrParserReadyFieldCount,
    ocrParserReviewFieldCount: diagnostics.ocrParserReviewFieldCount,
    ocrSummaryMathStatus: diagnostics.ocrSummaryMathStatus,
    ocrSummaryMathReconciled: diagnostics.ocrSummaryMathReconciled,
    ocrLineSequenceStatus: diagnostics.ocrLineSequenceStatus,
    ocrReceiptStructureStatus: diagnostics.ocrReceiptStructureStatus,
    ocrSourceSectionContinuityStatus:
        diagnostics.ocrSourceSectionContinuityStatus,
    ocrSourceSectionCount: diagnostics.ocrSourceSectionCount,
    ocrSourceSectionContinuityReviewNeeded:
        diagnostics.ocrSourceSectionContinuityReviewNeeded,
    ocrSubtotalCandidateLineCount: diagnostics.ocrSubtotalCandidateLineCount,
    ocrTaxCandidateLineCount: diagnostics.ocrTaxCandidateLineCount,
    ocrTotalCandidateLineCount: diagnostics.ocrTotalCandidateLineCount,
    ocrTenderCandidateLineCount: diagnostics.ocrTenderCandidateLineCount,
    ocrParserLineRoleCounts: diagnostics.ocrParserLineRoleCounts,
    ocrDominantParserLineRole: diagnostics.ocrDominantParserLineRole,
    ocrStableLineIdCount: diagnostics.ocrStableLineIdCount,
    ocrParserReadyItemLineIdCount: diagnostics.ocrParserReadyItemLineIdCount,
    ocrReviewItemLineIdCount: diagnostics.ocrReviewItemLineIdCount,
    ocrParserBucketCounts: diagnostics.ocrParserBucketCounts,
    ocrParserTaskCounts: diagnostics.ocrParserTaskCounts,
    ocrSourceHandoffStatus: diagnostics.ocrSourceHandoffStatus,
    ocrSourceHandoffSignalCounts: diagnostics.ocrSourceHandoffSignalCounts,
    ocrSourceReviewDepthSignalCounts:
        diagnostics.ocrSourceReviewDepthSignalCounts,
    ocrSourceReviewDepthStatus: diagnostics.ocrSourceReviewDepthStatus,
    ocrSourceStitchSignalCounts: diagnostics.ocrSourceStitchSignalCounts,
    ocrSourceScannerDecisionCounts: diagnostics.ocrSourceScannerDecisionCounts,
    ocrSourceCaptureSourceSignalCounts:
        diagnostics.ocrSourceCaptureSourceSignalCounts,
    ocrSourcePhotoQualityRiskCounts:
        diagnostics.ocrSourcePhotoQualityRiskCounts,
    clientProofRedactionStatus: diagnostics.clientProofRedactionStatus,
    clientProofVisibilityCounts: diagnostics.clientProofVisibilityCounts,
    ocrFieldReadinessCounts: diagnostics.ocrFieldReadinessCounts,
    ocrRequiredFieldStatusCounts: diagnostics.ocrRequiredFieldStatusCounts,
    ocrRequiredFieldStatusLabel: diagnostics.ocrRequiredFieldStatusLabel,
    ocrMetadataCandidateLineCount: diagnostics.ocrMetadataCandidateLineCount,
    reviewLineCount: diagnostics.reviewLineCount,
    materialLineCount: diagnostics.materialLineCount,
    catalogMatchedLineCount: diagnostics.catalogMatchedLineCount,
    unmatchedMaterialLineCount: diagnostics.unmatchedMaterialLineCount,
    negativeLineCount: diagnostics.negativeLineCount,
    adjustmentLineCount: diagnostics.adjustmentLineCount,
    reconciled: diagnostics.reconciled,
    taxMathReconciled: diagnostics.taxMathReconciled,
    explicitTotalsComplete: diagnostics.hasCompleteExplicitTotals,
    needsHeavyReview: diagnostics.needsHeavyReview,
  );
}

PrivacySafeReceiptEvent _privacySafeReceiptEventFromLineSelectionBundle({
  required ReceiptLineSelectionBundle bundle,
  required String featureArea,
}) {
  return PrivacySafeReceiptEvent(
    type: bundle.needsClientProofReview
        ? PrivacySafeReceiptEventType.receiptParserReview
        : PrivacySafeReceiptEventType.receiptParserGood,
    featureArea: _safeToken(featureArea),
    selectedReceiptLinePurpose: bundle.purpose.name,
    selectedReceiptLineCount: bundle.selectedLineCount,
    excludedReceiptLineCount: bundle.excludedLineCount,
    clientProofReviewLineCount: bundle.reviewBeforeShareCount,
    redactedReceiptLineCount: bundle.redactedByDefaultCount,
    clientProofRedactionPlanStatus: bundle.needsClientProofReview
        ? 'review_required'
        : 'ready_to_share',
    clientProofVisibleLineCount:
        bundle.selectedLineCount -
        bundle.reviewBeforeShareCount -
        bundle.redactedByDefaultCount,
    clientProofHiddenLineCount:
        bundle.excludedLineCount + bundle.redactedByDefaultCount,
    clientProofPlanReviewLineCount: bundle.reviewBeforeShareCount,
  );
}

PrivacySafeReceiptEvent _privacySafeReceiptEventFromClientProofImageReviewPlan({
  required ReceiptClientProofImageReviewPlan plan,
  required String featureArea,
}) {
  final status = plan.needsManualImageReview
      ? 'manual_image_review_required'
      : plan.needsRedactionPreview
      ? 'redaction_preview_required'
      : 'ready_to_share';
  return PrivacySafeReceiptEvent(
    type: plan.needsManualImageReview
        ? PrivacySafeReceiptEventType.receiptParserReview
        : PrivacySafeReceiptEventType.receiptParserGood,
    featureArea: _safeToken(featureArea),
    selectedReceiptLinePurpose: plan.purpose.name,
    clientProofImageReviewStatus: status,
    clientProofImageSectionCount: plan.sectionCount,
    clientProofImageVisibleSectionCount: plan.visibleSectionCount,
    clientProofImageHiddenSectionCount: plan.hiddenSectionCount,
    clientProofImageReviewSectionCount: plan.reviewSectionCount,
    clientProofImageUnassignedLineCount: plan.unassignedLineCount,
    clientProofImageUnassignedHiddenLineCount: plan.unassignedHiddenLineCount,
    clientProofImageUnassignedReviewLineCount: plan.unassignedReviewLineCount,
  );
}

PrivacySafeReceiptEvent _privacySafeReceiptEventFromLineRedactionPlan({
  required ReceiptLineRedactionPlan plan,
  required String featureArea,
}) {
  final status = plan.ignoredUnknownLines
      ? 'ignored_unknown_lines'
      : plan.protectsPrivateContent
      ? 'private_content_protected'
      : plan.hidesUnselectedLines
      ? 'redaction_preview_required'
      : 'ready_to_share';
  return PrivacySafeReceiptEvent(
    type: plan.ignoredUnknownLines || plan.protectsPrivateContent
        ? PrivacySafeReceiptEventType.receiptParserReview
        : PrivacySafeReceiptEventType.receiptParserGood,
    featureArea: _safeToken(featureArea),
    clientProofLayoutRedactionStatus: status,
    clientProofLayoutVisibleLineCount: plan.visibleLineNumbers.length,
    clientProofLayoutHiddenLineCount: plan.hiddenLineNumbers.length,
    clientProofLayoutIgnoredLineCount: plan.ignoredLineNumbers.length,
    clientProofLayoutProtectedTypeCount: plan.protectedContentTypes.length,
    clientProofLayoutKeepsMerchantContext: plan.keepsMerchantContext,
    clientProofLayoutKeepsTotalsContext: plan.keepsTotalsContext,
  );
}
