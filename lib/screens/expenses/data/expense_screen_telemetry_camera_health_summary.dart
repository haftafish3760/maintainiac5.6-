part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryCameraHealthSummary {
  final _coverageStatusCounts = <String, int>{};
  final _coverageReasonCounts = <String, int>{};
  final _savedPhotoWarningCounts = <String, int>{};
  final _savedPhotoWarningCauseCounts = <String, int>{};
  final _savedPhotoWarningSeverityCounts = <String, int>{};
  final _savedPhotoWarningActionCounts = <String, int>{};
  final _savedPhotoParserRiskCounts = <String, int>{};

  var coverageNeedsMoreCount = 0;
  var savedPhotoQualityWarningCount = 0;
  var savedPhotoCriticalWarningCount = 0;

  Map<String, int> get coverageStatusCounts {
    return Map.unmodifiable(_coverageStatusCounts);
  }

  Map<String, int> get coverageReasonCounts {
    return Map.unmodifiable(_coverageReasonCounts);
  }

  Map<String, int> get savedPhotoWarningCounts {
    return Map.unmodifiable(_savedPhotoWarningCounts);
  }

  Map<String, int> get savedPhotoWarningCauseCounts {
    return Map.unmodifiable(_savedPhotoWarningCauseCounts);
  }

  Map<String, int> get savedPhotoWarningSeverityCounts {
    return Map.unmodifiable(_savedPhotoWarningSeverityCounts);
  }

  Map<String, int> get savedPhotoWarningActionCounts {
    return Map.unmodifiable(_savedPhotoWarningActionCounts);
  }

  Map<String, int> get savedPhotoParserRiskCounts {
    return Map.unmodifiable(_savedPhotoParserRiskCounts);
  }

  String get topCoverageStatus {
    return _topReceiptPhotoCoverageStatusKey(_coverageStatusCounts);
  }

  String get topCoverageReason {
    return _topReceiptPhotoCoverageReasonKey(_coverageReasonCounts);
  }

  String get topSavedPhotoWarning => _topCountKey(_savedPhotoWarningCounts);
  String get topSavedPhotoWarningCause {
    return _topCountKey(_savedPhotoWarningCauseCounts);
  }

  String get topSavedPhotoWarningSeverity {
    return _topCountKey(_savedPhotoWarningSeverityCounts);
  }

  String get topSavedPhotoWarningActionCode {
    return _topCountKey(_savedPhotoWarningActionCounts);
  }

  String get topSavedPhotoWarningAction {
    return _savedPhotoWarningAction(
      topSavedPhotoWarning,
      topSavedPhotoWarningSeverity,
    );
  }

  String get topSavedPhotoParserRisk {
    return _topCountKey(_savedPhotoParserRiskCounts);
  }

  void record(Map<String, Object?> metadata) {
    _mergeCountMap(
      _coverageStatusCounts,
      _metadataValue(metadata['photoCoverageStatuses']),
    );
    _mergeCountMap(
      _coverageReasonCounts,
      _metadataValue(metadata['photoCoverageReasons']),
    );
    coverageNeedsMoreCount += _intValue(
      metadata['photoCoverageNeedsMoreCount'],
    );
    _mergeCountMap(
      _savedPhotoWarningCounts,
      _metadataValue(metadata['savedPhotoWarningCounts']),
    );
    _mergeCountMap(
      _savedPhotoWarningCauseCounts,
      _metadataValue(metadata['savedPhotoWarningCauseCounts']),
    );
    final severityCounts = _metadataValue(
      metadata['savedPhotoWarningSeverityCounts'],
    );
    _mergeCountMap(_savedPhotoWarningSeverityCounts, severityCounts);
    _mergeCountMap(
      _savedPhotoWarningActionCounts,
      _metadataValue(metadata['savedPhotoWarningActionCounts']),
    );
    _mergeCountMap(
      _savedPhotoParserRiskCounts,
      _metadataValue(metadata['savedPhotoParserRiskCounts']),
    );
    if (_boolValue(metadata['hasSavedPhotoQualityWarning'])) {
      savedPhotoQualityWarningCount += 1;
    }
    savedPhotoCriticalWarningCount += _intValue(severityCounts['critical']);
  }
}
