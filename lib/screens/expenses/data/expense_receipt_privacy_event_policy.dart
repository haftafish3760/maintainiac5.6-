part of 'expense_receipt_privacy_event_store.dart';

class ReceiptPrivacyEventPolicy {
  const ReceiptPrivacyEventPolicy._();

  static const allowedKeys = <String>{
    'event',
    'featureArea',
    'capabilityTier',
    'parserDepth',
    'ocrSeverity',
    'parseQuality',
    'parserTrust',
    'parserReviewCause',
    'totalsMathStatus',
    'fieldReviewKeys',
    'captureMode',
    'captureOutcome',
    'focusBucket',
    'readabilityBucket',
    'errorKind',
    'warningKinds',
    'parserLineRoleCounts',
    'parserTaskCounts',
    'parserCategoryCounts',
    'parserCategoryHealthCounts',
    'parserCategoryReviewActionCode',
    'parserRequiredFieldStatusCounts',
    'parserDownstreamReadinessStatus',
    'parserDownstreamReadinessCounts',
    'localReceiptParserRoutingCode',
    'localReceiptParserRoutingCounts',
    'localReceiptParserKeptLocalCount',
    'localReceiptParserOptionalPackOfferCount',
    'photoSectionCount',
    'retakeCount',
    'captureDurationMs',
    'attachmentsRead',
    'attachmentsSkipped',
    'rawLineCount',
    'parserLineCount',
    'ocrItemCandidateLineCount',
    'ocrPricedLineCount',
    'ocrParserReadyLineCount',
    'ocrParserReviewSignalCount',
    'ocrParserReadinessStatus',
    'ocrDownstreamReadinessStatus',
    'ocrDownstreamReadinessCounts',
    'ocrHighConfidenceItemLineCount',
    'ocrReviewItemLineCount',
    'ocrQuantitySignalItemLineCount',
    'ocrSkuSignalItemLineCount',
    'ocrGenericItemLineCount',
    'ocrInventoryPrepLineIdCount',
    'ocrParserReadyFieldCount',
    'ocrParserReviewFieldCount',
    'ocrSummaryMathStatus',
    'ocrSummaryMathReconciled',
    'ocrLineSequenceStatus',
    'ocrReceiptStructureStatus',
    'ocrSourceSectionContinuityStatus',
    'ocrSourceSectionCount',
    'ocrSourceSectionContinuityReviewNeeded',
    'ocrSubtotalCandidateLineCount',
    'ocrTaxCandidateLineCount',
    'ocrTotalCandidateLineCount',
    'ocrTenderCandidateLineCount',
    'ocrMetadataCandidateLineCount',
    'ocrParserLineRoleCounts',
    'ocrDominantParserLineRole',
    'ocrStableLineIdCount',
    'ocrParserReadyItemLineIdCount',
    'ocrReviewItemLineIdCount',
    'ocrParserBucketCounts',
    'ocrParserTaskCounts',
    'clientProofRedactionStatus',
    'clientProofVisibilityCounts',
    'selectedReceiptLinePurpose',
    'selectedReceiptLineCount',
    'excludedReceiptLineCount',
    'clientProofReviewLineCount',
    'redactedReceiptLineCount',
    'clientProofRedactionPlanStatus',
    'clientProofVisibleLineCount',
    'clientProofHiddenLineCount',
    'clientProofPlanReviewLineCount',
    'clientProofLayoutRedactionStatus',
    'clientProofLayoutVisibleLineCount',
    'clientProofLayoutHiddenLineCount',
    'clientProofLayoutIgnoredLineCount',
    'clientProofLayoutProtectedTypeCount',
    'clientProofLayoutKeepsMerchantContext',
    'clientProofLayoutKeepsTotalsContext',
    'clientProofImageReviewStatus',
    'clientProofImageSectionCount',
    'clientProofImageVisibleSectionCount',
    'clientProofImageHiddenSectionCount',
    'clientProofImageReviewSectionCount',
    'clientProofImageUnassignedLineCount',
    'clientProofImageUnassignedHiddenLineCount',
    'clientProofImageUnassignedReviewLineCount',
    'ocrFieldReadinessCounts',
    'detectedLineCount',
    'reviewLineCount',
    'materialLineCount',
    'catalogMatchedLineCount',
    'unmatchedMaterialLineCount',
    'negativeLineCount',
    'adjustmentLineCount',
    'pdfPagesRequested',
    'reconciled',
    'taxMathReconciled',
    'explicitTotalsComplete',
    'needsHeavyReview',
    'usedLocalOcr',
    'hadDuplicateOrOverlapText',
    'cloudAssistPlan',
    'ocrDecisionPolicy',
    'localOcrAvailable',
    'localOcrMode',
    'localOcrDefault',
    'cloudOcrOptional',
    'cloudInventoryOptional',
    'cloudAssistRequiresExplicitChoice',
    'cloudAssistRequiresInternet',
    'cameraCaptureCloudRequired',
    'receiptReviewCloudRequired',
    'baseReceiptBudgetBytes',
    'includedLocalPackBytes',
    'optionalLocalPackBytes',
    'baseIncludesHeavyParserPacks',
    'footprintCloudFallbackPackCodes',
    'lowStorageSafe',
    'requiresExplicitDownloadForHeavyPacks',
    'receiptInstallMode',
    'receiptInstallOptionalLocalDownloadAllowed',
    'receiptInstallCloudFallbackSuggested',
    'receiptInstallMaxOptionalLocalBytes',
    'receiptInstallReason',
  };

  static const maxStringLength = 64;
  static final RegExp _safeTokenPattern = RegExp(r'^[A-Za-z0-9_]+$');

  static Map<String, Object?> sanitize(PrivacySafeReceiptEvent event) {
    return sanitizeMap(event.toMap());
  }

  static Map<String, Object?> sanitizeMap(Map<String, Object?> source) {
    final sanitized = <String, Object?>{};
    for (final entry in source.entries) {
      final key = entry.key;
      if (!allowedKeys.contains(key)) continue;
      sanitized[key] = _sanitizeValue(key, entry.value);
    }
    return Map.unmodifiable(sanitized);
  }

  static bool isSafeMap(Map<String, Object?> source) {
    try {
      sanitizeMap(source);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Object? _sanitizeValue(String key, Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) {
      if (value < 0) {
        throw ArgumentError.value(value, key, 'Counts must be non-negative.');
      }
      return value;
    }
    if (value is String) return _sanitizeToken(key, value);
    if (value is Map) {
      final sanitized = <String, int>{};
      for (final entry in value.entries) {
        final mapKey = _sanitizeToken(key, entry.key);
        final mapValue = entry.value;
        if (mapValue is! int || mapValue < 0) {
          throw ArgumentError.value(
            value,
            key,
            'Map counts must be non-negative.',
          );
        }
        sanitized[mapKey] = mapValue;
      }
      return Map<String, int>.unmodifiable(sanitized);
    }
    if (value is Iterable) {
      return List<String>.unmodifiable(
        value.map((item) => _sanitizeToken(key, item)),
      );
    }
    throw ArgumentError.value(value, key, 'Unsupported receipt event value.');
  }

  static String _sanitizeToken(String key, Object? value) {
    if (value is! String) {
      throw ArgumentError.value(value, key, 'Expected a safe token.');
    }
    final token = value.trim();
    if (token.isEmpty ||
        token.length > maxStringLength ||
        !_safeTokenPattern.hasMatch(token)) {
      throw ArgumentError.value(value, key, 'Unsafe receipt event token.');
    }
    return token;
  }
}
