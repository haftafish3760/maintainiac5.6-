part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsStorage
    on ExpenseReceiptParseDiagnostics {
  bool get hasReceiptBrainOptionalPackDeferredForStorage =>
      (receiptBrainLowStorageDownloadRiskCounts['base_safe_optional_brain_deferred_for_low_storage'] ??
          0) >
      0;
  bool get hasReceiptBrainFullOfflineTooLargeForStorage =>
      (receiptBrainLowStorageDownloadRiskCounts['full_offline_too_large_for_low_storage'] ??
              0) >
          0 ||
      (receiptBrainLowStorageDownloadRiskCounts['full_offline_large_optional_only'] ??
              0) >
          0 ||
      (receiptBrainFullOfflineExceedsBaseGuardrailCounts['true'] ?? 0) > 0;
  bool get hasReceiptBrainBaseInstallStorageBlock =>
      (receiptBrainLowStorageDownloadRiskCounts['base_install_blocks_low_storage_users'] ??
          0) >
      0;
  String get receiptBrainParserLimitOutcome {
    if (hasReceiptBrainBaseInstallStorageBlock) {
      return 'base_install_blocks_low_storage_users';
    }
    if (hasReceiptBrainFullOfflineTooLargeForStorage) {
      return 'full_offline_receipt_brain_optional_only';
    }
    if (hasReceiptBrainOptionalPackDeferredForStorage) {
      return 'optional_parser_pack_deferred_for_storage';
    }
    if ((receiptBrainFullOfflineMustStayOptionalCounts['true'] ?? 0) > 0) {
      return 'optional_receipt_brain_user_choice_required';
    }
    return 'no_receipt_brain_storage_limit';
  }

  String get receiptBrainParserLimitSummaryLabel {
    return switch (receiptBrainParserLimitOutcome) {
      'base_install_blocks_low_storage_users' =>
        'Receipt app size needs review',
      'full_offline_receipt_brain_optional_only' =>
        'Full offline receipt brain is optional',
      'optional_parser_pack_deferred_for_storage' =>
        'Optional receipt brain deferred for storage',
      'optional_receipt_brain_user_choice_required' =>
        'Optional receipt brain available',
      _ => '',
    };
  }

  String get receiptBrainParserLimitActionLabel {
    return switch (receiptBrainParserLimitOutcome) {
      'base_install_blocks_low_storage_users' =>
        'Basic capture should not ship with a required download that blocks low-storage phones.',
      'full_offline_receipt_brain_optional_only' =>
        'Continue with local receipt review now; offer the full offline receipt brain as a separate choice.',
      'optional_parser_pack_deferred_for_storage' =>
        'Continue with the saved proof and core receipt fields. Offer stronger local packs only when the user chooses them.',
      'optional_receipt_brain_user_choice_required' =>
        'Keep the receipt usable now, then let the user choose whether to install more offline receipt help.',
      _ => '',
    };
  }

  bool get hasReceiptInstallBaseSizeBlock =>
      (receiptInstallRequiredSegmentCounts['required_base_block_over_100mb'] ??
          0) >
      0;

  bool get hasReceiptInstallOptionalOfflineBrain =>
      receiptInstallFullOfflineSegmentCounts.isNotEmpty &&
      (receiptInstallFullOfflineSegmentCounts['full_offline_same_as_base'] ??
              0) ==
          0;

  bool get hasReceiptInstallLowStorageBaseOnly =>
      (receiptInstallLowStorageImpactCounts['low_storage_base_only_optional_pack_hidden'] ??
          0) >
      0;

  bool get hasGenericReceiptStructure =>
      genericReceiptStructureStatus == 'receipt_structure_ready' ||
      genericReceiptStructureStatus == 'receipt_structure_ready_tax_optional' ||
      genericReceiptStructureStatus == 'unknown_merchant_items_ready';

  bool get hasGenericReceiptStructureReview =>
      genericReceiptStructureStatus != 'unknown' &&
      genericReceiptStructureStatus != 'receipt_structure_ready' &&
      genericReceiptStructureStatus != 'receipt_structure_ready_tax_optional';

  bool get hasGenericReceiptLineNumbers =>
      genericReceiptParserLineNumbers.isNotEmpty;

  int genericReceiptZoneCount(String zone) =>
      genericReceiptZoneCounts[zone] ?? 0;

  int genericReceiptSignalCount(String signal) =>
      genericReceiptSignalCounts[signal] ?? 0;

  String get genericReceiptStructureActionLabel {
    return switch (genericReceiptStructureStatus) {
      'receipt_structure_ready' =>
        'Receipt structure is ready for local merchant, item, tax, and total review.',
      'receipt_structure_ready_tax_optional' =>
        'Receipt structure is ready; tax can be reviewed or inferred.',
      'unknown_merchant_items_ready' =>
        'Line items and totals are readable even though the merchant needs review.',
      'receipt_items_need_total_review' =>
        'Line items were found; review totals before saving.',
      'total_only' =>
        'Totals were found, but item detail needs review or manual entry.',
      'header_only' =>
        'Receipt header was found, but line items and totals need review.',
      'no_receipt_structure' =>
        'Readable text did not look enough like a receipt yet.',
      'no_text' => 'No readable receipt text was found.',
      _ => '',
    };
  }

  String get receiptInstallFootprintOutcome {
    if (hasReceiptInstallBaseSizeBlock) {
      return 'required_base_too_large';
    }
    if ((receiptInstallRecommendedDistributionCounts['split_heavy_receipt_work_before_release'] ??
            0) >
        0) {
      return 'split_heavy_receipt_work';
    }
    if ((receiptInstallRecommendedDistributionCounts['ship_base_hide_large_packs_until_storage_allows'] ??
            0) >
        0) {
      return 'base_ready_hide_large_packs';
    }
    if ((receiptInstallRecommendedDistributionCounts['ship_base_offer_optional_offline_receipt_packs'] ??
            0) >
        0) {
      return 'base_ready_offer_optional_packs';
    }
    if ((receiptInstallRecommendedDistributionCounts['ship_base_receipt_flow_only'] ??
            0) >
        0) {
      return 'base_receipt_only_ready';
    }
    if (hasReceiptInstallOptionalOfflineBrain) {
      return 'base_ready_optional_offline_brain';
    }
    return 'receipt_install_footprint_unknown';
  }

  String get receiptInstallFootprintSummaryLabel {
    return switch (receiptInstallFootprintOutcome) {
      'required_base_too_large' => 'Receipt install size needs review',
      'split_heavy_receipt_work' => 'Heavy receipt work must be split out',
      'base_ready_hide_large_packs' =>
        'Basic receipt flow ready; large packs hidden',
      'base_ready_offer_optional_packs' =>
        'Basic receipt flow ready; offline packs optional',
      'base_receipt_only_ready' => 'Basic receipt flow ready',
      'base_ready_optional_offline_brain' =>
        'Offline receipt brain remains optional',
      _ => '',
    };
  }
}
