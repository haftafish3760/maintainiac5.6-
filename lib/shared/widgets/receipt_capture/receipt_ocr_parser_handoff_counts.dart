part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffCounts on ReceiptOcrParserHandoff {
  Map<String, int> get downstreamReadinessCounts {
    return Map.unmodifiable({
      'downstreamReadiness_$downstreamReadinessStatus': 1,
      'downstreamReadyItemLineCount': parserReadyLineCount,
      'downstreamReviewItemLineCount': reviewItemLineCount,
      'downstreamInventoryPrepLineCount': inventoryPrepLineCount,
      'downstreamMaterialCandidateLineCount': materialCandidateLineCount,
      'downstreamFuelCandidateLineCount': fuelCandidateLineCount,
      'downstreamVehicleSupplyCandidateLineCount':
          vehicleSupplyCandidateLineCount,
      'merchantIndependentStructure_$merchantIndependentStructureStatus': 1,
      'headerRecovery_$headerRecoveryStatus': 1,
      'vendorReview_$vendorReviewStatus': 1,
      'merchantIndependentReadyItemLineCount': parserReadyLineCount,
      'merchantIndependentReviewItemLineCount': reviewItemLineCount,
    });
  }

  Map<String, int> get requiredParserFieldStatusCounts {
    final counts = <String, int>{};

    void addFieldStatus(String field, ReceiptOcrParserLineSignal? line) {
      if (line == null) {
        counts['${field}_missing'] = (counts['${field}_missing'] ?? 0) + 1;
        counts['required_missing_total'] =
            (counts['required_missing_total'] ?? 0) + 1;
        return;
      }
      final status = line.needsReview ? 'needs_review' : 'ready';
      counts['${field}_$status'] = (counts['${field}_$status'] ?? 0) + 1;
      counts['required_${status}_total'] =
          (counts['required_${status}_total'] ?? 0) + 1;
    }

    addFieldStatus('vendor', primaryVendorLine);
    addFieldStatus('date', primaryDateLine);
    addFieldStatus('total', primaryTotalLine);

    final hasSubtotalOrTaxSignal =
        primarySubtotalLine != null || primaryTaxLine != null;
    if (hasSubtotalOrTaxSignal) {
      addFieldStatus('subtotal', primarySubtotalLine);
      addFieldStatus('tax', primaryTaxLine);
    }

    if (itemLines.isEmpty) {
      counts['item_price_missing'] = 1;
      counts['required_missing_total'] =
          (counts['required_missing_total'] ?? 0) + 1;
    } else {
      if (parserReadyLineCount > 0) {
        counts['item_price_ready'] = parserReadyLineCount;
        counts['required_ready_total'] =
            (counts['required_ready_total'] ?? 0) + 1;
      }
      if (reviewItemLineCount > 0) {
        counts['item_price_needs_review'] = reviewItemLineCount;
        counts['required_needs_review_total'] =
            (counts['required_needs_review_total'] ?? 0) + 1;
      }
    }

    counts['receipt_structure_$receiptStructureStatus'] = 1;
    counts['parser_readiness_$parserReadinessStatus'] = 1;
    counts['header_recovery_$headerRecoveryStatus'] = 1;
    counts['vendor_review_$vendorReviewStatus'] = 1;
    return Map.unmodifiable(counts);
  }

  String get requiredParserFieldStatusLabel {
    final counts = requiredParserFieldStatusCounts;
    final ready = counts['required_ready_total'] ?? 0;
    final review = counts['required_needs_review_total'] ?? 0;
    final missing = counts['required_missing_total'] ?? 0;
    return 'required_receipt_fields:ready=$ready;review=$review;missing=$missing;structure=$receiptStructureStatus;parser=$parserReadinessStatus';
  }

  Map<String, int> get counts {
    return Map.unmodifiable({
      'lineCount': lines.length,
      'vendorLineCount': vendorLines.length,
      'dateLineCount': dateLines.length,
      'itemLineCount': itemLines.length,
      'pricedLineCount': pricedLineCount,
      'parserReadyLineCount': parserReadyLineCount,
      'parserReviewSignalCount': parserReviewSignalCount,
      'parserReadinessReadyCount':
          parserReadinessStatus == 'receipt_ready' ||
              parserReadinessStatus == 'inventory_ready'
          ? 1
          : 0,
      'merchantIndependentStructureReadyCount':
          hasMerchantIndependentReceiptStructure ? 1 : 0,
      'recoverableMissingVendorCount': hasRecoverableMissingVendorHeader
          ? 1
          : 0,
      'highConfidenceItemLineCount': highConfidenceItemLineCount,
      'reviewItemLineCount': reviewItemLineCount,
      'quantitySignalItemLineCount': quantitySignalItemLineCount,
      'skuSignalItemLineCount': skuSignalItemLineCount,
      'genericItemLineCount': genericItemLineCount,
      'inventoryPrepLineCount': inventoryPrepLineCount,
      'materialCandidateLineCount': materialCandidateLineCount,
      'fuelCandidateLineCount': fuelCandidateLineCount,
      'vehicleSupplyCandidateLineCount': vehicleSupplyCandidateLineCount,
      'parserReadyFieldCount': parserReadyFieldCount,
      'parserReviewFieldCount': parserReviewFieldCount,
      'parserReadyItemLineIdCount': parserReadyItemLineIds.length,
      'reviewItemLineIdCount': reviewItemLineIds.length,
      'weakHeaderCandidateLineIdCount': weakHeaderCandidateLineIds.length,
      'inventoryPrepLineIdCount': inventoryPrepLineIds.length,
      'materialCandidateLineIdCount': materialCandidateLineIds.length,
      'fuelCandidateLineIdCount': fuelCandidateLineIds.length,
      'vehicleSupplyCandidateLineIdCount': vehicleSupplyCandidateLineIds.length,
      for (final entry in lineRoleCounts.entries)
        '${entry.key}RoleLineCount': entry.value,
      for (final entry in parserBucketCounts.entries) entry.key: entry.value,
      for (final entry in expenseFamilyCounts.entries)
        'expenseFamily_${entry.key}': entry.value,
      for (final entry in parserHintCounts.entries)
        'parserHint_${entry.key}': entry.value,
      for (final entry in parserTaskCounts.entries)
        '${entry.key}LineIdCount': entry.value,
      for (final entry in fieldReadinessCounts.entries) entry.key: entry.value,
      for (final entry in downstreamReadinessCounts.entries)
        entry.key: entry.value,
      for (final entry in requiredParserFieldStatusCounts.entries)
        entry.key: entry.value,
      'merchantIndependentStructure_$merchantIndependentStructureStatus': 1,
      'headerRecovery_$headerRecoveryStatus': 1,
      'vendorReview_$vendorReviewStatus': 1,
      'addressContactMetadataLineCount': addressContactMetadataLineCount,
      'weakHeaderCandidateLineCount': weakHeaderCandidateLineCount,
      'knownMerchantHeaderCandidateLineCount':
          knownMerchantHeaderCandidateLineIds.length,
      'unknownMerchantHeaderCandidateLineCount':
          unknownMerchantHeaderCandidateLineIds.length,
      'timeCandidateLineCount': timeCandidateLineIds.length,
      'mixedClassificationReadyCount': mixedClassificationReady ? 1 : 0,
      'mixedClassification_$mixedClassificationReadinessStatus': 1,
      'itemExpenseFamily_$itemExpenseFamilyStatus': 1,
      'mixedExpenseFamilyCount': hasMixedExpenseFamilies ? 1 : 0,
      'presentExpenseFamilyCount': presentExpenseFamilies.length,
      'summaryLineCount': summaryLines.length,
      'completeSummaryAmountCount': hasCompleteSummaryAmounts ? 1 : 0,
      'summaryMathMatchedCount': summaryMathReconciled ? 1 : 0,
      'expectedLineSequenceCount': hasExpectedLineSequence ? 1 : 0,
      'lineSequenceReviewCount': needsLineSequenceReview ? 1 : 0,
      'sourceSectionCount': sourceSectionCount,
      'sourceSectionContinuityReviewCount': needsSourceSectionContinuityReview
          ? 1
          : 0,
      'sourceSectionContinuity_$sourceSectionContinuityStatus': 1,
      'tenderLineCount': tenderLines.length,
      'metadataLineCount': metadataLines.length,
    });
  }
}
