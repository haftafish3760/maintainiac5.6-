part of 'expense_screen_telemetry.dart';

class _ExpenseSummaryOcrContractSyncSummary {
  int queuedCount = 0;
  int ocrContractQueuedCount = 0;
  int ocrContractSkippedCount = 0;

  final _sourceCounts = <String, int>{};
  final _skippedReasonCounts = <String, int>{};

  Map<String, int> get sourceCounts => Map.unmodifiable(_sourceCounts);
  Map<String, int> get skippedReasonCounts {
    return Map.unmodifiable(_skippedReasonCounts);
  }

  String get topSource => _topCountKey(_sourceCounts);
  String get topSkippedReason => _topCountKey(_skippedReasonCounts);

  void recordPendingSync(Map<String, Object?> metadata) {
    if (_stringValue(metadata['syncState']) != 'expense_summary_queued') {
      return;
    }
    queuedCount += 1;
    _increment(_sourceCounts, _stringValue(metadata['ocrContractSource']));
    if (_boolValue(metadata['ocrContractQueued'])) {
      ocrContractQueuedCount += 1;
      return;
    }
    ocrContractSkippedCount += 1;
    _increment(
      _skippedReasonCounts,
      _stringValue(metadata['ocrContractSkippedReason']),
    );
  }
}
