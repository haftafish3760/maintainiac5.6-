part of 'expense_receipt_parser.dart';

extension PrivacySafeReceiptEventSerialization on PrivacySafeReceiptEvent {
  Map<String, Object?> toMap() {
    return {
      'event': type.name,
      'featureArea': featureArea,
      if (capabilityTier != null) 'capabilityTier': capabilityTier,
      if (parserDepth != null) 'parserDepth': parserDepth,
      if (ocrSeverity != null) 'ocrSeverity': ocrSeverity,
      if (parseQuality != null) 'parseQuality': parseQuality,
      if (parserTrust != null) 'parserTrust': parserTrust,
      if (parserReviewCause != null) 'parserReviewCause': parserReviewCause,
      if (totalsMathStatus != null) 'totalsMathStatus': totalsMathStatus,
      if (fieldReviewKeys.isNotEmpty) 'fieldReviewKeys': fieldReviewKeys,
      if (captureMode != null) 'captureMode': captureMode,
      if (captureOutcome != null) 'captureOutcome': captureOutcome,
      if (focusBucket != null) 'focusBucket': focusBucket,
      if (readabilityBucket != null) 'readabilityBucket': readabilityBucket,
      if (errorKind != null) 'errorKind': errorKind,
      if (warningKinds.isNotEmpty) 'warningKinds': warningKinds,
      if (parserLineRoleCounts.isNotEmpty)
        'parserLineRoleCounts': parserLineRoleCounts,
      if (parserTaskCounts.isNotEmpty) 'parserTaskCounts': parserTaskCounts,
      if (parserCategoryCounts.isNotEmpty)
        'parserCategoryCounts': parserCategoryCounts,
      if (parserCategoryHealthCounts.isNotEmpty)
        'parserCategoryHealthCounts': parserCategoryHealthCounts,
      if (parserCategoryReviewActionCode != null)
        'parserCategoryReviewActionCode': parserCategoryReviewActionCode,
      if (parserRequiredFieldStatusCounts.isNotEmpty)
        'parserRequiredFieldStatusCounts': parserRequiredFieldStatusCounts,
      if (parserRequiredFieldStatusLabel != null &&
          parserRequiredFieldStatusLabel!.trim().isNotEmpty)
        'parserRequiredFieldStatusLabel': parserRequiredFieldStatusLabel,
      if (parserDownstreamReadinessStatus != null)
        'parserDownstreamReadinessStatus': parserDownstreamReadinessStatus,
      if (parserDownstreamReadinessCounts.isNotEmpty)
        'parserDownstreamReadinessCounts': parserDownstreamReadinessCounts,
      if (localReceiptParserRoutingCode != null &&
          localReceiptParserRoutingCode!.trim().isNotEmpty)
        'localReceiptParserRoutingCode': localReceiptParserRoutingCode,
      if (localReceiptParserRoutingCounts.isNotEmpty)
        'localReceiptParserRoutingCounts': localReceiptParserRoutingCounts,
      'localReceiptParserKeptLocalCount': localReceiptParserKeptLocalCount,
      'localReceiptParserOptionalPackOfferCount':
          localReceiptParserOptionalPackOfferCount,
      'photoSectionCount': photoSectionCount,
      'retakeCount': retakeCount,
      'captureDurationMs': captureDurationMs,
      'attachmentsRead': attachmentsRead,
      'attachmentsSkipped': attachmentsSkipped,
      'rawLineCount': rawLineCount,
      'parserLineCount': parserLineCount,
      'ocrItemCandidateLineCount': ocrItemCandidateLineCount,
      'ocrPricedLineCount': ocrPricedLineCount,
      'ocrParserReadyLineCount': ocrParserReadyLineCount,
      'ocrParserReviewSignalCount': ocrParserReviewSignalCount,
      if (ocrParserReadinessStatus != null)
        'ocrParserReadinessStatus': ocrParserReadinessStatus,
      if (ocrDownstreamReadinessStatus != null)
        'ocrDownstreamReadinessStatus': ocrDownstreamReadinessStatus,
      if (ocrDownstreamReadinessCounts.isNotEmpty)
        'ocrDownstreamReadinessCounts': ocrDownstreamReadinessCounts,
      'ocrHighConfidenceItemLineCount': ocrHighConfidenceItemLineCount,
      'ocrReviewItemLineCount': ocrReviewItemLineCount,
      'ocrQuantitySignalItemLineCount': ocrQuantitySignalItemLineCount,
      'ocrSkuSignalItemLineCount': ocrSkuSignalItemLineCount,
      'ocrGenericItemLineCount': ocrGenericItemLineCount,
      'ocrInventoryPrepLineIdCount': ocrInventoryPrepLineIdCount,
      'ocrParserReadyFieldCount': ocrParserReadyFieldCount,
      'ocrParserReviewFieldCount': ocrParserReviewFieldCount,
      if (ocrSummaryMathStatus != null)
        'ocrSummaryMathStatus': ocrSummaryMathStatus,
      'ocrSummaryMathReconciled': ocrSummaryMathReconciled,
      if (ocrLineSequenceStatus != null)
        'ocrLineSequenceStatus': ocrLineSequenceStatus,
      if (ocrReceiptStructureStatus != null)
        'ocrReceiptStructureStatus': ocrReceiptStructureStatus,
      if (ocrSourceSectionContinuityStatus != null)
        'ocrSourceSectionContinuityStatus': ocrSourceSectionContinuityStatus,
      'ocrSourceSectionCount': ocrSourceSectionCount,
      'ocrSourceSectionContinuityReviewNeeded':
          ocrSourceSectionContinuityReviewNeeded,
      'ocrSubtotalCandidateLineCount': ocrSubtotalCandidateLineCount,
      'ocrTaxCandidateLineCount': ocrTaxCandidateLineCount,
      'ocrTotalCandidateLineCount': ocrTotalCandidateLineCount,
      'ocrTenderCandidateLineCount': ocrTenderCandidateLineCount,
      'ocrMetadataCandidateLineCount': ocrMetadataCandidateLineCount,
      if (ocrParserLineRoleCounts.isNotEmpty)
        'ocrParserLineRoleCounts': ocrParserLineRoleCounts,
      if (ocrDominantParserLineRole != null &&
          ocrDominantParserLineRole!.trim().isNotEmpty)
        'ocrDominantParserLineRole': ocrDominantParserLineRole,
      'ocrStableLineIdCount': ocrStableLineIdCount,
      'ocrParserReadyItemLineIdCount': ocrParserReadyItemLineIdCount,
      'ocrReviewItemLineIdCount': ocrReviewItemLineIdCount,
      if (ocrParserBucketCounts.isNotEmpty)
        'ocrParserBucketCounts': ocrParserBucketCounts,
      if (ocrParserTaskCounts.isNotEmpty)
        'ocrParserTaskCounts': ocrParserTaskCounts,
      if (ocrSourceHandoffStatus != null &&
          ocrSourceHandoffStatus!.trim().isNotEmpty)
        'ocrSourceHandoffStatus': ocrSourceHandoffStatus,
      if (ocrSourceHandoffSignalCounts.isNotEmpty)
        'ocrSourceHandoffSignalCounts': ocrSourceHandoffSignalCounts,
      if (ocrSourceStitchSignalCounts.isNotEmpty)
        'ocrSourceStitchSignalCounts': ocrSourceStitchSignalCounts,
      if (ocrSourceScannerDecisionCounts.isNotEmpty)
        'ocrSourceScannerDecisionCounts': ocrSourceScannerDecisionCounts,
      if (ocrSourceCaptureSourceSignalCounts.isNotEmpty)
        'ocrSourceCaptureSourceSignalCounts':
            ocrSourceCaptureSourceSignalCounts,
      if (ocrSourcePhotoQualityRiskCounts.isNotEmpty)
        'ocrSourcePhotoQualityRiskCounts': ocrSourcePhotoQualityRiskCounts,
      if (clientProofRedactionStatus != null &&
          clientProofRedactionStatus!.trim().isNotEmpty)
        'clientProofRedactionStatus': clientProofRedactionStatus,
      if (clientProofVisibilityCounts.isNotEmpty)
        'clientProofVisibilityCounts': clientProofVisibilityCounts,
      if (selectedReceiptLinePurpose != null &&
          selectedReceiptLinePurpose!.trim().isNotEmpty)
        'selectedReceiptLinePurpose': selectedReceiptLinePurpose,
      'selectedReceiptLineCount': selectedReceiptLineCount,
      'excludedReceiptLineCount': excludedReceiptLineCount,
      'clientProofReviewLineCount': clientProofReviewLineCount,
      'redactedReceiptLineCount': redactedReceiptLineCount,
      if (clientProofRedactionPlanStatus != null &&
          clientProofRedactionPlanStatus!.trim().isNotEmpty)
        'clientProofRedactionPlanStatus': clientProofRedactionPlanStatus,
      'clientProofVisibleLineCount': clientProofVisibleLineCount < 0
          ? 0
          : clientProofVisibleLineCount,
      'clientProofHiddenLineCount': clientProofHiddenLineCount,
      'clientProofPlanReviewLineCount': clientProofPlanReviewLineCount,
      if (clientProofImageReviewStatus != null &&
          clientProofImageReviewStatus!.trim().isNotEmpty)
        'clientProofImageReviewStatus': clientProofImageReviewStatus,
      'clientProofImageSectionCount': clientProofImageSectionCount,
      'clientProofImageVisibleSectionCount':
          clientProofImageVisibleSectionCount,
      'clientProofImageHiddenSectionCount': clientProofImageHiddenSectionCount,
      'clientProofImageReviewSectionCount': clientProofImageReviewSectionCount,
      'clientProofImageUnassignedLineCount':
          clientProofImageUnassignedLineCount,
      'clientProofImageUnassignedHiddenLineCount':
          clientProofImageUnassignedHiddenLineCount,
      'clientProofImageUnassignedReviewLineCount':
          clientProofImageUnassignedReviewLineCount,
      if (ocrFieldReadinessCounts.isNotEmpty)
        'ocrFieldReadinessCounts': ocrFieldReadinessCounts,
      if (ocrRequiredFieldStatusCounts.isNotEmpty)
        'ocrRequiredFieldStatusCounts': ocrRequiredFieldStatusCounts,
      if (ocrRequiredFieldStatusLabel != null &&
          ocrRequiredFieldStatusLabel!.trim().isNotEmpty)
        'ocrRequiredFieldStatusLabel': ocrRequiredFieldStatusLabel,
      'detectedLineCount': detectedLineCount,
      'reviewLineCount': reviewLineCount,
      'materialLineCount': materialLineCount,
      'catalogMatchedLineCount': catalogMatchedLineCount,
      'unmatchedMaterialLineCount': unmatchedMaterialLineCount,
      'negativeLineCount': negativeLineCount,
      'adjustmentLineCount': adjustmentLineCount,
      'pdfPagesRequested': pdfPagesRequested,
      'reconciled': reconciled,
      'taxMathReconciled': taxMathReconciled,
      'explicitTotalsComplete': explicitTotalsComplete,
      'needsHeavyReview': needsHeavyReview,
      'usedLocalOcr': usedLocalOcr,
      'hadDuplicateOrOverlapText': hadDuplicateOrOverlapText,
    };
  }
}
