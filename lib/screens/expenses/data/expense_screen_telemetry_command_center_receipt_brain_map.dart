part of 'expense_screen_telemetry.dart';

extension ExpenseTelemetryHealthSnapshotReceiptBrainCommandCenterMap
    on ExpenseTelemetryHealthSnapshot {
  Map<String, Object?> get receiptBrainCommandCenterMap {
    return {
      'receiptBrainParserLimitOutcomeCounts':
          receiptBrainParserLimitOutcomeCounts,
      'receiptBrainLowStorageDownloadRiskCounts':
          receiptBrainLowStorageDownloadRiskCounts,
      'receiptBrainFullOfflineMustStayOptionalCounts':
          receiptBrainFullOfflineMustStayOptionalCounts,
      'receiptBrainFullOfflineExceedsBaseGuardrailCounts':
          receiptBrainFullOfflineExceedsBaseGuardrailCounts,
      'receiptBrainBaseLocalReadingAvailableCounts':
          receiptBrainBaseLocalReadingAvailableCounts,
      'receiptBrainBaseWorksWithoutCloudAssistCounts':
          receiptBrainBaseWorksWithoutCloudAssistCounts,
      'receiptBrainLocalFirstReadinessCounts':
          receiptBrainLocalFirstReadinessCounts,
      'receiptBrainLocalFirstReadinessActionCounts':
          receiptBrainLocalFirstReadinessActionCounts,
      'receiptBrainLocalFirstReadinessSummaryCounts':
          receiptBrainLocalFirstReadinessSummaryCounts,
      'receiptBrainFirstInstallBoundaryCounts':
          receiptBrainFirstInstallBoundaryCounts,
      'receiptBrainFirstInstallBoundaryActionCounts':
          receiptBrainFirstInstallBoundaryActionCounts,
      'receiptBrainFirstInstallCanRunLowStorageCounts':
          receiptBrainFirstInstallCanRunLowStorageCounts,
      'receiptBrainFirstInstallRequiresBaseCapabilityCounts':
          receiptBrainFirstInstallRequiresBaseCapabilityCounts,
      'receiptBrainFirstInstallBoundarySummaryCounts':
          receiptBrainFirstInstallBoundarySummaryCounts,
      'receiptInstallRequiredSegmentCounts':
          receiptInstallRequiredSegmentCounts,
      'receiptInstallFullOfflineSegmentCounts':
          receiptInstallFullOfflineSegmentCounts,
      'receiptInstallLowStorageImpactCounts':
          receiptInstallLowStorageImpactCounts,
      'receiptInstallRecommendedDistributionCounts':
          receiptInstallRecommendedDistributionCounts,
      'receiptInstallCameraShellParserFreeCounts':
          receiptInstallCameraShellParserFreeCounts,
      'receiptInstallBaseUsefulOnTinyPhonesCounts':
          receiptInstallBaseUsefulOnTinyPhonesCounts,
      'receiptInstallOptionalPacksRequireConsentCounts':
          receiptInstallOptionalPacksRequireConsentCounts,
      'receiptLocalOnlyAcceptanceStatusCounts':
          receiptLocalOnlyAcceptanceStatusCounts,
      'receiptLocalOnlyAcceptanceActionCounts':
          receiptLocalOnlyAcceptanceActionCounts,
      'receiptLocalOnlyBaseFlowCanRunCounts':
          receiptLocalOnlyBaseFlowCanRunCounts,
      'receiptLocalOnlyBlocksLowStorageCounts':
          receiptLocalOnlyBlocksLowStorageCounts,
      'receiptLocalOnlyEvidenceCounts': receiptLocalOnlyEvidenceCounts,
      'nativeLocalOnlyCapturePolicyCounts': nativeLocalOnlyCapturePolicyCounts,
      'nativeLocalOnlyBaseFlowCanRunCounts':
          nativeLocalOnlyBaseFlowCanRunCounts,
      'nativeLocalOnlyHeavyPacksMayBlockCaptureCounts':
          nativeLocalOnlyHeavyPacksMayBlockCaptureCounts,
      'nativeLocalOnlyCloudAssistMayBlockCaptureCounts':
          nativeLocalOnlyCloudAssistMayBlockCaptureCounts,
      'receiptRequiredBaseFootprintStatusCounts':
          receiptRequiredBaseFootprintStatusCounts,
      'receiptRequiredBaseFootprintCanShipCounts':
          receiptRequiredBaseFootprintCanShipCounts,
      'receiptRequiredBaseFootprintReviewCounts':
          receiptRequiredBaseFootprintReviewCounts,
      'receiptRequiredBaseFootprintBlockingReasonCounts':
          receiptRequiredBaseFootprintBlockingReasonCounts,
      'receiptRequiredBaseFootprintReviewReasonCounts':
          receiptRequiredBaseFootprintReviewReasonCounts,
      if (topReceiptBrainParserLimitOutcome.isNotEmpty)
        'topReceiptBrainParserLimitOutcome': topReceiptBrainParserLimitOutcome,
      if (topReceiptBrainLowStorageDownloadRisk.isNotEmpty)
        'topReceiptBrainLowStorageDownloadRisk':
            topReceiptBrainLowStorageDownloadRisk,
      if (topReceiptBrainLocalFirstReadiness.isNotEmpty)
        'topReceiptBrainLocalFirstReadiness':
            topReceiptBrainLocalFirstReadiness,
      if (topReceiptBrainLocalFirstReadinessAction.isNotEmpty)
        'topReceiptBrainLocalFirstReadinessAction':
            topReceiptBrainLocalFirstReadinessAction,
      if (topReceiptBrainFirstInstallBoundary.isNotEmpty)
        'topReceiptBrainFirstInstallBoundary':
            topReceiptBrainFirstInstallBoundary,
      if (topReceiptBrainFirstInstallBoundaryAction.isNotEmpty)
        'topReceiptBrainFirstInstallBoundaryAction':
            topReceiptBrainFirstInstallBoundaryAction,
      if (topReceiptInstallRecommendedDistribution.isNotEmpty)
        'topReceiptInstallRecommendedDistribution':
            topReceiptInstallRecommendedDistribution,
      if (topReceiptInstallLowStorageImpact.isNotEmpty)
        'topReceiptInstallLowStorageImpact': topReceiptInstallLowStorageImpact,
      if (topReceiptLocalOnlyAcceptanceStatus.isNotEmpty)
        'topReceiptLocalOnlyAcceptanceStatus':
            topReceiptLocalOnlyAcceptanceStatus,
      if (topReceiptLocalOnlyAcceptanceAction.isNotEmpty)
        'topReceiptLocalOnlyAcceptanceAction':
            topReceiptLocalOnlyAcceptanceAction,
      if (topNativeLocalOnlyCapturePolicy.isNotEmpty)
        'topNativeLocalOnlyCapturePolicy': topNativeLocalOnlyCapturePolicy,
      if (topReceiptRequiredBaseFootprintStatus.isNotEmpty)
        'topReceiptRequiredBaseFootprintStatus':
            topReceiptRequiredBaseFootprintStatus,
      if (topReceiptRequiredBaseFootprintBlockingReason.isNotEmpty)
        'topReceiptRequiredBaseFootprintBlockingReason':
            topReceiptRequiredBaseFootprintBlockingReason,
      if (topReceiptRequiredBaseFootprintReviewReason.isNotEmpty)
        'topReceiptRequiredBaseFootprintReviewReason':
            topReceiptRequiredBaseFootprintReviewReason,
    };
  }
}
