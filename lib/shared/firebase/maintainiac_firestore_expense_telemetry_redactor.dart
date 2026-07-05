part of 'maintainiac_firestore_documents.dart';

class _ExpenseTelemetryFirestoreRedactor {
  const _ExpenseTelemetryFirestoreRedactor._();

  static const privateReceiptHintTokenFields = {
    'failedAt',
    'confirmedCause',
    'evidence',
    'missingEvidence',
    'topOcrFailureCause',
    'topOcrFailureStage',
  };

  static const privateReceiptHintMapFields = {
    'ocrFailureCauseCounts',
    'ocrFailureStageCounts',
    'expenseSummaryOcrContractSkippedReasonCounts',
    'parserCategoryCounts',
    'parserNeedsReviewCategoryCounts',
    'parserFailedCategoryCounts',
    'parserFieldConfidenceCounts',
    'parserCategoryHealthCounts',
    'parserCategoryReviewActionCounts',
    'parserPackPressureStatusCounts',
    'receiptBrainParserLimitOutcomeCounts',
    'receiptBrainLowStorageDownloadRiskCounts',
    'receiptBrainFullOfflineMustStayOptionalCounts',
    'receiptBrainFullOfflineExceedsBaseGuardrailCounts',
    'receiptBrainBaseLocalReadingAvailableCounts',
    'receiptBrainBaseWorksWithoutCloudAssistCounts',
    'receiptBrainLocalFirstReadinessCounts',
    'receiptBrainLocalFirstReadinessActionCounts',
    'receiptBrainLocalFirstReadinessSummaryCounts',
    'receiptBrainFirstInstallBoundaryCounts',
    'receiptBrainFirstInstallBoundaryActionCounts',
    'receiptBrainFirstInstallCanRunLowStorageCounts',
    'receiptBrainFirstInstallRequiresBaseCapabilityCounts',
    'receiptBrainFirstInstallBoundarySummaryCounts',
    'receiptInstallRequiredSegmentCounts',
    'receiptInstallFullOfflineSegmentCounts',
    'receiptInstallLowStorageImpactCounts',
    'receiptInstallRecommendedDistributionCounts',
    'receiptInstallCameraShellParserFreeCounts',
    'receiptInstallBaseUsefulOnTinyPhonesCounts',
    'receiptInstallOptionalPacksRequireConsentCounts',
    'receiptLocalOnlyAcceptanceStatusCounts',
    'receiptLocalOnlyAcceptanceActionCounts',
    'receiptLocalOnlyBaseFlowCanRunCounts',
    'receiptLocalOnlyBlocksLowStorageCounts',
    'receiptLocalOnlyEvidenceCounts',
    'nativeLocalOnlyCapturePolicyCounts',
    'nativeLocalOnlyBaseFlowCanRunCounts',
    'nativeLocalOnlyHeavyPacksMayBlockCaptureCounts',
    'nativeLocalOnlyCloudAssistMayBlockCaptureCounts',
    'receiptRequiredBaseFootprintStatusCounts',
    'receiptRequiredBaseFootprintCanShipCounts',
    'receiptRequiredBaseFootprintReviewCounts',
    'receiptRequiredBaseFootprintBlockingReasonCounts',
    'receiptRequiredBaseFootprintReviewReasonCounts',
    'ocrStoragePolicyCounts',
    'ocrUsesPreparedSourceBeforeSavedProofCounts',
    'ocrUsesSavedProofFallbackCounts',
    'parserRequiredFieldStatusCounts',
    'parserDownstreamReadinessStatusCounts',
    'parserDownstreamReadinessCounts',
    'parserReviewRootCauseCounts',
    'localReceiptParserRoutingCounts',
    'localParserEvidenceOutcomeCounts',
    'ocrParserTaskCounts',
    'ocrFieldReadinessCounts',
    'ocrSourceHandoffStatusCounts',
    'ocrSourceHandoffSignalCounts',
    'ocrSourceStitchSignalCounts',
    'ocrSourceScannerDecisionCounts',
    'ocrSourceCaptureSourceSignalCounts',
    'ocrSourcePhotoQualityRiskCounts',
    'ocrSourceQualityReviewStatusCounts',
    'ocrSourceQualityReviewActionCounts',
    'clientProofRedactionStatusCounts',
    'clientProofVisibilityCounts',
    'receiptSelectedLinePurposeCounts',
    'clientProofRedactionPlanStatusCounts',
    'savedPhotoWarningCounts',
    'savedPhotoWarningCauseCounts',
    'savedPhotoWarningSeverityCounts',
    'savedPhotoWarningActionCounts',
    'savedPhotoParserRiskCounts',
    'preCaptureExposureDecisionBuckets',
    'preCaptureExposureDecisionCounts',
    'autoExposureDecisionBuckets',
    'autoExposureDecisionCounts',
    'autoExposureBrightnessBuckets',
    'autoExposureBrightnessCounts',
    'autoExposureCandidateBuckets',
    'autoExposureCandidateCounts',
    'exposureAssistStatuses',
    'exposureAssistStatusCounts',
    'acceptedPhotoQualityOutcomeCounts',
    'capturedPhotoBrightnessCounts',
    'capturedPhotoSharpnessCounts',
    'capturedPhotoExposureMismatchCounts',
    'capturedPhotoQualitySignalCounts',
    'capturedPhotoBottomBrightnessCounts',
    'capturedPhotoBottomEdgeScoreCounts',
    'capturedPhotoVerticalQualitySignalCounts',
    'nativeCameraEngineCounts',
    'nativeReceiptCameraSurfaceActualCounts',
    'nativeReceiptCameraSurfaceVerificationCounts',
    'nativeCameraIdentityCounts',
    'nativeSettingsContractVersionCounts',
    'nativeControlContractVersionCounts',
    'nativePreCaptureExposureAbortReasonCounts',
    'nativeCaptureReadinessCodeCounts',
    'nativeZoomStatusCounts',
    'nativeBackDispatchPathCounts',
    'receiptCloudAssistPlanCounts',
    'receiptLocalOcrModeCounts',
    'receiptParserDepthCounts',
    'receiptParserPackCodeCounts',
    'receiptOptionalLocalParserPackCodeCounts',
    'receiptCloudFallbackParserPackCodeCounts',
    'receiptParserPackAccuracyBandCounts',
    'nativeDevicePolicyCounts',
    'nativeCameraWorkloadTierCounts',
    'nativeCameraResolutionTierCounts',
    'nativeRecoveryResumeStatusCounts',
    'nativeRecoveryFreshnessCounts',
    'nativeRecoveryStorageStatusCounts',
    'capabilityPolicyCodeCounts',
    'nativeCaptureSourcePolicyCounts',
    'stitchStatusCounts',
    'stitchFallbackReasonCounts',
    'stitchConfidenceBucketCounts',
    'stitchPairDiagnosticCounts',
  };

