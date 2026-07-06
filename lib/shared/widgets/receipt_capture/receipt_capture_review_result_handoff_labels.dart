part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoffLabels on ReceiptPhotoReviewResult {
  String get acceptedPhotoHandoffActionLabel {
    if (keptForLater) {
      return 'Resume photo review, then tap Next to review receipt details.';
    }
    if (userConfirmedPossiblePartialReceiptComplete) {
      return 'Review receipt details next; the user confirmed this photo shows the full receipt.';
    }
    if (needsAnotherReceiptSectionBeforeDetails) {
      if (firstPossiblePartialReceiptReasonCode ==
          'missing_bottom_edge_and_totals') {
        return _bottomGhostSliceHandoffInstruction(
          suffix:
              'before reviewing receipt details, unless this photo already shows the full receipt.',
        );
      }
      return 'Add the next receipt section before reviewing receipt details, unless this photo already shows the full receipt.';
    }
    if (receiptSectionOrderNeedsReview) {
      return receiptSectionOrderReviewActionLabel;
    }
    final warningProfile = acceptedPhotoWarningProfile;
    if (warningProfile != 'saved_photo_ok') {
      return switch (warningProfile) {
        'saved_photo_brightness_assist_failed_dark' =>
          'Retake with the receipt light before reviewing receipt lines.',
        'saved_photo_darker_than_preview' =>
          'Retake with more light, or continue only if every line is readable.',
        'saved_photo_soft_blur_risk' =>
          'Retake while holding steady before relying on automatic fill.',
        'saved_photo_brighter_than_preview' || 'saved_photo_glare_risk' =>
          'Reduce glare, then continue only if totals and prices are readable.',
        'saved_photo_bottom_too_dark' =>
          'Add Another Photo for the bottom lines if the total is hard to read.',
        'saved_photo_bottom_soft' =>
          'Add Another Photo or retake the bottom lines if they look fuzzy.',
        'saved_photo_dirty_lens_or_haze' =>
          'Wipe the lens or retake before relying on automatic fill.',
        'saved_photo_shadow_risk' =>
          'Move the receipt into even light or retake before relying on automatic fill.',
        'saved_photo_brightness_assist_still_dim' =>
          'Check dim receipt text, then add light or retake if needed.',
        'saved_photo_dimmer_than_preview' =>
          'Check readability, then add light or retake if needed.',
        _ =>
          'Check readability, then review receipt details and mark Business, Personal, or Mixed.',
      };
    }
    return switch (acceptedPhotoHandoffOutcome) {
      'critical_quality_retake_recommended' =>
        'Retake or crop before reviewing receipt lines.',
      'possible_partial_receipt' =>
        'Add the next receipt section, or continue only if the full receipt is readable.',
      'stitch_fallback_sections' =>
        'Review ordered receipt sections from top to bottom.',
      'needs_review_before_ocr' =>
        'Check readability, then review receipt details and mark Business, Personal, or Mixed.',
      'accepted_no_quality_signal' =>
        'Check the photo, then review receipt details and mark Business, Personal, or Mixed.',
      _ => 'Review receipt details and mark Business, Personal, or Mixed.',
    };
  }

  String get receiptPhotoReviewHandoffPath {
    if (keptForLater) return 'saved_without_filling_resume_required';
    if (!hasOcrSourcePhotos) {
      return 'accepted_without_ocr_source_review_required';
    }
    if (usedSavedProofAsOcrSourceFallback) {
      return 'accepted_saved_proof_ocr_fallback';
    }
    if (ocrSourceReviewRiskCode ==
        'stitch_ocr_source_contract_review_required') {
      return 'accepted_stitch_ocr_source_review_required';
    }
    if (stitchResult.didStitch) return 'accepted_stitched_combined_image';
    if (stitchResult.usedFallback) return 'accepted_ordered_sections_fallback';
    if (ocrSourcePhotoCount > 1) return 'accepted_ordered_sections';
    if (usesSeparateOcrSourceCopies) return 'accepted_single_prepared_source';
    return 'accepted_single_photo';
  }

  String get receiptPhotoReviewHandoffPathLabel {
    return switch (receiptPhotoReviewHandoffPath) {
      'saved_without_filling_resume_required' =>
        'Saved without filling; resume photo review before receipt details.',
      'accepted_without_ocr_source_review_required' =>
        'Accepted photo review but OCR source is missing; review by hand.',
      'accepted_saved_proof_ocr_fallback' =>
        'Accepted photo review using saved proof as OCR fallback.',
      'accepted_stitch_ocr_source_review_required' =>
        'Accepted photo review, but stitch/OCR source handoff needs review.',
      'accepted_stitched_combined_image' =>
        'Accepted long receipt as one stitched OCR image.',
      'accepted_ordered_sections_fallback' =>
        'Accepted long receipt as ordered OCR sections after stitch fallback.',
      'accepted_ordered_sections' =>
        'Accepted multiple receipt sections in order.',
      'accepted_single_prepared_source' =>
        'Accepted single receipt with prepared OCR source.',
      _ => 'Accepted single receipt photo.',
    };
  }

  String get acceptedPhotoHandoffRoute => keptForLater
      ? 'saved_photo_review_resume_required'
      : needsAnotherReceiptSectionBeforeDetails
      ? 'photo_review_add_next_receipt_section'
      : receiptSectionOrderNeedsReview
      ? 'photo_review_section_order_review_required'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'photo_review_ocr_source_review_required'
      : 'photo_review_accepted_to_receipt_details';

  String get acceptedPhotoHandoffNextScreen => keptForLater
      ? 'receipt_photo_review_resume'
      : needsAnotherReceiptSectionBeforeDetails
      ? 'receipt_photo_capture_bottom_section'
      : receiptSectionOrderNeedsReview
      ? 'receipt_photo_section_order_review'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'receipt_photo_ocr_source_review'
      : 'receipt_details_store_date_total_tax_items';

  String get acceptedPhotoHandoffNextStepLabel => keptForLater
      ? 'Resume the saved receipt photo review, then tap Next to open receipt details.'
      : needsAnotherReceiptSectionBeforeDetails
      ? firstPossiblePartialReceiptReasonCode ==
                'missing_bottom_edge_and_totals'
            ? _bottomGhostSliceHandoffInstruction(
                suffix:
                    'before receipt details, or confirm this photo already shows the full receipt.',
              )
            : 'Add the next receipt section before receipt details, or confirm this photo already shows the full receipt.'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'Review the OCR source handoff before opening receipt details.'
      : 'Next opens receipt details with store, date, total, tax, item prices, and Business/Personal/Mixed choices.';

  String get acceptedPhotoHandoffProcessingLabel => keptForLater
      ? 'Receipt details stay closed until saved photo review is resumed.'
      : needsAnotherReceiptSectionBeforeDetails
      ? 'Receipt details stay paused until the bottom section is added or the user confirms this photo already shows the full receipt.'
      : receiptSectionOrderNeedsReview
      ? 'Receipt details stay paused until the user confirms the receipt section order.'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'Receipt details stay paused until the OCR source handoff is reviewed.'
      : 'Next reads the clearest OCR source first before the smaller saved proof copy is kept, then opens the filled receipt review.';

  String get acceptedPhotoHandoffRouteResultLabel => keptForLater
      ? 'Photo review is saved for later; receipt details stay closed until the user resumes and taps Next.'
      : userConfirmedPossiblePartialReceiptComplete
      ? 'Receipt details can open because the user confirmed the flagged photo covers the full receipt.'
      : needsAnotherReceiptSectionBeforeDetails
      ? firstPossiblePartialReceiptReasonCode ==
                'missing_bottom_edge_and_totals'
            ? _bottomGhostSliceHandoffInstruction(
                suffix:
                    'before receipt details can open, unless the user confirms this photo already shows the full receipt.',
              )
            : 'Receipt details can open only after the user accepts that this photo covers the full receipt or adds the next section.'
      : receiptSectionOrderNeedsReview
      ? 'Receipt details can open only after the receipt section order is reviewed.'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'Receipt details can open only after the OCR source handoff is reviewed.'
      : 'Accepted photo review must open receipt details next, not the previous expense screen.';

  bool get acceptedPhotoHandoffMustOpenFilledReview =>
      !keptForLater &&
      !needsAnotherReceiptSectionBeforeDetails &&
      !receiptSectionOrderNeedsReview &&
      ocrSourceReviewRequirement !=
          'manual_review_required_before_saving_receipt';

  bool get acceptedPhotoHandoffMustOpenReceiptDetails =>
      !keptForLater &&
      !needsAnotherReceiptSectionBeforeDetails &&
      !receiptSectionOrderNeedsReview &&
      ocrSourceReviewRequirement !=
          'manual_review_required_before_saving_receipt';

  String get acceptedPhotoHandoffUserAction => keptForLater
      ? 'resume_saved_photo_review'
      : userConfirmedPossiblePartialReceiptComplete
      ? 'confirm_complete_receipt_and_review_details'
      : needsAnotherReceiptSectionBeforeDetails
      ? 'add_next_section_or_confirm_complete_receipt'
      : receiptSectionOrderNeedsReview
      ? 'review_receipt_section_order'
      : ocrSourceReviewRequirement ==
            'manual_review_required_before_saving_receipt'
      ? 'review_ocr_source_handoff'
      : 'tap_next_after_photo_review';

  String get acceptedPhotoHandoffEvidenceLabel {
    final outcome = acceptedPhotoHandoffOutcome;
    final count = acceptedPhotoQualityOutcomeCounts[outcome] ?? 0;
    final countLabel = count == 1 ? '1 photo' : '$count photos';
    return '$outcome:$countLabel:$acceptedPhotoWarningProfile:${stitchResult.diagnosticReasonLabel}';
  }

  String get privacySafeOcrHandoffEvidenceLabel {
    final qualityOutcome = acceptedPhotoHandoffOutcome;
    final stitchStatus = stitchResult.status.name;
    final stitchReason = stitchResult.diagnosticReasonLabel;
    final sourceCount = ocrSourcePhotoPaths.length;
    final scannerPath = scannerUsedEnhancedOcrSource
        ? 'enhanced_ocr_source'
        : scannerKeptTemporaryFullQualitySourceForQuality
        ? 'temporary_full_quality_source_guard'
        : scannerDecisionCodes.isEmpty
        ? 'scanner_no_decision'
        : 'scanner_decision';
    final savedWarning = hasSavedPhotoQualityWarning
        ? 'saved_warning_${savedPhotoWarningSeverityCounts.keys.join("_")}'
        : 'saved_warning_none';
    final savedWarningProfile = acceptedPhotoWarningProfile;
    final coverage = hasPossiblePartialReceiptPhotos
        ? 'possible_partial_receipt'
        : 'coverage_ok';
    final uiCounts = nativeCameraUiHealthCounts;
    final uiHealth = uiCounts.isEmpty ? '' : nativeCameraUiHealthOutcome;
    final closeCounts = nativeCloseCapturedPhotoOutcomeCounts;
    final closeOutcome = closeCounts.isEmpty
        ? ''
        : nativeCloseCapturedPhotoHealthOutcome;
    final captureSource = nativeCaptureSourcePolicyOutcome;
    final sectionOrder = receiptSectionOrderOutcome;
    final completion = receiptCompletionReviewOutcome;
    return [
      'quality=$qualityOutcome',
      'stitch=$stitchStatus',
      'reason=$stitchReason',
      'sources=$sourceCount',
      !hasOcrSourcePhotos
          ? 'ocr_source_first=not_ready'
          : usedSavedProofAsOcrSourceFallback
          ? 'ocr_source_first=fallback_saved_proof'
          : 'ocr_source_first=true',
      'scanner=$scannerPath',
      'saved=$savedWarning',
      if (savedWarningProfile != 'saved_photo_ok')
        'savedProfile=$savedWarningProfile',
      'coverage=$coverage',
      if (captureSource != 'unknown') 'captureSource=$captureSource',
      if (sectionOrder != 'unknown') 'sections=$sectionOrder',
      if (completion != 'completion_not_prompted') 'completion=$completion',
      if (uiHealth.isNotEmpty) 'ui=$uiHealth',
      if (closeOutcome.isNotEmpty) 'close=$closeOutcome',
    ].join(';');
  }
}
