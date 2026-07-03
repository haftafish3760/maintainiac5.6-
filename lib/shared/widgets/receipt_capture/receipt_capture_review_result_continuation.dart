part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultContinuation on ReceiptPhotoReviewResult {
  int get savedBackupPhotoCount => photoPaths.length;

  int get ocrSourcePhotoCount => ocrSourcePhotoPaths.length;

  bool get hasSavedBackupPhotos => savedBackupPhotoCount > 0;

  bool get hasOcrSourcePhotos => ocrSourcePhotoCount > 0;

  bool get hasReceiptReaderHandoff =>
      hasSavedBackupPhotos && hasOcrSourcePhotos;

  bool get hasReceiptDetailsHandoff => hasReceiptReaderHandoff;

  bool get keptForLater => reviewExitAction == 'kept_for_later';

  bool get hasPreviousSectionContinuationRequest =>
      receiptContinuationSignalCounts.isNotEmpty;

  bool get hasOcrRequestedBottomSectionContinuation =>
      (receiptContinuationSignalCounts['ocr_requested_bottom_section'] ?? 0) >
          0 ||
      (receiptContinuationSignalCounts['missing_bottom_edge_and_totals_continuation'] ??
              0) >
          0;

  String get receiptContinuationHandoffStatus {
    if (hasOcrRequestedBottomSectionContinuation) {
      return 'ocr_requested_bottom_section_continuation';
    }
    if (hasPreviousSectionContinuationRequest) {
      return 'review_requested_continuation';
    }
    return 'no_continuation_request';
  }

  Map<String, int> get receiptContinuationSignalCounts {
    final counts = <String, int>{};
    void add(String key) {
      counts[key] = (counts[key] ?? 0) + 1;
    }

    for (final diagnostics in captureDiagnosticsByPhotoPath.values) {
      if (_diagnosticBool(diagnostics['previousSectionGuideRequested']) ==
              true ||
          _diagnosticBool(
                diagnostics['phoneCameraBackupHadPreviousSectionGuide'],
              ) ==
              true) {
        add('previous_section_guide_requested');
      }
      if (_diagnosticBool(diagnostics['previousSectionGuidePhotoAvailable']) ==
          true) {
        add('previous_section_ghost_guide_available');
      }
      if (_diagnosticBool(diagnostics['previousSectionGuidanceAvailable']) ==
          true) {
        add('previous_section_guidance_available');
      }
      final reason = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionReasonCode'],
        diagnostics['phoneCameraBackupPreviousSectionReasonCode'],
      );
      if (reason != null && reason.isNotEmpty && reason != 'none') {
        add('reason_${_diagnosticToken(reason)}');
      }
      final source = diagnostics['receiptContinuationSource']
          ?.toString()
          .trim();
      if (source != null && source.isNotEmpty && source != 'none') {
        add('source_${_diagnosticToken(source)}');
      }
      final ghostStatus = diagnostics['receiptContinuationGhostGuideStatus']
          ?.toString()
          .trim();
      if (ghostStatus != null &&
          ghostStatus.isNotEmpty &&
          ghostStatus != 'not_requested') {
        add('ghost_${_diagnosticToken(ghostStatus)}');
      }
      final missingBottomAndTotals =
          _diagnosticBool(
                diagnostics['previousSectionMissingBottomAndTotals'],
              ) ==
              true ||
          _diagnosticBool(
                diagnostics['phoneCameraBackupPreviousSectionMissingBottomAndTotals'],
              ) ==
              true;
      if (missingBottomAndTotals) {
        add('missing_bottom_edge_and_totals_continuation');
      }
      final ghostPolicy = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuidePolicy'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuidePolicy'],
      );
      if (ghostPolicy != null &&
          ghostPolicy.isNotEmpty &&
          ghostPolicy != 'not_requested') {
        add('ghost_policy_${_diagnosticToken(ghostPolicy)}');
      } else if (missingBottomAndTotals) {
        add('ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines');
      }
      final repeatLineTarget = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuideRepeatLineTarget'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget'],
      );
      if (repeatLineTarget != null &&
          repeatLineTarget.isNotEmpty &&
          repeatLineTarget != 'none') {
        add('ghost_repeat_target_${_diagnosticToken(repeatLineTarget)}');
      }
      final ghostPlacement = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuidePlacement'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuidePlacement'],
      );
      if (ghostPlacement != null &&
          ghostPlacement.isNotEmpty &&
          ghostPlacement != 'none') {
        add('ghost_placement_${_diagnosticToken(ghostPlacement)}');
      }
      final ghostMatchTarget = _firstContinuationDiagnosticValue(
        diagnostics['previousSectionGhostGuideMatchTarget'],
        diagnostics['phoneCameraBackupPreviousSectionGhostGuideMatchTarget'],
      );
      if (ghostMatchTarget != null &&
          ghostMatchTarget.isNotEmpty &&
          ghostMatchTarget != 'none') {
        add('ghost_match_target_${_diagnosticToken(ghostMatchTarget)}');
      }
      if (source == 'ocr_missing_bottom_totals' || missingBottomAndTotals) {
        add('ocr_requested_bottom_section');
      }
    }
    return Map.unmodifiable(counts);
  }

  Map<String, Object?> get privacySafeReceiptContinuationSummary {
    final counts = receiptContinuationSignalCounts;
    return Map.unmodifiable({
      'schema': 'receipt_continuation_handoff_v1',
      'status': receiptContinuationHandoffStatus,
      'hasContinuationRequest': hasPreviousSectionContinuationRequest,
      'hasOcrRequestedBottomSectionContinuation':
          hasOcrRequestedBottomSectionContinuation,
      if (counts.isNotEmpty) 'continuationSignalCounts': counts,
    });
  }

  String get ocrSourceFirstOutcome {
    if (!hasOcrSourcePhotos) return 'ocr_source_not_ready';
    if (usedSavedProofAsOcrSourceFallback) {
      return 'fallback_saved_proof_review_required';
    }
    if (scannerUsedEnhancedOcrSource) return 'prepared_source_ready';
    if (scannerKeptOriginalForQuality) return 'original_source_ready';
    if (usesSeparateOcrSourceCopies) return 'separate_source_ready';
    return 'saved_source_matched_original';
  }

  String get ocrSourceFirstActionLabel {
    return switch (ocrSourceFirstOutcome) {
      'prepared_source_ready' =>
        'OCR reads prepared receipt source before saved proof',
      'original_source_ready' =>
        'OCR reads original receipt source before saved proof',
      'separate_source_ready' =>
        'OCR reads separate source copies before saved proof',
      'saved_source_matched_original' =>
        'OCR source matches the accepted receipt proof',
      'fallback_saved_proof_review_required' =>
        'OCR fell back to saved proof; review the filled receipt carefully',
      _ => 'OCR source was not ready before saved proof',
    };
  }
}

String? _firstContinuationDiagnosticValue(Object? primary, Object? fallback) {
  final primaryText = primary?.toString().trim();
  if (primaryText != null && primaryText.isNotEmpty) return primaryText;
  final fallbackText = fallback?.toString().trim();
  if (fallbackText != null && fallbackText.isNotEmpty) return fallbackText;
  return null;
}
