part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryReceiptCapturePlanSummary {
  final _cloudAssistPlanCounts = <String, int>{};
  final _localOcrModeCounts = <String, int>{};
  final _parserDepthCounts = <String, int>{};
  final _parserPackCodeCounts = <String, int>{};
  final _optionalLocalParserPackCodeCounts = <String, int>{};
  final _cloudFallbackParserPackCodeCounts = <String, int>{};
  final _parserPackAccuracyBandCounts = <String, int>{};
  final _parserPackDisclosureLabelCounts = <String, int>{};
  final _stitchStatusCounts = <String, int>{};
  final _stitchFallbackReasonCounts = <String, int>{};
  final _stitchConfidenceBucketCounts = <String, int>{};
  final _stitchPairDiagnosticCounts = <String, int>{};

  var cloudOcrOptionalCount = 0;
  var cloudInventoryOptionalCount = 0;
  var estimatedOptionalLocalPackBytesTotal = 0;
  var estimatedOptionalLocalPackBytesMax = 0;

  Map<String, int> get cloudAssistPlanCounts =>
      Map.unmodifiable(_cloudAssistPlanCounts);
  Map<String, int> get localOcrModeCounts =>
      Map.unmodifiable(_localOcrModeCounts);
  Map<String, int> get parserDepthCounts =>
      Map.unmodifiable(_parserDepthCounts);
  Map<String, int> get parserPackCodeCounts =>
      Map.unmodifiable(_parserPackCodeCounts);
  Map<String, int> get optionalLocalParserPackCodeCounts =>
      Map.unmodifiable(_optionalLocalParserPackCodeCounts);
  Map<String, int> get cloudFallbackParserPackCodeCounts =>
      Map.unmodifiable(_cloudFallbackParserPackCodeCounts);
  Map<String, int> get parserPackAccuracyBandCounts =>
      Map.unmodifiable(_parserPackAccuracyBandCounts);
  Map<String, int> get stitchStatusCounts =>
      Map.unmodifiable(_stitchStatusCounts);
  Map<String, int> get stitchFallbackReasonCounts =>
      Map.unmodifiable(_stitchFallbackReasonCounts);
  Map<String, int> get stitchConfidenceBucketCounts =>
      Map.unmodifiable(_stitchConfidenceBucketCounts);
  Map<String, int> get stitchPairDiagnosticCounts =>
      Map.unmodifiable(_stitchPairDiagnosticCounts);

  String get topParserPackDisclosureLabel =>
      _topCountKey(_parserPackDisclosureLabelCounts);
  String get topCloudAssistPlan => _topCountKey(_cloudAssistPlanCounts);
  String get topLocalOcrMode => _topCountKey(_localOcrModeCounts);
  String get topParserDepth => _topCountKey(_parserDepthCounts);
  String get topParserPackCode => _topCountKey(_parserPackCodeCounts);
  String get topOptionalLocalParserPackCode =>
      _topCountKey(_optionalLocalParserPackCodeCounts);
  String get topCloudFallbackParserPackCode =>
      _topCountKey(_cloudFallbackParserPackCodeCounts);
  String get topParserPackAccuracyBand =>
      _topCountKey(_parserPackAccuracyBandCounts);
  String get topStitchStatus => _topCountKey(_stitchStatusCounts);
  String get topStitchFallbackReason =>
      _topCountKey(_stitchFallbackReasonCounts);
  String get topStitchConfidenceBucket =>
      _topCountKey(_stitchConfidenceBucketCounts);
  String get topStitchPairDiagnostic =>
      _topCountKey(_stitchPairDiagnosticCounts);

  void recordStarted(Map<String, Object?> metadata) {
    _increment(
      _cloudAssistPlanCounts,
      _stringValue(metadata['cloudAssistPlan']),
    );
    _mergeCountMap(
      _cloudAssistPlanCounts,
      _metadataValue(metadata['cloudAssistPlanBuckets']),
    );
    _increment(_localOcrModeCounts, _stringValue(metadata['localOcrMode']));
    _mergeCountMap(
      _localOcrModeCounts,
      _metadataValue(metadata['localOcrModeBuckets']),
    );
    _increment(_parserDepthCounts, _stringValue(metadata['parserDepth']));
    _mergeCountMap(
      _parserDepthCounts,
      _metadataValue(metadata['parserDepthBuckets']),
    );
    _mergeTokenList(_parserPackCodeCounts, metadata['parserPackCodes']);
    _mergeTokenList(
      _optionalLocalParserPackCodeCounts,
      metadata['optionalLocalParserPackCodes'],
    );
    _mergeTokenList(
      _cloudFallbackParserPackCodeCounts,
      metadata['cloudFallbackParserPackCodes'],
    );
    _mergeStringValueMap(
      _parserPackAccuracyBandCounts,
      _metadataValue(metadata['parserPackAccuracyBands']),
    );
    _recordOptionalPackBytes(metadata);
    _increment(
      _parserPackDisclosureLabelCounts,
      _stringValue(metadata['userFacingPackDisclosureLabel']),
    );
    if (_boolValue(metadata['cloudOcrOptional'])) cloudOcrOptionalCount += 1;
    cloudOcrOptionalCount += _intValue(metadata['cloudOcrOptionalCount']);
    if (_boolValue(metadata['cloudInventoryOptional'])) {
      cloudInventoryOptionalCount += 1;
    }
    cloudInventoryOptionalCount += _intValue(
      metadata['cloudInventoryOptionalCount'],
    );
    _increment(_stitchStatusCounts, _stringValue(metadata['stitchStatus']));
    _increment(
      _stitchFallbackReasonCounts,
      _stringValue(metadata['stitchFallbackReason']),
    );
    _increment(
      _stitchConfidenceBucketCounts,
      _stringValue(metadata['stitchConfidenceBucket']),
    );
    _mergeCountMap(
      _stitchPairDiagnosticCounts,
      _metadataValue(metadata['stitchPairDiagnosticCounts']),
    );
  }

  void _recordOptionalPackBytes(Map<String, Object?> metadata) {
    final optionalPackBytes = _intValue(
      metadata['estimatedOptionalLocalPackBytes'],
    );
    estimatedOptionalLocalPackBytesTotal += optionalPackBytes;
    if (optionalPackBytes > estimatedOptionalLocalPackBytesMax) {
      estimatedOptionalLocalPackBytesMax = optionalPackBytes;
    }
  }
}
