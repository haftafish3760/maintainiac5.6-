part of 'expense_receipt_parser.dart';

class PrivacySafeReceiptEvent {
  const PrivacySafeReceiptEvent({
    required this.type,
    required this.featureArea,
    this.capabilityTier,
    this.parserDepth,
    this.ocrSeverity,
    this.parseQuality,
    this.parserTrust,
    this.parserReviewCause,
    this.totalsMathStatus,
    this.fieldReviewKeys = const [],
    this.captureMode,
    this.captureOutcome,
    this.focusBucket,
    this.readabilityBucket,
    this.errorKind,
    this.warningKinds = const [],
    this.parserLineRoleCounts = const {},
    this.parserTaskCounts = const {},
    this.parserCategoryCounts = const {},
    this.parserCategoryHealthCounts = const {},
    this.parserCategoryReviewActionCode,
    this.parserRequiredFieldStatusCounts = const {},
    this.parserRequiredFieldStatusLabel,
    this.parserDownstreamReadinessStatus,
    this.parserDownstreamReadinessCounts = const {},
    this.localReceiptParserRoutingCode,
    this.localReceiptParserRoutingCounts = const {},
    this.localReceiptParserKeptLocalCount = 0,
    this.localReceiptParserOptionalPackOfferCount = 0,
    this.photoSectionCount = 0,
    this.retakeCount = 0,
    this.captureDurationMs = 0,
    this.attachmentsRead = 0,
    this.attachmentsSkipped = 0,
    this.rawLineCount = 0,
    this.parserLineCount = 0,
    this.ocrItemCandidateLineCount = 0,
    this.ocrPricedLineCount = 0,
    this.ocrParserReadyLineCount = 0,
    this.ocrParserReviewSignalCount = 0,
    this.ocrParserReadinessStatus,
    this.ocrDownstreamReadinessStatus,
    this.ocrDownstreamReadinessCounts = const {},
    this.ocrHighConfidenceItemLineCount = 0,
    this.ocrReviewItemLineCount = 0,
    this.ocrQuantitySignalItemLineCount = 0,
    this.ocrSkuSignalItemLineCount = 0,
    this.ocrGenericItemLineCount = 0,
    this.ocrInventoryPrepLineIdCount = 0,
    this.ocrParserReadyFieldCount = 0,
    this.ocrParserReviewFieldCount = 0,
    this.ocrSummaryMathStatus,
    this.ocrSummaryMathReconciled = false,
    this.ocrLineSequenceStatus,
    this.ocrReceiptStructureStatus,
    this.ocrSourceSectionContinuityStatus,
    this.ocrSourceSectionCount = 0,
    this.ocrSourceSectionContinuityReviewNeeded = false,
    this.ocrSubtotalCandidateLineCount = 0,
    this.ocrTaxCandidateLineCount = 0,
    this.ocrTotalCandidateLineCount = 0,
    this.ocrTenderCandidateLineCount = 0,
    this.ocrMetadataCandidateLineCount = 0,
    this.ocrParserLineRoleCounts = const {},
    this.ocrDominantParserLineRole,
    this.ocrStableLineIdCount = 0,
    this.ocrParserReadyItemLineIdCount = 0,
    this.ocrReviewItemLineIdCount = 0,
    this.ocrParserBucketCounts = const {},
    this.ocrParserTaskCounts = const {},
    this.ocrSourceHandoffStatus,
    this.ocrSourceHandoffSignalCounts = const {},
    this.ocrSourceStitchSignalCounts = const {},
    this.ocrSourceScannerDecisionCounts = const {},
    this.ocrSourceCaptureSourceSignalCounts = const {},
    this.ocrSourcePhotoQualityRiskCounts = const {},
    this.clientProofRedactionStatus,
    this.clientProofVisibilityCounts = const {},
    this.selectedReceiptLinePurpose,
    this.selectedReceiptLineCount = 0,
    this.excludedReceiptLineCount = 0,
    this.clientProofReviewLineCount = 0,
    this.redactedReceiptLineCount = 0,
    this.clientProofRedactionPlanStatus,
    this.clientProofVisibleLineCount = 0,
    this.clientProofHiddenLineCount = 0,
    this.clientProofPlanReviewLineCount = 0,
    this.clientProofImageReviewStatus,
    this.clientProofImageSectionCount = 0,
    this.clientProofImageVisibleSectionCount = 0,
    this.clientProofImageHiddenSectionCount = 0,
    this.clientProofImageReviewSectionCount = 0,
    this.clientProofImageUnassignedLineCount = 0,
    this.clientProofImageUnassignedHiddenLineCount = 0,
    this.clientProofImageUnassignedReviewLineCount = 0,
    this.clientProofLayoutRedactionStatus,
    this.clientProofLayoutVisibleLineCount = 0,
    this.clientProofLayoutHiddenLineCount = 0,
    this.clientProofLayoutIgnoredLineCount = 0,
    this.clientProofLayoutProtectedTypeCount = 0,
    this.clientProofLayoutKeepsMerchantContext = false,
    this.clientProofLayoutKeepsTotalsContext = false,
    this.ocrFieldReadinessCounts = const {},
    this.ocrRequiredFieldStatusCounts = const {},
    this.ocrRequiredFieldStatusLabel,
    this.detectedLineCount = 0,
    this.reviewLineCount = 0,
    this.materialLineCount = 0,
    this.catalogMatchedLineCount = 0,
    this.unmatchedMaterialLineCount = 0,
    this.negativeLineCount = 0,
    this.adjustmentLineCount = 0,
    this.pdfPagesRequested = 0,
    this.reconciled = false,
    this.taxMathReconciled = false,
    this.explicitTotalsComplete = false,
    this.needsHeavyReview = false,
    this.usedLocalOcr = false,
    this.hadDuplicateOrOverlapText = false,
  });

