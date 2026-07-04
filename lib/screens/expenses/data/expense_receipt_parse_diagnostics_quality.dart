part of 'expense_receipt_parser.dart';

extension ExpenseReceiptParseDiagnosticsQuality
    on ExpenseReceiptParseDiagnostics {
  bool get hasOcrReadabilityLimitEvidence =>
      ocrParserTaskCount('ocr_no_readable_text') > 0 ||
      ocrParserTaskCount('photo_read_failed') > 0 ||
      ocrParserTaskCount('photo_tiny_text_review') > 0 ||
      ocrParserTaskCount('photo_small_proof_review') > 0 ||
      hasOcrPhotoQualityActionReview ||
      ocrParserTaskCount('photo_quality_review') > 0 ||
      ocrParserReadinessStatus == 'no_text' ||
      ocrReceiptStructureStatus == 'no_text';

  bool get hasOcrPhotoRetakeActionReview =>
      ocrParserTaskCount('photo_retake_recommended_review') > 0 ||
      ocrParserTaskCount('photo_quality_retake_family_review') > 0;
  bool get hasOcrPhotoCropOrRetakeActionReview =>
      ocrParserTaskCount('photo_crop_or_retake_review') > 0;
  bool get hasOcrPhotoReadabilityOrCloserActionReview =>
      ocrParserTaskCount('photo_readability_or_closer_review') > 0;
  bool get hasOcrSavedDarkOrExposureReview =>
      ocrParserTaskCount('photo_saved_dark_or_exposure_review') > 0;
  bool get hasOcrSavedSoftBlurReview =>
      ocrParserTaskCount('photo_saved_soft_blur_review') > 0;
  bool get hasOcrSavedGlareReview =>
      ocrParserTaskCount('photo_saved_glare_review') > 0;
  bool get hasOcrSavedBottomQualityReview =>
      ocrParserTaskCount('photo_saved_bottom_quality_review') > 0;
  bool get hasOcrPhotoQualityActionReview =>
      hasOcrPhotoRetakeActionReview ||
      hasOcrPhotoCropOrRetakeActionReview ||
      hasOcrPhotoReadabilityOrCloserActionReview ||
      hasOcrSavedDarkOrExposureReview ||
      hasOcrSavedSoftBlurReview ||
      hasOcrSavedGlareReview ||
      hasOcrSavedBottomQualityReview ||
      ocrParserTaskCount('photo_quality_review_family') > 0;

  String get ocrPhotoQualityActionReviewCode {
    if (hasOcrSourceMissingBottomCoverageEvidence ||
        hasOcrSourceBottomOverlapGhostContinuation ||
        shouldSuggestLowerReceiptSection) {
      return 'add_bottom_section_first';
    }
    if (hasOcrPhotoRetakeActionReview) return 'retake_photo_recommended';
    if (hasOcrPhotoCropOrRetakeActionReview) return 'crop_or_retake_photo';
    if (hasOcrPhotoReadabilityOrCloserActionReview) {
      return 'check_readability_or_add_closer_photo';
    }
    if (hasOcrSavedBottomQualityReview) return 'check_bottom_photo_quality';
    if (hasOcrSavedDarkOrExposureReview) return 'retake_or_brighten_photo';
    if (hasOcrSavedSoftBlurReview) return 'retake_soft_photo';
    if (hasOcrSavedGlareReview) return 'reduce_glare_or_retake';
    if (ocrParserTaskCount('photo_quality_review') > 0 ||
        ocrParserTaskCount('photo_quality_review_family') > 0) {
      return 'review_photo_quality';
    }
    return 'photo_quality_action_not_reported';
  }

  String get ocrPhotoQualityActionReviewLabel {
    return switch (ocrPhotoQualityActionReviewCode) {
      'add_bottom_section_first' => 'Add bottom receipt section first',
      'retake_photo_recommended' => 'Retake recommended',
      'crop_or_retake_photo' => 'Crop or retake photo',
      'check_readability_or_add_closer_photo' =>
        'Check readability or add closer photo',
      'check_bottom_photo_quality' => 'Check bottom receipt section',
      'retake_or_brighten_photo' => 'Retake or brighten photo',
      'retake_soft_photo' => 'Retake soft photo',
      'reduce_glare_or_retake' => 'Reduce glare or retake',
      'review_photo_quality' => 'Check photo quality',
      _ => '',
    };
  }

  String get ocrPhotoQualityActionReviewInstruction {
    return switch (ocrPhotoQualityActionReviewCode) {
      'add_bottom_section_first' =>
        'Finish the receipt coverage first. Add the bottom receipt section with the ghost-slice guide before final classification.',
      'retake_photo_recommended' =>
        'The receipt photo can continue only if every line is readable. Retake before OCR review if text is soft, dark, cut off, or hard to inspect.',
      'crop_or_retake_photo' =>
        'Crop the receipt proof if the full receipt is visible, or retake/add a clearer photo if any line is missing.',
      'check_readability_or_add_closer_photo' =>
        'Check whether item text is readable at normal review zoom. If it is too small, add a closer receipt photo before final review.',
      'check_bottom_photo_quality' =>
        'The saved proof says the bottom receipt lines may be dark or soft. Zoom into the totals and final lines, then add a clearer bottom photo or retake if needed.',
      'retake_or_brighten_photo' =>
        'The saved proof is darker than the camera preview or stayed too dark after assist. Add light, raise Brightness, or retake before relying on OCR.',
      'retake_soft_photo' =>
        'The saved proof may be soft. Retake while holding steady before relying on automatic line fill.',
      'review_photo_quality' =>
        'Check the accepted receipt proof before saving. Continue only if store, date, totals, and item prices are readable.',
      _ => '',
    };
  }

  String get ocrPhotoQualityActionReviewActionLabel {
    return switch (ocrPhotoQualityActionReviewCode) {
      'add_bottom_section_first' => 'Add bottom section',
      'retake_photo_recommended' => 'Retake or confirm readable',
      'crop_or_retake_photo' => 'Crop or retake',
      'check_readability_or_add_closer_photo' => 'Add closer photo if needed',
      'check_bottom_photo_quality' => 'Check bottom or add photo',
      'retake_or_brighten_photo' => 'Retake with better light',
      'retake_soft_photo' => 'Retake while holding steady',
      'review_photo_quality' => 'Check receipt photo',
      _ => '',
    };
  }

  bool get hasReadableOcrParserEvidence =>
      ocrParserLineCount > 0 ||
      ocrPricedLineCount > 0 ||
      ocrItemCandidateLineCount > 0 ||
      hasOcrTotalSignals ||
      hasMixedReceiptMathBasis;

  bool get hasLocalParserPatternGapEvidence =>
      hasReadableOcrParserEvidence &&
      (detectedLineCount == 0 ||
          ocrParserTaskCount('item_price_ready_missing') > 0 ||
          ocrParserTaskCount('item_price_review_required') > 0 ||
          parserDownstreamReadinessCount('totals_found_no_safe_lines') > 0);

  String get localParserEvidenceOutcome {
    if (hasReceiptBrainBaseInstallStorageBlock ||
        hasReceiptBrainFullOfflineTooLargeForStorage ||
        hasReceiptBrainOptionalPackDeferredForStorage) {
      return 'receipt_brain_storage_limited';
    }
    if (hasParserCategoryPackLimits || shouldOfferDetailedParserPack) {
      return 'optional_parser_pack_limited';
    }
    if (hasOcrReadabilityLimitEvidence ||
        (!hasReadableOcrParserEvidence && detectedLineCount == 0)) {
      return 'ocr_readability_limited';
    }
    if (hasLocalParserPatternGapEvidence) {
      return 'local_parser_patterns_limited';
    }
    if (hasParserCategoryWeakConfidence || reviewRatio > .5) {
      return 'local_parser_review_limited';
    }
    if (detectedLineCount > 0 || hasOcrParserReadyLines) {
      return 'local_parser_ready';
    }
    return 'local_parser_evidence_unknown';
  }

  String get localParserEvidenceSummaryLabel {
    return switch (localParserEvidenceOutcome) {
      'receipt_brain_storage_limited' =>
        'Receipt brain was limited by local storage guardrails',
      'optional_parser_pack_limited' =>
        'Receipt was readable, but stronger optional parser details may help',
      'ocr_readability_limited' =>
        'Receipt text was not readable enough for reliable local parsing',
      'local_parser_patterns_limited' =>
        'Receipt text was readable, but local parser patterns need strengthening',
      'local_parser_review_limited' =>
        'Receipt parsed locally, but line confidence needs review',
      'local_parser_ready' => 'Local receipt parser evidence is ready',
      _ => 'Local parser evidence was not available',
    };
  }

  String get localParserEvidenceActionLabel {
    return switch (localParserEvidenceOutcome) {
      'receipt_brain_storage_limited' =>
        'Keep capture usable now and offer heavy offline receipt packs separately.',
      'optional_parser_pack_limited' =>
        'Let the user continue, then offer stronger local receipt detail packs when useful.',
      'ocr_readability_limited' =>
        'Improve capture guidance, focus, lighting, crop, or OCR image prep before parser rules.',
      'local_parser_patterns_limited' =>
        'Strengthen local merchant, total, tax, and line-item parser rules for this receipt family.',
      'local_parser_review_limited' =>
        'Show the parsed receipt review screen with clear line-level correction controls.',
      'local_parser_ready' =>
        'Continue into business, personal, or mixed receipt review.',
      _ => 'Keep privacy-safe diagnostics and route to manual review.',
    };
  }

  bool get hasParserCategoryWeakConfidence =>
      parserCategoryHealthCount('category_confidence_weak_total') > 0 ||
      parserCategoryHealthCount('category_confidence_poor_total') > 0;
  int parserCategoryFamilyConfidenceCount(String family, String status) =>
      parserCategoryHealthCount('category_family_${family}_confidence_$status');
  String get parserCategoryReviewActionCode {
    if (!hasParserCategoryHealthCounts) return 'no_category_signals';
    if (!hasParserCategoryReady && !hasParserCategoryReview) {
      return 'no_priced_lines';
    }
    if (hasParserCategoryWeakConfidence) {
      return 'review_low_confidence_lines';
    }
    if (hasParserCategoryPackLimits) {
      return 'optional_parser_pack_available';
    }
    if (hasParserCategoryReview) return 'review_flagged_lines';
    return 'ready';
  }

  String get parserCategoryReviewActionLabel {
    return switch (parserCategoryReviewActionCode) {
      'no_category_signals' =>
        'No category signals were available for this receipt.',
      'no_priced_lines' =>
        'No priced receipt lines were ready. Save the proof or enter the receipt by hand.',
      'review_low_confidence_lines' =>
        'Review the low-confidence receipt lines before saving.',
      'optional_parser_pack_available' =>
        'This receipt is readable, but a stronger optional parser pack may improve category details.',
      'review_flagged_lines' =>
        'Review the flagged receipt lines before saving.',
      'ready' => 'Receipt lines are ready to review and save.',
      _ => 'Review this receipt before saving.',
    };
  }

  String get localReceiptParserRoutingCode {
    if (parserDepth == ReceiptParserDepth.proofTotalsOnly) {
      return hasMixedReceiptMathBasis
          ? 'proof_totals_first'
          : 'manual_receipt_entry';
    }
    if (parserCategoryCount('fuel') > 0) return 'fuel_simple_local';
    if (detectedLineCount > 0 &&
        detectedLineCount <= 2 &&
        !hasParserCategoryPackLimits) {
      return 'simple_expense_local';
    }
    if (hasParserCategoryPackLimits) return 'optional_detail_pack_available';
    if (detectedLineCount > 0) return 'standard_line_review_local';
    if (hasMixedReceiptMathBasis) return 'proof_totals_first';
    return 'manual_receipt_entry';
  }

  bool get keepsSimpleReceiptLocal =>
      localReceiptParserRoutingCode == 'proof_totals_first' ||
      localReceiptParserRoutingCode == 'fuel_simple_local' ||
      localReceiptParserRoutingCode == 'simple_expense_local';

  bool get shouldOfferDetailedParserPack =>
      localReceiptParserRoutingCode == 'optional_detail_pack_available';

  String get localReceiptParserRoutingLabel {
    return switch (localReceiptParserRoutingCode) {
      'proof_totals_first' =>
        'Use local receipt proof fields first; detailed lines can be entered or reviewed later.',
      'fuel_simple_local' =>
        'Fuel and simple receipt details stay local before heavier parser packs.',
      'simple_expense_local' =>
        'Simple receipt line review can stay local on this device.',
      'optional_detail_pack_available' =>
        'This receipt is readable locally, but detailed category matching may improve with an optional parser pack.',
      'standard_line_review_local' =>
        'Local line review is available for this receipt.',
      _ => 'Enter this receipt manually or add a clearer proof.',
    };
  }

  String get localReceiptParserRoutingSummaryLabel {
    return switch (localReceiptParserRoutingCode) {
      'proof_totals_first' => 'Proof totals stayed local',
      'fuel_simple_local' => 'Fuel receipt stayed local',
      'simple_expense_local' => 'Simple receipt stayed local',
      'optional_detail_pack_available' =>
        'Optional detail pack can improve categories',
      'standard_line_review_local' => 'Line review stayed local',
      _ => 'Manual receipt review',
    };
  }

  String get localReceiptParserRoutingActionLabel {
    return switch (localReceiptParserRoutingCode) {
      'proof_totals_first' =>
        'Review the total and add detailed lines only if you need them.',
      'fuel_simple_local' =>
        'Review fuel amount, tax, total, and mileage details before saving.',
      'simple_expense_local' =>
        'Review the filled fields, then save or add more line details.',
      'optional_detail_pack_available' =>
        'Continue with the saved proof, or install an optional pack later for better item categories.',
      'standard_line_review_local' =>
        'Review each detected line before saving this receipt.',
      _ =>
        'Keep the saved proof and fill in the missing receipt details manually.',
    };
  }
}
