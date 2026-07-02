part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultHandoff on ReceiptPhotoReviewResult {
  bool get ocrReadsClearSourceBeforeSavedProof {
    return hasOcrSourcePhotos && !usedSavedProofAsOcrSourceFallback;
  }

  bool get ocrUsesSavedProofOnlyAsFallback {
    return hasOcrSourcePhotos && usedSavedProofAsOcrSourceFallback;
  }

  String get ocrSourceFirstDecisionCode {
    if (!hasOcrSourcePhotos) return 'ocr_source_missing_block_review';
    if (ocrUsesSavedProofOnlyAsFallback) {
      return 'saved_proof_fallback_review_required';
    }
    if (scannerUsedEnhancedOcrSource) {
      return 'prepared_receipt_source_before_saved_proof';
    }
    if (scannerKeptOriginalForQuality) {
      return 'original_receipt_source_before_saved_proof';
    }
    if (usesSeparateOcrSourceCopies) {
      return 'separate_receipt_source_before_saved_proof';
    }
    return 'accepted_receipt_source_before_saved_proof';
  }

  String get ocrSourceFirstReviewCue {
    return switch (ocrSourceFirstDecisionCode) {
      'prepared_receipt_source_before_saved_proof' =>
        'OCR is using the prepared clear receipt source before the smaller saved proof copy.',
      'original_receipt_source_before_saved_proof' =>
        'OCR is using the original receipt source before the smaller saved proof copy.',
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
