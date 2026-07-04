part of 'expense_screen_telemetry.dart';

extension _ExpenseTelemetryHealthSnapshotAccumulatorSnapshot
    on _ExpenseTelemetryHealthSnapshotAccumulator {
  ExpenseTelemetryHealthSnapshot toSnapshot() {
    final failureSummary = buildFailureSnapshotSummary();
    return ExpenseTelemetryHealthSnapshot(
      generatedAtUtc: generatedAtUtc,
      totalEventCount: totalEventCount,
      pendingUploadCount: pendingUploadCount,
      uploadedEventCount: uploadedEventCount,
      eventCounts: Map.unmodifiable(eventCounts),
      platformCounts: Map.unmodifiable(platformCounts),
      deviceTierCounts: Map.unmodifiable(deviceTierCounts),
      storageModeCounts: Map.unmodifiable(storageModeCounts),
      planStatusCounts: Map.unmodifiable(planStatusCounts),
      connectionStatusCounts: Map.unmodifiable(connectionStatusCounts),
      screenOpenCount: screenOpenCount,
      timeSpentEventCount: timeSpentEventCount,
      totalTimeSpentMs: totalTimeSpentMs,
      addExpenseStartedCount: addExpenseStartedCount,
      addExpenseCompletedCount: addExpenseCompletedCount,
      addExpenseAbandonedCount: addExpenseAbandonedCount,
      validationErrorCount: validationErrorCount,
      saveFailureCount: saveFailureCount,
      imageAttachSuccessCount: imageAttachSuccessCount,
      imageAttachFailureCount: imageAttachFailureCount,
      ocrStartedCount: ocrStartedCount,
      ocrCompletedCount: ocrCompletedCount,
      ocrFailedCount: ocrFailedCount,
      parserStartedCount: parserStartedCount,
      parserCompletedCount: parserCompletedCount,
      parserNeedsReviewCount: parserNeedsReviewCount,
      parserFailedCount: parserFailedCount,
      parserCategoryCounts: parserCategorySnapshotCounts,
      parserNeedsReviewCategoryCounts: parserNeedsReviewCategorySnapshotCounts,
      parserFailedCategoryCounts: parserFailedCategorySnapshotCounts,
      parserFieldConfidenceCounts: parserFieldConfidenceSnapshotCounts,
      parserCategoryHealthCounts: parserCategoryHealthSnapshotCounts,
      parserCategoryReviewActionCounts:
          parserCategoryReviewActionSnapshotCounts,
      parserPackPressureStatusCounts: parserPackPressureStatusSnapshotCounts,
      receiptBrainParserLimitOutcomeCounts:
          receiptReadinessSummary.parserLimitOutcomeCounts,
      receiptBrainLowStorageDownloadRiskCounts:
          receiptReadinessSummary.lowStorageDownloadRiskCounts,
      receiptBrainFullOfflineMustStayOptionalCounts:
          receiptReadinessSummary.fullOfflineMustStayOptionalCounts,
      receiptBrainFullOfflineExceedsBaseGuardrailCounts:
          receiptReadinessSummary.fullOfflineExceedsBaseGuardrailCounts,
      receiptBrainBaseLocalReadingAvailableCounts:
          receiptReadinessSummary.baseLocalReadingAvailableCounts,
      receiptBrainBaseWorksWithoutCloudAssistCounts:
          receiptReadinessSummary.baseWorksWithoutCloudAssistCounts,
      receiptBrainLocalFirstReadinessCounts:
          receiptReadinessSummary.localFirstReadinessCounts,
      receiptBrainLocalFirstReadinessActionCounts:
          receiptReadinessSummary.localFirstReadinessActionCounts,
      receiptBrainLocalFirstReadinessSummaryCounts:
          receiptReadinessSummary.localFirstReadinessSummaryCounts,
      receiptBrainFirstInstallBoundaryCounts:
          receiptReadinessSummary.firstInstallBoundaryCounts,
      receiptBrainFirstInstallBoundaryActionCounts:
          receiptReadinessSummary.firstInstallBoundaryActionCounts,
      receiptBrainFirstInstallCanRunLowStorageCounts:
          receiptReadinessSummary.firstInstallCanRunLowStorageCounts,
      receiptBrainFirstInstallRequiresBaseCapabilityCounts:
          receiptReadinessSummary.firstInstallRequiresBaseCapabilityCounts,
      receiptBrainFirstInstallBoundarySummaryCounts:
          receiptReadinessSummary.firstInstallBoundarySummaryCounts,
      receiptInstallRequiredSegmentCounts:
          receiptReadinessSummary.installRequiredSegmentCounts,
      receiptInstallFullOfflineSegmentCounts:
          receiptReadinessSummary.installFullOfflineSegmentCounts,
      receiptInstallLowStorageImpactCounts:
          receiptReadinessSummary.installLowStorageImpactCounts,
      receiptInstallRecommendedDistributionCounts:
          receiptReadinessSummary.installRecommendedDistributionCounts,
      receiptInstallCameraShellParserFreeCounts:
          receiptReadinessSummary.installCameraShellParserFreeCounts,
      receiptInstallBaseUsefulOnTinyPhonesCounts:
          receiptReadinessSummary.installBaseUsefulOnTinyPhonesCounts,
      receiptInstallOptionalPacksRequireConsentCounts:
          receiptReadinessSummary.installOptionalPacksRequireConsentCounts,
      receiptLocalOnlyAcceptanceStatusCounts:
          receiptReadinessSummary.localOnlyAcceptanceStatusCounts,
      receiptLocalOnlyAcceptanceActionCounts:
          receiptReadinessSummary.localOnlyAcceptanceActionCounts,
      receiptLocalOnlyBaseFlowCanRunCounts:
          receiptReadinessSummary.localOnlyBaseFlowCanRunCounts,
      receiptLocalOnlyBlocksLowStorageCounts:
          receiptReadinessSummary.localOnlyBlocksLowStorageCounts,
      receiptLocalOnlyEvidenceCounts:
          receiptReadinessSummary.localOnlyEvidenceCounts,
      nativeLocalOnlyCapturePolicyCounts:
          receiptReadinessSummary.nativeLocalOnlyCapturePolicyCounts,
      nativeLocalOnlyBaseFlowCanRunCounts:
          receiptReadinessSummary.nativeLocalOnlyBaseFlowCanRunCounts,
      nativeLocalOnlyHeavyPacksMayBlockCaptureCounts: receiptReadinessSummary
          .nativeLocalOnlyHeavyPacksMayBlockCaptureCounts,
      nativeLocalOnlyCloudAssistMayBlockCaptureCounts: receiptReadinessSummary
          .nativeLocalOnlyCloudAssistMayBlockCaptureCounts,
      receiptRequiredBaseFootprintStatusCounts:
          receiptReadinessSummary.requiredBaseFootprintStatusCounts,
      receiptRequiredBaseFootprintCanShipCounts:
          receiptReadinessSummary.requiredBaseFootprintCanShipCounts,
      receiptRequiredBaseFootprintReviewCounts:
          receiptReadinessSummary.requiredBaseFootprintReviewCounts,
      receiptRequiredBaseFootprintBlockingReasonCounts:
          receiptReadinessSummary.requiredBaseFootprintBlockingReasonCounts,
      receiptRequiredBaseFootprintReviewReasonCounts:
          receiptReadinessSummary.requiredBaseFootprintReviewReasonCounts,
      ocrStoragePolicyCounts: receiptReadinessSummary.ocrStoragePolicyCounts,
      ocrUsesPreparedSourceBeforeSavedProofCounts:
          receiptReadinessSummary.ocrUsesPreparedSourceBeforeSavedProofCounts,
      ocrUsesSavedProofFallbackCounts:
          receiptReadinessSummary.ocrUsesSavedProofFallbackCounts,
      parserRequiredFieldStatusCounts: parserRequiredFieldStatusSnapshotCounts,
      parserDownstreamReadinessStatusCounts:
          parserDownstreamReadinessStatusSnapshotCounts,
      parserDownstreamReadinessCounts: parserDownstreamReadinessSnapshotCounts,
      parserReviewRootCauseCounts: parserReviewRootCauseSnapshotCounts,
      localReceiptParserRoutingCounts: localReceiptParserRoutingSnapshotCounts,
      localParserEvidenceOutcomeCounts:
          localParserEvidenceOutcomeSnapshotCounts,
      localReceiptParserKeptLocalCount: localReceiptParserKeptLocalCount,
      localReceiptParserOptionalPackOfferCount:
          localReceiptParserOptionalPackOfferCount,
      ocrParserTaskCounts: ocrParserTaskSnapshotCounts,
      ocrFieldReadinessCounts: ocrFieldReadinessSnapshotCounts,
      ocrSourceHandoffStatusCounts: ocrSourceSummary.handoffStatusCounts,
      ocrSourceHandoffSignalCounts: ocrSourceSummary.handoffSignalCounts,
      ocrSourceStitchSignalCounts: ocrSourceSummary.stitchSignalCounts,
      ocrSourceScannerDecisionCounts: ocrSourceSummary.scannerDecisionCounts,
      ocrSourceCaptureSourceSignalCounts:
          ocrSourceSummary.captureSourceSignalCounts,
      ocrSourcePhotoQualityRiskCounts: ocrSourceSummary.photoQualityRiskCounts,
      ocrSourceQualityReviewStatusCounts:
          ocrSourceSummary.qualityReviewStatusCounts,
      ocrSourceQualityReviewActionCounts:
          ocrSourceSummary.qualityReviewActionCounts,
      clientProofRedactionStatusCounts:
          clientProofSummary.redactionStatusCounts,
      clientProofVisibilityCounts: clientProofSummary.visibilityCounts,
      receiptSelectedLinePurposeCounts:
          clientProofSummary.selectedLinePurposeCounts,
      receiptSelectedLineCountTotal: clientProofSummary.selectedLineCountTotal,
      receiptExcludedLineCountTotal: clientProofSummary.excludedLineCountTotal,
      receiptClientProofReviewLineCountTotal:
          clientProofSummary.reviewLineCountTotal,
      receiptRedactedLineCountTotal: clientProofSummary.redactedLineCountTotal,
      clientProofRedactionPlanStatusCounts:
          clientProofSummary.redactionPlanStatusCounts,
      clientProofVisibleLineCountTotal:
          clientProofSummary.visibleLineCountTotal,
      clientProofHiddenLineCountTotal: clientProofSummary.hiddenLineCountTotal,
      clientProofPlanReviewLineCountTotal:
          clientProofSummary.planReviewLineCountTotal,
      clientProofLayoutRedactionStatusCounts:
          clientProofSummary.layoutRedactionStatusCounts,
      clientProofLayoutVisibleLineCountTotal:
          clientProofSummary.layoutVisibleLineCountTotal,
      clientProofLayoutHiddenLineCountTotal:
          clientProofSummary.layoutHiddenLineCountTotal,
      clientProofLayoutIgnoredLineCountTotal:
          clientProofSummary.layoutIgnoredLineCountTotal,
      clientProofLayoutProtectedTypeCountTotal:
          clientProofSummary.layoutProtectedTypeCountTotal,
      clientProofLayoutMerchantContextCountTotal:
          clientProofSummary.layoutMerchantContextCountTotal,
      clientProofLayoutTotalsContextCountTotal:
          clientProofSummary.layoutTotalsContextCountTotal,
      topParserCategory: topParserCategory,
      topParserNeedsReviewCategory: topParserNeedsReviewCategory,
      topParserFailedCategory: topParserFailedCategory,
      topParserCategoryHealth: topParserCategoryHealth,
      topParserCategoryReviewAction: topParserCategoryReviewAction,
      topParserPackPressureStatus: topParserPackPressureStatus,
      topReceiptBrainParserLimitOutcome:
          receiptReadinessSummary.topParserLimitOutcome,
      topReceiptBrainLowStorageDownloadRisk:
          receiptReadinessSummary.topLowStorageDownloadRisk,
      topReceiptBrainLocalFirstReadiness:
          receiptReadinessSummary.topLocalFirstReadiness,
      topReceiptBrainLocalFirstReadinessAction:
          receiptReadinessSummary.topLocalFirstReadinessAction,
      topReceiptBrainFirstInstallBoundary:
          receiptReadinessSummary.topFirstInstallBoundary,
      topReceiptBrainFirstInstallBoundaryAction:
          receiptReadinessSummary.topFirstInstallBoundaryAction,
      topReceiptInstallRecommendedDistribution:
          receiptReadinessSummary.topInstallRecommendedDistribution,
      topReceiptInstallLowStorageImpact:
          receiptReadinessSummary.topInstallLowStorageImpact,
      topReceiptLocalOnlyAcceptanceStatus:
          receiptReadinessSummary.topLocalOnlyAcceptanceStatus,
      topReceiptLocalOnlyAcceptanceAction:
          receiptReadinessSummary.topLocalOnlyAcceptanceAction,
      topNativeLocalOnlyCapturePolicy:
          receiptReadinessSummary.topNativeLocalOnlyCapturePolicy,
      topReceiptRequiredBaseFootprintStatus:
          receiptReadinessSummary.topRequiredBaseFootprintStatus,
      topReceiptRequiredBaseFootprintBlockingReason:
          receiptReadinessSummary.topRequiredBaseFootprintBlockingReason,
      topReceiptRequiredBaseFootprintReviewReason:
          receiptReadinessSummary.topRequiredBaseFootprintReviewReason,
      topOcrStoragePolicy: receiptReadinessSummary.topOcrStoragePolicy,
      topOcrUsesPreparedSourceBeforeSavedProof:
          receiptReadinessSummary.topOcrUsesPreparedSourceBeforeSavedProof,
      topOcrUsesSavedProofFallback:
          receiptReadinessSummary.topOcrUsesSavedProofFallback,
      topParserRequiredFieldStatus: topParserRequiredFieldStatus,
      topParserDownstreamReadinessStatus: topParserDownstreamReadinessStatus,
      topParserDownstreamReadiness: topParserDownstreamReadiness,
      topParserReviewRootCause: topParserReviewRootCause,
      topLocalReceiptParserRouting: topLocalReceiptParserRouting,
      topLocalParserEvidenceOutcome: topLocalParserEvidenceOutcome,
      topOcrParserTask: topOcrParserTask,
      topOcrFieldReadiness: topOcrFieldReadiness,
      topOcrSourceHandoffStatus: ocrSourceSummary.topHandoffStatus,
      topOcrSourceHandoffSignal: ocrSourceSummary.topHandoffSignal,
      topOcrSourceStitchSignal: ocrSourceSummary.topStitchSignal,
      topOcrSourceScannerDecision: ocrSourceSummary.topScannerDecision,
      topOcrSourceCaptureSourceSignal: ocrSourceSummary.topCaptureSourceSignal,
      topOcrSourcePhotoQualityRisk: ocrSourceSummary.topPhotoQualityRisk,
      topOcrSourceQualityReviewStatus: ocrSourceSummary.topQualityReviewStatus,
      topOcrSourceQualityReviewAction: ocrSourceSummary.topQualityReviewAction,
      topClientProofRedactionStatus: clientProofSummary.topRedactionStatus,
      topClientProofVisibility: clientProofSummary.topVisibility,
      topReceiptSelectedLinePurpose: clientProofSummary.topSelectedLinePurpose,
      topClientProofRedactionPlanStatus:
          clientProofSummary.topRedactionPlanStatus,
      topClientProofLayoutRedactionStatus:
          clientProofSummary.topLayoutRedactionStatus,
      receiptPhotoCoverageStatusCounts:
          cameraHealthSummary.coverageStatusCounts,
      receiptPhotoCoverageReasonCounts:
          cameraHealthSummary.coverageReasonCounts,
      receiptPhotoCoverageNeedsMoreCount:
          cameraHealthSummary.coverageNeedsMoreCount,
      topReceiptPhotoCoverageStatus: cameraHealthSummary.topCoverageStatus,
      topReceiptPhotoCoverageReason: cameraHealthSummary.topCoverageReason,
      savedPhotoWarningCounts: cameraHealthSummary.savedPhotoWarningCounts,
      savedPhotoWarningCauseCounts:
          cameraHealthSummary.savedPhotoWarningCauseCounts,
      savedPhotoWarningSeverityCounts:
          cameraHealthSummary.savedPhotoWarningSeverityCounts,
      savedPhotoWarningActionCounts:
          cameraHealthSummary.savedPhotoWarningActionCounts,
      savedPhotoParserRiskCounts:
          cameraHealthSummary.savedPhotoParserRiskCounts,
      savedPhotoQualityWarningCount:
          cameraHealthSummary.savedPhotoQualityWarningCount,
      savedPhotoCriticalWarningCount:
          cameraHealthSummary.savedPhotoCriticalWarningCount,
      topSavedPhotoWarning: cameraHealthSummary.topSavedPhotoWarning,
      topSavedPhotoWarningCause: cameraHealthSummary.topSavedPhotoWarningCause,
      topSavedPhotoWarningSeverity:
          cameraHealthSummary.topSavedPhotoWarningSeverity,
      topSavedPhotoWarningActionCode:
          cameraHealthSummary.topSavedPhotoWarningActionCode,
      topSavedPhotoWarningAction:
          cameraHealthSummary.topSavedPhotoWarningAction,
      topSavedPhotoParserRisk: cameraHealthSummary.topSavedPhotoParserRisk,
      preCaptureExposureDecisionCounts:
          exposureQualitySummary.preCaptureDecisionCounts,
      preCaptureExposureAdjustmentCount:
          exposureQualitySummary.preCaptureAdjustmentCount,
      topPreCaptureExposureDecision:
          exposureQualitySummary.topPreCaptureDecision,
      autoExposureDecisionCounts: exposureQualitySummary.autoDecisionCounts,
      autoExposureBrightnessCounts: exposureQualitySummary.autoBrightnessCounts,
      autoExposureCandidateCounts: exposureQualitySummary.autoCandidateCounts,
      exposureAssistStatusCounts: exposureQualitySummary.assistStatusCounts,
      autoExposureCandidateFrameCount:
          exposureQualitySummary.autoCandidateFrameCount,
      manualBrightnessChangeCount: manualBrightnessChangeCount,
      topAutoExposureDecision: exposureQualitySummary.topAutoDecision,
      topAutoExposureBrightness: exposureQualitySummary.topAutoBrightness,
      topAutoExposureCandidate: exposureQualitySummary.topAutoCandidate,
      topExposureAssistStatus: exposureQualitySummary.topAssistStatus,
      acceptedPhotoQualityOutcomeCounts:
          exposureQualitySummary.acceptedPhotoOutcomeCounts,
      topAcceptedPhotoQualityOutcome:
          exposureQualitySummary.topAcceptedPhotoOutcome,
      capturedPhotoBrightnessCounts:
          exposureQualitySummary.capturedBrightnessCounts,
      capturedPhotoSharpnessCounts:
          exposureQualitySummary.capturedSharpnessCounts,
      capturedPhotoExposureMismatchCounts:
          exposureQualitySummary.capturedExposureMismatchCounts,
      capturedPhotoQualitySignalCounts:
          exposureQualitySummary.capturedQualitySignalCounts,
      capturedPhotoBottomBrightnessCounts:
          exposureQualitySummary.capturedBottomBrightnessCounts,
      capturedPhotoBottomEdgeScoreCounts:
          exposureQualitySummary.capturedBottomEdgeScoreCounts,
      capturedPhotoVerticalQualitySignalCounts:
          exposureQualitySummary.capturedVerticalQualitySignalCounts,
      topCapturedPhotoBrightness: exposureQualitySummary.topCapturedBrightness,
      topCapturedPhotoSharpness: exposureQualitySummary.topCapturedSharpness,
      topCapturedPhotoExposureMismatch:
          exposureQualitySummary.topCapturedExposureMismatch,
      topCapturedPhotoQualitySignal:
          exposureQualitySummary.topCapturedQualitySignal,
      topCapturedPhotoBottomBrightness:
          exposureQualitySummary.topCapturedBottomBrightness,
      topCapturedPhotoBottomEdgeScore:
          exposureQualitySummary.topCapturedBottomEdgeScore,
      topCapturedPhotoVerticalQualitySignal:
          exposureQualitySummary.topCapturedVerticalQualitySignal,
      nativeCameraEngineCounts: nativeCameraSummary.engineCounts,
      nativeReceiptCameraSurfaceActualCounts:
          nativeCameraSummary.surfaceActualCounts,
      nativeReceiptCameraSurfaceVerificationCounts:
          nativeCameraSummary.surfaceVerificationCounts,
      nativeCameraIdentityCounts: nativeCameraSummary.identityCounts,
      nativeSettingsContractVersionCounts:
          nativeCameraSummary.settingsContractVersionCounts,
      nativeControlContractVersionCounts:
          nativeCameraSummary.controlContractVersionCounts,
      receiptCloudAssistPlanCounts:
          receiptCapturePlanSummary.cloudAssistPlanCounts,
      receiptLocalOcrModeCounts: receiptCapturePlanSummary.localOcrModeCounts,
      receiptParserDepthCounts: receiptCapturePlanSummary.parserDepthCounts,
      receiptParserPackCodeCounts:
          receiptCapturePlanSummary.parserPackCodeCounts,
      receiptOptionalLocalParserPackCodeCounts:
          receiptCapturePlanSummary.optionalLocalParserPackCodeCounts,
      receiptCloudFallbackParserPackCodeCounts:
          receiptCapturePlanSummary.cloudFallbackParserPackCodeCounts,
      receiptParserPackAccuracyBandCounts:
          receiptCapturePlanSummary.parserPackAccuracyBandCounts,
      receiptEstimatedOptionalLocalPackBytesTotal:
          receiptCapturePlanSummary.estimatedOptionalLocalPackBytesTotal,
      receiptEstimatedOptionalLocalPackBytesMax:
          receiptCapturePlanSummary.estimatedOptionalLocalPackBytesMax,
      receiptCloudOcrOptionalCount:
          receiptCapturePlanSummary.cloudOcrOptionalCount,
      receiptCloudInventoryOptionalCount:
          receiptCapturePlanSummary.cloudInventoryOptionalCount,
      topReceiptParserPackDisclosureLabel:
          receiptCapturePlanSummary.topParserPackDisclosureLabel,
      nativeDevicePolicyCounts: nativeCameraSummary.devicePolicyCounts,
      nativeCameraWorkloadTierCounts: nativeCameraSummary.workloadTierCounts,
      nativeCameraResolutionTierCounts:
          nativeCameraSummary.resolutionTierCounts,
      nativeRecoveryResumeStatusCounts:
          nativeCameraSummary.recoveryResumeStatusCounts,
      nativeRecoveryFreshnessCounts:
          nativeCameraSummary.recoveryFreshnessCounts,
      nativeRecoveryStorageStatusCounts:
          nativeCameraSummary.recoveryStorageStatusCounts,
      nativeRecoveryRecoveredPhotoCount:
          nativeCameraSummary.recoveredPhotoCount,
      nativeRecoveryMultipleSectionCount:
          nativeCameraSummary.multipleSectionCount,
      nativePreCaptureExposureAbortCount: nativePreCaptureExposureAbortCount,
      nativePreCaptureExposureAbortReasonCounts: Map.unmodifiable(
        nativePreCaptureExposureAbortReasonCounts,
      ),
      nativeTapFocusControlExpectedCount:
          nativeControlsSummary.tapFocusExpectedCount,
      nativeContinuousFocusExpectedCount:
          nativeControlsSummary.continuousFocusExpectedCount,
      nativePinchZoomControlExpectedCount:
          nativeControlsSummary.pinchZoomExpectedCount,
      nativeExposureSliderControlExpectedCount:
          nativeControlsSummary.exposureSliderExpectedCount,
      nativeExposureResetControlExpectedCount:
          nativeControlsSummary.exposureResetExpectedCount,
      nativeSettingsControlExpectedCount:
          nativeControlsSummary.settingsExpectedCount,
      nativeBackControlExpectedCount: nativeControlsSummary.backExpectedCount,
      nativeTorchControlExpectedCount: nativeControlsSummary.torchExpectedCount,
      nativeSettingsOpenCount: nativeControlsSummary.settingsOpenCount,
      nativeZoomGestureStartCount: nativeControlsSummary.zoomGestureStartCount,
      nativeZoomChangeCount: nativeControlsSummary.zoomChangeCount,
      nativeZoomUnavailableCount: nativeControlsSummary.zoomUnavailableCount,
      nativeZoomStatusCounts: nativeControlsSummary.zoomStatusCounts,
      nativeBackDispatchPathCounts:
          nativeControlsSummary.backDispatchPathCounts,
      topNativeZoomStatus: nativeControlsSummary.topZoomStatus,
      topNativePreCaptureExposureAbortReason: _topCountKey(
        nativePreCaptureExposureAbortReasonCounts,
      ),
      topNativeBackDispatchPath: nativeControlsSummary.topBackDispatchPath,
      topNativeCameraEngine: nativeCameraSummary.topEngine,
      topNativeReceiptCameraSurfaceActual: nativeCameraSummary.topSurfaceActual,
      topNativeReceiptCameraSurfaceVerification:
          nativeCameraSummary.topSurfaceVerification,
      topNativeCameraIdentity: nativeCameraSummary.topIdentity,
      topNativeSettingsContractVersion:
          nativeCameraSummary.topSettingsContractVersion,
      topNativeControlContractVersion:
          nativeCameraSummary.topControlContractVersion,
      topReceiptCloudAssistPlan: receiptCapturePlanSummary.topCloudAssistPlan,
      topReceiptLocalOcrMode: receiptCapturePlanSummary.topLocalOcrMode,
      topReceiptParserDepth: receiptCapturePlanSummary.topParserDepth,
      topReceiptParserPackCode: receiptCapturePlanSummary.topParserPackCode,
      topReceiptOptionalLocalParserPackCode:
          receiptCapturePlanSummary.topOptionalLocalParserPackCode,
      topReceiptCloudFallbackParserPackCode:
          receiptCapturePlanSummary.topCloudFallbackParserPackCode,
      topReceiptParserPackAccuracyBand:
          receiptCapturePlanSummary.topParserPackAccuracyBand,
      topNativeDevicePolicy: nativeCameraSummary.topDevicePolicy,
      topNativeCameraWorkloadTier: nativeCameraSummary.topWorkloadTier,
      topNativeCameraResolutionTier: nativeCameraSummary.topResolutionTier,
      topNativeRecoveryResumeStatus:
          nativeCameraSummary.topRecoveryResumeStatus,
      topNativeRecoveryFreshness: nativeCameraSummary.topRecoveryFreshness,
      topNativeRecoveryStorageStatus:
          nativeCameraSummary.topRecoveryStorageStatus,
      topNativeRecoveryAction: nativeCameraSummary.topRecoveryAction,
      capabilityPolicyCodeCounts:
          nativeCameraSummary.capabilityPolicyCodeCounts,
      topCapabilityPolicyCode: nativeCameraSummary.topCapabilityPolicyCode,
      nativeCaptureSourcePolicyCounts:
          nativeCameraSummary.captureSourcePolicyCounts,
      topNativeCaptureSourcePolicy: nativeCameraSummary.topCaptureSourcePolicy,
      stitchStatusCounts: receiptCapturePlanSummary.stitchStatusCounts,
      stitchFallbackReasonCounts:
          receiptCapturePlanSummary.stitchFallbackReasonCounts,
      stitchConfidenceBucketCounts:
          receiptCapturePlanSummary.stitchConfidenceBucketCounts,
      stitchPairDiagnosticCounts:
          receiptCapturePlanSummary.stitchPairDiagnosticCounts,
      topStitchStatus: receiptCapturePlanSummary.topStitchStatus,
      topStitchFallbackReason:
          receiptCapturePlanSummary.topStitchFallbackReason,
      topStitchConfidenceBucket:
          receiptCapturePlanSummary.topStitchConfidenceBucket,
      topStitchPairDiagnostic:
          receiptCapturePlanSummary.topStitchPairDiagnostic,
      ocrCorrectionOpenedCount: ocrCorrectionOpenedCount,
      appFilledReceiptLineConfirmedCount: appFilledReceiptLineConfirmedCount,
      appFilledReceiptLineCorrectedCount: appFilledReceiptLineCorrectedCount,
      userCorrectionCount: userCorrectionCount,
      cloudBackupSuccessCount: cloudBackupSuccessCount,
      cloudBackupFailureCount: cloudBackupFailureCount,
      syncPendingCount: syncPendingCount,
      syncedCount: syncedCount,
      syncFailedCount: syncFailedCount,
      expenseSummaryQueuedCount: expenseSummarySync.queuedCount,
      expenseSummaryOcrContractQueuedCount:
          expenseSummarySync.ocrContractQueuedCount,
      expenseSummaryOcrContractSkippedCount:
          expenseSummarySync.ocrContractSkippedCount,
      expenseSummaryOcrContractSourceCounts: expenseSummarySync.sourceCounts,
      topExpenseSummaryOcrContractSource: expenseSummarySync.topSource,
      expenseSummaryOcrContractSkippedReasonCounts:
          expenseSummarySync.skippedReasonCounts,
      topExpenseSummaryOcrContractSkippedReason:
          expenseSummarySync.topSkippedReason,
      exportStartedCount: exportStartedCount,
      exportCompletedCount: exportCompletedCount,
      exportBlockedCount: exportBlockedCount,
      exportFailedCount: exportFailedCount,
      ocrFailureCauseCounts: failureSummary.ocrFailure.causeCounts,
      topOcrFailureCause: failureSummary.ocrFailure.topCause,
      ocrFailureSourceCounts: failureSummary.ocrFailure.sourceCounts,
      topOcrFailureSource: failureSummary.ocrFailure.topSource,
      ocrFailureStageCounts: failureSummary.ocrFailure.stageCounts,
      topOcrFailureStage: failureSummary.ocrFailure.topStage,
      failureBreakdowns: failureSummary.breakdowns,
      recentFailureDetails: failureSummary.recentDetails,
    );
  }
}
