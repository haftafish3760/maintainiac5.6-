part of 'expense_receipt_parser.dart';

ExpenseReceiptParseResult parseExpenseReceiptOcrResult(
  ReceiptOcrResult ocr, {
  DateTime? fallbackDate,
  ReceiptDeviceCapability? capability,
  ReceiptParserLearningMemory? materialCatalogMemory,
  ReceiptParserDepth? parserDepth,
  int? maxCatalogCandidates,
}) {
  final handoff = ocr.parserHandoff;
  final effectiveDepth =
      parserDepth ?? capability?.parserDepth ?? ReceiptParserDepth.lineItems;
  final effectiveMaxCatalogCandidates =
      maxCatalogCandidates ??
      capability?.cloudAssistPlan.localCatalogMatchLimit ??
      80;
  final ocrDiagnostics = ocr.diagnostics;
  final parsed = parseExpenseReceiptText(
    ocr.appFillText,
    fallbackDate: fallbackDate,
    materialCatalogMemory: materialCatalogMemory,
    parserDepth: effectiveDepth,
    maxCatalogCandidates: effectiveMaxCatalogCandidates,
  );
  final parsedWithOcrLineEvidence = _withOcrParserLineEvidence(parsed, handoff);
  final enrichedParserItemFamilyCounts = _parserItemExpenseFamilyCountsFor(
    parsedWithOcrLineEvidence.lines,
  );
  final warnings = <String>[
    ...ocr.structuredParserHandoffWarnings,
    ...parsedWithOcrLineEvidence.warnings,
  ];
  final leanLocalStatus = _leanLocalOcrReadinessStatusForDepth(
    handoff,
    effectiveDepth,
  );
  final totalsCoverageEvidence =
      ocrDiagnostics.receiptTotalsCoverageEvidenceDiagnostics;
  final duplicateLinePairs = _adjacentDuplicateParsedLinePairs(
    parsedWithOcrLineEvidence.lines,
  );
  return parsedWithOcrLineEvidence.copyWith(
    warnings: List.unmodifiable(warnings),
    diagnostics: parsedWithOcrLineEvidence.diagnostics.copyWith(
      parserDuplicateOverlapSourceLabels:
          _adjacentDuplicateParsedLineSourceLabels(duplicateLinePairs),
      parserDuplicateOverlapWindowLabels:
          _adjacentDuplicateParsedLineWindowLabels(duplicateLinePairs),
      parserDuplicateOverlapConfidenceLabels:
          _adjacentDuplicateParsedLineConfidenceLabels(duplicateLinePairs),
      parserItemExpenseFamilyStatus: _parserItemExpenseFamilyStatusFor(
        enrichedParserItemFamilyCounts,
      ),
      parserItemExpenseFamilySummaryLabel:
          _parserItemExpenseFamilySummaryLabelFor(
            enrichedParserItemFamilyCounts,
          ),
      parserItemExpenseFamilyCounts: enrichedParserItemFamilyCounts,
      ocrParserLineCount: handoff.lines.length,
      ocrItemCandidateLineCount: handoff.itemLines.length,
      ocrPricedLineCount: handoff.pricedLineCount,
      ocrParserReadyLineCount: handoff.parserReadyLineCount,
      ocrParserReviewSignalCount: handoff.parserReviewSignalCount,
      ocrParserReadinessStatus: handoff.parserReadinessStatus,
      ocrDownstreamReadinessStatus: handoff.downstreamReadinessStatus,
      ocrDownstreamReadinessCounts: handoff.downstreamReadinessCounts,
      ocrLeanLocalReadinessStatus: leanLocalStatus,
      ocrLeanLocalReadinessCounts: _leanLocalOcrReadinessCountsForDepth(
        handoff,
        leanLocalStatus,
      ),
      ocrLeanLocalReadinessLabel: _leanLocalOcrReadinessLabelForDepth(
        handoff,
        effectiveDepth,
        leanLocalStatus,
      ),
      ocrHighConfidenceItemLineCount: handoff.highConfidenceItemLineCount,
      ocrReviewItemLineCount: handoff.reviewItemLineCount,
      ocrQuantitySignalItemLineCount: handoff.quantitySignalItemLineCount,
      ocrSkuSignalItemLineCount: handoff.skuSignalItemLineCount,
      ocrGenericItemLineCount: handoff.genericItemLineCount,
      ocrInventoryPrepLineIdCount: handoff.inventoryPrepLineIds.length,
      ocrParserReadyFieldCount: handoff.parserReadyFieldCount,
      ocrParserReviewFieldCount: handoff.parserReviewFieldCount,
      ocrSummaryMathStatus: handoff.summaryMathStatus,
      ocrSummaryMathReconciled: handoff.summaryMathReconciled,
      ocrLineSequenceStatus: handoff.lineSequenceStatus,
      ocrSourceSectionContinuityStatus: handoff.sourceSectionContinuityStatus,
      ocrSourceSectionCount: handoff.sourceSectionCount,
      ocrSourceSectionContinuityReviewNeeded:
          handoff.needsSourceSectionContinuityReview,
      ocrReceiptStructureStatus: handoff.receiptStructureStatus,
      ocrSubtotalCandidateLineCount: ocr.subtotalCandidateLines.length,
      ocrTaxCandidateLineCount: ocr.taxCandidateLines.length,
      ocrTotalCandidateLineCount: ocr.totalCandidateLines.length,
      ocrTenderCandidateLineCount: handoff.tenderLines.length,
      ocrMetadataCandidateLineCount: handoff.metadataLines.length,
      ocrParserLineRoleCounts: handoff.lineRoleCounts,
      ocrDominantParserLineRole: handoff.dominantLineRole,
      ocrStableLineIdCount: handoff.stableLineIds.length,
      ocrParserReadyItemLineIdCount: handoff.parserReadyItemLineIds.length,
      ocrReviewItemLineIdCount: handoff.reviewItemLineIds.length,
      ocrLineIdsByRole: handoff.lineIdsByRole,
      ocrRoleByLineId: handoff.roleByLineId,
      ocrParserBucketByLineId: handoff.parserBucketByLineId,
      ocrOrderedParserReadyLineIds: handoff.orderedParserReadyLineIds,
      ocrOrderedParserReviewLineIds: handoff.orderedParserReviewLineIds,
      ocrParserBucketCounts: handoff.parserBucketCounts,
      ocrParserTaskCounts: ocrDiagnostics.parserTaskCounts,
      ocrItemExpenseFamilyStatus: ocrDiagnostics.itemExpenseFamilyStatus,
      ocrItemExpenseFamilySummaryLabel:
          ocrDiagnostics.itemExpenseFamilySummaryLabel,
      ocrItemExpenseFamilyCounts: ocrDiagnostics.itemExpenseFamilyCounts,
      ocrSourceHandoffStatus: ocrDiagnostics.ocrSourceHandoffStatus,
      ocrSourceHandoffSignalCounts: ocrDiagnostics.ocrSourceHandoffSignalCounts,
      ocrSourceReviewDepthSignalCounts:
          ocrDiagnostics.ocrSourceReviewDepthSignalCounts,
      ocrSourceReviewDepthStatus: ocrDiagnostics.ocrSourceReviewDepthStatus,
      ocrSourceStitchSignalCounts: ocrDiagnostics.ocrSourceStitchSignalCounts,
      ocrSourceScannerDecisionCounts:
          ocrDiagnostics.ocrSourceScannerDecisionCounts,
      ocrSourceCaptureSourceSignalCounts:
          ocrDiagnostics.ocrSourceCaptureSourceSignalCounts,
      ocrSourceCoverageSignalCounts:
          ocrDiagnostics.ocrSourceCoverageSignalCounts,
      ocrSourceContinuationSignalCounts:
          ocrDiagnostics.ocrSourceContinuationSignalCounts,
      ocrSourceSectionOrderSignalCounts:
          ocrDiagnostics.ocrSourceSectionOrderSignalCounts,
      ocrSourcePhotoQualityRiskCounts:
          ocrDiagnostics.ocrSourcePhotoQualityRiskCounts,
      ocrSourceQualityReviewStatus: _stringMetadataValue(
        ocrDiagnostics.ocrSourceHandoffContract['sourceQualityReviewStatus'],
      ),
      ocrSourceQualityReviewAction: _stringMetadataValue(
        ocrDiagnostics.ocrSourceHandoffContract['sourceQualityReviewAction'],
      ),
      ocrSourceSectionOrderReviewStatus: _stringMetadataValue(
        ocrDiagnostics.ocrSourceHandoffContract['sectionOrderReviewStatus'],
      ),
      ocrSourceSectionOrderFailedPairStatus: _stringMetadataValue(
        ocrDiagnostics.ocrSourceHandoffContract['sectionOrderFailedPairStatus'],
      ),
      missingBottomTotalsEvidenceCode: _stringMetadataValue(
        totalsCoverageEvidence['missingBottomTotalsEvidenceCode'],
      ),
      missingBottomTotalsEvidenceLabel: _stringMetadataValue(
        totalsCoverageEvidence['missingBottomTotalsEvidenceLabel'],
      ),
      missingBottomTotalsEvidenceFamilyCount: _intMetadataValue(
        totalsCoverageEvidence['missingBottomTotalsEvidenceFamilyCount'],
      ),
      clientProofRedactionStatus: ocrDiagnostics.clientProofRedactionStatus,
      clientProofVisibilityCounts: ocrDiagnostics.clientProofVisibilityCounts,
      ocrFieldReadinessCounts: handoff.fieldReadinessCounts,
      ocrRequiredFieldStatusCounts: handoff.requiredParserFieldStatusCounts,
      ocrRequiredFieldStatusLabel: handoff.requiredParserFieldStatusLabel,
    ),
  );
}

