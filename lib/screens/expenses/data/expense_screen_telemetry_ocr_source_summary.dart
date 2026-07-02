part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryOcrSourceSummary {
  final _handoffStatusCounts = <String, int>{};
  final _handoffSignalCounts = <String, int>{};
  final _stitchSignalCounts = <String, int>{};
  final _scannerDecisionCounts = <String, int>{};
  final _captureSourceSignalCounts = <String, int>{};
  final _photoQualityRiskCounts = <String, int>{};
  final _qualityReviewStatusCounts = <String, int>{};
  final _qualityReviewActionCounts = <String, int>{};

  Map<String, int> get handoffStatusCounts {
    return Map.unmodifiable(_handoffStatusCounts);
  }

  Map<String, int> get handoffSignalCounts {
    return Map.unmodifiable(_handoffSignalCounts);
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

  Map<String, int> get photoQualityRiskCounts {
    return Map.unmodifiable(_photoQualityRiskCounts);
  }

  Map<String, int> get qualityReviewStatusCounts {
    return Map.unmodifiable(_qualityReviewStatusCounts);
  }

  Map<String, int> get qualityReviewActionCounts {
    return Map.unmodifiable(_qualityReviewActionCounts);
  }

  String get topHandoffStatus => _topCountKey(_handoffStatusCounts);
  String get topHandoffSignal => _topCountKey(_handoffSignalCounts);
  String get topStitchSignal => _topCountKey(_stitchSignalCounts);
  String get topScannerDecision => _topCountKey(_scannerDecisionCounts);
  String get topCaptureSourceSignal => _topCountKey(_captureSourceSignalCounts);
  String get topPhotoQualityRisk => _topCountKey(_photoQualityRiskCounts);
  String get topQualityReviewStatus => _topCountKey(_qualityReviewStatusCounts);
  String get topQualityReviewAction => _topCountKey(_qualityReviewActionCounts);

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
  }
}
