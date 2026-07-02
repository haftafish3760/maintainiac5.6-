part of 'expense_screen_telemetry.dart';

class _ExpenseTelemetryHealthSnapshotAccumulator {
  _ExpenseTelemetryHealthSnapshotAccumulator({
    required this.totalEventCount,
    DateTime? generatedAtUtc,
  }) : generatedAtUtc = (generatedAtUtc ?? DateTime.now().toUtc()).toUtc();

  final int totalEventCount;
  final DateTime generatedAtUtc;
  final eventCounts = <String, int>{};
  final platformCounts = <String, int>{};
  final deviceTierCounts = <String, int>{};
  final storageModeCounts = <String, int>{};
  final planStatusCounts = <String, int>{};
  final connectionStatusCounts = <String, int>{};
  var pendingUploadCount = 0;
  var uploadedEventCount = 0;
  var screenOpenCount = 0;
  var timeSpentEventCount = 0;
  var totalTimeSpentMs = 0;
  var addExpenseStartedCount = 0;
  var addExpenseCompletedCount = 0;
  var addExpenseAbandonedCount = 0;
  var validationErrorCount = 0;
  var saveFailureCount = 0;
  var imageAttachSuccessCount = 0;
  var imageAttachFailureCount = 0;
  var ocrStartedCount = 0;
  var ocrCompletedCount = 0;
  var ocrFailedCount = 0;
  var parserStartedCount = 0;
  var parserCompletedCount = 0;
  var parserNeedsReviewCount = 0;
  var parserFailedCount = 0;
  final parserCategoryCounts = <String, int>{};
  final parserNeedsReviewCategoryCounts = <String, int>{};
  final parserFailedCategoryCounts = <String, int>{};
  final parserFieldConfidenceCounts = <String, int>{};
  final parserCategoryHealthCounts = <String, int>{};
  final parserCategoryReviewActionCounts = <String, int>{};
  final parserPackPressureStatusCounts = <String, int>{};
  final receiptReadinessSummary = _ExpenseTelemetryReceiptReadinessSummary();
  final parserRequiredFieldStatusCounts = <String, int>{};
  final parserDownstreamReadinessStatusCounts = <String, int>{};
  final parserDownstreamReadinessCounts = <String, int>{};
  final parserReviewRootCauseCounts = <String, int>{};
  final localReceiptParserRoutingCounts = <String, int>{};
  final localParserEvidenceOutcomeCounts = <String, int>{};
  final ocrParserTaskCounts = <String, int>{};
  final ocrFieldReadinessCounts = <String, int>{};
  final ocrSourceSummary = _ExpenseTelemetryOcrSourceSummary();
  final clientProofSummary = _ExpenseTelemetryClientProofSummary();
  final cameraHealthSummary = _ExpenseTelemetryCameraHealthSummary();
  final exposureQualitySummary = _ExpenseTelemetryExposureQualitySummary();
  final nativeCameraSummary = _ExpenseTelemetryNativeCameraSummary();
  final receiptCapturePlanSummary =
      _ExpenseTelemetryReceiptCapturePlanSummary();
  var nativePreCaptureExposureAbortCount = 0;
  final nativePreCaptureExposureAbortReasonCounts = <String, int>{};
  var manualBrightnessChangeCount = 0;
  final nativeControlsSummary = _ExpenseTelemetryNativeControlsSummary();
  var localReceiptParserKeptLocalCount = 0;
  var localReceiptParserOptionalPackOfferCount = 0;
  var ocrCorrectionOpenedCount = 0;
  var appFilledReceiptLineConfirmedCount = 0;
  var appFilledReceiptLineCorrectedCount = 0;
  var userCorrectionCount = 0;
  var cloudBackupSuccessCount = 0;
  var cloudBackupFailureCount = 0;
  var syncPendingCount = 0;
  var syncedCount = 0;
  var syncFailedCount = 0;
  final expenseSummarySync = _ExpenseSummaryOcrContractSyncSummary();
  var exportStartedCount = 0;
  var exportCompletedCount = 0;
  var exportBlockedCount = 0;
  var exportFailedCount = 0;
  final failureStats = <String, _ExpenseFailureStats>{};
  final recentFailures = <ExpenseFailureEventDetail>[];
  void mergeParserPackPressure(Map<String, Object?> metadata) {
    _increment(
      parserCategoryReviewActionCounts,
      _stringValue(metadata['parserCategoryReviewActionCode']),
    );
    _increment(
      parserPackPressureStatusCounts,
      _stringValue(metadata['parserPackPressureStatus']),
    );
  }

  void mergeParserReviewRootCause(Map<String, Object?> metadata) {
    _increment(
      parserReviewRootCauseCounts,
      _stringValue(metadata['parserReviewRootCauseCode']),
    );
  }

  void mergeLocalReceiptParserRouting(Map<String, Object?> metadata) {
    final routeCounts = _metadataValue(
      metadata['localReceiptParserRoutingCounts'],
    );
    if (routeCounts.isEmpty) {
      _increment(
        localReceiptParserRoutingCounts,
        _stringValue(metadata['localReceiptParserRoutingCode']),
      );
    } else {
      _mergeCountMap(localReceiptParserRoutingCounts, routeCounts);
    }
    localReceiptParserKeptLocalCount += _intValue(
      metadata['localReceiptParserKeptLocalCount'],
    );
    localReceiptParserOptionalPackOfferCount += _intValue(
      metadata['localReceiptParserOptionalPackOfferCount'],
    );
  }

  void mergeLocalParserEvidence(Map<String, Object?> metadata) {
    final evidenceCounts = _metadataValue(
      metadata['localParserEvidenceOutcomeCounts'],
    );
    if (evidenceCounts.isEmpty) {
      _increment(
        localParserEvidenceOutcomeCounts,
        _stringValue(metadata['localParserEvidenceOutcome']),
      );
    } else {
      _mergeCountMap(localParserEvidenceOutcomeCounts, evidenceCounts);
    }
  }
}
