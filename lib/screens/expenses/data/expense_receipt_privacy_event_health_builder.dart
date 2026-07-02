part of 'expense_receipt_privacy_event_store.dart';

ReceiptPrivacyEventHealthSnapshot _buildReceiptPrivacyEventHealthSnapshot(
  Iterable<PrivacySafeReceiptEventRecord> records, {
  DateTime? generatedAtUtc,
}) {
  final sorted = records.toList(growable: false)
    ..sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
  final counts = _ReceiptPrivacyEventHealthCounts();

  for (final record in sorted) {
    final payload = ReceiptPrivacyEventPolicy.sanitizeMap(record.payload);
    if (record.isPendingUpload) {
      counts.pendingUploadCount += 1;
    } else {
      counts.uploadedEventCount += 1;
    }
    final event = _stringValue(payload['event']);
    _addReceiptPrivacyEventPayloadCounts(counts, payload, event: event);
    final ocrSummaryMathStatus = _stringValue(payload['ocrSummaryMathStatus']);
    _increment(counts.ocrSummaryMathStatusCounts, ocrSummaryMathStatus);
    if (_receiptPrivacyOcrSummaryMathNeedsReview(
      ocrSummaryMathStatus,
      reconciled: _boolValue(payload['ocrSummaryMathReconciled']),
    )) {
      counts.ocrSummaryMathMismatchCount += 1;
    }
    final ocrLineSequenceStatus = _stringValue(
      payload['ocrLineSequenceStatus'],
    );
    _increment(counts.ocrLineSequenceStatusCounts, ocrLineSequenceStatus);
    if (_receiptPrivacyOcrLineSequenceNeedsReview(ocrLineSequenceStatus)) {
      counts.ocrLineSequenceReviewCount += 1;
    }
    final ocrReceiptStructureStatus = _stringValue(
      payload['ocrReceiptStructureStatus'],
    );
    _increment(
      counts.ocrReceiptStructureStatusCounts,
      ocrReceiptStructureStatus,
    );
    if (_receiptPrivacyOcrStructureNeedsReview(ocrReceiptStructureStatus)) {
      counts.ocrReceiptStructureReviewCount += 1;
    }
    final ocrSourceSectionContinuityStatus = _stringValue(
      payload['ocrSourceSectionContinuityStatus'],
    );
    _increment(
      counts.ocrSourceSectionContinuityStatusCounts,
      ocrSourceSectionContinuityStatus,
    );
    counts.ocrSourceSectionCount += _intValue(payload['ocrSourceSectionCount']);
    if (_receiptPrivacyOcrSourceSectionNeedsReview(
      ocrSourceSectionContinuityStatus,
      reviewNeeded: _boolValue(
        payload['ocrSourceSectionContinuityReviewNeeded'],
      ),
    )) {
      counts.ocrSourceSectionReviewCount += 1;
    }
    final ocrSeverity = _stringValue(payload['ocrSeverity']);
    final parseQuality = _stringValue(payload['parseQuality']);
    if (_receiptPrivacyEventNeedsReview(
      event: event,
      ocrSeverity: ocrSeverity,
      parseQuality: parseQuality,
      needsHeavyReview: _boolValue(payload['needsHeavyReview']),
    )) {
      counts.reviewOrProblemCount += 1;
    }
    if (event == PrivacySafeReceiptEventType.receiptOcrBlocked.name) {
      counts.blockedOcrCount += 1;
    }
    if (event == PrivacySafeReceiptEventType.receiptTotalsMismatch.name) {
      counts.totalsMismatchCount += 1;
    }
    if (_boolValue(payload['explicitTotalsComplete']) &&
        !_boolValue(payload['taxMathReconciled'])) {
      counts.taxMathMismatchCount += 1;
    }
    if (_boolValue(payload['needsHeavyReview'])) {
      counts.heavyReviewCount += 1;
    }
    if (event == PrivacySafeReceiptEventType.inventoryCatalogMatchWeak.name) {
      counts.catalogWeakMatchCount += 1;
    }
    if (_boolValue(payload['hadDuplicateOrOverlapText'])) {
      counts.duplicateOrOverlapCount += 1;
    }
    counts.unmatchedMaterialLineCount += _intValue(
      payload['unmatchedMaterialLineCount'],
    );
    counts.catalogMatchedLineCount += _intValue(
      payload['catalogMatchedLineCount'],
    );
    counts.detectedLineCount += _intValue(payload['detectedLineCount']);
    counts.parserLineCount += _intValue(payload['parserLineCount']);
    counts.ocrItemCandidateLineCount += _intValue(
      payload['ocrItemCandidateLineCount'],
    );
    counts.ocrPricedLineCount += _intValue(payload['ocrPricedLineCount']);
    counts.ocrParserReadyLineCount += _intValue(
      payload['ocrParserReadyLineCount'],
    );
    counts.ocrParserReviewSignalCount += _intValue(
      payload['ocrParserReviewSignalCount'],
    );
    counts.ocrHighConfidenceItemLineCount += _intValue(
      payload['ocrHighConfidenceItemLineCount'],
    );
    counts.ocrReviewItemLineCount += _intValue(
      payload['ocrReviewItemLineCount'],
    );
    counts.ocrQuantitySignalItemLineCount += _intValue(
      payload['ocrQuantitySignalItemLineCount'],
    );
    counts.ocrSkuSignalItemLineCount += _intValue(
      payload['ocrSkuSignalItemLineCount'],
    );
    counts.ocrGenericItemLineCount += _intValue(
      payload['ocrGenericItemLineCount'],
    );
    counts.ocrInventoryPrepLineIdCount += _intValue(
      payload['ocrInventoryPrepLineIdCount'],
    );
    counts.ocrParserReadyFieldCount += _intValue(
      payload['ocrParserReadyFieldCount'],
    );
    counts.ocrParserReviewFieldCount += _intValue(
      payload['ocrParserReviewFieldCount'],
    );
    counts.ocrSubtotalCandidateLineCount += _intValue(
      payload['ocrSubtotalCandidateLineCount'],
    );
    counts.ocrTaxCandidateLineCount += _intValue(
      payload['ocrTaxCandidateLineCount'],
    );
    counts.ocrTotalCandidateLineCount += _intValue(
      payload['ocrTotalCandidateLineCount'],
    );
    counts.ocrTenderCandidateLineCount += _intValue(
      payload['ocrTenderCandidateLineCount'],
    );
    counts.ocrMetadataCandidateLineCount += _intValue(
      payload['ocrMetadataCandidateLineCount'],
    );
    counts.ocrStableLineIdCount += _intValue(payload['ocrStableLineIdCount']);
    counts.ocrParserReadyItemLineIdCount += _intValue(
      payload['ocrParserReadyItemLineIdCount'],
    );
    counts.ocrReviewItemLineIdCount += _intValue(
      payload['ocrReviewItemLineIdCount'],
    );
    counts.pdfPagesRequested += _intValue(payload['pdfPagesRequested']);
    counts.photoSectionCount += _intValue(payload['photoSectionCount']);
    counts.retakeCount += _intValue(payload['retakeCount']);
    counts.captureDurationMs += _intValue(payload['captureDurationMs']);
  }

  return counts.toSnapshot(sorted: sorted, generatedAtUtc: generatedAtUtc);
}
