part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultMetadata on ReceiptPhotoReviewResult {
  Map<String, Object?> get privacySafeReceiptReaderHandoffMetadata {
    return Map.unmodifiable({
      'receiptReaderHandoffSchema': 'receipt_reader_handoff_v1',
      'receiptDetailsHandoffSchema': 'receipt_details_handoff_v1',
      'receiptReviewExitAction': reviewExitAction,
      'receiptReviewKeptForLater': keptForLater,
      'receiptReaderHandoffIntegrity': receiptReaderHandoffIntegrityLabel,
      'receiptDetailsHandoffIntegrity': receiptDetailsHandoffIntegrityLabel,
      'receiptReaderHandoffCounts': receiptReaderHandoffCounts,
      'receiptDetailsHandoffCounts': receiptDetailsHandoffCounts,
      'receiptReaderHandoffOutcome': acceptedPhotoHandoffOutcome,
      'receiptDetailsHandoffOutcome': acceptedPhotoHandoffOutcome,
      'receiptPhotoReviewHandoffPath': receiptPhotoReviewHandoffPath,
      'receiptPhotoReviewHandoffPathLabel': receiptPhotoReviewHandoffPathLabel,
      'receiptReaderHandoffRoute': acceptedPhotoHandoffRoute,
      'receiptDetailsHandoffRoute': acceptedPhotoHandoffRoute,
      'receiptReaderHandoffNextScreen': acceptedPhotoHandoffNextScreen,
      'receiptDetailsHandoffNextScreen': acceptedPhotoHandoffNextScreen,
      'receiptReaderHandoffNextStepLabel': acceptedPhotoHandoffNextStepLabel,
      'receiptDetailsHandoffNextStepLabel': acceptedPhotoHandoffNextStepLabel,
      'receiptReaderHandoffProcessingLabel':
          acceptedPhotoHandoffProcessingLabel,
      'receiptDetailsHandoffProcessingLabel':
          acceptedPhotoHandoffProcessingLabel,
      'receiptReaderHandoffRouteResultLabel':
          acceptedPhotoHandoffRouteResultLabel,
      'receiptDetailsHandoffRouteResultLabel':
          acceptedPhotoHandoffRouteResultLabel,
      'receiptReaderHandoffMustOpenReceiptDetails':
          acceptedPhotoHandoffMustOpenReceiptDetails,
      'receiptDetailsHandoffMustOpenReceiptDetails':
          acceptedPhotoHandoffMustOpenReceiptDetails,
      'receiptReaderHandoffMustOpenFilledReview':
          acceptedPhotoHandoffMustOpenFilledReview,
      'receiptDetailsHandoffMustOpenFilledReview':
          acceptedPhotoHandoffMustOpenFilledReview,
      'receiptReaderHandoffUserAction': acceptedPhotoHandoffUserAction,
      'receiptDetailsHandoffUserAction': acceptedPhotoHandoffUserAction,
      'receiptReaderHandoffEvidence': privacySafeOcrHandoffEvidenceLabel,
      'receiptDetailsHandoffEvidence': privacySafeOcrHandoffEvidenceLabel,
      'acceptedPhotoWarningProfile': acceptedPhotoWarningProfile,
      'receiptCompletionReviewOutcome': receiptCompletionReviewOutcome,
      if (receiptCompletionChoiceCounts.isNotEmpty)
        'receiptCompletionChoiceCounts': receiptCompletionChoiceCounts,
      'receiptCompletionUserConfirmedComplete':
          userConfirmedPossiblePartialReceiptComplete,
      'receiptNeedsAnotherSectionBeforeDetails':
          needsAnotherReceiptSectionBeforeDetails,
      if (needsAnotherReceiptSectionBeforeDetails)
        'receiptNeedsAnotherSectionReason':
            firstPossiblePartialReceiptReasonCode,
      if (needsAnotherReceiptSectionBeforeDetails)
        'receiptFinalSectionContinuationEvidence':
            finalReceiptSectionContinuationEvidence,
      if (needsAnotherReceiptSectionBeforeDetails)
        'receiptFinalSectionContinuationEvidenceLabel':
            finalReceiptSectionContinuationEvidenceLabel,
      if (hasSavedPhotoQualityWarning)
        'acceptedPhotoWarningActionLabel':
            acceptedPhotoWarningReviewActionLabel,
      if (savedPhotoWarningReviewActionLabels.isNotEmpty)
        'savedPhotoWarningReviewActions': savedPhotoWarningReviewActionLabels,
      'nextReviewMatchReadinessOutcome': nextReviewMatchReadinessOutcome,
      'nextReviewMatchReadinessLabel': nextReviewMatchReadinessLabel,
      'stitchOverlapCoverageCode': stitchResult.overlapCoverageCode,
      'stitchOverlapCoverageLabel': stitchResult.overlapCoverageLabel,
      'stitchSourcePreservationCode': stitchResult.sourcePreservationCode,
      'stitchInputSourceCount': stitchResult.inputPaths.length,
      'stitchOcrSourceCount': stitchResult.ocrSourcePaths.length,
      'stitchOverlapPixelTotal': stitchResult.overlapPixelTotal,
      'stitchUsedManualAdjustment': stitchResult.usedManualAdjustment,
      'stitchMatchedPairCount': stitchResult.matchedPairCount,
      'stitchMissingPairCount': stitchResult.missingPairCount,
      'stitchAllPairsHaveOverlapEvidence':
          stitchResult.allPairsHaveOverlapEvidence,
      ...stitchResult.privacySafeOcrHandoffSafety,
      if (stitchResult.usedFallback)
        'stitchFallbackReasonCode': stitchResult.diagnosticReasonLabel,
      if (stitchResult.usedFallback)
        'stitchFallbackReasonLabel': stitchResult.userFallbackReasonLabel,
      if (stitchResult.usedFallback && stitchResult.failedPairLabel.isNotEmpty)
        'stitchFailedPairLabel': stitchResult.failedPairLabel,
      if (stitchResult.failedPairIndex != null)
        'stitchFailedPairStartSectionNumber': stitchResult.failedPairIndex! + 1,
      if (stitchResult.failedPairIndex != null)
        'stitchFailedPairEndSectionNumber': stitchResult.failedPairIndex! + 2,
      ...privacySafeOcrSourceFirstSummary,
      'nativeReceiptReviewDepth': nativeReceiptReviewDepth,
      if (nativeReceiptReviewDepthCounts.isNotEmpty)
        'nativeReceiptReviewDepthCounts': nativeReceiptReviewDepthCounts,
      'receiptProofDataSaverLevel': dataSaverLevel.name,
      'ocrSourcePreparationCount': preparationDiagnosticsByOcrPath.length,
      if (scannerDecisionCounts.isNotEmpty)
        'ocrSourcePreparationDecisionCounts': scannerDecisionCounts,
      if (ocrStoragePolicyCounts.isNotEmpty)
        'ocrStoragePolicyCounts': ocrStoragePolicyCounts,
      if (ocrStoragePolicyCounts.isNotEmpty)
        'ocrStoragePolicyOutcome': ocrStoragePolicyOutcome,
      if (receiptProofStoragePolicyCounts.isNotEmpty)
        'receiptProofStoragePolicyCounts': receiptProofStoragePolicyCounts,
      if (receiptProofStoragePolicyCounts.isNotEmpty)
        'receiptProofStoragePolicyOutcome': receiptProofStoragePolicyOutcome,
      ...receiptProofTargetSizePolicy.toPrivacySafeDiagnostics(),
      if (ocrUsesPreparedSourceBeforeSavedProofCounts.isNotEmpty)
        'ocrUsesPreparedSourceBeforeSavedProofCounts':
            ocrUsesPreparedSourceBeforeSavedProofCounts,
      if (ocrUsesSavedProofFallbackCounts.isNotEmpty)
        'ocrUsesSavedProofFallbackCounts': ocrUsesSavedProofFallbackCounts,
      if (photoCoverageStatusCounts.isNotEmpty)
        'receiptPhotoCoverageStatusCounts': photoCoverageStatusCounts,
      if (savedPhotoWarningCounts.isNotEmpty)
        'savedPhotoWarningCounts': savedPhotoWarningCounts,
      if (savedPhotoWarningSeverityCounts.isNotEmpty)
        'savedPhotoWarningSeverityCounts': savedPhotoWarningSeverityCounts,
      if (savedPhotoWarningActionCounts.isNotEmpty)
        'savedPhotoWarningActionCounts': savedPhotoWarningActionCounts,
      if (savedPhotoWarningCauseCounts.isNotEmpty)
        'savedPhotoWarningCauseCounts': savedPhotoWarningCauseCounts,
      if (savedPhotoParserRiskCounts.isNotEmpty)
        'savedPhotoParserRiskCounts': savedPhotoParserRiskCounts,
      if (editedPhotoActionCounts.isNotEmpty)
        'reviewPhotoEditActionCounts': editedPhotoActionCounts,
      if (editedPhotoSourceSelectionCounts.isNotEmpty)
        'reviewPhotoEditSourceSelectionCounts':
            editedPhotoSourceSelectionCounts,
      if (editedPhotoReplacedOriginalCounts.isNotEmpty)
        'reviewPhotoEditReplacedOriginalCounts':
            editedPhotoReplacedOriginalCounts,
      if (nativeCameraUiHealthCounts.isNotEmpty)
        'nativeCameraUiHealthCounts': nativeCameraUiHealthCounts,
      if (nativeCameraUiHealthCounts.isNotEmpty)
        'nativeCameraUiHealthOutcome': nativeCameraUiHealthOutcome,
      if (receiptSectionOrderCounts.isNotEmpty)
        'receiptSectionOrderCounts': receiptSectionOrderCounts,
      if (receiptSectionOrderCounts.isNotEmpty)
        'receiptSectionOrderOutcome': receiptSectionOrderOutcome,
      if (receiptSectionOrderCounts.isNotEmpty)
        'receiptSectionOrderEvidenceLabel': receiptSectionOrderEvidenceLabel,
      'receiptSectionOrderNeedsReview': receiptSectionOrderNeedsReview,
      'receiptSectionOrderReviewActionCode':
          receiptSectionOrderReviewActionCode,
      'receiptSectionOrderReviewActionLabel':
          receiptSectionOrderReviewActionLabel,
      ...privacySafeReceiptBrainInstallMetadata,
      if (nativeCloseCapturedPhotoOutcomeCounts.isNotEmpty)
        'nativeCloseCapturedPhotoOutcomeCounts':
            nativeCloseCapturedPhotoOutcomeCounts,
      if (nativeCloseCapturedPhotoOutcomeCounts.isNotEmpty)
        'nativeCloseCapturedPhotoHealthOutcome':
            nativeCloseCapturedPhotoHealthOutcome,
      if (nativeCloseCapturedPhotoOutcomeCounts.isNotEmpty)
        'nativeCloseCapturedPhotoActionLabel':
            nativeCloseCapturedPhotoActionLabel,
      if (nativeRecoveryFreshnessCounts.isNotEmpty)
        'nativeRecoveryFreshnessCounts': nativeRecoveryFreshnessCounts,
      if (nativeRecoveryStorageStatusCounts.isNotEmpty)
        'nativeRecoveryStorageStatusCounts': nativeRecoveryStorageStatusCounts,
      if (nativeCaptureSourcePolicyCounts.isNotEmpty)
        'nativeCaptureSourcePolicyCounts': nativeCaptureSourcePolicyCounts,
      if (nativeCaptureSourcePolicyCounts.isNotEmpty)
        'nativeCaptureSourcePolicyOutcome': nativeCaptureSourcePolicyOutcome,
      if (nativeReceiptCameraSurfaceActualCounts.isNotEmpty)
        'nativeReceiptCameraSurfaceActualCounts':
            nativeReceiptCameraSurfaceActualCounts,
      if (nativeReceiptCameraSurfaceVerificationCounts.isNotEmpty)
        'nativeReceiptCameraSurfaceVerificationCounts':
            nativeReceiptCameraSurfaceVerificationCounts,
      if (nativeCameraIdentityCounts.isNotEmpty)
        'nativeCameraIdentityCounts': nativeCameraIdentityCounts,
      if (stitchPairDiagnosticCounts.isNotEmpty)
        'stitchPairDiagnosticCounts': stitchPairDiagnosticCounts,
    });
  }
}
