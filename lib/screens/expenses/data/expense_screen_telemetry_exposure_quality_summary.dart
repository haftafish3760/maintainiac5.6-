part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryExposureQualitySummary {
  final _preCaptureDecisionCounts = <String, int>{};
  final _autoDecisionCounts = <String, int>{};
  final _autoBrightnessCounts = <String, int>{};
  final _autoCandidateCounts = <String, int>{};
  final _assistStatusCounts = <String, int>{};
  final _acceptedPhotoOutcomeCounts = <String, int>{};
  final _capturedBrightnessCounts = <String, int>{};
  final _capturedSharpnessCounts = <String, int>{};
  final _capturedExposureMismatchCounts = <String, int>{};
  final _capturedQualitySignalCounts = <String, int>{};
  final _capturedBottomBrightnessCounts = <String, int>{};
  final _capturedBottomEdgeScoreCounts = <String, int>{};
  final _capturedVerticalQualitySignalCounts = <String, int>{};

  var preCaptureAdjustmentCount = 0;
  var autoCandidateFrameCount = 0;

  Map<String, int> get preCaptureDecisionCounts {
    return Map.unmodifiable(_preCaptureDecisionCounts);
  }

  Map<String, int> get autoDecisionCounts {
    return Map.unmodifiable(_autoDecisionCounts);
  }

  Map<String, int> get autoBrightnessCounts {
    return Map.unmodifiable(_autoBrightnessCounts);
  }

  Map<String, int> get autoCandidateCounts {
    return Map.unmodifiable(_autoCandidateCounts);
  }

  Map<String, int> get assistStatusCounts {
    return Map.unmodifiable(_assistStatusCounts);
  }

  Map<String, int> get acceptedPhotoOutcomeCounts {
    return Map.unmodifiable(_acceptedPhotoOutcomeCounts);
  }

  Map<String, int> get capturedBrightnessCounts {
    return Map.unmodifiable(_capturedBrightnessCounts);
  }

  Map<String, int> get capturedSharpnessCounts {
    return Map.unmodifiable(_capturedSharpnessCounts);
  }

  Map<String, int> get capturedExposureMismatchCounts {
    return Map.unmodifiable(_capturedExposureMismatchCounts);
  }

  Map<String, int> get capturedQualitySignalCounts {
    return Map.unmodifiable(_capturedQualitySignalCounts);
  }

  Map<String, int> get capturedBottomBrightnessCounts {
    return Map.unmodifiable(_capturedBottomBrightnessCounts);
  }

  Map<String, int> get capturedBottomEdgeScoreCounts {
    return Map.unmodifiable(_capturedBottomEdgeScoreCounts);
  }

  Map<String, int> get capturedVerticalQualitySignalCounts {
    return Map.unmodifiable(_capturedVerticalQualitySignalCounts);
  }

  String get topPreCaptureDecision => _topCountKey(_preCaptureDecisionCounts);
  String get topAutoDecision => _topCountKey(_autoDecisionCounts);
  String get topAutoBrightness => _topCountKey(_autoBrightnessCounts);
  String get topAutoCandidate => _topCountKey(_autoCandidateCounts);
  String get topAssistStatus => _topCountKey(_assistStatusCounts);
  String get topAcceptedPhotoOutcome =>
      _topCountKey(_acceptedPhotoOutcomeCounts);
  String get topCapturedBrightness => _topCountKey(_capturedBrightnessCounts);
  String get topCapturedSharpness => _topCountKey(_capturedSharpnessCounts);
  String get topCapturedExposureMismatch {
    return _topCountKey(_capturedExposureMismatchCounts);
  }

  String get topCapturedQualitySignal {
    return _topCountKey(_capturedQualitySignalCounts);
  }

  String get topCapturedBottomBrightness {
    return _topCountKey(_capturedBottomBrightnessCounts);
  }

  String get topCapturedBottomEdgeScore {
    return _topCountKey(_capturedBottomEdgeScoreCounts);
  }

  String get topCapturedVerticalQualitySignal {
    return _topCountKey(_capturedVerticalQualitySignalCounts);
  }

  void record(Map<String, Object?> metadata) {
    _mergeCountMap(
      _preCaptureDecisionCounts,
      _metadataValue(metadata['preCaptureExposureDecisionBuckets']),
    );
    preCaptureAdjustmentCount += _intValue(
      metadata['preCaptureExposureAdjustmentTotal'],
    );
    _mergeCountMap(
      _autoDecisionCounts,
      _metadataValue(metadata['autoExposureDecisionBuckets']),
    );
    _mergeCountMap(
      _autoBrightnessCounts,
      _metadataValue(metadata['autoExposureBrightnessBuckets']),
    );
    _mergeCountMap(
      _autoCandidateCounts,
      _metadataValue(metadata['autoExposureCandidateBuckets']),
    );
    _mergeCountMap(
      _assistStatusCounts,
      _metadataValue(metadata['exposureAssistStatuses']),
    );
    autoCandidateFrameCount += _intValue(
      metadata['autoExposureCandidateFrameTotal'],
    );
    _mergeCountMap(
      _acceptedPhotoOutcomeCounts,
      _metadataValue(metadata['acceptedPhotoQualityOutcomeCounts']),
    );
    _mergeCountMap(
      _capturedBrightnessCounts,
      _metadataValue(metadata['capturedPhotoBrightnessBuckets']),
    );
    _mergeCountMap(
      _capturedSharpnessCounts,
      _metadataValue(metadata['capturedPhotoSharpnessBuckets']),
    );
    _mergeCountMap(
      _capturedExposureMismatchCounts,
      _metadataValue(metadata['capturedPhotoExposureMismatches']),
    );
    _mergeCountMap(
      _capturedQualitySignalCounts,
      _metadataValue(metadata['capturedPhotoQualitySignals']),
    );
    _mergeCountMap(
      _capturedBottomBrightnessCounts,
      _metadataValue(metadata['capturedPhotoBottomBrightnessBuckets']),
    );
    _mergeCountMap(
      _capturedBottomEdgeScoreCounts,
      _metadataValue(metadata['capturedPhotoBottomEdgeScoreBuckets']),
    );
    _mergeCountMap(
      _capturedVerticalQualitySignalCounts,
      _metadataValue(metadata['capturedPhotoVerticalQualitySignals']),
    );
  }
}
