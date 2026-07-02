part of 'expense_screen_telemetry.dart';

extension ExpenseTelemetryHealthSnapshotMetrics
    on ExpenseTelemetryHealthSnapshot {
  double get averageTimeSpentSeconds {
    if (timeSpentEventCount == 0) return 0;
    return (totalTimeSpentMs / timeSpentEventCount) / 1000;
  }

  double get addExpenseCompletionRate {
    if (addExpenseStartedCount == 0) return 0;
    return addExpenseCompletedCount / addExpenseStartedCount;
  }

  double get addExpenseAbandonmentRate {
    if (addExpenseStartedCount == 0) return 0;
    return addExpenseAbandonedCount / addExpenseStartedCount;
  }

  double get imageAttachFailureRate {
    final total = imageAttachSuccessCount + imageAttachFailureCount;
    if (total == 0) return 0;
    return imageAttachFailureCount / total;
  }

  double get ocrSuccessRate {
    if (ocrStartedCount == 0) return 0;
    return ocrCompletedCount / ocrStartedCount;
  }

  double get parserSuccessRate {
    if (parserStartedCount == 0) return 0;
    return parserCompletedCount / parserStartedCount;
  }

  double get parserReviewRate {
    if (parserStartedCount == 0) return 0;
    return parserNeedsReviewCount / parserStartedCount;
  }

  double get parserFailureRate {
    if (parserStartedCount == 0) return 0;
    return parserFailedCount / parserStartedCount;
  }

  double get receiptPhotoCoverageNeedsMoreRate {
    if (ocrStartedCount == 0) return 0;
    return receiptPhotoCoverageNeedsMoreCount / ocrStartedCount;
  }

  double get savedPhotoQualityWarningRate {
    if (ocrStartedCount == 0) return 0;
    return savedPhotoQualityWarningCount / ocrStartedCount;
  }

  double get savedPhotoCriticalWarningRate {
    if (ocrStartedCount == 0) return 0;
    return savedPhotoCriticalWarningCount / ocrStartedCount;
  }

  double get preCaptureExposureAdjustmentRate {
    if (ocrStartedCount == 0) return 0;
    return preCaptureExposureAdjustmentCount / ocrStartedCount;
  }

  double get appFilledReceiptLineCorrectionRate {
    final total =
        appFilledReceiptLineConfirmedCount + appFilledReceiptLineCorrectedCount;
    if (total == 0) return 0;
    return appFilledReceiptLineCorrectedCount / total;
  }

  double get cloudBackupFailureRate {
    final total = cloudBackupSuccessCount + cloudBackupFailureCount;
    if (total == 0) return 0;
    return cloudBackupFailureCount / total;
  }

  double get syncFailureRate {
    final total = syncedCount + syncFailedCount;
    if (total == 0) return 0;
    return syncFailedCount / total;
  }

  double get exportCompletionRate {
    if (exportStartedCount == 0) return 0;
    return exportCompletedCount / exportStartedCount;
  }

  double get exportFailureRate {
    final totalAttempts = exportStartedCount + exportBlockedCount;
    if (totalAttempts == 0) return 0;
    return (exportFailedCount + exportBlockedCount) / totalAttempts;
  }

  bool get needsAttention {
    return saveFailureCount > 0 ||
        validationErrorCount > 0 ||
        addExpenseAbandonmentRate >= .25 ||
        imageAttachFailureRate >= .1 ||
        ocrSuccessRate < .9 && ocrStartedCount > 0 ||
        savedPhotoQualityWarningRate >= .1 && ocrStartedCount > 0 ||
        parserFailureRate >= .05 && parserStartedCount > 0 ||
        parserReviewRate >= .25 && parserStartedCount > 0 ||
        cloudBackupFailureRate >= .1 ||
        syncFailureRate >= .1 ||
        exportFailureRate >= .1 && exportStartedCount > 0;
  }

  String get healthLabel {
    if (totalEventCount == 0) return 'no_data';
    if (saveFailureCount > 0 || syncFailureRate >= .2) {
      return 'needs_attention';
    }
    if (needsAttention) return 'review';
    return 'healthy';
  }
}