ExpenseReceiptParseResult _withOcrParserLineEvidence(
  ExpenseReceiptParseResult parsed,
  ReceiptOcrParserHandoff handoff,
) {
  if (parsed.lines.isEmpty || handoff.lineDrafts.isEmpty) return parsed;
  final draftsByLineNumber = _ocrLineDraftsByLineNumber(handoff.lineDrafts);
  var changed = false;
  final enrichedLines = <ExpenseReceiptLineRecord>[];
  for (final line in parsed.lines) {
    final draft = _ocrLineDraftForParsedLine(
      line: line,
      handoff: handoff,
      draftsByLineNumber: draftsByLineNumber,
    );
    if (draft == null) {
      enrichedLines.add(line);
      continue;
    }
    final sourceLocation = draft.sourceLocation;
    enrichedLines.add(
      _copyReceiptLineWithOcrParserEvidence(
        line,
        ocrSourceLineId: draft.stableLineId,
        ocrSourceLineNumber: draft.safeLineNumber,
        ocrSourceSectionNumber: sourceLocation?.safeSectionNumber,
        ocrSourceSectionLineNumber: sourceLocation?.safeSectionLineNumber,
        parserConfidence: line.parserConfidence ?? draft.confidence,
        parserReviewReason: _mergeParserReviewReasons(
          line.parserReviewReason,
          draft.reviewReason,
        ),
        parserNeedsReview: line.parserNeedsReview || draft.needsReview,
        parserExpenseFamily: _preferSpecificParserExpenseFamily(
          current: line.parserExpenseFamily,
          ocrCandidate: draft.expenseFamilyToken,
        ),
        parserHint: line.parserHint ?? draft.parserHint,
      ),
    );
    changed = true;
  }
  if (!changed) return parsed;
  return parsed.copyWith(lines: List.unmodifiable(enrichedLines));
}

