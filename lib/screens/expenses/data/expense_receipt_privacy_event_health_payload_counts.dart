part of 'expense_receipt_privacy_event_store.dart';

void _addReceiptPrivacyEventPayloadCounts(
  _ReceiptPrivacyEventHealthCounts counts,
  Map<String, Object?> payload, {
  required String event,
}) {
  _increment(counts.eventCounts, event);
  _increment(counts.featureAreaCounts, _stringValue(payload['featureArea']));
  _increment(counts.ocrSeverityCounts, _stringValue(payload['ocrSeverity']));
  _increment(counts.parseQualityCounts, _stringValue(payload['parseQuality']));
  _increment(counts.parserTrustCounts, _stringValue(payload['parserTrust']));
  _increment(
    counts.parserReviewCauseCounts,
    _stringValue(payload['parserReviewCause']),
  );
  _increment(
    counts.totalsMathStatusCounts,
    _stringValue(payload['totalsMathStatus']),
  );
  for (final fieldKey in _stringListValue(payload['fieldReviewKeys'])) {
    _increment(counts.fieldReviewKeyCounts, fieldKey);
  }
  _increment(
    counts.capabilityTierCounts,
    _stringValue(payload['capabilityTier']),
  );
  _increment(counts.captureModeCounts, _stringValue(payload['captureMode']));
  _increment(
    counts.captureOutcomeCounts,
    _stringValue(payload['captureOutcome']),
  );
  _increment(counts.focusBucketCounts, _stringValue(payload['focusBucket']));
  _increment(
    counts.readabilityBucketCounts,
    _stringValue(payload['readabilityBucket']),
  );
  _increment(counts.errorKindCounts, _stringValue(payload['errorKind']));
  for (final warning in _stringListValue(payload['warningKinds'])) {
    _increment(counts.warningKindCounts, warning);
  }
  _mergeCountMap(
    counts.parserLineRoleCounts,
    _mapValue(payload['parserLineRoleCounts']),
  );
  _mergeCountMap(
    counts.parserTaskCounts,
    _mapValue(payload['parserTaskCounts']),
  );
  _mergeCountMap(
    counts.parserCategoryCounts,
    _mapValue(payload['parserCategoryCounts']),
  );
  _mergeCountMap(
    counts.parserCategoryHealthCounts,
    _mapValue(payload['parserCategoryHealthCounts']),
  );
  _increment(
    counts.parserCategoryReviewActionCounts,
    _stringValue(payload['parserCategoryReviewActionCode']),
  );
  _mergeCountMap(
    counts.parserRequiredFieldStatusCounts,
    _mapValue(payload['parserRequiredFieldStatusCounts']),
  );
  _increment(
    counts.parserDownstreamReadinessStatusCounts,
    _stringValue(payload['parserDownstreamReadinessStatus']),
  );
  _mergeCountMap(
    counts.parserDownstreamReadinessCounts,
    _mapValue(payload['parserDownstreamReadinessCounts']),
  );
  _addReceiptPrivacyEventLocalRoutingCounts(counts, payload);
  _increment(
    counts.ocrParserReadinessStatusCounts,
    _stringValue(payload['ocrParserReadinessStatus']),
  );
  _increment(
    counts.ocrDownstreamReadinessStatusCounts,
    _stringValue(payload['ocrDownstreamReadinessStatus']),
  );
  _mergeCountMap(
    counts.ocrDownstreamReadinessCounts,
    _mapValue(payload['ocrDownstreamReadinessCounts']),
  );
  _mergeCountMap(
    counts.ocrParserLineRoleCounts,
    _mapValue(payload['ocrParserLineRoleCounts']),
  );
  _increment(
    counts.ocrDominantParserLineRoleCounts,
    _stringValue(payload['ocrDominantParserLineRole']),
  );
  _mergeCountMap(
    counts.ocrParserBucketCounts,
    _mapValue(payload['ocrParserBucketCounts']),
  );
  _mergeCountMap(
    counts.ocrParserTaskCounts,
    _mapValue(payload['ocrParserTaskCounts']),
  );
  _increment(
    counts.clientProofRedactionStatusCounts,
    _stringValue(payload['clientProofRedactionStatus']),
  );
  _mergeCountMap(
    counts.clientProofVisibilityCounts,
    _mapValue(payload['clientProofVisibilityCounts']),
  );
  _increment(
    counts.selectedReceiptLinePurposeCounts,
    _stringValue(payload['selectedReceiptLinePurpose']),
  );
  counts.selectedReceiptLineCount += _intValue(
    payload['selectedReceiptLineCount'],
  );
  counts.excludedReceiptLineCount += _intValue(
    payload['excludedReceiptLineCount'],
  );
  counts.clientProofReviewLineCount += _intValue(
    payload['clientProofReviewLineCount'],
  );
  counts.redactedReceiptLineCount += _intValue(
    payload['redactedReceiptLineCount'],
  );
  _increment(
    counts.clientProofRedactionPlanStatusCounts,
    _stringValue(payload['clientProofRedactionPlanStatus']),
  );
  counts.clientProofVisibleLineCount += _intValue(
    payload['clientProofVisibleLineCount'],
  );
  counts.clientProofHiddenLineCount += _intValue(
    payload['clientProofHiddenLineCount'],
  );
  counts.clientProofPlanReviewLineCount += _intValue(
    payload['clientProofPlanReviewLineCount'],
  );
  _increment(
    counts.clientProofImageReviewStatusCounts,
    _stringValue(payload['clientProofImageReviewStatus']),
  );
  counts.clientProofImageSectionCount += _intValue(
    payload['clientProofImageSectionCount'],
  );
  counts.clientProofImageVisibleSectionCount += _intValue(
    payload['clientProofImageVisibleSectionCount'],
  );
  counts.clientProofImageHiddenSectionCount += _intValue(
    payload['clientProofImageHiddenSectionCount'],
  );
  counts.clientProofImageReviewSectionCount += _intValue(
    payload['clientProofImageReviewSectionCount'],
  );
  counts.clientProofImageUnassignedLineCount += _intValue(
    payload['clientProofImageUnassignedLineCount'],
  );
  counts.clientProofImageUnassignedHiddenLineCount += _intValue(
    payload['clientProofImageUnassignedHiddenLineCount'],
  );
  counts.clientProofImageUnassignedReviewLineCount += _intValue(
    payload['clientProofImageUnassignedReviewLineCount'],
  );
  _mergeCountMap(
    counts.ocrFieldReadinessCounts,
    _mapValue(payload['ocrFieldReadinessCounts']),
  );
}

void _addReceiptPrivacyEventLocalRoutingCounts(
  _ReceiptPrivacyEventHealthCounts counts,
  Map<String, Object?> payload,
) {
  final localRouteCounts = _mapValue(
    payload['localReceiptParserRoutingCounts'],
  );
  if (localRouteCounts.isEmpty) {
    _increment(
      counts.localReceiptParserRoutingCounts,
      _stringValue(payload['localReceiptParserRoutingCode']),
    );
  } else {
    _mergeCountMap(counts.localReceiptParserRoutingCounts, localRouteCounts);
  }
  counts.localReceiptParserKeptLocalCount += _intValue(
    payload['localReceiptParserKeptLocalCount'],
  );
  counts.localReceiptParserOptionalPackOfferCount += _intValue(
    payload['localReceiptParserOptionalPackOfferCount'],
  );
}
