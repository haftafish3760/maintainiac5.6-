part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryPhotoPreparationTelemetryTail
    on _ExpenseReceiptEntryScreenState {
  Map<String, Object?> _receiptPhotoPreparationTailTelemetryMetadata({
    required ReceiptPhotoReviewResult result,
    required List<Map<String, Object?>> captureDiagnostics,
    required int enhancedCount,
    required Set<String> cleanupActions,
  }) {
    Map<String, int> stringCounts(String key) =>
        _diagnosticStringCounts(captureDiagnostics, key);

    final storageSafetyLevels = stringCounts('storageSafetyLevel');
    final storageSafetyReasons = stringCounts('storageSafetyReason');
    final photoEditActions = stringCounts('photoEditAction');
    final photoCoverageStatuses = stringCounts(
      ReceiptCaptureDiagnosticKeys.photoCoverageStatus,
    );
    final photoCoverageReasons = stringCounts(
      ReceiptCaptureDiagnosticKeys.photoCoverageReason,
    );
    final receiptBottomEdgeStatuses = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptBottomEdgeStatus,
    );
    final receiptBottomEdgeDetected = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptBottomEdgeDetected,
    );
    final receiptSubtotalDetected = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected,
    );
    final receiptTotalDetected = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptTotalDetected,
    );
    final receiptTotalAmountDetected = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected,
    );
    final receiptTotalsTextEvidenceStatuses = stringCounts(
      ReceiptCaptureDiagnosticKeys.receiptTotalsTextEvidenceStatus,
    );
    final zoomStatuses = stringCounts('lastZoomStatus');

    return {
      if (storageSafetyLevels.isNotEmpty)
        'storageSafetyLevelBuckets': storageSafetyLevels,
      if (storageSafetyReasons.isNotEmpty)
        'storageSafetyReasonBuckets': storageSafetyReasons,
      'storageConstrainedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'storageConstrained',
      ),
      if (photoEditActions.isNotEmpty) 'photoEditActions': photoEditActions,
      if (photoCoverageStatuses.isNotEmpty)
        'photoCoverageStatuses': photoCoverageStatuses,
      if (photoCoverageReasons.isNotEmpty)
        'photoCoverageReasons': photoCoverageReasons,
      if (receiptBottomEdgeStatuses.isNotEmpty)
        'receiptBottomEdgeStatusBuckets': receiptBottomEdgeStatuses,
      if (receiptBottomEdgeDetected.isNotEmpty)
        'receiptBottomEdgeDetectedBuckets': receiptBottomEdgeDetected,
      if (receiptSubtotalDetected.isNotEmpty)
        'receiptSubtotalDetectedBuckets': receiptSubtotalDetected,
      if (receiptTotalDetected.isNotEmpty)
        'receiptTotalDetectedBuckets': receiptTotalDetected,
      if (receiptTotalAmountDetected.isNotEmpty)
        'receiptTotalAmountDetectedBuckets': receiptTotalAmountDetected,
      if (receiptTotalsTextEvidenceStatuses.isNotEmpty)
        'receiptTotalsTextEvidenceStatusBuckets':
            receiptTotalsTextEvidenceStatuses,
      if (result.receiptSectionOrderCounts.isNotEmpty)
        'receiptSectionOrderCounts': result.receiptSectionOrderCounts,
      if (result.receiptSectionOrderCounts.isNotEmpty)
        'receiptSectionOrderOutcome': result.receiptSectionOrderOutcome,
      'photoCoverageNeedsMoreCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos,
      ),
      'hasPossiblePartialReceiptPhotos': result.hasPossiblePartialReceiptPhotos,
      'acceptedPhotoQualityOutcomeCounts':
          result.acceptedPhotoQualityOutcomeCounts,
      'acceptedPhotoHandoffOutcome': result.acceptedPhotoHandoffOutcome,
      'privacySafeOcrHandoffEvidence':
          result.privacySafeOcrHandoffEvidenceLabel,
      'userEditedPhotoCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'userEditedPhoto',
      ),
      'edgeDetectionEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'edgeDetectionEnabled',
      ),
      'edgeOverlayEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'edgeOverlayEnabled',
      ),
      'tapFocusEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'tapFocusEnabled',
      ),
      'pinchZoomEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'pinchZoomEnabled',
      ),
      'brightnessSliderEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'exposureSliderEnabled',
      ),
      'tapFocusControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'tapFocusControlExpected',
      ),
      'continuousFocusExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'continuousFocusExpected',
      ),
      'pinchZoomControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'pinchZoomControlExpected',
      ),
      'exposureSliderControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'exposureSliderControlExpected',
      ),
      'exposureResetControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'exposureResetControlExpected',
      ),
      'settingsControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'settingsControlExpected',
      ),
      'backControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'backControlExpected',
      ),
      'torchControlExpectedCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'torchControlExpected',
      ),
      'shadowWarningEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'shadowWarningEnabled',
      ),
      'textTooSmallWarningEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'textTooSmallWarningEnabled',
      ),
      'autoCropSuggestionEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'autoCropSuggestionEnabled',
      ),
      'grayscalePreviewEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'grayscalePreviewEnabled',
      ),
      'contrastBoostEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'contrastBoostEnabled',
      ),
      'shadowReductionEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'shadowReductionEnabled',
      ),
      'orientationCorrectionEnabledCount': _diagnosticBoolTrueCount(
        captureDiagnostics,
        'orientationCorrectionEnabled',
      ),
      'tapFocusTotal': _diagnosticIntSum(captureDiagnostics, 'tapFocusCount'),
      'tapFocusSuppressedAfterZoomTotal': _diagnosticIntSum(
        captureDiagnostics,
        'tapFocusSuppressedAfterZoomCount',
      ),
      'zoomChangeTotal': _diagnosticIntSum(
        captureDiagnostics,
        'zoomChangeCount',
      ),
      'zoomGestureStartTotal': _diagnosticIntSum(
        captureDiagnostics,
        'zoomGestureStartCount',
      ),
      'zoomUnavailableTotal': _diagnosticIntSum(
        captureDiagnostics,
        'zoomUnavailableCount',
      ),
      if (zoomStatuses.isNotEmpty) 'zoomStatusBuckets': zoomStatuses,
      'manualBrightnessChangeTotal': _diagnosticIntSum(
        captureDiagnostics,
        'manualExposureChangeCount',
      ),
      'settingsOpenTotal': _diagnosticIntSum(
        captureDiagnostics,
        'settingsOpenCount',
      ),
      'autoCaptureTriggerTotal': _diagnosticIntSum(
        captureDiagnostics,
        'autoCaptureTriggerCount',
      ),
      'closeRetryTotal': _diagnosticIntSum(
        captureDiagnostics,
        'closeRetryCount',
      ),
      'scannerCleanupUsedCount': enhancedCount,
      'cleanupActionCount': cleanupActions.length,
      'cleanupActions': cleanupActions.toList(growable: false)..sort(),
      'stitchStatus': result.stitchResult.status.name,
      'stitchFallbackReason': result.stitchResult.diagnosticReasonLabel,
      'stitchConfidenceBucket': _ratioBucket(result.stitchResult.confidence),
      if (result.stitchPairDiagnosticCounts.isNotEmpty)
        'stitchPairDiagnosticCounts': result.stitchPairDiagnosticCounts,
    };
  }
}
