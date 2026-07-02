part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryClientProofSummary {
  final _redactionStatusCounts = <String, int>{};
  final _visibilityCounts = <String, int>{};
  final _selectedLinePurposeCounts = <String, int>{};
  final _redactionPlanStatusCounts = <String, int>{};

  var selectedLineCountTotal = 0;
  var excludedLineCountTotal = 0;
  var reviewLineCountTotal = 0;
  var redactedLineCountTotal = 0;
  var visibleLineCountTotal = 0;
  var hiddenLineCountTotal = 0;
  var planReviewLineCountTotal = 0;

  Map<String, int> get redactionStatusCounts {
    return Map.unmodifiable(_redactionStatusCounts);
  }

  Map<String, int> get visibilityCounts => Map.unmodifiable(_visibilityCounts);
  Map<String, int> get selectedLinePurposeCounts {
    return Map.unmodifiable(_selectedLinePurposeCounts);
  }

  Map<String, int> get redactionPlanStatusCounts {
    return Map.unmodifiable(_redactionPlanStatusCounts);
  }

  String get topRedactionStatus => _topCountKey(_redactionStatusCounts);
  String get topVisibility => _topCountKey(_visibilityCounts);
  String get topSelectedLinePurpose => _topCountKey(_selectedLinePurposeCounts);
  String get topRedactionPlanStatus => _topCountKey(_redactionPlanStatusCounts);

  void record(Map<String, Object?> metadata) {
    _increment(
      _redactionStatusCounts,
      _stringValue(metadata['clientProofRedactionStatus']),
    );
    _mergeCountMap(
      _visibilityCounts,
      _metadataValue(metadata['clientProofVisibilityCounts']),
    );
    _increment(
      _selectedLinePurposeCounts,
      _stringValue(metadata['selectedReceiptLinePurpose']),
    );
    selectedLineCountTotal += _intValue(metadata['selectedReceiptLineCount']);
    excludedLineCountTotal += _intValue(metadata['excludedReceiptLineCount']);
    reviewLineCountTotal += _intValue(metadata['clientProofReviewLineCount']);
    redactedLineCountTotal += _intValue(metadata['redactedReceiptLineCount']);
    _increment(
      _redactionPlanStatusCounts,
      _stringValue(metadata['clientProofRedactionPlanStatus']),
    );
    visibleLineCountTotal += _intValue(metadata['clientProofVisibleLineCount']);
    hiddenLineCountTotal += _intValue(metadata['clientProofHiddenLineCount']);
    planReviewLineCountTotal += _intValue(
      metadata['clientProofPlanReviewLineCount'],
    );
  }
}
