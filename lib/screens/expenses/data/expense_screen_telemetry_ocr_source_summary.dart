part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryOcrSourceSummary {
  final _handoffStatusCounts = <String, int>{};
  final _handoffSignalCounts = <String, int>{};
  final _reviewDepthSignalCounts = <String, int>{};
  final _reviewDepthStatusCounts = <String, int>{};
  final _stitchSignalCounts = <String, int>{};
  final _scannerDecisionCounts = <String, int>{};
  final _captureSourceSignalCounts = <String, int>{};
  final _sectionOrderSignalCounts = <String, int>{};
  final _photoQualityRiskCounts = <String, int>{};
  final _qualityReviewStatusCounts = <String, int>{};
  final _qualityReviewActionCounts = <String, int>{};
  final _sectionOrderReviewStatusCounts = <String, int>{};
  final _sectionOrderFailedPairStatusCounts = <String, int>{};

  Map<String, int> get handoffStatusCounts {
    return Map.unmodifiable(_handoffStatusCounts);
  }

  Map<String, int> get handoffSignalCounts {
    return Map.unmodifiable(_handoffSignalCounts);
  }

  Map<String, int> get reviewDepthSignalCounts {
    return Map.unmodifiable(_reviewDepthSignalCounts);
  }

  Map<String, int> get reviewDepthStatusCounts {
    return Map.unmodifiable(_reviewDepthStatusCounts);
  }

  Map<String, int> get stitchSignalCounts {
    return Map.unmodifiable(_stitchSignalCounts);
  }

  Map<String, int> get scannerDecisionCounts {
    return Map.unmodifiable(_scannerDecisionCounts);
  }

  Map<String, int> get captureSourceSignalCounts {
    return Map.unmodifiable(_captureSourceSignalCounts);
  }

  Map<String, int> get sectionOrderSignalCounts {
    return Map.unmodifiable(_sectionOrderSignalCounts);
  }

  Map<String, int> get photoQualityRiskCounts {
    return Map.unmodifiable(_photoQualityRiskCounts);
  }

  Map<String, int> get qualityReviewStatusCounts {
    return Map.unmodifiable(_qualityReviewStatusCounts);
  }

  Map<String, int> get qualityReviewActionCounts {
    return Map.unmodifiable(_qualityReviewActionCounts);
  }

  Map<String, int> get sectionOrderReviewStatusCounts {
    return Map.unmodifiable(_sectionOrderReviewStatusCounts);
  }

  Map<String, int> get sectionOrderFailedPairStatusCounts {
    return Map.unmodifiable(_sectionOrderFailedPairStatusCounts);
  }

  String get topHandoffStatus => _topCountKey(_handoffStatusCounts);
  String get topHandoffSignal => _topCountKey(_handoffSignalCounts);
  String get topReviewDepthSignal => _topCountKey(_reviewDepthSignalCounts);
  String get topReviewDepthStatus => _topCountKey(_reviewDepthStatusCounts);
  String get topStitchSignal => _topCountKey(_stitchSignalCounts);
  String get topScannerDecision => _topCountKey(_scannerDecisionCounts);
  String get topCaptureSourceSignal => _topCountKey(_captureSourceSignalCounts);
  String get topSectionOrderSignal => _topCountKey(_sectionOrderSignalCounts);
  String get topPhotoQualityRisk => _topCountKey(_photoQualityRiskCounts);
  String get topQualityReviewStatus => _topCountKey(_qualityReviewStatusCounts);
  String get topQualityReviewAction => _topCountKey(_qualityReviewActionCounts);
  String get topSectionOrderReviewStatus =>
      _topCountKey(_sectionOrderReviewStatusCounts);
  String get topSectionOrderFailedPairStatus =>
      _topCountKey(_sectionOrderFailedPairStatusCounts);

  void record(Map<String, Object?> metadata) {
    _increment(
      _handoffStatusCounts,
      _stringValue(metadata['ocrSourceHandoffStatus']),
    );
    _mergeCountMap(
      _handoffSignalCounts,
      _metadataValue(metadata['ocrSourceHandoffSignalCounts']),
    );
    _mergeCountMap(
      _reviewDepthSignalCounts,
      _metadataValue(metadata['ocrSourceReviewDepthSignalCounts']),
    );
    _increment(
      _reviewDepthStatusCounts,
      _stringValue(metadata['ocrSourceReviewDepthStatus']),
    );
    _mergeCountMap(
      _stitchSignalCounts,
      _metadataValue(metadata['ocrSourceStitchSignalCounts']),
    );
    _mergeCountMap(
      _scannerDecisionCounts,
      _metadataValue(metadata['ocrSourceScannerDecisionCounts']),
    );
    _mergeCountMap(
      _captureSourceSignalCounts,
      _metadataValue(metadata['ocrSourceCaptureSourceSignalCounts']),
    );
    _mergeCountMap(
      _sectionOrderSignalCounts,
      _metadataValue(metadata['ocrSourceSectionOrderSignalCounts']),
    );
    _mergeCountMap(
      _photoQualityRiskCounts,
      _metadataValue(metadata['ocrSourcePhotoQualityRiskCounts']),
    );
    _increment(
      _qualityReviewStatusCounts,
      _stringValue(metadata['ocrSourceQualityReviewStatus']),
    );
    _increment(
      _qualityReviewActionCounts,
      _stringValue(metadata['ocrSourceQualityReviewAction']),
    );
    _increment(
      _sectionOrderReviewStatusCounts,
      _stringValue(metadata['ocrSourceSectionOrderReviewStatus']),
    );
    _increment(
      _sectionOrderFailedPairStatusCounts,
      _stringValue(metadata['ocrSourceSectionOrderFailedPairStatus']),
    );
  }
}