  static final _knownMerchantPattern = RegExp(
    r"\b(?:lowe\s*s|lowe'?s|walmart|target|home depot|costco|sam\s*s club|sam'?s club|shell|exxon|mobil|chevron|marathon|sheetz|wawa|speedway|circle k|bp|sunoco|pilot|flying j|love\s*s|love'?s|casey\s*s|casey'?s|kwik trip|kum\s*(?:and|&)?\s*go|quicktrip|qt|racetrac|raceway|royal farms|murphy usa|valero|phillips 66|citgo|sinclair|mapco|getgo|thorntons|travelcenters of america|petro|jiffy lube|valvoline|take 5|midas|pep boys|firestone|discount tire|les schwab|goodyear|ntb|autozone|advance auto|oreilly|o'?reilly|napa|carquest|tractor supply|harbor freight|menards|ace hardware|true value|rural king|fleet farm|blain\s*s farm fleet|blain'?s farm fleet)\b",
    caseSensitive: false,
  );
  static final _knownLocationPattern = RegExp(
    r'\b(?:austin|atlanta|baltimore|charlotte|chicago|columbus|dallas|denver|detroit|houston|indianapolis|jacksonville|knoxville|las vegas|los angeles|louisville|memphis|miami|nashville|new york|orlando|philadelphia|phoenix|raleigh|richmond|san antonio|san diego|san francisco|seattle|tampa|washington)\b',
    caseSensitive: false,
  );
  static final _privateReferencePattern = RegExp(
    r'\b(?:auth(?:code)?|approval|barcode|card|customer|client|employee|driver|email|invoice|member|name|note|notes|order|phone|sale|store|terminal|transaction|trans|user)\s+[a-z0-9]+\b',
    caseSensitive: false,
  );
  static final _privateNotePattern = RegExp(
    r'\b(?:user|customer|client|employee|driver)?\s*(?:note|notes|name)\s+(?:[a-z0-9]+\s+){0,3}[a-z0-9]+\b',
    caseSensitive: false,
  );
  static final _unknownSourceLabelPattern = RegExp(
    r'\bsource\s+(?!(?:photo|camera|image|capture|pdf|document|text|imported\s+text|pasted\s+text|mixed|combined|multiple|none|missing|unknown)\b)[a-z0-9]+(?:\s+[a-z0-9]+){0,1}',
    caseSensitive: false,
  );

  static String readableText(String value) {
    final safe = redactPrivateReceiptHints(value)
        .replaceAll(RegExp(r'[^A-Za-z0-9_ .,;:/()%-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (safe.isEmpty) return 'Unknown';
    return safe.length > 180 ? safe.substring(0, 180) : safe;
  }

  static String appGeneratedDisclosureText(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_ .,;:/()%-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (safe.isEmpty) return 'Unknown';
    return safe.length > 240 ? safe.substring(0, 240) : safe;
  }

  static String tokenFor(String key, String value) {
    final tokenValue = privateReceiptHintTokenFields.contains(key)
        ? redactPrivateReceiptHints(value)
        : value;
    return _safeToken(tokenValue);
  }

  static String mapKeyFor(String key, String value) {
    final tokenValue = privateReceiptHintMapFields.contains(key)
        ? redactPrivateReceiptHints(value)
        : value;
    return _safeToken(tokenValue);
  }

  static String redactPrivateReceiptHints(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\$+\s*\d+(?:[._\s]\d+)?'), 'amount')
        .replaceAll(RegExp(r'\d+[._]\d{2,}'), 'amount')
        .replaceAll(RegExp(r'\b\d+\s+\d{2,}\b'), 'amount')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(_unknownSourceLabelPattern, 'source unknown')
        .replaceAll(RegExp(r'(?<![A-Za-z0-9])\d{3,}(?![A-Za-z0-9])'), 'number')
        .replaceAll(_privateNotePattern, 'private reference')
        .replaceAll(_knownMerchantPattern, 'merchant')
        .replaceAll(_knownLocationPattern, 'location')
        .replaceAll(
          RegExp(r'\breceipt\s+number\b', caseSensitive: false),
          'private reference',
        )
        .replaceAll(_privateReferencePattern, 'private reference');
  }
}
