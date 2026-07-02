part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsOcr on ExpenseReceiptParseDiagnostics {
  bool get hasParserRequiredFieldStatusCounts =>
      parserRequiredFieldStatusCounts.isNotEmpty;
  int parserRequiredFieldStatusCount(String bucket) =>
      parserRequiredFieldStatusCounts[bucket] ?? 0;
  bool get hasParserRequiredFieldMissing =>
      parserRequiredFieldStatusCount('parser_required_missing_total') > 0;
  bool get hasParserRequiredFieldReview =>
      parserRequiredFieldStatusCount('parser_required_needs_review_total') > 0;
  bool get hasParserDownstreamReadyStatus =>
      parserDownstreamReadinessStatus == 'expense_lines_ready' ||
      parserDownstreamReadinessStatus == 'inventory_material_ready' ||
      parserDownstreamReadinessStatus == 'vehicle_cost_ready';
  bool get hasParserDownstreamReviewStatus =>
      parserDownstreamReadinessStatus == 'expense_lines_need_review' ||
      parserDownstreamReadinessStatus == 'proof_total_only' ||
      parserDownstreamReadinessStatus == 'proof_needs_review';
  int parserDownstreamReadinessCount(String bucket) =>
      parserDownstreamReadinessCounts[bucket] ?? 0;
  bool get hasOcrLineRoleSignals => ocrParserLineRoleCounts.isNotEmpty;
  int ocrLineRoleCount(String role) => ocrParserLineRoleCounts[role] ?? 0;
  bool get hasOcrStableLineIds => ocrStableLineIdCount > 0;
  bool get hasOcrReadyItemLineIds => ocrParserReadyItemLineIdCount > 0;
  bool get hasOcrReviewItemLineIds => ocrReviewItemLineIdCount > 0;
  bool get hasOcrLineIdentityMaps =>
      ocrRoleByLineId.isNotEmpty && ocrParserBucketByLineId.isNotEmpty;
  bool get hasOcrParserBucketCounts => ocrParserBucketCounts.isNotEmpty;
  int ocrParserBucketCount(String bucket) => ocrParserBucketCounts[bucket] ?? 0;
  bool get hasOcrParserTaskCounts => ocrParserTaskCounts.isNotEmpty;
  int ocrParserTaskCount(String task) => ocrParserTaskCounts[task] ?? 0;
  bool get hasOcrVendorTaskEvidence =>
      ocrParserTaskCount('vendor_candidate') > 0;
  bool get hasOcrDateTaskEvidence => ocrParserTaskCount('date_candidate') > 0;
  bool get hasOcrSubtotalTaskEvidence =>
      ocrParserTaskCount('subtotal_candidate') > 0;
  bool get hasOcrTaxTaskEvidence => ocrParserTaskCount('tax_candidate') > 0;
  bool get hasOcrTotalTaskEvidence => ocrParserTaskCount('total_candidate') > 0;
  bool get hasOcrItemPriceTaskEvidence =>
      ocrParserTaskCount('item_price_ready') > 0 ||
      ocrParserTaskCount('item_price_needs_review') > 0;
  bool get hasOcrMaterialPrepTaskEvidence =>
      ocrParserTaskCount('inventory_material_candidate') > 0;
  bool get hasOcrFuelTaskEvidence =>
      ocrParserTaskCount('fuel_line_ready') > 0 ||
      ocrParserTaskCount('generic_fuel_receipt_ready') > 0 ||
      ocrParserTaskCount('fuel_line_candidate') > 0;
  bool get hasOcrMixedItemExpenseFamilies =>
      ocrItemExpenseFamilyStatus == 'mixed_item_families' ||
      ocrParserTaskCount('expense_family_mixed_receipt') > 0;
  bool get hasParserMixedItemExpenseFamilies =>
      parserItemExpenseFamilyStatus == 'mixed_item_families' ||
      parserTaskCount('parser_expense_family_mixed_receipt') > 0;
  bool get hasAnyMixedItemExpenseFamilies =>
      hasOcrMixedItemExpenseFamilies || hasParserMixedItemExpenseFamilies;
  bool get hasParserGenericFuelReceiptReady =>
      parserTaskCount('generic_fuel_receipt_ready') > 0 ||
      parserTaskCount('fuel_line_ready') > 0 ||
      hasOcrFuelTaskEvidence;
  bool get hasOcrSourceHandoffSignals =>
      ocrSourceHandoffSignalCounts.isNotEmpty ||
      ocrSourceStitchSignalCounts.isNotEmpty ||
      ocrSourceScannerDecisionCounts.isNotEmpty ||
      ocrSourceCaptureSourceSignalCounts.isNotEmpty ||
      ocrSourceCoverageSignalCounts.isNotEmpty ||
      ocrSourceContinuationSignalCounts.isNotEmpty ||
      ocrSourcePhotoQualityRiskCounts.isNotEmpty ||
      ocrSourceQualityReviewStatus.trim().isNotEmpty ||
      ocrSourceQualityReviewAction.trim().isNotEmpty ||
      hasMissingBottomTotalsLocalEvidence;
  bool get hasMissingBottomTotalsLocalEvidence {
    final code = missingBottomTotalsEvidenceCode.trim();
    return missingBottomTotalsEvidenceFamilyCount > 0 &&
        code.isNotEmpty &&
        code != 'no_missing_bottom_totals_evidence';
  }

  bool get hasOcrFieldReadinessCounts => ocrFieldReadinessCounts.isNotEmpty;
  int ocrFieldReadinessCount(String bucket) =>
      ocrFieldReadinessCounts[bucket] ?? 0;
  bool get hasOcrRequiredFieldStatusCounts =>
      ocrRequiredFieldStatusCounts.isNotEmpty;
  int ocrRequiredFieldStatusCount(String bucket) =>
      ocrRequiredFieldStatusCounts[bucket] ?? 0;
  bool get hasOcrRequiredFieldMissing =>
      ocrRequiredFieldStatusCount('required_missing_total') > 0;
  bool get hasOcrRequiredFieldReview =>
      ocrRequiredFieldStatusCount('required_needs_review_total') > 0;
  List<String> ocrLineIdsForRole(String role) =>
      ocrLineIdsByRole[role] ?? const [];
  String ocrRoleForLineId(String lineId) => ocrRoleByLineId[lineId] ?? '';
  String ocrParserBucketForLineId(String lineId) =>
      ocrParserBucketByLineId[lineId] ?? '';

  Map<String, String> get ocrRequiredFieldStatusByField {
    String statusFor(String field) {
      if (ocrRequiredFieldStatusCount('${field}_missing') > 0) {
        return 'missing';
      }
      if (ocrRequiredFieldStatusCount('${field}_needs_review') > 0) {
        return 'needs_review';
      }
      if (ocrRequiredFieldStatusCount('${field}_ready') > 0) return 'ready';
      return 'unknown';
    }

    return Map.unmodifiable({
      'vendor': statusFor('vendor'),
      'date': statusFor('date'),
      'subtotal': statusFor('subtotal'),
      'tax': statusFor('tax'),
      'total': statusFor('total'),
      'item_price': ocrRequiredFieldStatusCount('item_price_missing') > 0
          ? 'missing'
          : ocrRequiredFieldStatusCount('item_price_needs_review') > 0
          ? 'needs_review'
          : ocrRequiredFieldStatusCount('item_price_ready') > 0
          ? 'ready'
          : 'unknown',
    });
  }

  List<String> get ocrRequiredFieldIssueLabels {
    const labels = {
      'vendor': 'store',
      'date': 'date',
      'subtotal': 'subtotal',
      'tax': 'tax',
      'total': 'total',
      'item_price': 'item prices',
    };
    final statuses = ocrRequiredFieldStatusByField;
    final issues = <String>[
      for (final entry in labels.entries)
        if (statuses[entry.key] == 'missing') 'missing ${entry.value}',
      for (final entry in labels.entries)
        if (statuses[entry.key] == 'needs_review') 'check ${entry.value}',
    ];
    return List.unmodifiable(issues);
  }

  String get ocrRequiredFieldIssueSummaryLabel {
    final issues = ocrRequiredFieldIssueLabels;
    if (issues.isEmpty) return '';
    if (issues.length <= 3) return issues.join(', ');
    return '${issues.take(3).join(', ')}, +${issues.length - 3} more';
  }

  List<String> get ocrParserReviewCauseCodes {
    final causes = <String>[
      if (ocrParserTaskCount('vendor_missing') > 0)
        'receipt_ocr_missing_vendor',
      if (ocrParserTaskCount('date_missing') > 0) 'receipt_ocr_missing_date',
      if (ocrParserTaskCount('ocr_no_readable_text') > 0)
        'receipt_ocr_no_readable_text',
      if (ocrParserTaskCount('photo_read_failed') > 0)
        'receipt_ocr_photo_read_failed',
      if (ocrParserTaskCount('photo_tiny_text_review') > 0)
        'receipt_ocr_photo_tiny_text',
      if (ocrParserTaskCount('photo_small_proof_review') > 0)
        'receipt_ocr_small_proof_copy',
      if (ocrParserTaskCount('photo_retake_recommended_review') > 0 ||
          ocrParserTaskCount('photo_quality_retake_family_review') > 0)
        'receipt_ocr_photo_retake_recommended',
      if (ocrParserTaskCount('photo_crop_or_retake_review') > 0)
        'receipt_ocr_photo_crop_or_retake',
      if (ocrParserTaskCount('photo_readability_or_closer_review') > 0)
        'receipt_ocr_photo_readability_or_closer',
      if (ocrParserTaskCount('photo_saved_bottom_quality_review') > 0)
        'receipt_ocr_photo_saved_bottom_quality',
      if (ocrParserTaskCount('photo_saved_dark_or_exposure_review') > 0)
        'receipt_ocr_photo_saved_dark_or_exposure',
      if (ocrParserTaskCount('photo_saved_soft_blur_review') > 0)
        'receipt_ocr_photo_saved_soft_blur',
      if (ocrParserTaskCount('photo_quality_review') > 0)
        'receipt_ocr_photo_quality_review',
      if (ocrParserTaskCount('long_receipt_section_gap') > 0)
        'receipt_ocr_long_receipt_section_gap',
      if (ocrParserTaskCount('long_receipt_probable_overlap') > 0)
        'receipt_ocr_long_receipt_probable_overlap',
      if (ocrParserTaskCount('long_receipt_duplicate_text') > 0)
        'receipt_ocr_long_receipt_duplicate_text',
      if (ocrParserTaskCount('total_missing') > 0) 'receipt_ocr_missing_total',
      if (ocrParserTaskCount('summary_missing') > 0)
        'receipt_ocr_missing_summary',
      if (ocrParserTaskCount('tax_missing') > 0) 'receipt_ocr_missing_tax',
      if (ocrParserTaskCount('item_price_missing') > 0)
        'receipt_ocr_no_priced_lines',
      if (ocrParserTaskCount('item_price_ready_missing') > 0)
        'receipt_ocr_no_parser_ready_items',
      if (ocrParserTaskCount('line_sequence_needs_review') > 0)
        'receipt_ocr_line_sequence_review',
      if (ocrParserTaskCount('summary_math_needs_review') > 0)
        'receipt_ocr_summary_math_review',
      if (ocrParserTaskCount('item_price_review_required') > 0)
        'receipt_ocr_parser_readiness_review',
      if (hasReceiptBrainBaseInstallStorageBlock)
        'receipt_parser_base_install_blocks_low_storage',
      if (hasParserCategoryPackLimits &&
          hasReceiptBrainFullOfflineTooLargeForStorage)
        'receipt_parser_full_offline_too_large_optional_only',
      if (hasParserCategoryPackLimits &&
          hasReceiptBrainOptionalPackDeferredForStorage)
        'receipt_parser_optional_pack_deferred_for_storage',
    ];
    return List.unmodifiable(causes);
  }

  String get ocrRequiredFieldReadinessSummaryLabel {
    if (!hasOcrRequiredFieldStatusCounts) {
      return 'OCR required field status not available';
    }
    final statuses = ocrRequiredFieldStatusByField;
    String labelFor(String field, String label) {
      final status = statuses[field] ?? 'unknown';
      return '$label=$status';
    }

    return [
      labelFor('vendor', 'vendor'),
      labelFor('date', 'date'),
      labelFor('subtotal', 'subtotal'),
      labelFor('tax', 'tax'),
      labelFor('total', 'total'),
      labelFor('item_price', 'item_price'),
      'structure=$ocrReceiptStructureStatus',
      'sections=$ocrSourceSectionContinuityStatus',
      'readiness=$ocrParserReadinessStatus',
    ].join(';');
  }

  String get ocrLineIdentitySummaryLabel {
    if (!hasOcrStableLineIds) return 'OCR line identity not available';
    final ready = ocrOrderedParserReadyLineIds.length;
    final review = ocrOrderedParserReviewLineIds.length;
    final material = ocrInventoryPrepLineIdCount;
    final parts = <String>[
      '$ocrStableLineIdCount OCR ${ocrStableLineIdCount == 1 ? 'line' : 'lines'} mapped',
      if (ready > 0) '$ready ready',
      if (review > 0) '$review to check',
      if (material > 0) '$material material-prep',
    ];
    return parts.join('; ');
  }

  ExpenseReceiptFieldConfidence? confidenceForField(String fieldKey) {
    return fieldConfidences[fieldKey];
  }
}
