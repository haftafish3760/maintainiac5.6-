part of 'expense_screen_telemetry.dart';

extension ExpenseTelemetryHealthSnapshotCommandCenterMap
    on ExpenseTelemetryHealthSnapshot {
  Map<String, Object?> toCommandCenterMap() {
    return {
      'schema': 'expense_screen_telemetry_health_v1',
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'healthLabel': healthLabel,
      'totalEventCount': totalEventCount,
      'pendingUploadCount': pendingUploadCount,
      'uploadedEventCount': uploadedEventCount,
      'eventCounts': eventCounts,
      'platformCounts': platformCounts,
      'deviceTierCounts': deviceTierCounts,
      'storageModeCounts': storageModeCounts,
      'planStatusCounts': planStatusCounts,
      'connectionStatusCounts': connectionStatusCounts,
      'screenOpenCount': screenOpenCount,
      'averageTimeSpentSeconds': averageTimeSpentSeconds,
      'addExpenseStartedCount': addExpenseStartedCount,
      'addExpenseCompletedCount': addExpenseCompletedCount,
      'addExpenseAbandonedCount': addExpenseAbandonedCount,
      'addExpenseCompletionRate': addExpenseCompletionRate,
      'addExpenseAbandonmentRate': addExpenseAbandonmentRate,
      'validationErrorCount': validationErrorCount,
      'saveFailureCount': saveFailureCount,
      'imageAttachSuccessCount': imageAttachSuccessCount,
      'imageAttachFailureCount': imageAttachFailureCount,
      'imageAttachFailureRate': imageAttachFailureRate,
      'ocrStartedCount': ocrStartedCount,
      'ocrCompletedCount': ocrCompletedCount,
      'ocrFailedCount': ocrFailedCount,
      'ocrSuccessRate': ocrSuccessRate,
      'parserStartedCount': parserStartedCount,
      'parserCompletedCount': parserCompletedCount,
      'parserNeedsReviewCount': parserNeedsReviewCount,
      'parserFailedCount': parserFailedCount,
      'parserSuccessRate': parserSuccessRate,
      'parserReviewRate': parserReviewRate,
      'parserFailureRate': parserFailureRate,
      'parserCategoryCounts': parserCategoryCounts,
      'parserNeedsReviewCategoryCounts': parserNeedsReviewCategoryCounts,
      'parserFailedCategoryCounts': parserFailedCategoryCounts,
      'parserFieldConfidenceCounts': parserFieldConfidenceCounts,
      'parserCategoryHealthCounts': parserCategoryHealthCounts,
      'parserCategoryReviewActionCounts': parserCategoryReviewActionCounts,
      'parserPackPressureStatusCounts': parserPackPressureStatusCounts,
      ...receiptBrainCommandCenterMap,
      'ocrStoragePolicyCounts': ocrStoragePolicyCounts,
      'ocrUsesPreparedSourceBeforeSavedProofCounts':
          ocrUsesPreparedSourceBeforeSavedProofCounts,
      'ocrUsesSavedProofFallbackCounts': ocrUsesSavedProofFallbackCounts,
      'parserRequiredFieldStatusCounts': parserRequiredFieldStatusCounts,
      'parserDownstreamReadinessStatusCounts':
          parserDownstreamReadinessStatusCounts,
      'parserDownstreamReadinessCounts': parserDownstreamReadinessCounts,
      'parserReviewRootCauseCounts': parserReviewRootCauseCounts,
      'localReceiptParserRoutingCounts': localReceiptParserRoutingCounts,
      'localParserEvidenceOutcomeCounts': localParserEvidenceOutcomeCounts,
      'localReceiptParserKeptLocalCount': localReceiptParserKeptLocalCount,
      'localReceiptParserOptionalPackOfferCount':
          localReceiptParserOptionalPackOfferCount,
      'topLocalReceiptParserRouting': topLocalReceiptParserRouting,
      'topLocalParserEvidenceOutcome': topLocalParserEvidenceOutcome,
      'topOcrStoragePolicy': topOcrStoragePolicy,
      'topOcrUsesPreparedSourceBeforeSavedProof':
          topOcrUsesPreparedSourceBeforeSavedProof,
      'topOcrUsesSavedProofFallback': topOcrUsesSavedProofFallback,
      'ocrParserTaskCounts': ocrParserTaskCounts,
      'ocrFieldReadinessCounts': ocrFieldReadinessCounts,
      'ocrSourceHandoffStatusCounts': ocrSourceHandoffStatusCounts,
      'ocrSourceHandoffSignalCounts': ocrSourceHandoffSignalCounts,
      'ocrSourceReviewDepthSignalCounts': ocrSourceReviewDepthSignalCounts,
      'ocrSourceReviewDepthStatusCounts': ocrSourceReviewDepthStatusCounts,
      'ocrSourceStitchSignalCounts': ocrSourceStitchSignalCounts,
      'ocrSourceScannerDecisionCounts': ocrSourceScannerDecisionCounts,
      'ocrSourceCaptureSourceSignalCounts': ocrSourceCaptureSourceSignalCounts,
      'ocrSourcePhotoQualityRiskCounts': ocrSourcePhotoQualityRiskCounts,
      'ocrSourceQualityReviewStatusCounts': ocrSourceQualityReviewStatusCounts,
      'ocrSourceQualityReviewActionCounts': ocrSourceQualityReviewActionCounts,
      'clientProofRedactionStatusCounts': clientProofRedactionStatusCounts,
      'clientProofVisibilityCounts': clientProofVisibilityCounts,
      'receiptSelectedLinePurposeCounts': receiptSelectedLinePurposeCounts,
      'receiptSelectedLineCountTotal': receiptSelectedLineCountTotal,
      'receiptExcludedLineCountTotal': receiptExcludedLineCountTotal,
      'receiptClientProofReviewLineCountTotal':
          receiptClientProofReviewLineCountTotal,
      'receiptRedactedLineCountTotal': receiptRedactedLineCountTotal,
      'clientProofRedactionPlanStatusCounts':
          clientProofRedactionPlanStatusCounts,
      'clientProofVisibleLineCountTotal': clientProofVisibleLineCountTotal,
      'clientProofHiddenLineCountTotal': clientProofHiddenLineCountTotal,
      'clientProofPlanReviewLineCountTotal':
          clientProofPlanReviewLineCountTotal,
      'clientProofLayoutRedactionStatusCounts':
          clientProofLayoutRedactionStatusCounts,
      'clientProofLayoutVisibleLineCountTotal':
          clientProofLayoutVisibleLineCountTotal,
      'clientProofLayoutHiddenLineCountTotal':
          clientProofLayoutHiddenLineCountTotal,
      'clientProofLayoutIgnoredLineCountTotal':
          clientProofLayoutIgnoredLineCountTotal,
      'clientProofLayoutProtectedTypeCountTotal':
          clientProofLayoutProtectedTypeCountTotal,
      'clientProofLayoutMerchantContextCountTotal':
          clientProofLayoutMerchantContextCountTotal,
      'clientProofLayoutTotalsContextCountTotal':
          clientProofLayoutTotalsContextCountTotal,
      if (topParserCategory.isNotEmpty) 'topParserCategory': topParserCategory,
      if (topParserNeedsReviewCategory.isNotEmpty)
        'topParserNeedsReviewCategory': topParserNeedsReviewCategory,
      if (topParserFailedCategory.isNotEmpty)
        'topParserFailedCategory': topParserFailedCategory,
      if (topParserCategoryHealth.isNotEmpty)
        'topParserCategoryHealth': topParserCategoryHealth,
      if (topParserCategoryReviewAction.isNotEmpty)
        'topParserCategoryReviewAction': topParserCategoryReviewAction,
      if (topParserPackPressureStatus.isNotEmpty)
        'topParserPackPressureStatus': topParserPackPressureStatus,
      if (topParserRequiredFieldStatus.isNotEmpty)
        'topParserRequiredFieldStatus': topParserRequiredFieldStatus,
      if (topParserDownstreamReadinessStatus.isNotEmpty)
        'topParserDownstreamReadinessStatus':
            topParserDownstreamReadinessStatus,
      if (topParserDownstreamReadiness.isNotEmpty)
        'topParserDownstreamReadiness': topParserDownstreamReadiness,
      if (topParserReviewRootCause.isNotEmpty)
        'topParserReviewRootCause': topParserReviewRootCause,
      if (topOcrParserTask.isNotEmpty) 'topOcrParserTask': topOcrParserTask,
      if (topOcrFieldReadiness.isNotEmpty)
        'topOcrFieldReadiness': topOcrFieldReadiness,
      if (topOcrSourceHandoffStatus.isNotEmpty)
        'topOcrSourceHandoffStatus': topOcrSourceHandoffStatus,
      if (topOcrSourceHandoffSignal.isNotEmpty)
        'topOcrSourceHandoffSignal': topOcrSourceHandoffSignal,
      if (topOcrSourceReviewDepthSignal.isNotEmpty)
        'topOcrSourceReviewDepthSignal': topOcrSourceReviewDepthSignal,
      if (topOcrSourceReviewDepthStatus.isNotEmpty)
        'topOcrSourceReviewDepthStatus': topOcrSourceReviewDepthStatus,
      if (topOcrSourceStitchSignal.isNotEmpty)
        'topOcrSourceStitchSignal': topOcrSourceStitchSignal,
      if (topOcrSourceScannerDecision.isNotEmpty)
        'topOcrSourceScannerDecision': topOcrSourceScannerDecision,
      if (topOcrSourceCaptureSourceSignal.isNotEmpty)
        'topOcrSourceCaptureSourceSignal': topOcrSourceCaptureSourceSignal,
      if (topOcrSourcePhotoQualityRisk.isNotEmpty)
        'topOcrSourcePhotoQualityRisk': topOcrSourcePhotoQualityRisk,
      if (topOcrSourceQualityReviewStatus.isNotEmpty)
        'topOcrSourceQualityReviewStatus': topOcrSourceQualityReviewStatus,
      if (topOcrSourceQualityReviewAction.isNotEmpty)
        'topOcrSourceQualityReviewAction': topOcrSourceQualityReviewAction,
      if (topClientProofRedactionStatus.isNotEmpty)
        'topClientProofRedactionStatus': topClientProofRedactionStatus,
      if (topClientProofVisibility.isNotEmpty)
        'topClientProofVisibility': topClientProofVisibility,
      if (topReceiptSelectedLinePurpose.isNotEmpty)
        'topReceiptSelectedLinePurpose': topReceiptSelectedLinePurpose,
      if (topClientProofRedactionPlanStatus.isNotEmpty)
        'topClientProofRedactionPlanStatus': topClientProofRedactionPlanStatus,
      if (topClientProofLayoutRedactionStatus.isNotEmpty)
        'topClientProofLayoutRedactionStatus':
            topClientProofLayoutRedactionStatus,
      'receiptPhotoCoverageStatusCounts': receiptPhotoCoverageStatusCounts,
      'receiptPhotoCoverageReasonCounts': receiptPhotoCoverageReasonCounts,
      'receiptPhotoCoverageNeedsMoreCount': receiptPhotoCoverageNeedsMoreCount,
      'receiptPhotoCoverageNeedsMoreRate': receiptPhotoCoverageNeedsMoreRate,
      if (topReceiptPhotoCoverageStatus.isNotEmpty)
        'topReceiptPhotoCoverageStatus': topReceiptPhotoCoverageStatus,
      if (topReceiptPhotoCoverageReason.isNotEmpty)
        'topReceiptPhotoCoverageReason': topReceiptPhotoCoverageReason,
      'savedPhotoWarningCounts': savedPhotoWarningCounts,
      'savedPhotoWarningCauseCounts': savedPhotoWarningCauseCounts,
      'savedPhotoWarningSeverityCounts': savedPhotoWarningSeverityCounts,
      'savedPhotoWarningActionCounts': savedPhotoWarningActionCounts,
      'savedPhotoParserRiskCounts': savedPhotoParserRiskCounts,
      'savedPhotoQualityWarningCount': savedPhotoQualityWarningCount,
      'savedPhotoQualityWarningRate': savedPhotoQualityWarningRate,
      'savedPhotoCriticalWarningCount': savedPhotoCriticalWarningCount,
      'savedPhotoCriticalWarningRate': savedPhotoCriticalWarningRate,
      if (topSavedPhotoWarning.isNotEmpty)
        'topSavedPhotoWarning': topSavedPhotoWarning,
      if (topSavedPhotoWarningCause.isNotEmpty)
        'topSavedPhotoWarningCause': topSavedPhotoWarningCause,
      if (topSavedPhotoWarningSeverity.isNotEmpty)
        'topSavedPhotoWarningSeverity': topSavedPhotoWarningSeverity,
      if (topSavedPhotoWarningActionCode.isNotEmpty)
        'topSavedPhotoWarningActionCode': topSavedPhotoWarningActionCode,
      if (topSavedPhotoWarningAction.isNotEmpty)
        'topSavedPhotoWarningAction': topSavedPhotoWarningAction,
      if (topSavedPhotoParserRisk.isNotEmpty)
        'topSavedPhotoParserRisk': topSavedPhotoParserRisk,
      'preCaptureExposureDecisionCounts': preCaptureExposureDecisionCounts,
      'preCaptureExposureAdjustmentCount': preCaptureExposureAdjustmentCount,
      'preCaptureExposureAdjustmentRate': preCaptureExposureAdjustmentRate,
      if (topPreCaptureExposureDecision.isNotEmpty)
        'topPreCaptureExposureDecision': topPreCaptureExposureDecision,
      'autoExposureDecisionCounts': autoExposureDecisionCounts,
      'autoExposureBrightnessCounts': autoExposureBrightnessCounts,
      'autoExposureCandidateCounts': autoExposureCandidateCounts,
      'exposureAssistStatusCounts': exposureAssistStatusCounts,
      'autoExposureCandidateFrameCount': autoExposureCandidateFrameCount,
      'manualBrightnessChangeCount': manualBrightnessChangeCount,
      if (topAutoExposureDecision.isNotEmpty)
        'topAutoExposureDecision': topAutoExposureDecision,
      if (topAutoExposureBrightness.isNotEmpty)
        'topAutoExposureBrightness': topAutoExposureBrightness,
      if (topAutoExposureCandidate.isNotEmpty)
        'topAutoExposureCandidate': topAutoExposureCandidate,
      if (topExposureAssistStatus.isNotEmpty)
        'topExposureAssistStatus': topExposureAssistStatus,
      'acceptedPhotoQualityOutcomeCounts': acceptedPhotoQualityOutcomeCounts,
      if (topAcceptedPhotoQualityOutcome.isNotEmpty)
        'topAcceptedPhotoQualityOutcome': topAcceptedPhotoQualityOutcome,
      'capturedPhotoBrightnessCounts': capturedPhotoBrightnessCounts,
      'capturedPhotoSharpnessCounts': capturedPhotoSharpnessCounts,
      'capturedPhotoExposureMismatchCounts':
          capturedPhotoExposureMismatchCounts,
      'capturedPhotoQualitySignalCounts': capturedPhotoQualitySignalCounts,
      'capturedPhotoBottomBrightnessCounts':
          capturedPhotoBottomBrightnessCounts,
      'capturedPhotoBottomEdgeScoreCounts': capturedPhotoBottomEdgeScoreCounts,
      'capturedPhotoVerticalQualitySignalCounts':
          capturedPhotoVerticalQualitySignalCounts,
      if (topCapturedPhotoBrightness.isNotEmpty)
        'topCapturedPhotoBrightness': topCapturedPhotoBrightness,
      if (topCapturedPhotoSharpness.isNotEmpty)
        'topCapturedPhotoSharpness': topCapturedPhotoSharpness,
      if (topCapturedPhotoExposureMismatch.isNotEmpty)
        'topCapturedPhotoExposureMismatch': topCapturedPhotoExposureMismatch,
      if (topCapturedPhotoQualitySignal.isNotEmpty)
        'topCapturedPhotoQualitySignal': topCapturedPhotoQualitySignal,
      if (topCapturedPhotoBottomBrightness.isNotEmpty)
        'topCapturedPhotoBottomBrightness': topCapturedPhotoBottomBrightness,
      if (topCapturedPhotoBottomEdgeScore.isNotEmpty)
        'topCapturedPhotoBottomEdgeScore': topCapturedPhotoBottomEdgeScore,
      if (topCapturedPhotoVerticalQualitySignal.isNotEmpty)
        'topCapturedPhotoVerticalQualitySignal':
            topCapturedPhotoVerticalQualitySignal,
      'nativeCameraEngineCounts': nativeCameraEngineCounts,
      'nativeReceiptCameraSurfaceActualCounts':
          nativeReceiptCameraSurfaceActualCounts,
      'nativeReceiptCameraSurfaceVerificationCounts':
          nativeReceiptCameraSurfaceVerificationCounts,
      'nativeCameraIdentityCounts': nativeCameraIdentityCounts,
      'nativeSettingsContractVersionCounts':
          nativeSettingsContractVersionCounts,
      'nativeControlContractVersionCounts': nativeControlContractVersionCounts,
      'receiptCloudAssistPlanCounts': receiptCloudAssistPlanCounts,
      'receiptLocalOcrModeCounts': receiptLocalOcrModeCounts,
      'receiptParserDepthCounts': receiptParserDepthCounts,
      'receiptParserPackCodeCounts': receiptParserPackCodeCounts,
      'receiptOptionalLocalParserPackCodeCounts':
          receiptOptionalLocalParserPackCodeCounts,
      'receiptCloudFallbackParserPackCodeCounts':
          receiptCloudFallbackParserPackCodeCounts,
      'receiptParserPackAccuracyBandCounts':
          receiptParserPackAccuracyBandCounts,
      'receiptEstimatedOptionalLocalPackBytesTotal':
          receiptEstimatedOptionalLocalPackBytesTotal,
      'receiptEstimatedOptionalLocalPackBytesMax':
          receiptEstimatedOptionalLocalPackBytesMax,
      'receiptCloudOcrOptionalCount': receiptCloudOcrOptionalCount,
      'receiptCloudInventoryOptionalCount': receiptCloudInventoryOptionalCount,
      if (topReceiptParserPackDisclosureLabel.isNotEmpty)
        'topReceiptParserPackDisclosureLabel':
            topReceiptParserPackDisclosureLabel,
      ...nativeCameraCommandCenterMap,
      'ocrCorrectionOpenedCount': ocrCorrectionOpenedCount,
      'appFilledReceiptLineConfirmedCount': appFilledReceiptLineConfirmedCount,
      'appFilledReceiptLineCorrectedCount': appFilledReceiptLineCorrectedCount,
      'appFilledReceiptLineCorrectionRate': appFilledReceiptLineCorrectionRate,
      'userCorrectionCount': userCorrectionCount,
      'cloudBackupSuccessCount': cloudBackupSuccessCount,
      'cloudBackupFailureCount': cloudBackupFailureCount,
      'cloudBackupFailureRate': cloudBackupFailureRate,
      'syncPendingCount': syncPendingCount,
      'syncedCount': syncedCount,
      'syncFailedCount': syncFailedCount,
      'syncFailureRate': syncFailureRate,
      'expenseSummaryQueuedCount': expenseSummaryQueuedCount,
      'expenseSummaryOcrContractQueuedCount':
          expenseSummaryOcrContractQueuedCount,
      'expenseSummaryOcrContractSkippedCount':
          expenseSummaryOcrContractSkippedCount,
      'expenseSummaryOcrContractSourceCounts':
          expenseSummaryOcrContractSourceCounts,
      if (topExpenseSummaryOcrContractSource.isNotEmpty)
        'topExpenseSummaryOcrContractSource':
            topExpenseSummaryOcrContractSource,
      'expenseSummaryOcrContractSkippedReasonCounts':
          expenseSummaryOcrContractSkippedReasonCounts,
      if (topExpenseSummaryOcrContractSkippedReason.isNotEmpty)
        'topExpenseSummaryOcrContractSkippedReason':
            topExpenseSummaryOcrContractSkippedReason,
      'exportStartedCount': exportStartedCount,
      'exportCompletedCount': exportCompletedCount,
      'exportBlockedCount': exportBlockedCount,
      'exportFailedCount': exportFailedCount,
      'exportCompletionRate': exportCompletionRate,
      'exportFailureRate': exportFailureRate,
      'ocrFailureCauseCounts': ocrFailureCauseCounts,
      if (topOcrFailureCause.isNotEmpty)
        'topOcrFailureCause': topOcrFailureCause,
      'ocrFailureSourceCounts': ocrFailureSourceCounts,
      if (topOcrFailureSource.isNotEmpty)
        'topOcrFailureSource': topOcrFailureSource,
      if (topOcrFailureSource.isNotEmpty)
        'topOcrFailureSourceAction': _recommendedOcrSourceAction(
          topOcrFailureSource,
        ),
      'ocrFailureStageCounts': ocrFailureStageCounts,
      if (topOcrFailureStage.isNotEmpty)
        'topOcrFailureStage': topOcrFailureStage,
      if (topOcrFailureStage.isNotEmpty)
        'topOcrFailureStageLabel': _safeDiagnosticLabel(topOcrFailureStage),
      'failureBreakdowns': [
        for (final failure in failureBreakdowns) failure.toMap(),
      ],
      'recentFailureDetails': [
        for (final failure in recentFailureDetails) failure.toMap(),
      ],
    };
  }
}
