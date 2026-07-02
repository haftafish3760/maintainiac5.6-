part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryPhotoPreparationTelemetryMetadata
    on _ExpenseReceiptEntryScreenState {
  Map<String, Object?> _receiptPhotoPreparationTelemetryMetadata({
    required ReceiptPhotoReviewResult result,
    required List<Map<String, Object?>> diagnostics,
    required List<Map<String, Object?>> captureDiagnostics,
    required int enhancedCount,
    required Set<String> cleanupActions,
  }) {
    Map<String, int> stringCounts(String key) =>
        _diagnosticStringCounts(captureDiagnostics, key);
    Map<String, int> listCounts(String key) =>
        _diagnosticStringListCounts(captureDiagnostics, key);
    Map<String, int> lumaBuckets(String key) =>
        _diagnosticLumaBuckets(captureDiagnostics, key);
    Map<String, int> edgeScoreBuckets(String key) =>
        _diagnosticEdgeScoreBuckets(captureDiagnostics, key);

    final brightnessBuckets = stringCounts('latestBrightnessBucket');
    final capturedMegapixels = stringCounts('latestCapturedMegapixelBucket');
    final capturedByteBuckets = stringCounts('latestCapturedByteBucket');
    final capturedBrightnessBuckets = stringCounts(
      'latestCapturedBrightnessBucket',
    );
    final capturedSharpnessBuckets = stringCounts(
      'latestCapturedSharpnessBucket',
    );
    final capturedQualitySignals = stringCounts('latestCapturedQualitySignal');
    final capturedExposureMismatches = stringCounts(
      'latestCapturedExposureMismatch',
    );
    final capturedBottomBrightnessBuckets = lumaBuckets(
      'latestCapturedBottomLuma',
    );
    final capturedBottomEdgeScoreBuckets = edgeScoreBuckets(
      'latestCapturedBottomEdgeScore',
    );
    final capturedVerticalQualitySignals = stringCounts(
      'latestCapturedVerticalQualitySignal',
    );
    final nativeCameraEngines = stringCounts('engine');
    final nativeControlContractVersions = stringCounts(
      'nativeControlContractVersion',
    );
    final nativeDevicePolicies = stringCounts('devicePolicyLabel');
    final nativeCameraWorkloadTiers = stringCounts('cameraWorkloadTier');
    final nativeCameraResolutionTiers = stringCounts('cameraResolutionTier');
    final nativeRecoveryResumeStatuses = stringCounts(
      'nativeRecoveryResumeStatus',
    );
    final nativeRecoveryFreshnesses = stringCounts('nativeRecoveryFreshness');
    final nativeRecoveryStorageStatuses = stringCounts(
      'nativeRecoveryStorageStatus',
    );
    final cloudAssistPlans = stringCounts('cloudAssistPlan');
    final localOcrModes = stringCounts('localOcrMode');
    final parserDepths = stringCounts('parserDepth');
    final capabilityPolicyCodes = listCounts('capabilityPolicyCodes');
    final readabilitySignals = stringCounts('latestReadabilitySignal');
    final exposureStatuses = stringCounts('exposureAssistStatus');
    final autoExposureDecisions = stringCounts('lastAutoExposureDecision');
    final preCaptureExposureDecisions = stringCounts(
      'lastPreCaptureExposureDecision',
    );
    final autoExposureBrightness = stringCounts(
      'lastAutoExposureBrightnessBucket',
    );
    final autoExposureCandidates = stringCounts('lastAutoExposureCandidate');
    final framingConfidence = stringCounts(
      ReceiptCaptureDiagnosticKeys.latestFramingConfidence,
    );
    final perspectiveReadiness = stringCounts(
      ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness,
    );
    final focusStatuses = stringCounts('lastFocusStatus');
    final autoCaptureStatuses = stringCounts('latestAutoCaptureStatus');
    final closeActions = stringCounts('closeAction');
    final backDispatchPaths = stringCounts('lastBackDispatchPath');
    final preCaptureExposureAbortReasons = stringCounts(
      'lastPreCaptureExposureAbortReason',
    );

    return {
      'source': _receiptPrivacyFeatureArea,
      'captureFlow': 'receipt_photo_review',
      ...result.privacySafeReceiptReaderHandoffMetadata,
      'savedProofCount': result.photoPaths.length,
      'ocrSourceCount': result.ocrSourcePhotoPaths.length,
      'ocrSourceHandoffStatus': result.usedSavedProofAsOcrSourceFallback
          ? 'saved_proof_fallback'
          : result.nextReviewMatchReadinessOutcome,
      'ocrSourceHandoffSignalCounts': result.receiptReaderHandoffCounts,
      'captureDiagnosticsCount': captureDiagnostics.length,
      if (nativeCameraEngines.isNotEmpty)
        'nativeCameraEngineBuckets': nativeCameraEngines,
      if (nativeControlContractVersions.isNotEmpty)
        'nativeControlContractVersionBuckets': nativeControlContractVersions,
      if (nativeDevicePolicies.isNotEmpty)
        'nativeDevicePolicyBuckets': nativeDevicePolicies,
      if (nativeCameraWorkloadTiers.isNotEmpty)
        'nativeCameraWorkloadTierBuckets': nativeCameraWorkloadTiers,
      if (nativeCameraResolutionTiers.isNotEmpty)
        'nativeCameraResolutionTierBuckets': nativeCameraResolutionTiers,
      if (nativeRecoveryResumeStatuses.isNotEmpty)
        'nativeRecoveryResumeStatusBuckets': nativeRecoveryResumeStatuses,
      if (nativeRecoveryFreshnesses.isNotEmpty)
        'nativeRecoveryFreshnessBuckets': nativeRecoveryFreshnesses,
      if (nativeRecoveryStorageStatuses.isNotEmpty)
        'nativeRecoveryStorageStatusBuckets': nativeRecoveryStorageStatuses,
      if (cloudAssistPlans.isNotEmpty)
        'cloudAssistPlanBuckets': cloudAssistPlans,
      if (localOcrModes.isNotEmpty) 'localOcrModeBuckets': localOcrModes,
      if (parserDepths.isNotEmpty) 'parserDepthBuckets': parserDepths,
      'cloudOcrOptionalCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'cloudOcrOptional',
      ),
      'cloudInventoryOptionalCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'cloudInventoryOptional',
      ),
      'nativeRecoveryRecoveredPhotoTotal': _diagnosticIntSum(
        captureDiagnostics,
        'nativeRecoveryRecoveredPhotoCount',
      ),
      'nativeRecoveryMultipleSectionCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'nativeRecoveryMultipleSections',
      ),
      if (capturedMegapixels.isNotEmpty)
        'capturedPhotoMegapixelBuckets': capturedMegapixels,
      if (capturedByteBuckets.isNotEmpty)
        'capturedPhotoByteBuckets': capturedByteBuckets,
      if (capturedBrightnessBuckets.isNotEmpty)
        'capturedPhotoBrightnessBuckets': capturedBrightnessBuckets,
      if (capturedSharpnessBuckets.isNotEmpty)
        'capturedPhotoSharpnessBuckets': capturedSharpnessBuckets,
      if (capturedQualitySignals.isNotEmpty)
        'capturedPhotoQualitySignals': capturedQualitySignals,
      if (capturedExposureMismatches.isNotEmpty)
        'capturedPhotoExposureMismatches': capturedExposureMismatches,
      if (capturedBottomBrightnessBuckets.isNotEmpty)
        'capturedPhotoBottomBrightnessBuckets': capturedBottomBrightnessBuckets,
      if (capturedBottomEdgeScoreBuckets.isNotEmpty)
        'capturedPhotoBottomEdgeScoreBuckets': capturedBottomEdgeScoreBuckets,
      if (capturedVerticalQualitySignals.isNotEmpty)
        'capturedPhotoVerticalQualitySignals': capturedVerticalQualitySignals,
      if (capabilityPolicyCodes.isNotEmpty)
        'capabilityPolicyCodeCounts': capabilityPolicyCodes,
      if (result.savedPhotoWarningCounts.isNotEmpty)
        'savedPhotoWarningCounts': result.savedPhotoWarningCounts,
      if (result.savedPhotoWarningSeverityCounts.isNotEmpty)
        'savedPhotoWarningSeverityCounts':
            result.savedPhotoWarningSeverityCounts,
      if (result.savedPhotoWarningActionCounts.isNotEmpty)
        'savedPhotoWarningActionCounts': result.savedPhotoWarningActionCounts,
      if (result.savedPhotoParserRiskCounts.isNotEmpty)
        'savedPhotoParserRiskCounts': result.savedPhotoParserRiskCounts,
      'hasSavedPhotoQualityWarning': result.hasSavedPhotoQualityWarning,
      'capturedPhotoWidthMax': _diagnosticIntMax(
        captureDiagnostics,
        'latestCapturedPhotoWidth',
      ),
      'capturedPhotoHeightMax': _diagnosticIntMax(
        captureDiagnostics,
        'latestCapturedPhotoHeight',
      ),
      if (brightnessBuckets.isNotEmpty) 'brightnessBuckets': brightnessBuckets,
      if (readabilitySignals.isNotEmpty)
        'readabilitySignalBuckets': readabilitySignals,
      if (autoExposureDecisions.isNotEmpty)
        'autoExposureDecisionBuckets': autoExposureDecisions,
      if (preCaptureExposureDecisions.isNotEmpty)
        'preCaptureExposureDecisionBuckets': preCaptureExposureDecisions,
      'preCaptureExposureAdjustmentTotal': _diagnosticIntSum(
        captureDiagnostics,
        'preCaptureExposureAdjustmentCount',
      ),
      'preCaptureExposureAbortTotal': _diagnosticIntSum(
        captureDiagnostics,
        'preCaptureExposureAbortCount',
      ),
      if (preCaptureExposureAbortReasons.isNotEmpty)
        'preCaptureExposureAbortReasonBuckets': preCaptureExposureAbortReasons,
      if (autoExposureBrightness.isNotEmpty)
        'autoExposureBrightnessBuckets': autoExposureBrightness,
      if (autoExposureCandidates.isNotEmpty)
        'autoExposureCandidateBuckets': autoExposureCandidates,
      'autoExposureCandidateFrameTotal': _diagnosticIntSum(
        captureDiagnostics,
        'autoExposureCandidateFrameCount',
      ),
      if (exposureStatuses.isNotEmpty)
        'exposureAssistStatuses': exposureStatuses,
      if (framingConfidence.isNotEmpty)
        'framingConfidenceBuckets': framingConfidence,
      if (perspectiveReadiness.isNotEmpty)
        'perspectiveReadinessBuckets': perspectiveReadiness,
      if (focusStatuses.isNotEmpty) 'focusStatusBuckets': focusStatuses,
      if (autoCaptureStatuses.isNotEmpty)
        'autoCaptureStatusBuckets': autoCaptureStatuses,
      if (closeActions.isNotEmpty) 'closeActionBuckets': closeActions,
      if (backDispatchPaths.isNotEmpty)
        'backDispatchPathBuckets': backDispatchPaths,
      'pendingCloseAfterCaptureCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'pendingCloseAfterCapture',
      ),
      'closeResultDeliveredCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'closeResultDelivered',
      ),
      'autoCaptureAllowedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'autoCaptureAllowed',
      ),
      'autoCaptureCurrentlyAllowedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'autoCaptureCurrentlyAllowed',
      ),
      ..._receiptPhotoPreparationTailTelemetryMetadata(
        result: result,
        captureDiagnostics: captureDiagnostics,
        enhancedCount: enhancedCount,
        cleanupActions: cleanupActions,
      ),
    };
  }
}
