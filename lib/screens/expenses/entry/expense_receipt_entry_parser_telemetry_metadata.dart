part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryParserTelemetryMetadata
    on _ExpenseReceiptEntryScreenState {
  Map<String, Object?> _parserTelemetryMetadata(
    ExpenseReceiptParseResult result, {
    required Map<String, int> categoryBuckets,
    required Map<String, int> reviewCategoryBuckets,
    required Map<String, int> fieldConfidenceBuckets,
  }) {
    return {
      'source': _receiptPrivacyFeatureArea,
      'parserDepth': result.diagnostics.parserDepth.name,
      'lineCount': result.diagnostics.detectedLineCount,
      if (categoryBuckets.isNotEmpty) 'parsedCategoryBuckets': categoryBuckets,
      if (reviewCategoryBuckets.isNotEmpty)
        'reviewCategoryBuckets': reviewCategoryBuckets,
      if (fieldConfidenceBuckets.isNotEmpty)
        'parserFieldConfidenceBuckets': fieldConfidenceBuckets,
      'parserDownstreamReadinessStatus':
          result.diagnostics.parserDownstreamReadinessStatus,
      'parserReviewRootCauseCode': result.diagnostics.parserReviewRootCauseCode,
      if (result.diagnostics.parserDownstreamReadinessCounts.isNotEmpty)
        'parserDownstreamReadinessCounts':
            result.diagnostics.parserDownstreamReadinessCounts,
      if (result.diagnostics.ocrParserTaskCounts.isNotEmpty)
        'ocrParserTaskCounts': result.diagnostics.ocrParserTaskCounts,
      'ocrSourceHandoffStatus': result.diagnostics.ocrSourceHandoffStatus,
      if (result.diagnostics.ocrSourceHandoffSignalCounts.isNotEmpty)
        'ocrSourceHandoffSignalCounts':
            result.diagnostics.ocrSourceHandoffSignalCounts,
      if (result.diagnostics.ocrSourceStitchSignalCounts.isNotEmpty)
        'ocrSourceStitchSignalCounts':
            result.diagnostics.ocrSourceStitchSignalCounts,
      if (result.diagnostics.ocrSourceScannerDecisionCounts.isNotEmpty)
        'ocrSourceScannerDecisionCounts':
            result.diagnostics.ocrSourceScannerDecisionCounts,
      if (result.diagnostics.ocrSourceCaptureSourceSignalCounts.isNotEmpty)
        'ocrSourceCaptureSourceSignalCounts':
            result.diagnostics.ocrSourceCaptureSourceSignalCounts,
      if (result.diagnostics.ocrSourceContinuationSignalCounts.isNotEmpty)
        'ocrSourceContinuationSignalCounts':
            result.diagnostics.ocrSourceContinuationSignalCounts,
      if (result.diagnostics.ocrSourcePhotoQualityRiskCounts.isNotEmpty)
        'ocrSourcePhotoQualityRiskCounts':
            result.diagnostics.ocrSourcePhotoQualityRiskCounts,
      if (result.diagnostics.ocrSourceQualityReviewStatus.trim().isNotEmpty)
        'ocrSourceQualityReviewStatus':
            result.diagnostics.ocrSourceQualityReviewStatus,
      if (result.diagnostics.ocrSourceQualityReviewAction.trim().isNotEmpty)
        'ocrSourceQualityReviewAction':
            result.diagnostics.ocrSourceQualityReviewAction,
      'clientProofRedactionStatus':
          result.diagnostics.clientProofRedactionStatus,
      if (result.diagnostics.clientProofVisibilityCounts.isNotEmpty)
        'clientProofVisibilityCounts':
            result.diagnostics.clientProofVisibilityCounts,
      if (result.diagnostics.ocrFieldReadinessCounts.isNotEmpty)
        'ocrFieldReadinessCounts': result.diagnostics.ocrFieldReadinessCounts,
      'parserCategoryReviewActionCode':
          result.diagnostics.parserCategoryReviewActionCode,
      'parserPackPressureStatus': _parserPackPressureStatusFor(result),
      'receiptBrainParserLimitOutcome':
          result.diagnostics.receiptBrainParserLimitOutcome,
      if (result
          .diagnostics
          .receiptBrainLowStorageDownloadRiskCounts
          .isNotEmpty)
        'receiptBrainLowStorageDownloadRiskCounts':
            result.diagnostics.receiptBrainLowStorageDownloadRiskCounts,
      if (result
          .diagnostics
          .receiptBrainFullOfflineMustStayOptionalCounts
          .isNotEmpty)
        'receiptBrainFullOfflineMustStayOptionalCounts':
            result.diagnostics.receiptBrainFullOfflineMustStayOptionalCounts,
      if (result
          .diagnostics
          .receiptBrainFullOfflineExceedsBaseGuardrailCounts
          .isNotEmpty)
        'receiptBrainFullOfflineExceedsBaseGuardrailCounts': result
            .diagnostics
            .receiptBrainFullOfflineExceedsBaseGuardrailCounts,
      'receiptInstallFootprintOutcome':
          result.diagnostics.receiptInstallFootprintOutcome,
      if (result.diagnostics.receiptInstallRequiredSegmentCounts.isNotEmpty)
        'receiptInstallRequiredSegmentCounts':
            result.diagnostics.receiptInstallRequiredSegmentCounts,
      if (result.diagnostics.receiptInstallFullOfflineSegmentCounts.isNotEmpty)
        'receiptInstallFullOfflineSegmentCounts':
            result.diagnostics.receiptInstallFullOfflineSegmentCounts,
      if (result.diagnostics.receiptInstallLowStorageImpactCounts.isNotEmpty)
        'receiptInstallLowStorageImpactCounts':
            result.diagnostics.receiptInstallLowStorageImpactCounts,
      if (result
          .diagnostics
          .receiptInstallRecommendedDistributionCounts
          .isNotEmpty)
        'receiptInstallRecommendedDistributionCounts':
            result.diagnostics.receiptInstallRecommendedDistributionCounts,
      if (result
          .diagnostics
          .receiptInstallCameraShellParserFreeCounts
          .isNotEmpty)
        'receiptInstallCameraShellParserFreeCounts':
            result.diagnostics.receiptInstallCameraShellParserFreeCounts,
      if (result
          .diagnostics
          .receiptInstallBaseUsefulOnTinyPhonesCounts
          .isNotEmpty)
        'receiptInstallBaseUsefulOnTinyPhonesCounts':
            result.diagnostics.receiptInstallBaseUsefulOnTinyPhonesCounts,
      if (result
          .diagnostics
          .receiptInstallOptionalPacksRequireConsentCounts
          .isNotEmpty)
        'receiptInstallOptionalPacksRequireConsentCounts':
            result.diagnostics.receiptInstallOptionalPacksRequireConsentCounts,
      'ocrDownstreamReadinessStatus':
          result.diagnostics.ocrDownstreamReadinessStatus,
      if (result.diagnostics.ocrDownstreamReadinessCounts.isNotEmpty)
        'ocrDownstreamReadinessCounts':
            result.diagnostics.ocrDownstreamReadinessCounts,
      'parseQualityBucket': _confidenceBucket(result.quality.confidence),
      'parserLineReviewCount': result.diagnostics.reviewLineCount,
      'parserMatchedMaterialCount': result.diagnostics.catalogMatchedLineCount,
      'parserUnmatchedMaterialCount':
          result.diagnostics.unmatchedMaterialLineCount,
      'receiptReviewFlowStarted': _receiptReviewFlowStarted,
      if (_receiptReadHandoffStage.isNotEmpty)
        'receiptReadHandoffStage': _telemetryToken(_receiptReadHandoffStage),
      if (_receiptReadHandoffAction.isNotEmpty)
        'receiptReadHandoffAction': _telemetryToken(_receiptReadHandoffAction),
      if (_receiptReadHandoffDecision.isNotEmpty)
        'receiptReadHandoffDecision': _telemetryToken(
          _receiptReadHandoffDecision,
        ),
      if (_receiptReadHandoffRouteResult.isNotEmpty)
        'receiptReadHandoffRouteResult': _telemetryToken(
          _receiptReadHandoffRouteResult,
        ),
      if (_receiptBrainLowStorageDownloadRiskCounts.isNotEmpty)
        'receiptBrainLowStorageDownloadRiskCounts':
            _receiptBrainLowStorageDownloadRiskCounts,
      if (_receiptBrainFullOfflineMustStayOptionalCounts.isNotEmpty)
        'receiptBrainFullOfflineMustStayOptionalCounts':
            _receiptBrainFullOfflineMustStayOptionalCounts,
      if (_receiptBrainFullOfflineExceedsBaseGuardrailCounts.isNotEmpty)
        'receiptBrainFullOfflineExceedsBaseGuardrailCounts':
            _receiptBrainFullOfflineExceedsBaseGuardrailCounts,
      if (_receiptInstallRequiredSegmentCounts.isNotEmpty)
        'receiptInstallRequiredSegmentCounts':
            _receiptInstallRequiredSegmentCounts,
      if (_receiptInstallFullOfflineSegmentCounts.isNotEmpty)
        'receiptInstallFullOfflineSegmentCounts':
            _receiptInstallFullOfflineSegmentCounts,
      if (_receiptInstallLowStorageImpactCounts.isNotEmpty)
        'receiptInstallLowStorageImpactCounts':
            _receiptInstallLowStorageImpactCounts,
      if (_receiptInstallRecommendedDistributionCounts.isNotEmpty)
        'receiptInstallRecommendedDistributionCounts':
            _receiptInstallRecommendedDistributionCounts,
      if (_receiptInstallCameraShellParserFreeCounts.isNotEmpty)
        'receiptInstallCameraShellParserFreeCounts':
            _receiptInstallCameraShellParserFreeCounts,
      if (_receiptInstallBaseUsefulOnTinyPhonesCounts.isNotEmpty)
        'receiptInstallBaseUsefulOnTinyPhonesCounts':
            _receiptInstallBaseUsefulOnTinyPhonesCounts,
      if (_receiptInstallOptionalPacksRequireConsentCounts.isNotEmpty)
        'receiptInstallOptionalPacksRequireConsentCounts':
            _receiptInstallOptionalPacksRequireConsentCounts,
      'receiptReadHandoffProofCount': _receiptReadHandoffProofCount,
      'receiptReadHandoffOcrSourceCount': _receiptReadHandoffOcrSourceCount,
      'subtotalReconciliationStatus': result.diagnostics.reconciled
          ? 'matched'
          : 'needs_review',
      'taxMathStatus': result.diagnostics.taxMathReconciled
          ? 'matched'
          : result.diagnostics.hasCompleteExplicitTotals
          ? 'needs_review'
          : 'not_available',
    };
  }
}
