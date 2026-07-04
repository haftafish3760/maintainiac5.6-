part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryClientProofSummary {
  final _redactionStatusCounts = <String, int>{};
  final _visibilityCounts = <String, int>{};
  final _selectedLinePurposeCounts = <String, int>{};
  final _redactionPlanStatusCounts = <String, int>{};
  final _layoutRedactionStatusCounts = <String, int>{};

  var selectedLineCountTotal = 0;
  var excludedLineCountTotal = 0;
  var reviewLineCountTotal = 0;
  var redactedLineCountTotal = 0;
  var visibleLineCountTotal = 0;
  var hiddenLineCountTotal = 0;
  var planReviewLineCountTotal = 0;
  var layoutVisibleLineCountTotal = 0;
  var layoutHiddenLineCountTotal = 0;
  var layoutIgnoredLineCountTotal = 0;
  var layoutProtectedTypeCountTotal = 0;
  var layoutMerchantContextCountTotal = 0;
  var layoutTotalsContextCountTotal = 0;

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

  Map<String, int> get layoutRedactionStatusCounts {
    return Map.unmodifiable(_layoutRedactionStatusCounts);
  }

  String get topRedactionStatus => _topCountKey(_redactionStatusCounts);
  String get topVisibility => _topCountKey(_visibilityCounts);
  String get topSelectedLinePurpose => _topCountKey(_selectedLinePurposeCounts);
  String get topRedactionPlanStatus => _topCountKey(_redactionPlanStatusCounts);
  String get topLayoutRedactionStatus {
    return _topCountKey(_layoutRedactionStatusCounts);
  }

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
    _increment(
      _layoutRedactionStatusCounts,
      _stringValue(metadata['clientProofLayoutRedactionStatus']),
    );
    layoutVisibleLineCountTotal += _intValue(
      metadata['clientProofLayoutVisibleLineCount'],
    );
    layoutHiddenLineCountTotal += _intValue(
      metadata['clientProofLayoutHiddenLineCount'],
    );
    layoutIgnoredLineCountTotal += _intValue(
      metadata['clientProofLayoutIgnoredLineCount'],
    );
    layoutProtectedTypeCountTotal += _intValue(
      metadata['clientProofLayoutProtectedTypeCount'],
    );
    layoutMerchantContextCountTotal +=
        _boolValue(metadata['clientProofLayoutKeepsMerchantContext']) ? 1 : 0;
    layoutTotalsContextCountTotal +=
        _boolValue(metadata['clientProofLayoutKeepsTotalsContext']) ? 1 : 0;
  }
}