  factory PrivacySafeReceiptEvent.fromCapture({
    required PrivacySafeReceiptEventType type,
    String featureArea = 'receipts',
    ReceiptDeviceCapability? capability,
    String captureMode = 'manual',
    String captureOutcome = 'unknown',
    ReceiptPhotoQualityCheck? quality,
    int photoSectionCount = 0,
    int retakeCount = 0,
    int captureDurationMs = 0,
    String? errorKind,
  }) {
    return _privacySafeReceiptEventFromCapture(
      type: type,
      featureArea: featureArea,
      capability: capability,
      captureMode: captureMode,
      captureOutcome: captureOutcome,
      quality: quality,
      photoSectionCount: photoSectionCount,
      retakeCount: retakeCount,
      captureDurationMs: captureDurationMs,
      errorKind: errorKind,
    );
  }

  factory PrivacySafeReceiptEvent.fromOcrResult({
    required ReceiptOcrResult result,
    String featureArea = 'receipts',
    ReceiptDeviceCapability? capability,
  }) {
    return _privacySafeReceiptEventFromOcrResult(
      result: result,
      featureArea: featureArea,
      capability: capability,
    );
  }

  factory PrivacySafeReceiptEvent.fromParseResult({
    required ExpenseReceiptParseResult result,
    String featureArea = 'receipts',
  }) {
    return _privacySafeReceiptEventFromParseResult(
      result: result,
      featureArea: featureArea,
    );
  }

  factory PrivacySafeReceiptEvent.fromLineSelectionBundle({
    required ReceiptLineSelectionBundle bundle,
    String featureArea = 'receipts',
  }) {
    return _privacySafeReceiptEventFromLineSelectionBundle(
      bundle: bundle,
      featureArea: featureArea,
    );
  }

  factory PrivacySafeReceiptEvent.fromClientProofImageReviewPlan({
    required ReceiptClientProofImageReviewPlan plan,
    String featureArea = 'receipts',
  }) {
    return _privacySafeReceiptEventFromClientProofImageReviewPlan(
      plan: plan,
      featureArea: featureArea,
    );
  }

  factory PrivacySafeReceiptEvent.fromLineRedactionPlan({
    required ReceiptLineRedactionPlan plan,
    String featureArea = 'receipts',
  }) {
    return _privacySafeReceiptEventFromLineRedactionPlan(
      plan: plan,
      featureArea: featureArea,
    );
  }

