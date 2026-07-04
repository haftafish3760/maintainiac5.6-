part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffTasks on ReceiptOcrParserHandoff {
  List<String> get orderedParserReadyLineIds {
    return List<String>.unmodifiable(
      lines
          .where((line) => line.isParserReadyField)
          .map((line) => line.stableLineId),
    );
  }

  List<String> get orderedParserReviewLineIds {
    return List<String>.unmodifiable(
      lines
          .where((line) => line.isParserReviewField)
          .map((line) => line.stableLineId),
    );
  }

  Map<String, List<String>> get parserTaskLineIds {
    List<String> idsFor(Iterable<ReceiptOcrParserLineSignal> source) {
      return List<String>.unmodifiable(source.map((line) => line.stableLineId));
    }

    final result = <String, List<String>>{
      'vendor_candidate': idsFor(vendorLines),
      'date_candidate': idsFor(dateLines),
      'time_candidate': timeCandidateLineIds,
      'subtotal_candidate': idsFor(
        summaryLines.where(
          (line) => line.kind == ReceiptOcrParserLineKind.subtotalCandidate,
        ),
      ),
      'tax_candidate': idsFor(
        summaryLines.where(
          (line) => line.kind == ReceiptOcrParserLineKind.taxCandidate,
        ),
      ),
      'total_candidate': idsFor(
        summaryLines.where(
          (line) => line.kind == ReceiptOcrParserLineKind.totalCandidate,
        ),
      ),
      'item_price_ready': parserReadyItemLineIds,
      'item_price_needs_review': reviewItemLineIds,
      'inventory_material_candidate': inventoryPrepLineIds,
      'material_line_candidate': materialCandidateLineIds,
      'fuel_line_candidate': fuelCandidateLineIds,
      'fuel_line_ready': fuelReadyLineIds,
      'fuel_quantity_signal': fuelQuantitySignalLineIds,
      'fuel_unit_price_signal': fuelUnitPriceSignalLineIds,
      'fuel_detail_ready': fuelDetailReadyLineIds,
      'vehicle_supply_line_candidate': vehicleSupplyCandidateLineIds,
      for (final entry in itemLineIdsByExpenseFamily.entries)
        'expense_family_${entry.key}_item': entry.value,
      if (hasMixedExpenseFamilies)
        'expense_family_mixed_receipt': idsFor(itemLines),
      if (!hasMixedExpenseFamilies && itemLines.isNotEmpty)
        'expense_family_single_receipt': idsFor(itemLines),
      'known_merchant_header_candidate': knownMerchantHeaderCandidateLineIds,
      'unknown_merchant_header_candidate':
          unknownMerchantHeaderCandidateLineIds,
      'separatorless_money_inferred': separatorlessMoneyInferenceLineIds,
      'split_cents_money_inferred': splitCentsMoneyInferenceLineIds,
      if (missingVendorRecoveryEvidenceLineIds.isNotEmpty)
        'missing_vendor_recoverable': missingVendorRecoveryEvidenceLineIds,
      merchantIndependentStructureStatus: hasMerchantIndependentReceiptStructure
          ? orderedParserReadyLineIds
          : orderedParserReviewLineIds,
      'parser_ready_field': orderedParserReadyLineIds,
      'parser_review_field': orderedParserReviewLineIds,
    };
    result.removeWhere((_, ids) => ids.isEmpty);
    return Map<String, List<String>>.unmodifiable(result);
  }

  Map<String, int> get parserTaskCounts {
    return Map<String, int>.unmodifiable({
      for (final entry in parserTaskLineIds.entries)
        entry.key: entry.value.length,
      for (final entry in parserMissingFieldCounts.entries)
        entry.key: entry.value,
      for (final entry in parserReviewTaskCounts.entries)
        entry.key: entry.value,
      if (hasTotalOnlySummary && totalOnlyLineMathReconciled)
        'receipt_total_only_ready': 1,
      if (hasTotalOnlySummary && totalOnlyLineMathReconciled)
        'total_only_line_math_reconciled': 1,
      if (totalOnlyLineMathNeedsReview) 'total_only_line_math_needs_review': 1,
    });
  }

  Map<String, int> get parserMissingFieldCounts {
    if (lines.isEmpty) return const {};
    final hasSubtotalOrTaxSignal =
        primarySubtotalLine != null || primaryTaxLine != null;
    final counts = <String, int>{
      if (vendorLines.isEmpty) 'vendor_missing': 1,
      if (dateLines.isEmpty) 'date_missing': 1,
      if (itemLines.isEmpty) 'item_price_missing': 1,
      if (summaryLines.isEmpty) 'summary_missing': 1,
      if (primarySubtotalLine == null && hasSubtotalOrTaxSignal)
        'subtotal_missing': 1,
      if (primaryTaxLine == null && hasSubtotalOrTaxSignal) 'tax_missing': 1,
      if (primaryTotalLine == null) 'total_missing': 1,
    };
    return Map.unmodifiable(counts);
  }

  Map<String, int> get parserReviewTaskCounts {
    if (lines.isEmpty) return const {};
    final counts = <String, int>{
      if (hasDuplicateLineIds)
        'duplicate_line_ids_need_review': duplicateLineIds.length,
      if (needsLineSequenceReview) 'line_sequence_needs_review': 1,
      if (hasCompleteSummaryAmounts && !summaryMathReconciled)
        'summary_math_needs_review': 1,
      if (reviewItemLineCount > 0)
        'item_price_review_required': reviewItemLineCount,
      if (parserReadyLineCount == 0 && itemLines.isNotEmpty)
        'item_price_ready_missing': 1,
      if (totalOnlyLineMathNeedsReview)
        'receipt_total_only_line_math_review': 1,
      if (hasRecoverableMissingVendorHeader) 'missing_vendor_recoverable': 1,
      if (vendorReviewStatus != 'vendor_ready' &&
          (vendorReviewStatus != 'vendor_candidate_needs_review' ||
              parserReadyLineCount > 0))
        vendorReviewStatus: 1,
    };
    return Map.unmodifiable(counts);
  }

  Map<String, int> get parserBucketCounts {
    final counts = <String, int>{};
    for (final line in lines) {
      counts[line.parserBucketId] = (counts[line.parserBucketId] ?? 0) + 1;
      if (line.isLikelySummary) {
        final bucket = line.needsReview
            ? 'summary_needs_review'
            : 'summary_ready';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      } else if (line.isLikelyMetadata) {
        final bucket = line.needsReview
            ? 'metadata_needs_review'
            : 'metadata_ready';
        counts[bucket] = (counts[bucket] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get expenseFamilyCounts {
    final counts = <String, int>{};
    for (final line in itemLines) {
      final family = _receiptExpenseFamilyToken(line.expenseFamily);
      counts[family] = (counts[family] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get parserHintCounts {
    final counts = <String, int>{};
    for (final line in itemLines) {
      counts[line.parserHint] = (counts[line.parserHint] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get fieldReadinessCounts {
    final counts = <String, int>{
      'vendor_ready':
          primaryVendorLine == null || primaryVendorLine!.needsReview ? 0 : 1,
      'vendor_needs_review':
          primaryVendorLine != null && primaryVendorLine!.needsReview ? 1 : 0,
      'date_ready': primaryDateLine == null || primaryDateLine!.needsReview
          ? 0
          : 1,
      'date_needs_review':
          primaryDateLine != null && primaryDateLine!.needsReview ? 1 : 0,
      'subtotal_ready':
          primarySubtotalLine == null || primarySubtotalLine!.needsReview
          ? 0
          : 1,
      'subtotal_needs_review':
          primarySubtotalLine != null && primarySubtotalLine!.needsReview
          ? 1
          : 0,
      'tax_ready': primaryTaxLine == null || primaryTaxLine!.needsReview
          ? 0
          : 1,
      'tax_needs_review': primaryTaxLine != null && primaryTaxLine!.needsReview
          ? 1
          : 0,
      'total_ready': primaryTotalLine == null || primaryTotalLine!.needsReview
          ? 0
          : 1,
      'total_needs_review':
          primaryTotalLine != null && primaryTotalLine!.needsReview ? 1 : 0,
      'item_price_ready': parserReadyLineCount,
      'item_price_needs_review': reviewItemLineCount,
      'inventory_material_candidate': inventoryPrepLineCount,
      'material_line_candidate': materialCandidateLineCount,
      'fuel_line_candidate': fuelCandidateLineCount,
      'vehicle_supply_line_candidate': vehicleSupplyCandidateLineCount,
      'field_ready_total': parserReadyFieldCount,
      'field_review_total': parserReviewFieldCount,
      for (final entry in parserMissingFieldCounts.entries)
        entry.key: entry.value,
      for (final entry in parserReviewTaskCounts.entries)
        entry.key: entry.value,
    };
    counts.removeWhere((_, value) => value == 0);
    return Map.unmodifiable(counts);
  }
}