Map<int, ReceiptOcrParserLineDraft> _ocrLineDraftsByLineNumber(
  List<ReceiptOcrParserLineDraft> drafts,
) {
  final mapped = <int, ReceiptOcrParserLineDraft>{};
  for (final draft in drafts) {
    mapped.putIfAbsent(draft.safeLineNumber, () => draft);
  }
  return Map<int, ReceiptOcrParserLineDraft>.unmodifiable(mapped);
}

ReceiptOcrParserLineDraft? _ocrLineDraftForParsedLine({
  required ExpenseReceiptLineRecord line,
  required ReceiptOcrParserHandoff handoff,
  required Map<int, ReceiptOcrParserLineDraft> draftsByLineNumber,
}) {
  final sourceLineId = (line.ocrSourceLineId ?? '').trim();
  if (sourceLineId.isNotEmpty) {
    final draft = handoff.lineDraftsById[sourceLineId];
    if (draft != null) return draft;
  }
  final sourceLineNumber = line.ocrSourceLineNumber;
  return sourceLineNumber == null ? null : draftsByLineNumber[sourceLineNumber];
}

String? _preferSpecificParserExpenseFamily({
  required String? current,
  required String? ocrCandidate,
}) {
  final currentToken = (current ?? '').trim();
  final ocrToken = (ocrCandidate ?? '').trim();
  if (ocrToken.isEmpty) return currentToken.isEmpty ? null : currentToken;
  if (currentToken.isEmpty) return ocrToken;
  final currentSafe = _safeParserToken(currentToken);
  if (currentSafe == 'general_expense' ||
      currentSafe == 'uncategorized' ||
      currentSafe == 'unknown') {
    return ocrToken;
  }
  return currentToken;
}

