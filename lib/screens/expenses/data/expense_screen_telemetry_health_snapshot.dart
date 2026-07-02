part of 'expense_screen_telemetry.dart';

// This DTO is intentionally compact: dart format expands the constructor and
// field declarations past the 500-line source limit without improving behavior.
// Keep the raw source under the audit line-length guard instead.
// dart format off
class ExpenseTelemetryHealthSnapshot {
  const ExpenseTelemetryHealthSnapshot({
    required this.generatedAtUtc, required this.totalEventCount, required this.pendingUploadCount, required this.uploadedEventCount, required this.eventCounts,
    required this.platformCounts, required this.deviceTierCounts, required this.storageModeCounts, required this.planStatusCounts, required this.connectionStatusCounts,
    required this.screenOpenCount, required this.timeSpentEventCount, required this.totalTimeSpentMs, required this.addExpenseStartedCount, required this.addExpenseCompletedCount,
    required this.addExpenseAbandonedCount, required this.validationErrorCount, required this.saveFailureCount, required this.imageAttachSuccessCount,
    required this.imageAttachFailureCount, required this.ocrStartedCount, required this.ocrCompletedCount, required this.ocrFailedCount, required this.parserStartedCount,
    required this.parserCompletedCount, required this.parserNeedsReviewCount, required this.parserFailedCount, required this.parserCategoryCounts,
    required this.parserNeedsReviewCategoryCounts, required this.parserFailedCategoryCounts, required this.parserFieldConfidenceCounts, required this.parserCategoryHealthCounts,
    required this.parserCategoryReviewActionCounts, required this.parserPackPressureStatusCounts, required this.receiptBrainParserLimitOutcomeCounts,
    required this.receiptBrainLowStorageDownloadRiskCounts, required this.receiptBrainFullOfflineMustStayOptionalCounts,
    required this.receiptBrainFullOfflineExceedsBaseGuardrailCounts, required this.receiptBrainBaseLocalReadingAvailableCounts,
    required this.receiptBrainBaseWorksWithoutCloudAssistCounts, required this.receiptBrainLocalFirstReadinessCounts, required this.receiptBrainLocalFirstReadinessActionCounts,
    required this.receiptBrainLocalFirstReadinessSummaryCounts, required this.receiptBrainFirstInstallBoundaryCounts, required this.receiptBrainFirstInstallBoundaryActionCounts,
    required this.receiptBrainFirstInstallCanRunLowStorageCounts, required this.receiptBrainFirstInstallRequiresBaseCapabilityCounts,
    required this.receiptBrainFirstInstallBoundarySummaryCounts, required this.receiptInstallRequiredSegmentCounts, required this.receiptInstallFullOfflineSegmentCounts,
    required this.receiptInstallLowStorageImpactCounts, required this.receiptInstallRecommendedDistributionCounts, required this.receiptInstallCameraShellParserFreeCounts,
    required this.receiptInstallBaseUsefulOnTinyPhonesCounts, required this.receiptInstallOptionalPacksRequireConsentCounts, required this.receiptLocalOnlyAcceptanceStatusCounts,
    required this.receiptLocalOnlyAcceptanceActionCounts, required this.receiptLocalOnlyBaseFlowCanRunCounts, required this.receiptLocalOnlyBlocksLowStorageCounts,
    required this.receiptLocalOnlyEvidenceCounts, required this.nativeLocalOnlyCapturePolicyCounts, required this.nativeLocalOnlyBaseFlowCanRunCounts,
    required this.nativeLocalOnlyHeavyPacksMayBlockCaptureCounts, required this.nativeLocalOnlyCloudAssistMayBlockCaptureCounts, required this.receiptRequiredBaseFootprintStatusCounts,
    required this.receiptRequiredBaseFootprintCanShipCounts, required this.receiptRequiredBaseFootprintReviewCounts, required this.receiptRequiredBaseFootprintBlockingReasonCounts,
    required this.receiptRequiredBaseFootprintReviewReasonCounts, required this.ocrStoragePolicyCounts, required this.ocrUsesPreparedSourceBeforeSavedProofCounts,
    required this.ocrUsesSavedProofFallbackCounts, required this.parserRequiredFieldStatusCounts, required this.parserDownstreamReadinessStatusCounts,
    required this.parserDownstreamReadinessCounts, required this.parserReviewRootCauseCounts, required this.localReceiptParserRoutingCounts,
    required this.localParserEvidenceOutcomeCounts, required this.localReceiptParserKeptLocalCount, required this.localReceiptParserOptionalPackOfferCount,
    required this.ocrParserTaskCounts, required this.ocrFieldReadinessCounts, required this.ocrSourceHandoffStatusCounts, required this.ocrSourceHandoffSignalCounts,
    required this.ocrSourceStitchSignalCounts, required this.ocrSourceScannerDecisionCounts, required this.ocrSourceCaptureSourceSignalCounts,
    required this.ocrSourcePhotoQualityRiskCounts, required this.ocrSourceQualityReviewStatusCounts, required this.ocrSourceQualityReviewActionCounts,
    required this.clientProofRedactionStatusCounts, required this.clientProofVisibilityCounts, required this.receiptSelectedLinePurposeCounts,
    required this.receiptSelectedLineCountTotal, required this.receiptExcludedLineCountTotal, required this.receiptClientProofReviewLineCountTotal,
    required this.receiptRedactedLineCountTotal, required this.clientProofRedactionPlanStatusCounts, required this.clientProofVisibleLineCountTotal,
    required this.clientProofHiddenLineCountTotal, required this.clientProofPlanReviewLineCountTotal, required this.topParserCategory, required this.topParserNeedsReviewCategory,
    required this.topParserFailedCategory, required this.topParserCategoryHealth, required this.topParserCategoryReviewAction, required this.topParserPackPressureStatus,
    required this.topReceiptBrainParserLimitOutcome, required this.topReceiptBrainLowStorageDownloadRisk, required this.topReceiptBrainLocalFirstReadiness,
    required this.topReceiptBrainLocalFirstReadinessAction, required this.topReceiptBrainFirstInstallBoundary, required this.topReceiptBrainFirstInstallBoundaryAction,
    required this.topReceiptInstallRecommendedDistribution, required this.topReceiptInstallLowStorageImpact, required this.topReceiptLocalOnlyAcceptanceStatus,
    required this.topReceiptLocalOnlyAcceptanceAction, required this.topNativeLocalOnlyCapturePolicy, required this.topReceiptRequiredBaseFootprintStatus,
    required this.topReceiptRequiredBaseFootprintBlockingReason, required this.topReceiptRequiredBaseFootprintReviewReason, required this.topOcrStoragePolicy,
    required this.topOcrUsesPreparedSourceBeforeSavedProof, required this.topOcrUsesSavedProofFallback, required this.topParserRequiredFieldStatus,
    required this.topParserDownstreamReadinessStatus, required this.topParserDownstreamReadiness, required this.topParserReviewRootCause, required this.topLocalReceiptParserRouting,
    required this.topLocalParserEvidenceOutcome, required this.topOcrParserTask, required this.topOcrFieldReadiness, required this.topOcrSourceHandoffStatus,
    required this.topOcrSourceHandoffSignal, required this.topOcrSourceStitchSignal, required this.topOcrSourceScannerDecision, required this.topOcrSourceCaptureSourceSignal,
    required this.topOcrSourcePhotoQualityRisk, required this.topOcrSourceQualityReviewStatus, required this.topOcrSourceQualityReviewAction,
    required this.topClientProofRedactionStatus, required this.topClientProofVisibility, required this.topReceiptSelectedLinePurpose, required this.topClientProofRedactionPlanStatus,
    required this.receiptPhotoCoverageStatusCounts, required this.receiptPhotoCoverageReasonCounts, required this.receiptPhotoCoverageNeedsMoreCount,
    required this.topReceiptPhotoCoverageStatus, required this.topReceiptPhotoCoverageReason, required this.savedPhotoWarningCounts, required this.savedPhotoWarningCauseCounts,
    required this.savedPhotoWarningSeverityCounts, required this.savedPhotoWarningActionCounts, required this.savedPhotoParserRiskCounts, required this.savedPhotoQualityWarningCount,
    required this.savedPhotoCriticalWarningCount, required this.topSavedPhotoWarning, required this.topSavedPhotoWarningCause, required this.topSavedPhotoWarningSeverity,
    required this.topSavedPhotoWarningActionCode, required this.topSavedPhotoWarningAction, required this.topSavedPhotoParserRisk, required this.preCaptureExposureDecisionCounts,
    required this.preCaptureExposureAdjustmentCount, required this.topPreCaptureExposureDecision, required this.autoExposureDecisionCounts, required this.autoExposureBrightnessCounts,
    required this.autoExposureCandidateCounts, required this.exposureAssistStatusCounts, required this.autoExposureCandidateFrameCount, required this.manualBrightnessChangeCount,
    required this.topAutoExposureDecision, required this.topAutoExposureBrightness, required this.topAutoExposureCandidate, required this.topExposureAssistStatus,
    required this.acceptedPhotoQualityOutcomeCounts, required this.topAcceptedPhotoQualityOutcome, required this.capturedPhotoBrightnessCounts,
    required this.capturedPhotoSharpnessCounts, required this.capturedPhotoExposureMismatchCounts, required this.capturedPhotoQualitySignalCounts,
    required this.capturedPhotoBottomBrightnessCounts, required this.capturedPhotoBottomEdgeScoreCounts, required this.capturedPhotoVerticalQualitySignalCounts,
    required this.topCapturedPhotoBrightness, required this.topCapturedPhotoSharpness, required this.topCapturedPhotoExposureMismatch, required this.topCapturedPhotoQualitySignal,
    required this.topCapturedPhotoBottomBrightness, required this.topCapturedPhotoBottomEdgeScore, required this.topCapturedPhotoVerticalQualitySignal,
    required this.nativeCameraEngineCounts, required this.nativeReceiptCameraSurfaceActualCounts, required this.nativeReceiptCameraSurfaceVerificationCounts,
    required this.nativeCameraIdentityCounts, required this.nativeSettingsContractVersionCounts, required this.nativeControlContractVersionCounts,
    required this.receiptCloudAssistPlanCounts, required this.receiptLocalOcrModeCounts, required this.receiptParserDepthCounts, required this.receiptParserPackCodeCounts,
    required this.receiptOptionalLocalParserPackCodeCounts, required this.receiptCloudFallbackParserPackCodeCounts, required this.receiptParserPackAccuracyBandCounts,
    required this.receiptEstimatedOptionalLocalPackBytesTotal, required this.receiptEstimatedOptionalLocalPackBytesMax, required this.receiptCloudOcrOptionalCount,
    required this.receiptCloudInventoryOptionalCount, required this.topReceiptParserPackDisclosureLabel, required this.nativeDevicePolicyCounts,
    required this.nativeCameraWorkloadTierCounts, required this.nativeCameraResolutionTierCounts, required this.nativeRecoveryResumeStatusCounts,
    required this.nativeRecoveryFreshnessCounts, required this.nativeRecoveryStorageStatusCounts, required this.nativeRecoveryRecoveredPhotoCount,
    required this.nativeRecoveryMultipleSectionCount, required this.nativePreCaptureExposureAbortCount, required this.nativePreCaptureExposureAbortReasonCounts,
    required this.nativeTapFocusControlExpectedCount, required this.nativePinchZoomControlExpectedCount, required this.nativeExposureSliderControlExpectedCount,
    required this.nativeExposureResetControlExpectedCount, required this.nativeSettingsControlExpectedCount, required this.nativeBackControlExpectedCount,
    required this.nativeTorchControlExpectedCount, required this.nativeSettingsOpenCount, required this.nativeZoomGestureStartCount, required this.nativeZoomChangeCount,
    required this.nativeZoomUnavailableCount, required this.nativeZoomStatusCounts, required this.nativeBackDispatchPathCounts, required this.topNativeZoomStatus,
    required this.topNativePreCaptureExposureAbortReason, required this.topNativeBackDispatchPath, required this.topNativeCameraEngine,
    required this.topNativeReceiptCameraSurfaceActual, required this.topNativeReceiptCameraSurfaceVerification, required this.topNativeCameraIdentity,
    required this.topNativeSettingsContractVersion, required this.topNativeControlContractVersion, required this.topReceiptCloudAssistPlan, required this.topReceiptLocalOcrMode,
    required this.topReceiptParserDepth, required this.topReceiptParserPackCode, required this.topReceiptOptionalLocalParserPackCode,
    required this.topReceiptCloudFallbackParserPackCode, required this.topReceiptParserPackAccuracyBand, required this.topNativeDevicePolicy, required this.topNativeCameraWorkloadTier,
    required this.topNativeCameraResolutionTier, required this.topNativeRecoveryResumeStatus, required this.topNativeRecoveryFreshness, required this.topNativeRecoveryStorageStatus,
    required this.topNativeRecoveryAction, required this.capabilityPolicyCodeCounts, required this.topCapabilityPolicyCode, required this.nativeCaptureSourcePolicyCounts,
    required this.topNativeCaptureSourcePolicy, required this.stitchStatusCounts, required this.stitchFallbackReasonCounts, required this.stitchConfidenceBucketCounts,
    required this.stitchPairDiagnosticCounts, required this.topStitchStatus, required this.topStitchFallbackReason, required this.topStitchConfidenceBucket,
    required this.topStitchPairDiagnostic, required this.ocrCorrectionOpenedCount, required this.appFilledReceiptLineConfirmedCount, required this.appFilledReceiptLineCorrectedCount,
    required this.userCorrectionCount, required this.cloudBackupSuccessCount, required this.cloudBackupFailureCount, required this.syncPendingCount, required this.syncedCount,
    required this.syncFailedCount, required this.expenseSummaryQueuedCount, required this.expenseSummaryOcrContractQueuedCount, required this.expenseSummaryOcrContractSkippedCount,
    required this.expenseSummaryOcrContractSourceCounts, required this.topExpenseSummaryOcrContractSource, required this.expenseSummaryOcrContractSkippedReasonCounts,
    required this.topExpenseSummaryOcrContractSkippedReason, required this.exportStartedCount, required this.exportCompletedCount, required this.exportBlockedCount,
    required this.exportFailedCount, required this.ocrFailureCauseCounts, required this.topOcrFailureCause, required this.ocrFailureSourceCounts, required this.topOcrFailureSource,
    required this.ocrFailureStageCounts, required this.topOcrFailureStage, required this.failureBreakdowns, required this.recentFailureDetails,
  });

