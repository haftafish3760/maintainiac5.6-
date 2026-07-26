part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffReadiness on ReceiptOcrParserHandoff {
  bool get hasMerchantIndependentReceiptStructure =>
      parserReadyLineCount > 0 && primaryTotalAmount != null;

  bool get hasRecoverableMissingVendorHeader {
    return vendorLines.isEmpty &&
        dateLines.isNotEmpty &&
        primaryTotalAmount != null &&
        parserReadyLineCount > 0 &&
        !hasDuplicateLineIds &&
        !needsLineSequenceReview &&
        !needsSourceSectionContinuityReview;
  }

  String get headerRecoveryStatus {
    if (lines.isEmpty) return 'no_text';
    if (vendorLines.isNotEmpty) return 'vendor_ready';
    if (hasRecoverableMissingVendorHeader) {
      return 'missing_vendor_recoverable';
    }
    return 'missing_vendor_needs_review';
  }

  String get headerRecoveryLabel {
    return switch (headerRecoveryStatus) {
      'vendor_ready' => 'Receipt store header is ready.',
      'missing_vendor_recoverable' =>
        'Receipt store header needs review, but date, items, and total are usable.',
      'missing_vendor_needs_review' =>
        'Receipt store header needs review before trusting app-filled fields.',
      'no_text' => 'No receipt text is ready for store-header review.',
      _ => 'Receipt store-header status needs review.',
    };
  }

  String get vendorReviewStatus {
    if (lines.isEmpty) return 'no_text';
    if (vendorLines.isNotEmpty) {
      return primaryVendorLine?.needsReview == true
          ? 'vendor_candidate_needs_review'
          : 'vendor_ready';
    }
    if (hasRecoverableMissingVendorHeader) {
      if (weakHeaderCandidateLineCount > 0) {
        return 'vendor_missing_recoverable_weak_header_candidate';
      }
      return addressContactMetadataLineCount > 0
          ? 'vendor_missing_recoverable_address_contact_suppressed'
          : 'vendor_missing_recoverable_no_header_text';
    }
    if (needsLineSequenceReview) {
      return 'vendor_missing_unrecoverable_line_order';
    }
    if (primaryTotalAmount == null) {
      return 'vendor_missing_unrecoverable_no_total';
    }
    if (parserReadyLineCount == 0) {
      return 'vendor_missing_unrecoverable_no_safe_items';
    }
    if (hasDuplicateLineIds) {
      return 'vendor_missing_unrecoverable_line_identity';
    }
    return 'vendor_missing_needs_manual_entry';
  }

  String get vendorReviewLabel {
    return switch (vendorReviewStatus) {
      'vendor_ready' => 'Receipt store name is ready.',
      'vendor_candidate_needs_review' =>
        'Receipt store name was found, but needs review.',
      'vendor_missing_recoverable_address_contact_suppressed' =>
        'Store name needs review; address or phone rows were kept as metadata.',
      'vendor_missing_recoverable_weak_header_candidate' =>
        'Store name needs review; Receipt Assist found weak header text near the top.',
      'vendor_missing_recoverable_no_header_text' =>
        'Store name needs review; date, line items, and total can still continue.',
      'vendor_missing_unrecoverable_line_order' =>
        'Store name needs review and receipt line order is not safe enough yet.',
      'vendor_missing_unrecoverable_no_total' =>
        'Store name needs review and the receipt total is missing.',
      'vendor_missing_unrecoverable_no_safe_items' =>
        'Store name needs review and no safe item prices were found.',
      'vendor_missing_unrecoverable_line_identity' =>
        'Store name needs review and receipt line numbers need review.',
      'no_text' => 'No receipt text is ready for store-name review.',
      _ => 'Receipt store name needs review.',
    };
  }

  Map<String, Object?> get vendorReviewDiagnostics {
    return Map.unmodifiable({
      'status': vendorReviewStatus,
      'label': vendorReviewLabel,
      'trustedVendorReady':
          vendorLines.isNotEmpty && primaryVendorLine?.needsReview != true,
      'recoverable': hasRecoverableMissingVendorHeader,
      'vendorLineCount': vendorLines.length,
      'addressContactMetadataLineCount': addressContactMetadataLineCount,
      'addressContactMetadataLineIds': addressContactMetadataLineIds,
      'weakHeaderCandidateLineCount': weakHeaderCandidateLineCount,
      'weakHeaderCandidateLineIds': weakHeaderCandidateLineIds,
      'knownMerchantHeaderCandidateLineCount':
          knownMerchantHeaderCandidateLineIds.length,
      'knownMerchantHeaderCandidateLineIds':
          knownMerchantHeaderCandidateLineIds,
      'unknownMerchantHeaderCandidateLineCount':
          unknownMerchantHeaderCandidateLineIds.length,
      'unknownMerchantHeaderCandidateLineIds':
          unknownMerchantHeaderCandidateLineIds,
      'dateLineCount': dateLines.length,
      'readyItemLineCount': parserReadyLineCount,
      'totalPresent': primaryTotalAmount != null,
      'lineSequenceStatus': lineSequenceStatus,
      'lineIdentityStatus': lineIdentityStatus,
      'sourceSectionContinuityStatus': sourceSectionContinuityStatus,
    });
  }

  List<String> get missingVendorRecoveryEvidenceLineIds {
    if (!hasRecoverableMissingVendorHeader) return const [];
    final ids = <String>[
      if (primaryDateLine != null) primaryDateLine!.stableLineId,
      ...parserReadyItemLineIds,
      if (primaryTotalLine != null) primaryTotalLine!.stableLineId,
    ];
    return List<String>.unmodifiable(ids.toSet());
  }

  Map<String, Object?> get headerRecoveryDiagnostics {
    return Map.unmodifiable({
      'status': headerRecoveryStatus,
      'recoverable': hasRecoverableMissingVendorHeader,
      'label': headerRecoveryLabel,
      'vendorLineCount': vendorLines.length,
      'dateLineCount': dateLines.length,
      'readyItemLineCount': parserReadyLineCount,
      'totalPresent': primaryTotalAmount != null,
      'lineSequenceStatus': lineSequenceStatus,
      'sourceSectionContinuityStatus': sourceSectionContinuityStatus,
      'evidenceLineCount': missingVendorRecoveryEvidenceLineIds.length,
      'vendorReviewStatus': vendorReviewStatus,
      'addressContactMetadataLineCount': addressContactMetadataLineCount,
      'weakHeaderCandidateLineCount': weakHeaderCandidateLineCount,
    });
  }

  String get merchantIndependentStructureStatus {
    if (lines.isEmpty) return 'no_text';
    if (primaryTotalAmount == null) return 'needs_total';
    if (itemLines.isEmpty) return 'needs_item_lines';
    if (parserReadyLineCount == 0) return 'needs_safe_item_prices';
    if (hasDuplicateLineIds) return 'needs_line_identity_review';
    if (needsSourceSectionContinuityReview) return 'needs_section_order_review';
    if (needsLineSequenceReview) return 'needs_line_order_review';
    if (fuelCandidateLineCount > 0) return 'generic_fuel_receipt_ready';
    if (materialCandidateLineCount > 0) return 'generic_material_receipt_ready';
    if (vehicleSupplyCandidateLineCount > 0) {
      return 'generic_vehicle_supply_receipt_ready';
    }
    if (reviewItemLineCount > 0) return 'generic_receipt_ready_with_review';
    return 'generic_receipt_ready';
  }

  String get merchantIndependentStructureLabel {
    return switch (merchantIndependentStructureStatus) {
      'generic_fuel_receipt_ready' =>
        'Merchant-independent fuel receipt structure is ready.',
      'generic_material_receipt_ready' =>
        'Merchant-independent material receipt structure is ready.',
      'generic_vehicle_supply_receipt_ready' =>
        'Merchant-independent vehicle supply receipt structure is ready.',
      'generic_receipt_ready_with_review' =>
        'Merchant-independent receipt structure is usable with line review.',
      'generic_receipt_ready' =>
        'Merchant-independent receipt structure is ready.',
      'needs_line_order_review' =>
        'Receipt line order needs review before merchant-independent parsing.',
      'needs_line_identity_review' =>
        'Receipt line numbering needs review before merchant-independent parsing.',
      'needs_section_order_review' =>
        'Receipt section order needs review before merchant-independent parsing.',
      'needs_safe_item_prices' =>
        'Receipt item prices need review before merchant-independent parsing.',
      'needs_item_lines' =>
        'Receipt needs item lines before merchant-independent parsing.',
      'needs_total' =>
        'Receipt needs a total before merchant-independent parsing.',
      'no_text' => 'No receipt text is ready for receipt reconstruction.',
      _ => 'Merchant-independent receipt structure needs review.',
    };
  }

  Map<String, Object?> get merchantIndependentStructureDiagnostics {
    return Map.unmodifiable({
      'status': merchantIndependentStructureStatus,
      'ready': hasMerchantIndependentReceiptStructure,
      'label': merchantIndependentStructureLabel,
      'headerRecoveryStatus': headerRecoveryStatus,
      'lineCount': lines.length,
      'vendorLineCount': vendorLines.length,
      'itemLineCount': itemLines.length,
      'readyItemLineCount': parserReadyLineCount,
      'reviewItemLineCount': reviewItemLineCount,
      'summaryLineCount': summaryLines.length,
      'fuelLineCount': fuelCandidateLineCount,
      'materialLineCount': materialCandidateLineCount,
      'vehicleSupplyLineCount': vehicleSupplyCandidateLineCount,
      'lineSequenceStatus': lineSequenceStatus,
      'lineIdentityStatus': lineIdentityStatus,
      'sourceSectionContinuityStatus': sourceSectionContinuityStatus,
    });
  }

  String get leanLocalOcrReadinessStatus {
    if (lines.isEmpty) return 'no_text';
    if (vendorLines.isEmpty ||
        dateLines.isEmpty ||
        primaryTotalAmount == null) {
      return 'proof_fields_need_review';
    }
    if (hasCompleteSummaryAmounts && !summaryMathReconciled) {
      return 'proof_totals_need_review';
    }
    if (parserReadyLineCount == 0) {
      return 'proof_totals_ready_lines_deferred';
    }
    if (reviewItemLineCount > 0 ||
        needsLineSequenceReview ||
        hasDuplicateLineIds) {
      return 'proof_totals_ready_lines_need_review';
    }
    return 'line_items_ready';
  }

  String get leanLocalOcrReadinessLabel {
    return switch (leanLocalOcrReadinessStatus) {
      'no_text' => 'No receipt text is ready for Receipt Assist.',
      'proof_fields_need_review' =>
        'On-device Receipt Assist needs review before using store, date, and total.',
      'proof_totals_need_review' =>
        'On-device Receipt Assist found receipt totals, but the math needs review.',
      'proof_totals_ready_lines_deferred' =>
        'On-device Receipt Assist can use store, date, and total; detailed lines should be entered or reviewed manually.',
      'proof_totals_ready_lines_need_review' =>
        'On-device Receipt Assist can use receipt proof fields, but line items need review.',
      _ => 'On-device Receipt Assist can prepare line items for review.',
    };
  }

  Map<String, int> get leanLocalOcrReadinessCounts {
    return Map.unmodifiable({
      leanLocalOcrReadinessStatus: 1,
      if (vendorLines.isNotEmpty) 'vendor_ready': 1,
      if (dateLines.isNotEmpty) 'date_ready': 1,
      if (primaryTotalAmount != null) 'total_ready': 1,
      if (parserReadyLineCount > 0)
        'parser_ready_item_lines': parserReadyLineCount,
      if (reviewItemLineCount > 0) 'review_item_lines': reviewItemLineCount,
      if (needsLineSequenceReview) 'line_sequence_review': 1,
      if (hasDuplicateLineIds) 'line_identity_review': 1,
      if (hasCompleteSummaryAmounts && !summaryMathReconciled)
        'summary_math_review': 1,
    });
  }
}
