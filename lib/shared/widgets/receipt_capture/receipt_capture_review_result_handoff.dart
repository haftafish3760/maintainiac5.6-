part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoff on ReceiptPhotoReviewResult {
  bool get ocrReadsClearSourceBeforeSavedProof {
    return hasOcrSourcePhotos && !usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrUsesSavedProofOnlyAsFallback {
    return hasOcrSourcePhotos && usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrSourceFallbackRequiresManualReview {
    return !hasOcrSourcePhotos || usedSavedProofAsOcrSourceFallback;
  }

  String get ocrSourceReviewRiskCode {
    if (!hasOcrSourcePhotos) return 'ocr_source_missing_manual_entry_required';
    if (usedSavedProofAsOcrSourceFallback) {
      return 'saved_proof_ocr_fallback_review_required';
    }
    if (scannerNeedsOperatorReview) {
      return 'scanner_preparation_review_required';
    }
    return 'ocr_source_ready';
  }

  String get ocrSourceReviewRequirement {
    return ocrSourceFallbackRequiresManualReview || scannerNeedsOperatorReview
        ? 'manual_review_required_before_saving_receipt'
        : 'standard_user_confirmation_required';
  }

  String get ocrSourceFirstDecisionCode {
    if (!hasOcrSourcePhotos) return 'ocr_source_missing_block_review';
    if (ocrUsesSavedProofOnlyAsFallback) {
      return 'saved_proof_fallback_review_required';
    }
    if (scannerUsedEnhancedOcrSource) {
      return 'prepared_receipt_source_before_saved_proof';
    }
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      return 'temporary_full_quality_source_before_saved_proof';
    }
    if (usesSeparateOcrSourceCopies) {
      return 'separate_receipt_source_before_saved_proof';
    }
    return 'accepted_receipt_source_before_saved_proof';
  }

  String get ocrSourceProofRelationship {
    if (!hasOcrSourcePhotos) return 'missing_ocr_source';
    if (ocrUsesSavedProofOnlyAsFallback) return 'saved_proof_fallback';
    if (scannerUsedEnhancedOcrSource) return 'prepared_clear_source';
    if (scannerKeptTemporaryFullQualitySourceForQuality) {
      return 'temporary_full_quality_source';
    }
    if (usesSeparateOcrSourceCopies) return 'separate_clear_source';
    return 'same_accepted_source';
  }

  String get ocrSourceFirstReviewCue {
    return switch (ocrSourceFirstDecisionCode) {
      'prepared_receipt_source_before_saved_proof' =>
        'OCR is using the prepared clear receipt source before the smaller saved proof copy.',
      'temporary_full_quality_source_before_saved_proof' =>
        'OCR is using the temporary full-quality receipt source before the smaller saved proof copy.',
      'separate_receipt_source_before_saved_proof' =>
        'OCR is using separate clear receipt sources before the smaller saved proof copies.',
      'accepted_receipt_source_before_saved_proof' =>
        'OCR is using the accepted receipt source before any storage-saving proof copy.',
      'saved_proof_fallback_review_required' =>
        'OCR is using the saved proof only because a clearer source was not available. Review the filled receipt carefully.',
      _ =>
        'OCR source was not ready. Add a clearer receipt photo or continue by hand.',
    };
  }

  Map<String, Object?> get privacySafeOcrSourceFirstSummary {
    return Map.unmodifiable({
      'ocrSourceFirstPolicy': 'ocr_reads_clear_source_before_saved_proof',
      'ocrSourceFirstDecisionCode': ocrSourceFirstDecisionCode,
      'ocrSourceFirstOutcome': ocrSourceFirstOutcome,
      'ocrSourceFirstActionLabel': ocrSourceFirstActionLabel,
      'ocrSourceFirstReviewCue': ocrSourceFirstReviewCue,
      'ocrSourceProofRelationship': ocrSourceProofRelationship,
      'ocrSourceReviewRiskCode': ocrSourceReviewRiskCode,
      'ocrSourceReviewRequirement': ocrSourceReviewRequirement,
      'ocrSourceFallbackRequiresManualReview':
          ocrSourceFallbackRequiresManualReview,
      'ocrReadsClearSourceBeforeSavedProof':
          ocrReadsClearSourceBeforeSavedProof,
      'ocrUsesSavedProofOnlyAsFallback': ocrUsesSavedProofOnlyAsFallback,
      'ocrSourceCount': ocrSourcePhotoCount,
      'savedProofCount': savedBackupPhotoCount,
      'savedProofDataSaverLevel': dataSaverLevel.name,
    });
  }

  bool get usesSeparateOcrSourceCopies {
    if (!hasReceiptReaderHandoff) return false;
    if (photoPaths.length != ocrSourcePhotoPaths.length) return true;
    for (var index = 0; index < photoPaths.length; index++) {
      if (photoPaths[index] != ocrSourcePhotoPaths[index]) return true;
    }
    return false;
  }
}
