part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryReceiptReadinessSummary {
  final _parserLimitOutcomeCounts = <String, int>{};
  final _lowStorageDownloadRiskCounts = <String, int>{};
  final _fullOfflineMustStayOptionalCounts = <String, int>{};
  final _fullOfflineExceedsBaseGuardrailCounts = <String, int>{};
  final _baseLocalReadingAvailableCounts = <String, int>{};
  final _baseWorksWithoutCloudAssistCounts = <String, int>{};
  final _localFirstReadinessCounts = <String, int>{};
  final _localFirstReadinessActionCounts = <String, int>{};
  final _localFirstReadinessSummaryCounts = <String, int>{};
  final _firstInstallBoundaryCounts = <String, int>{};
  final _firstInstallBoundaryActionCounts = <String, int>{};
  final _firstInstallCanRunLowStorageCounts = <String, int>{};
  final _firstInstallRequiresBaseCapabilityCounts = <String, int>{};
  final _firstInstallBoundarySummaryCounts = <String, int>{};
  final _installRequiredSegmentCounts = <String, int>{};
  final _installFullOfflineSegmentCounts = <String, int>{};
  final _installLowStorageImpactCounts = <String, int>{};
  final _installRecommendedDistributionCounts = <String, int>{};
  final _installCameraShellParserFreeCounts = <String, int>{};
  final _installBaseUsefulOnTinyPhonesCounts = <String, int>{};
  final _installOptionalPacksRequireConsentCounts = <String, int>{};
  final _localOnlyAcceptanceStatusCounts = <String, int>{};
  final _localOnlyAcceptanceActionCounts = <String, int>{};
  final _localOnlyBaseFlowCanRunCounts = <String, int>{};
  final _localOnlyBlocksLowStorageCounts = <String, int>{};
  final _localOnlyEvidenceCounts = <String, int>{};
  final _nativeLocalOnlyCapturePolicyCounts = <String, int>{};
  final _nativeLocalOnlyBaseFlowCanRunCounts = <String, int>{};
  final _nativeLocalOnlyHeavyPacksMayBlockCaptureCounts = <String, int>{};
  final _nativeLocalOnlyCloudAssistMayBlockCaptureCounts = <String, int>{};
  final _requiredBaseFootprintStatusCounts = <String, int>{};
  final _requiredBaseFootprintCanShipCounts = <String, int>{};
  final _requiredBaseFootprintReviewCounts = <String, int>{};
  final _requiredBaseFootprintBlockingReasonCounts = <String, int>{};
  final _requiredBaseFootprintReviewReasonCounts = <String, int>{};
  final _ocrStoragePolicyCounts = <String, int>{};
  final _ocrUsesPreparedSourceBeforeSavedProofCounts = <String, int>{};
  final _ocrUsesSavedProofFallbackCounts = <String, int>{};

  Map<String, int> get parserLimitOutcomeCounts =>
      Map.unmodifiable(_parserLimitOutcomeCounts);
  Map<String, int> get lowStorageDownloadRiskCounts =>
      Map.unmodifiable(_lowStorageDownloadRiskCounts);
  Map<String, int> get fullOfflineMustStayOptionalCounts =>
      Map.unmodifiable(_fullOfflineMustStayOptionalCounts);
  Map<String, int> get fullOfflineExceedsBaseGuardrailCounts =>
      Map.unmodifiable(_fullOfflineExceedsBaseGuardrailCounts);
  Map<String, int> get baseLocalReadingAvailableCounts =>
      Map.unmodifiable(_baseLocalReadingAvailableCounts);
  Map<String, int> get baseWorksWithoutCloudAssistCounts =>
      Map.unmodifiable(_baseWorksWithoutCloudAssistCounts);
  Map<String, int> get localFirstReadinessCounts =>
      Map.unmodifiable(_localFirstReadinessCounts);
  Map<String, int> get localFirstReadinessActionCounts =>
      Map.unmodifiable(_localFirstReadinessActionCounts);
  Map<String, int> get localFirstReadinessSummaryCounts =>
      Map.unmodifiable(_localFirstReadinessSummaryCounts);
  Map<String, int> get firstInstallBoundaryCounts =>
      Map.unmodifiable(_firstInstallBoundaryCounts);
  Map<String, int> get firstInstallBoundaryActionCounts =>
      Map.unmodifiable(_firstInstallBoundaryActionCounts);
  Map<String, int> get firstInstallCanRunLowStorageCounts =>
      Map.unmodifiable(_firstInstallCanRunLowStorageCounts);
  Map<String, int> get firstInstallRequiresBaseCapabilityCounts =>
      Map.unmodifiable(_firstInstallRequiresBaseCapabilityCounts);
  Map<String, int> get firstInstallBoundarySummaryCounts =>
      Map.unmodifiable(_firstInstallBoundarySummaryCounts);
  Map<String, int> get installRequiredSegmentCounts =>
      Map.unmodifiable(_installRequiredSegmentCounts);
  Map<String, int> get installFullOfflineSegmentCounts =>
      Map.unmodifiable(_installFullOfflineSegmentCounts);
  Map<String, int> get installLowStorageImpactCounts =>
      Map.unmodifiable(_installLowStorageImpactCounts);
  Map<String, int> get installRecommendedDistributionCounts =>
      Map.unmodifiable(_installRecommendedDistributionCounts);
  Map<String, int> get installCameraShellParserFreeCounts =>
      Map.unmodifiable(_installCameraShellParserFreeCounts);
  Map<String, int> get installBaseUsefulOnTinyPhonesCounts =>
      Map.unmodifiable(_installBaseUsefulOnTinyPhonesCounts);
  Map<String, int> get installOptionalPacksRequireConsentCounts =>
      Map.unmodifiable(_installOptionalPacksRequireConsentCounts);
  Map<String, int> get localOnlyAcceptanceStatusCounts =>
      Map.unmodifiable(_localOnlyAcceptanceStatusCounts);
  Map<String, int> get localOnlyAcceptanceActionCounts =>
      Map.unmodifiable(_localOnlyAcceptanceActionCounts);
  Map<String, int> get localOnlyBaseFlowCanRunCounts =>
      Map.unmodifiable(_localOnlyBaseFlowCanRunCounts);
  Map<String, int> get localOnlyBlocksLowStorageCounts =>
      Map.unmodifiable(_localOnlyBlocksLowStorageCounts);
  Map<String, int> get localOnlyEvidenceCounts =>
      Map.unmodifiable(_localOnlyEvidenceCounts);
  Map<String, int> get nativeLocalOnlyCapturePolicyCounts =>
      Map.unmodifiable(_nativeLocalOnlyCapturePolicyCounts);
  Map<String, int> get nativeLocalOnlyBaseFlowCanRunCounts =>
      Map.unmodifiable(_nativeLocalOnlyBaseFlowCanRunCounts);
  Map<String, int> get nativeLocalOnlyHeavyPacksMayBlockCaptureCounts =>
      Map.unmodifiable(_nativeLocalOnlyHeavyPacksMayBlockCaptureCounts);
  Map<String, int> get nativeLocalOnlyCloudAssistMayBlockCaptureCounts =>
      Map.unmodifiable(_nativeLocalOnlyCloudAssistMayBlockCaptureCounts);
  Map<String, int> get requiredBaseFootprintStatusCounts =>
      Map.unmodifiable(_requiredBaseFootprintStatusCounts);
  Map<String, int> get requiredBaseFootprintCanShipCounts =>
      Map.unmodifiable(_requiredBaseFootprintCanShipCounts);
  Map<String, int> get requiredBaseFootprintReviewCounts =>
      Map.unmodifiable(_requiredBaseFootprintReviewCounts);
  Map<String, int> get requiredBaseFootprintBlockingReasonCounts =>
      Map.unmodifiable(_requiredBaseFootprintBlockingReasonCounts);
  Map<String, int> get requiredBaseFootprintReviewReasonCounts =>
      Map.unmodifiable(_requiredBaseFootprintReviewReasonCounts);
  Map<String, int> get ocrStoragePolicyCounts =>
      Map.unmodifiable(_ocrStoragePolicyCounts);
  Map<String, int> get ocrUsesPreparedSourceBeforeSavedProofCounts =>
      Map.unmodifiable(_ocrUsesPreparedSourceBeforeSavedProofCounts);
  Map<String, int> get ocrUsesSavedProofFallbackCounts =>
      Map.unmodifiable(_ocrUsesSavedProofFallbackCounts);

  String get topParserLimitOutcome => _topCountKey(_parserLimitOutcomeCounts);
  String get topLowStorageDownloadRisk =>
      _topCountKey(_lowStorageDownloadRiskCounts);
  String get topLocalFirstReadiness => _topCountKey(_localFirstReadinessCounts);
  String get topLocalFirstReadinessAction =>
      _topCountKey(_localFirstReadinessActionCounts);
  String get topFirstInstallBoundary =>
      _topCountKey(_firstInstallBoundaryCounts);
  String get topFirstInstallBoundaryAction =>
      _topCountKey(_firstInstallBoundaryActionCounts);
  String get topInstallRecommendedDistribution =>
      _topCountKey(_installRecommendedDistributionCounts);
  String get topInstallLowStorageImpact =>
      _topCountKey(_installLowStorageImpactCounts);
  String get topLocalOnlyAcceptanceStatus =>
      _topCountKey(_localOnlyAcceptanceStatusCounts);
  String get topLocalOnlyAcceptanceAction =>
      _topCountKey(_localOnlyAcceptanceActionCounts);
  String get topNativeLocalOnlyCapturePolicy =>
      _topCountKey(_nativeLocalOnlyCapturePolicyCounts);
  String get topRequiredBaseFootprintStatus =>
      _topCountKey(_requiredBaseFootprintStatusCounts);
  String get topRequiredBaseFootprintBlockingReason =>
      _topCountKey(_requiredBaseFootprintBlockingReasonCounts);
  String get topRequiredBaseFootprintReviewReason =>
      _topCountKey(_requiredBaseFootprintReviewReasonCounts);
  String get topOcrStoragePolicy => _topCountKey(_ocrStoragePolicyCounts);
  String get topOcrUsesPreparedSourceBeforeSavedProof =>
      _topCountKey(_ocrUsesPreparedSourceBeforeSavedProofCounts);
  String get topOcrUsesSavedProofFallback =>
      _topCountKey(_ocrUsesSavedProofFallbackCounts);

  void recordParserLimits(Map<String, Object?> metadata) {
    _increment(
      _parserLimitOutcomeCounts,
      _stringValue(metadata['receiptBrainParserLimitOutcome']),
    );
    _mergeCountMap(
      _lowStorageDownloadRiskCounts,
      _metadataValue(metadata['receiptBrainLowStorageDownloadRiskCounts']),
    );
    _mergeCountMap(
      _fullOfflineMustStayOptionalCounts,
      _metadataValue(metadata['receiptBrainFullOfflineMustStayOptionalCounts']),
    );
    _mergeCountMap(
      _fullOfflineExceedsBaseGuardrailCounts,
      _metadataValue(
        metadata['receiptBrainFullOfflineExceedsBaseGuardrailCounts'],
      ),
    );
  }

  void recordLocalFirstReadiness(Map<String, Object?> metadata) {
    _mergeCountMap(
      _baseLocalReadingAvailableCounts,
      _metadataValue(metadata['receiptBrainBaseLocalReadingAvailableCounts']),
    );
    _mergeCountMap(
      _baseWorksWithoutCloudAssistCounts,
      _metadataValue(metadata['receiptBrainBaseWorksWithoutCloudAssistCounts']),
    );
    _mergeOrOutcome(
      target: _localFirstReadinessCounts,
      counts: metadata['receiptBrainLocalFirstReadinessCounts'],
      outcome: metadata['receiptBrainLocalFirstReadinessOutcome'],
    );
    _mergeOrOutcome(
      target: _localFirstReadinessActionCounts,
      counts: metadata['receiptBrainLocalFirstReadinessActionCounts'],
      outcome: metadata['receiptBrainLocalFirstReadinessActionOutcome'],
    );
    _mergeCountMap(
      _localFirstReadinessSummaryCounts,
      _metadataValue(metadata['receiptBrainLocalFirstReadinessSummaryCounts']),
    );
    _mergeOrOutcome(
      target: _firstInstallBoundaryCounts,
      counts: metadata['receiptBrainFirstInstallBoundaryCounts'],
      outcome: metadata['receiptBrainFirstInstallBoundaryOutcome'],
    );
    _mergeCountMap(
      _firstInstallBoundaryActionCounts,
      _metadataValue(metadata['receiptBrainFirstInstallBoundaryActionCounts']),
    );
    _mergeCountMap(
      _firstInstallCanRunLowStorageCounts,
      _metadataValue(
        metadata['receiptBrainFirstInstallCanRunLowStorageCounts'],
      ),
    );
    _mergeCountMap(
      _firstInstallRequiresBaseCapabilityCounts,
      _metadataValue(
        metadata['receiptBrainFirstInstallRequiresBaseCapabilityCounts'],
      ),
    );
    _mergeCountMap(
      _firstInstallBoundarySummaryCounts,
      _metadataValue(metadata['receiptBrainFirstInstallBoundarySummaryCounts']),
    );
  }

  void recordInstallFootprint(Map<String, Object?> metadata) {
    _mergeOrOutcome(
      target: _installRequiredSegmentCounts,
      counts: metadata['receiptInstallRequiredSegmentCounts'],
      outcome: metadata['receiptInstallRequiredSegmentOutcome'],
    );
    _mergeOrOutcome(
      target: _installFullOfflineSegmentCounts,
      counts: metadata['receiptInstallFullOfflineSegmentCounts'],
      outcome: metadata['receiptInstallFullOfflineSegmentOutcome'],
    );
    _mergeOrOutcome(
      target: _installLowStorageImpactCounts,
      counts: metadata['receiptInstallLowStorageImpactCounts'],
      outcome: metadata['receiptInstallLowStorageImpactOutcome'],
    );
    _mergeOrOutcome(
      target: _installRecommendedDistributionCounts,
      counts: metadata['receiptInstallRecommendedDistributionCounts'],
      outcome: metadata['receiptInstallRecommendedDistributionOutcome'],
    );
    _mergeCountMap(
      _installCameraShellParserFreeCounts,
      _metadataValue(metadata['receiptInstallCameraShellParserFreeCounts']),
    );
    _mergeCountMap(
      _installBaseUsefulOnTinyPhonesCounts,
      _metadataValue(metadata['receiptInstallBaseUsefulOnTinyPhonesCounts']),
    );
    _mergeCountMap(
      _installOptionalPacksRequireConsentCounts,
      _metadataValue(
        metadata['receiptInstallOptionalPacksRequireConsentCounts'],
      ),
    );
  }

  void recordLocalOnlyAcceptance(Map<String, Object?> metadata) {
    _mergeOrOutcome(
      target: _localOnlyAcceptanceStatusCounts,
      counts: metadata['receiptLocalOnlyAcceptanceStatusCounts'],
      outcome: metadata['receiptLocalOnlyAcceptanceStatusOutcome'],
    );
    _mergeOrOutcome(
      target: _localOnlyAcceptanceActionCounts,
      counts: metadata['receiptLocalOnlyAcceptanceActionCounts'],
      outcome: metadata['receiptLocalOnlyAcceptanceActionOutcome'],
    );
    _mergeCountMap(
      _localOnlyBaseFlowCanRunCounts,
      _metadataValue(metadata['receiptLocalOnlyBaseFlowCanRunCounts']),
    );
    _mergeCountMap(
      _localOnlyBlocksLowStorageCounts,
      _metadataValue(metadata['receiptLocalOnlyBlocksLowStorageCounts']),
    );
    _mergeCountMap(
      _localOnlyEvidenceCounts,
      _metadataValue(metadata['receiptLocalOnlyEvidenceCounts']),
    );
  }

  void recordNativeLocalOnlyPolicy(Map<String, Object?> metadata) {
    _mergeOrOutcome(
      target: _nativeLocalOnlyCapturePolicyCounts,
      counts: metadata['nativeLocalOnlyCapturePolicyCounts'],
      outcome: metadata['nativeLocalOnlyCapturePolicyOutcome'],
    );
    _mergeCountMap(
      _nativeLocalOnlyBaseFlowCanRunCounts,
      _metadataValue(metadata['nativeLocalOnlyBaseFlowCanRunCounts']),
    );
    _mergeCountMap(
      _nativeLocalOnlyHeavyPacksMayBlockCaptureCounts,
      _metadataValue(
        metadata['nativeLocalOnlyHeavyPacksMayBlockCaptureCounts'],
      ),
    );
    _mergeCountMap(
      _nativeLocalOnlyCloudAssistMayBlockCaptureCounts,
      _metadataValue(
        metadata['nativeLocalOnlyCloudAssistMayBlockCaptureCounts'],
      ),
    );
  }

  void recordRequiredBaseFootprint(Map<String, Object?> metadata) {
    _mergeOrOutcome(
      target: _requiredBaseFootprintStatusCounts,
      counts: metadata['receiptRequiredBaseFootprintStatusCounts'],
      outcome: metadata['receiptRequiredBaseFootprintStatusOutcome'],
    );
    _mergeCountMap(
      _requiredBaseFootprintCanShipCounts,
      _metadataValue(metadata['receiptRequiredBaseFootprintCanShipCounts']),
    );
    _mergeCountMap(
      _requiredBaseFootprintReviewCounts,
      _metadataValue(metadata['receiptRequiredBaseFootprintReviewCounts']),
    );
    _mergeCountMap(
      _requiredBaseFootprintBlockingReasonCounts,
      _metadataValue(
        metadata['receiptRequiredBaseFootprintBlockingReasonCounts'],
      ),
    );
    _mergeCountMap(
      _requiredBaseFootprintReviewReasonCounts,
      _metadataValue(
        metadata['receiptRequiredBaseFootprintReviewReasonCounts'],
      ),
    );
  }

  void recordOcrStoragePolicy(Map<String, Object?> metadata) {
    _mergeOrOutcome(
      target: _ocrStoragePolicyCounts,
      counts: metadata['ocrStoragePolicyCounts'],
      outcome: metadata['ocrStoragePolicyOutcome'],
    );
    _mergeCountMap(
      _ocrUsesPreparedSourceBeforeSavedProofCounts,
      _metadataValue(metadata['ocrUsesPreparedSourceBeforeSavedProofCounts']),
    );
    _mergeCountMap(
      _ocrUsesSavedProofFallbackCounts,
      _metadataValue(metadata['ocrUsesSavedProofFallbackCounts']),
    );
  }

  void _mergeOrOutcome({
    required Map<String, int> target,
    required Object? counts,
    required Object? outcome,
  }) {
    final countMap = _metadataValue(counts);
    if (countMap.isEmpty) {
      _increment(target, _stringValue(outcome));
    } else {
      _mergeCountMap(target, countMap);
    }
  }
}