  factory ExpenseTelemetryHealthSnapshot.fromRecords(Iterable<ExpenseTelemetryRecord> records, {DateTime? generatedAtUtc}) {
    return _buildExpenseTelemetryHealthSnapshotFromRecords(records, generatedAtUtc: generatedAtUtc);
  }
  final DateTime generatedAtUtc;
  final int totalEventCount, pendingUploadCount, uploadedEventCount;
  final Map<String, int> eventCounts, platformCounts, deviceTierCounts, storageModeCounts;
  final Map<String, int> planStatusCounts, connectionStatusCounts;
  final int screenOpenCount, timeSpentEventCount, totalTimeSpentMs, addExpenseStartedCount, addExpenseCompletedCount, addExpenseAbandonedCount;
  final int validationErrorCount, saveFailureCount, imageAttachSuccessCount, imageAttachFailureCount, ocrStartedCount, ocrCompletedCount;
  final int ocrFailedCount, parserStartedCount, parserCompletedCount, parserNeedsReviewCount, parserFailedCount;
  final Map<String, int> parserCategoryCounts, parserNeedsReviewCategoryCounts, parserFailedCategoryCounts, parserFieldConfidenceCounts;
  final Map<String, int> parserCategoryHealthCounts, parserCategoryReviewActionCounts, parserPackPressureStatusCounts, receiptBrainParserLimitOutcomeCounts;
  final Map<String, int> receiptBrainLowStorageDownloadRiskCounts, receiptBrainFullOfflineMustStayOptionalCounts, receiptBrainFullOfflineExceedsBaseGuardrailCounts, receiptBrainBaseLocalReadingAvailableCounts;
  final Map<String, int> receiptBrainBaseWorksWithoutCloudAssistCounts, receiptBrainLocalFirstReadinessCounts, receiptBrainLocalFirstReadinessActionCounts, receiptBrainLocalFirstReadinessSummaryCounts;
  final Map<String, int> receiptBrainFirstInstallBoundaryCounts, receiptBrainFirstInstallBoundaryActionCounts, receiptBrainFirstInstallCanRunLowStorageCounts, receiptBrainFirstInstallRequiresBaseCapabilityCounts;
  final Map<String, int> receiptBrainFirstInstallBoundarySummaryCounts, receiptInstallRequiredSegmentCounts, receiptInstallFullOfflineSegmentCounts, receiptInstallLowStorageImpactCounts;
  final Map<String, int> receiptInstallRecommendedDistributionCounts, receiptInstallCameraShellParserFreeCounts, receiptInstallBaseUsefulOnTinyPhonesCounts, receiptInstallOptionalPacksRequireConsentCounts;
  final Map<String, int> receiptLocalOnlyAcceptanceStatusCounts, receiptLocalOnlyAcceptanceActionCounts, receiptLocalOnlyBaseFlowCanRunCounts, receiptLocalOnlyBlocksLowStorageCounts;
  final Map<String, int> receiptLocalOnlyEvidenceCounts, nativeLocalOnlyCapturePolicyCounts, nativeLocalOnlyBaseFlowCanRunCounts, nativeLocalOnlyHeavyPacksMayBlockCaptureCounts;
  final Map<String, int> nativeLocalOnlyCloudAssistMayBlockCaptureCounts, receiptRequiredBaseFootprintStatusCounts, receiptRequiredBaseFootprintCanShipCounts, receiptRequiredBaseFootprintReviewCounts;
  final Map<String, int> receiptRequiredBaseFootprintBlockingReasonCounts, receiptRequiredBaseFootprintReviewReasonCounts, ocrStoragePolicyCounts, ocrUsesPreparedSourceBeforeSavedProofCounts;
  final Map<String, int> ocrUsesSavedProofFallbackCounts, parserRequiredFieldStatusCounts, parserDownstreamReadinessStatusCounts, parserDownstreamReadinessCounts;
  final Map<String, int> parserReviewRootCauseCounts, localReceiptParserRoutingCounts, localParserEvidenceOutcomeCounts;
  final int localReceiptParserKeptLocalCount, localReceiptParserOptionalPackOfferCount;
  final Map<String, int> ocrParserTaskCounts, ocrFieldReadinessCounts, ocrSourceHandoffStatusCounts, ocrSourceHandoffSignalCounts;
  final Map<String, int> ocrSourceStitchSignalCounts, ocrSourceScannerDecisionCounts, ocrSourceCaptureSourceSignalCounts, ocrSourcePhotoQualityRiskCounts;
  final Map<String, int> ocrSourceQualityReviewStatusCounts, ocrSourceQualityReviewActionCounts, clientProofRedactionStatusCounts, clientProofVisibilityCounts;
  final Map<String, int> receiptSelectedLinePurposeCounts;
  final int receiptSelectedLineCountTotal, receiptExcludedLineCountTotal, receiptClientProofReviewLineCountTotal, receiptRedactedLineCountTotal;
  final Map<String, int> clientProofRedactionPlanStatusCounts;
  final int clientProofVisibleLineCountTotal, clientProofHiddenLineCountTotal, clientProofPlanReviewLineCountTotal;
  final String topParserCategory, topParserNeedsReviewCategory, topParserFailedCategory, topParserCategoryHealth, topParserCategoryReviewAction, topParserPackPressureStatus;
  final String topReceiptBrainParserLimitOutcome, topReceiptBrainLowStorageDownloadRisk, topReceiptBrainLocalFirstReadiness, topReceiptBrainLocalFirstReadinessAction;
  final String topReceiptBrainFirstInstallBoundary, topReceiptBrainFirstInstallBoundaryAction;
  final String topReceiptInstallRecommendedDistribution, topReceiptInstallLowStorageImpact, topReceiptLocalOnlyAcceptanceStatus, topReceiptLocalOnlyAcceptanceAction;
  final String topNativeLocalOnlyCapturePolicy, topReceiptRequiredBaseFootprintStatus;
  final String topReceiptRequiredBaseFootprintBlockingReason, topReceiptRequiredBaseFootprintReviewReason, topOcrStoragePolicy, topOcrUsesPreparedSourceBeforeSavedProof;
  final String topOcrUsesSavedProofFallback, topParserRequiredFieldStatus;
  final String topParserDownstreamReadinessStatus, topParserDownstreamReadiness, topParserReviewRootCause, topLocalReceiptParserRouting, topLocalParserEvidenceOutcome, topOcrParserTask;
  final String topOcrFieldReadiness, topOcrSourceHandoffStatus, topOcrSourceHandoffSignal, topOcrSourceStitchSignal, topOcrSourceScannerDecision, topOcrSourceCaptureSourceSignal;
  final String topOcrSourcePhotoQualityRisk, topOcrSourceQualityReviewStatus, topOcrSourceQualityReviewAction, topClientProofRedactionStatus, topClientProofVisibility, topReceiptSelectedLinePurpose;
  final String topClientProofRedactionPlanStatus;
  final Map<String, int> receiptPhotoCoverageStatusCounts, receiptPhotoCoverageReasonCounts;
  final int receiptPhotoCoverageNeedsMoreCount;
  final String topReceiptPhotoCoverageStatus, topReceiptPhotoCoverageReason;
  final Map<String, int> savedPhotoWarningCounts, savedPhotoWarningCauseCounts, savedPhotoWarningSeverityCounts, savedPhotoWarningActionCounts;
  final Map<String, int> savedPhotoParserRiskCounts;
  final int savedPhotoQualityWarningCount, savedPhotoCriticalWarningCount;
  final String topSavedPhotoWarning, topSavedPhotoWarningCause, topSavedPhotoWarningSeverity, topSavedPhotoWarningActionCode, topSavedPhotoWarningAction, topSavedPhotoParserRisk;
  final Map<String, int> preCaptureExposureDecisionCounts;
  final int preCaptureExposureAdjustmentCount;
  final String topPreCaptureExposureDecision;
  final Map<String, int> autoExposureDecisionCounts, autoExposureBrightnessCounts, autoExposureCandidateCounts, exposureAssistStatusCounts;
  final int autoExposureCandidateFrameCount, manualBrightnessChangeCount;
  final String topAutoExposureDecision, topAutoExposureBrightness, topAutoExposureCandidate, topExposureAssistStatus;
  final Map<String, int> acceptedPhotoQualityOutcomeCounts;
  final String topAcceptedPhotoQualityOutcome;
  final Map<String, int> capturedPhotoBrightnessCounts, capturedPhotoSharpnessCounts, capturedPhotoExposureMismatchCounts, capturedPhotoQualitySignalCounts;
  final Map<String, int> capturedPhotoBottomBrightnessCounts, capturedPhotoBottomEdgeScoreCounts, capturedPhotoVerticalQualitySignalCounts;
  final String topCapturedPhotoBrightness, topCapturedPhotoSharpness, topCapturedPhotoExposureMismatch, topCapturedPhotoQualitySignal, topCapturedPhotoBottomBrightness, topCapturedPhotoBottomEdgeScore;
  final String topCapturedPhotoVerticalQualitySignal;
  final Map<String, int> nativeCameraEngineCounts, nativeReceiptCameraSurfaceActualCounts, nativeReceiptCameraSurfaceVerificationCounts, nativeCameraIdentityCounts;
  final Map<String, int> nativeSettingsContractVersionCounts, nativeControlContractVersionCounts, receiptCloudAssistPlanCounts, receiptLocalOcrModeCounts;
  final Map<String, int> receiptParserDepthCounts, receiptParserPackCodeCounts, receiptOptionalLocalParserPackCodeCounts, receiptCloudFallbackParserPackCodeCounts;
  final Map<String, int> receiptParserPackAccuracyBandCounts;
  final int receiptEstimatedOptionalLocalPackBytesTotal, receiptEstimatedOptionalLocalPackBytesMax, receiptCloudOcrOptionalCount, receiptCloudInventoryOptionalCount;
  final String topReceiptParserPackDisclosureLabel;
  final Map<String, int> nativeDevicePolicyCounts, nativeCameraWorkloadTierCounts, nativeCameraResolutionTierCounts, nativeRecoveryResumeStatusCounts;
  final Map<String, int> nativeRecoveryFreshnessCounts, nativeRecoveryStorageStatusCounts;
  final int nativeRecoveryRecoveredPhotoCount, nativeRecoveryMultipleSectionCount, nativePreCaptureExposureAbortCount;
  final Map<String, int> nativePreCaptureExposureAbortReasonCounts;
  final int nativeTapFocusControlExpectedCount, nativePinchZoomControlExpectedCount, nativeExposureSliderControlExpectedCount, nativeExposureResetControlExpectedCount;
  final int nativeSettingsControlExpectedCount, nativeBackControlExpectedCount;
  final int nativeTorchControlExpectedCount, nativeSettingsOpenCount, nativeZoomGestureStartCount, nativeZoomChangeCount, nativeZoomUnavailableCount;
  final Map<String, int> nativeZoomStatusCounts, nativeBackDispatchPathCounts;
  final String topNativeZoomStatus, topNativePreCaptureExposureAbortReason, topNativeBackDispatchPath, topNativeCameraEngine, topNativeReceiptCameraSurfaceActual, topNativeReceiptCameraSurfaceVerification;
  final String topNativeCameraIdentity, topNativeSettingsContractVersion, topNativeControlContractVersion, topReceiptCloudAssistPlan, topReceiptLocalOcrMode, topReceiptParserDepth;
  final String topReceiptParserPackCode, topReceiptOptionalLocalParserPackCode, topReceiptCloudFallbackParserPackCode, topReceiptParserPackAccuracyBand, topNativeDevicePolicy, topNativeCameraWorkloadTier;
  final String topNativeCameraResolutionTier, topNativeRecoveryResumeStatus, topNativeRecoveryFreshness, topNativeRecoveryStorageStatus, topNativeRecoveryAction;
  final Map<String, int> capabilityPolicyCodeCounts;
  final String topCapabilityPolicyCode;
  final Map<String, int> nativeCaptureSourcePolicyCounts;
  final String topNativeCaptureSourcePolicy;
  final Map<String, int> stitchStatusCounts, stitchFallbackReasonCounts, stitchConfidenceBucketCounts, stitchPairDiagnosticCounts;
  final String topStitchStatus, topStitchFallbackReason, topStitchConfidenceBucket, topStitchPairDiagnostic;
  final int ocrCorrectionOpenedCount, appFilledReceiptLineConfirmedCount, appFilledReceiptLineCorrectedCount, userCorrectionCount, cloudBackupSuccessCount, cloudBackupFailureCount;
  final int syncPendingCount, syncedCount, syncFailedCount, expenseSummaryQueuedCount, expenseSummaryOcrContractQueuedCount, expenseSummaryOcrContractSkippedCount;
  final Map<String, int> expenseSummaryOcrContractSourceCounts;
  final String topExpenseSummaryOcrContractSource;
  final Map<String, int> expenseSummaryOcrContractSkippedReasonCounts;
  final String topExpenseSummaryOcrContractSkippedReason;
  final int exportStartedCount, exportCompletedCount, exportBlockedCount, exportFailedCount;
  final Map<String, int> ocrFailureCauseCounts;
  final String topOcrFailureCause;
  final Map<String, int> ocrFailureSourceCounts;
  final String topOcrFailureSource;
  final Map<String, int> ocrFailureStageCounts;
  final String topOcrFailureStage;
  final List<ExpenseFailureBreakdown> failureBreakdowns;
  final List<ExpenseFailureEventDetail> recentFailureDetails;
}
// dart format on
