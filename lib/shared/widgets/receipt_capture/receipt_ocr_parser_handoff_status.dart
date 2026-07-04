part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffStatus on ReceiptOcrParserHandoff {
  String get parserReadinessStatus {
    if (lines.isEmpty) return 'no_text';
    if (hasDuplicateLineIds) return 'needs_review';
    if (vendorLines.isEmpty) {
      return hasRecoverableMissingVendorHeader
          ? 'needs_vendor_review'
          : 'missing_vendor';
    }
    if (primaryTotalAmount == null) return 'missing_total';
    if (pricedLineCount == 0) return 'no_priced_lines';
    if (itemLines.isEmpty) return 'no_item_lines';
    if (parserReadyLineCount == 0) return 'no_parser_ready_items';
    if (needsLineSequenceReview || reviewItemLineCount > 0) {
      return 'needs_review';
    }
    if (quantitySignalItemLineCount > 0 || skuSignalItemLineCount > 0) {
      return 'inventory_ready';
    }
    return 'receipt_ready';
  }

  String get downstreamReadinessStatus {
    if (lines.isEmpty) return 'no_text';
    if (hasDuplicateLineIds) return 'expense_lines_need_review';
    if (vendorLines.isEmpty && hasRecoverableMissingVendorHeader) {
      return 'receipt_header_needs_review';
    }
    if (vendorLines.isEmpty || primaryTotalAmount == null) {
      return 'proof_needs_review';
    }
    if (parserReadyLineCount == 0) return 'proof_total_only';
    if (totalOnlyLineMathNeedsReview) return 'expense_lines_need_review';
    if (inventoryPrepLineCount > 0) return 'inventory_material_ready';
    if (materialCandidateLineCount > 0) return 'material_expense_ready';
    if (fuelCandidateLineCount > 0 || vehicleSupplyCandidateLineCount > 0) {
      return 'vehicle_cost_ready';
    }
    if (reviewItemLineCount > 0 || needsLineSequenceReview) {
      return 'expense_lines_need_review';
    }
    return 'expense_lines_ready';
  }

  String get downstreamReadinessLabel {
    return switch (downstreamReadinessStatus) {
      'no_text' => 'No OCR text ready for downstream review.',
      'proof_needs_review' =>
        'Receipt proof needs review before expenses or inventory use it.',
      'receipt_header_needs_review' =>
        'Receipt lines and total are usable, but the store name needs review.',
      'proof_total_only' =>
        'Receipt total is usable, but line items need manual review.',
      'inventory_material_ready' =>
        'Material-style item lines are ready for inventory review.',
      'material_expense_ready' =>
        'Material expense lines are ready for expense review.',
      'vehicle_cost_ready' =>
        'Vehicle cost lines are ready for expense review.',
      'expense_lines_need_review' =>
        'Expense lines were found, but some need review before saving.',
      _ => 'Expense lines are ready for review.',
    };
  }

  bool get hasSummaryEvidence => summaryLines.isNotEmpty;
  bool get hasCompleteSummaryAmounts =>
      primarySubtotalAmount != null &&
      primaryTaxAmount != null &&
      primaryTotalAmount != null;
  bool get summaryMathReconciled {
    final subtotal = primarySubtotalAmount;
    final tax = primaryTaxAmount;
    final total = primaryTotalAmount;
    if (subtotal == null || tax == null || total == null) return false;
    return (_roundReceiptOcrMoney(subtotal + tax) - total).abs() <= .02;
  }

  String get summaryMathStatus {
    if (!hasCompleteSummaryAmounts) return 'incomplete';
    return summaryMathReconciled ? 'matched' : 'mismatch';
  }

  String get lineSequenceStatus {
    if (lines.isEmpty) return 'empty';
    final firstItem = firstItemLineIndex;
    if (firstItem == null) return 'no_items';
    final firstHeader = firstHeaderLineIndex;
    if (firstHeader == null || firstHeader > firstItem) return 'missing_header';
    final firstSummary = firstSummaryLineIndex;
    if (firstSummary == null) return 'missing_summary';
    final lastItem = lastItemLineIndex ?? firstItem;
    if (firstSummary <= lastItem) return 'summary_before_items';
    final firstTender = firstPaymentTenderLineIndex;
    if (firstTender != null && firstTender <= firstSummary) {
      return 'tender_before_summary';
    }
    return 'expected_order';
  }

  bool get hasExpectedLineSequence => lineSequenceStatus == 'expected_order';
  bool get needsLineSequenceReview {
    return lineSequenceStatus != 'empty' && !hasExpectedLineSequence;
  }

  int get parserReviewSignalCount {
    var count = reviewItemLineCount;
    if (hasDuplicateLineIds) count += 1;
    if (needsLineSequenceReview) count += 1;
    if (hasCompleteSummaryAmounts && !summaryMathReconciled) count += 1;
    if (vendorLines.isEmpty && lines.isNotEmpty) count += 1;
    if (itemLines.isEmpty && lines.isNotEmpty) count += 1;
    if (primaryTotalAmount == null && lines.isNotEmpty) count += 1;
    return count;
  }

  String get receiptStructureStatus {
    if (lines.isEmpty) return 'no_text';
    if (hasDuplicateLineIds) return 'line_identity_review';
    if (vendorLines.isEmpty && hasRecoverableMissingVendorHeader) {
      return 'recoverable_missing_vendor';
    }
    if (vendorLines.isEmpty) return 'missing_vendor';
    if (itemLines.isEmpty) return 'no_items';
    if (primaryTotalAmount == null) return 'missing_total';
    if (needsLineSequenceReview) return 'line_sequence_review';
    if (hasCompleteSummaryAmounts && !summaryMathReconciled) {
      return 'summary_math_review';
    }
    if (reviewItemLineCount > 0) return 'line_item_review';
    return 'ready_for_parser';
  }

  bool get hasTenderOrMetadataNoise =>
      tenderLines.isNotEmpty || metadataLines.isNotEmpty;
}
