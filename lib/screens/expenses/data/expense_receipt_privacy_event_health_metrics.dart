part of 'expense_receipt_privacy_event_store.dart';

extension ReceiptPrivacyEventHealthMetrics
    on ReceiptPrivacyEventHealthSnapshot {
  bool get hasEvents => totalEventCount > 0;
  bool get needsAttention => reviewOrProblemCount > 0;

  double get reviewRate {
    if (totalEventCount == 0) return 0;
    return reviewOrProblemCount / totalEventCount;
  }

  int get ocrAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptOcrGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrPartial) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrBlocked);
  }

  int get captureAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptCaptureStarted) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureCompleted) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureAbandoned) +
        _eventCount(PrivacySafeReceiptEventType.receiptCaptureFailed);
  }

  int get captureCompletedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureCompleted);

  int get captureFailedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureFailed);

  int get captureAbandonedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptCaptureAbandoned);

  double get captureSuccessRate {
    final completedOrProblem =
        captureCompletedCount + captureFailedCount + captureAbandonedCount;
    if (completedOrProblem == 0) return 0;
    return captureCompletedCount / completedOrProblem;
  }

  double get averageCaptureDurationMs {
    if (captureCompletedCount == 0) return 0;
    return captureDurationMs / captureCompletedCount;
  }

  int get ocrGoodCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptOcrGood);

  int get ocrReadableCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptOcrGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptOcrPartial);
  }

  int get ocrFailedCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptOcrBlocked);

  double get ocrGoodRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrGoodCount / ocrAttemptCount;
  }

  double get ocrReadableRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrReadableCount / ocrAttemptCount;
  }

  double get ocrFailRate {
    if (ocrAttemptCount == 0) return 0;
    return ocrFailedCount / ocrAttemptCount;
  }

  int get parserAttemptCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptParserGood) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserPoor) +
        _eventCount(PrivacySafeReceiptEventType.receiptTotalsMismatch) +
        _eventCount(PrivacySafeReceiptEventType.inventoryCatalogMatchWeak);
  }

  int get parserGoodCount =>
      _eventCount(PrivacySafeReceiptEventType.receiptParserGood);

  int get parserProblemCount {
    return _eventCount(PrivacySafeReceiptEventType.receiptParserReview) +
        _eventCount(PrivacySafeReceiptEventType.receiptParserPoor) +
        _eventCount(PrivacySafeReceiptEventType.receiptTotalsMismatch) +
        _eventCount(PrivacySafeReceiptEventType.inventoryCatalogMatchWeak);
  }

  double get parserSuccessRate {
    if (parserAttemptCount == 0) return 0;
    return parserGoodCount / parserAttemptCount;
  }

  double get parserProblemRate {
    if (parserAttemptCount == 0) return 0;
    return parserProblemCount / parserAttemptCount;
  }

  double get catalogMatchRate {
    final total = catalogMatchedLineCount + unmatchedMaterialLineCount;
    if (total == 0) return 0;
    return catalogMatchedLineCount / total;
  }

  String get healthLabel {
    if (totalEventCount == 0) return 'no_data';
    if (blockedOcrCount > 0 ||
        taxMathMismatchCount > 0 ||
        heavyReviewCount > 0 ||
        reviewRate >= .35) {
      return 'needs_attention';
    }
    if (reviewRate >= .12 || catalogWeakMatchCount > 0) return 'watch';
    return 'healthy';
  }
}