String? _mergeParserReviewReasons(String? existing, String next) {
  final cleanExisting = existing?.trim() ?? '';
  final cleanNext = next.trim();
  if (cleanNext.isEmpty) return cleanExisting.isEmpty ? null : cleanExisting;
  if (cleanExisting.isEmpty) return cleanNext;
  if (cleanExisting.contains(cleanNext)) return cleanExisting;
  return '$cleanExisting OCR source: $cleanNext';
}

ExpenseReceiptLineRecord _copyReceiptLineWithOcrParserEvidence(
  ExpenseReceiptLineRecord line, {
  required String ocrSourceLineId,
  required int ocrSourceLineNumber,
  required int? ocrSourceSectionNumber,
  required int? ocrSourceSectionLineNumber,
  required double? parserConfidence,
  required String? parserReviewReason,
  required bool parserNeedsReview,
  required String? parserExpenseFamily,
  required String? parserHint,
}) {
  return ExpenseReceiptLineRecord(
    id: line.id,
    description: line.description,
    category: line.category,
    use: line.use,
    quantity: line.quantity,
    unitsPerPackage: line.unitsPerPackage,
    unit: line.unit,
    subtotal: line.subtotal,
    businessPercent: line.businessPercent,
    splitAllocationMethod: line.splitAllocationMethod,
    businessSplitValue: line.businessSplitValue,
    splitConfirmed: line.splitConfirmed,
    odometerReading: line.odometerReading,
    fuelType: line.fuelType,
    fillType: line.fillType,
    unitPrice: line.unitPrice,
    rawReceiptText: line.rawReceiptText,
    catalogItemId: line.catalogItemId,
    catalogItemName: line.catalogItemName,
    catalogItemPath: line.catalogItemPath,
    catalogMatchConfidence: line.catalogMatchConfidence,
    catalogMatchedTerms: line.catalogMatchedTerms,
    parserConfidence: parserConfidence,
    parserReviewLabel: line.parserReviewLabel,
    parserReviewReason: parserReviewReason,
    parserNeedsReview: parserNeedsReview,
    ocrSourceLineId: ocrSourceLineId,
    ocrSourceLineNumber: ocrSourceLineNumber,
    ocrSourceSectionNumber: ocrSourceSectionNumber,
    ocrSourceSectionLineNumber: ocrSourceSectionLineNumber,
    parserExpenseFamily: parserExpenseFamily,
    parserHint: parserHint,
  );
}

String _stringMetadataValue(Object? value) => (value ?? '').toString().trim();

int _intMetadataValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString().trim()) ?? 0;
}

String _leanLocalOcrReadinessStatusForDepth(
  ReceiptOcrParserHandoff handoff,
  ReceiptParserDepth depth,
) {
  final evidenceStatus = handoff.leanLocalOcrReadinessStatus;
  if (depth == ReceiptParserDepth.proofTotalsOnly &&
      evidenceStatus == 'line_items_ready') {
    return 'proof_totals_ready_lines_deferred';
  }
  return evidenceStatus;
}

Map<String, int> _leanLocalOcrReadinessCountsForDepth(
  ReceiptOcrParserHandoff handoff,
  String status,
) {
  final counts = Map<String, int>.of(handoff.leanLocalOcrReadinessCounts);
  if (status != handoff.leanLocalOcrReadinessStatus) {
    counts.remove(handoff.leanLocalOcrReadinessStatus);
  }
  counts[status] = (counts[status] ?? 0) + 1;
  if (status == 'proof_totals_ready_lines_deferred' &&
      handoff.parserReadyLineCount > 0) {
    counts['parser_ready_lines_deferred_by_device'] =
        handoff.parserReadyLineCount;
  }
  return Map.unmodifiable(counts);
}

String _leanLocalOcrReadinessLabelForDepth(
  ReceiptOcrParserHandoff handoff,
  ReceiptParserDepth depth,
  String status,
) {
  if (depth == ReceiptParserDepth.proofTotalsOnly &&
      status == 'proof_totals_ready_lines_deferred' &&
      handoff.parserReadyLineCount > 0) {
    return 'Lean local OCR found line items, but this device is using totals-only receipt help. Review or enter detailed lines manually.';
  }
  return handoff.leanLocalOcrReadinessLabel;
}
