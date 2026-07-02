part of 'expense_receipt_privacy_event_store.dart';

bool _receiptPrivacyOcrSummaryMathNeedsReview(
  String status, {
  required bool reconciled,
}) {
  return status == 'mismatch' ||
      (status.isNotEmpty && status != 'incomplete' && !reconciled);
}

bool _receiptPrivacyOcrLineSequenceNeedsReview(String status) {
  return status.isNotEmpty &&
      status != 'unknown' &&
      status != 'empty' &&
      status != 'expected_order';
}

bool _receiptPrivacyOcrStructureNeedsReview(String status) {
  return status.isNotEmpty &&
      status != 'unknown' &&
      status != 'ready_for_parser';
}

bool _receiptPrivacyOcrSourceSectionNeedsReview(
  String status, {
  required bool reviewNeeded,
}) {
  return reviewNeeded ||
      (status.isNotEmpty &&
          status != 'unknown' &&
          status != 'no_text' &&
          status != 'no_source_sections' &&
          status != 'single_section' &&
          status != 'continuous_sections');
}

bool _receiptPrivacyEventNeedsReview({
  required String event,
  required String ocrSeverity,
  required String parseQuality,
  required bool needsHeavyReview,
}) {
  return event.contains('Review') ||
      event.contains('Poor') ||
      event.contains('Blocked') ||
      event.contains('Mismatch') ||
      event.contains('Weak') ||
      ocrSeverity == 'review' ||
      ocrSeverity == 'partial' ||
      ocrSeverity == 'blocked' ||
      parseQuality == 'medium' ||
      parseQuality == 'low' ||
      needsHeavyReview;
}