  final PrivacySafeReceiptEventType type;
  final String featureArea;
  final String? capabilityTier;
  final String? parserDepth;
  final String? ocrSeverity;
  final String? parseQuality;
  final String? parserTrust;
  final String? parserReviewCause;
  final String? totalsMathStatus;
  final List<String> fieldReviewKeys;
  final String? captureMode;
  final String? captureOutcome;
  final String? focusBucket;
  final String? readabilityBucket;
  final String? errorKind;
  final List<String> warningKinds;
  final Map<String, int> parserLineRoleCounts;
  final Map<String, int> parserTaskCounts;
  final Map<String, int> parserCategoryCounts;
  final Map<String, int> parserCategoryHealthCounts;
  final String? parserCategoryReviewActionCode;
  final Map<String, int> parserRequiredFieldStatusCounts;
  final String? parserRequiredFieldStatusLabel;
  final String? parserDownstreamReadinessStatus;
  final Map<String, int> parserDownstreamReadinessCounts;
  final String? localReceiptParserRoutingCode;
  final Map<String, int> localReceiptParserRoutingCounts;
  final int localReceiptParserKeptLocalCount;
  final int localReceiptParserOptionalPackOfferCount;
  final int photoSectionCount;
  final int retakeCount;
  final int captureDurationMs;
  final int attachmentsRead;
  final int attachmentsSkipped;
  final int rawLineCount;
  final int parserLineCount;
  final int ocrItemCandidateLineCount;
  final int ocrPricedLineCount;
  final int ocrParserReadyLineCount;
  final int ocrParserReviewSignalCount;
  final String? ocrParserReadinessStatus;
  final String? ocrDownstreamReadinessStatus;
  final Map<String, int> ocrDownstreamReadinessCounts;
  final int ocrHighConfidenceItemLineCount;
  final int ocrReviewItemLineCount;
  final int ocrQuantitySignalItemLineCount;
  final int ocrSkuSignalItemLineCount;
  final int ocrGenericItemLineCount;
  final int ocrInventoryPrepLineIdCount;
  final int ocrParserReadyFieldCount;
  final int ocrParserReviewFieldCount;
  final String? ocrSummaryMathStatus;
  final bool ocrSummaryMathReconciled;
  final String? ocrLineSequenceStatus;
  final String? ocrReceiptStructureStatus;
  final String? ocrSourceSectionContinuityStatus;
  final int ocrSourceSectionCount;
  final bool ocrSourceSectionContinuityReviewNeeded;
  final int ocrSubtotalCandidateLineCount;
  final int ocrTaxCandidateLineCount;
  final int ocrTotalCandidateLineCount;
  final int ocrTenderCandidateLineCount;
  final int ocrMetadataCandidateLineCount;
  final Map<String, int> ocrParserLineRoleCounts;
  final String? ocrDominantParserLineRole;
  final int ocrStableLineIdCount;
  final int ocrParserReadyItemLineIdCount;
  final int ocrReviewItemLineIdCount;
  final Map<String, int> ocrParserBucketCounts;
  final Map<String, int> ocrParserTaskCounts;
  final String? ocrSourceHandoffStatus;
  final Map<String, int> ocrSourceHandoffSignalCounts;
  final Map<String, int> ocrSourceStitchSignalCounts;
  final Map<String, int> ocrSourceScannerDecisionCounts;
  final Map<String, int> ocrSourceCaptureSourceSignalCounts;
  final Map<String, int> ocrSourcePhotoQualityRiskCounts;
  final String? clientProofRedactionStatus;
  final Map<String, int> clientProofVisibilityCounts;
  final String? selectedReceiptLinePurpose;
  final int selectedReceiptLineCount;
  final int excludedReceiptLineCount;
  final int clientProofReviewLineCount;
  final int redactedReceiptLineCount;
  final String? clientProofRedactionPlanStatus;
  final int clientProofVisibleLineCount;
  final int clientProofHiddenLineCount;
  final int clientProofPlanReviewLineCount;
  final String? clientProofImageReviewStatus;
  final int clientProofImageSectionCount;
  final int clientProofImageVisibleSectionCount;
  final int clientProofImageHiddenSectionCount;
  final int clientProofImageReviewSectionCount;
  final int clientProofImageUnassignedLineCount;
  final int clientProofImageUnassignedHiddenLineCount;
  final int clientProofImageUnassignedReviewLineCount;
  final String? clientProofLayoutRedactionStatus;
  final int clientProofLayoutVisibleLineCount;
  final int clientProofLayoutHiddenLineCount;
  final int clientProofLayoutIgnoredLineCount;
  final int clientProofLayoutProtectedTypeCount;
  final bool clientProofLayoutKeepsMerchantContext;
  final bool clientProofLayoutKeepsTotalsContext;
  final Map<String, int> ocrFieldReadinessCounts;
  final Map<String, int> ocrRequiredFieldStatusCounts;
  final String? ocrRequiredFieldStatusLabel;
  final int detectedLineCount;
  final int reviewLineCount;
  final int materialLineCount;
  final int catalogMatchedLineCount;
  final int unmatchedMaterialLineCount;
  final int negativeLineCount;
  final int adjustmentLineCount;
  final int pdfPagesRequested;
  final bool reconciled;
  final bool taxMathReconciled;
  final bool explicitTotalsComplete;
  final bool needsHeavyReview;
  final bool usedLocalOcr;
  final bool hadDuplicateOrOverlapText;
}
