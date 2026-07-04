part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentPublishSignals
    on _SharedReceiptAttachmentPanelState {
  List<String> photoDocumentSignalsFor(String path) {
    final quality = _photoQualityByPath[path];
    final diagnostics = _photoCaptureDiagnosticsByPath[path] ?? const {};
    final signals = <String>{
      'receipt_camera_review',
      'linked_module_$_receiptAttachmentLinkedModule',
      'data_saver_${_dataSaverLevel.name}',
    };
    if (quality != null) {
      signals
        ..add('quality_score_${qualityScoreBucket(quality.reviewScore)}')
        ..add('quality_light_${attachmentSignalToken(quality.lightLabel)}')
        ..add('quality_focus_${attachmentSignalToken(quality.focusLabel)}')
        ..add('quality_framing_${attachmentSignalToken(quality.framingLabel)}')
        ..add(
          'quality_action_${attachmentSignalToken(quality.reviewActionCode)}',
        )
        ..add(
          'quality_family_${attachmentSignalToken(quality.reviewActionFamily)}',
        );
      if (quality.needsReview) signals.add('quality_needs_review');
      if (quality.canContinueWithReview) signals.add('quality_can_continue');
    }
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.latestReadabilitySignal,
      'native_readability',
    );
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.latestFramingSignal,
      'native_framing',
    );
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness,
      'native_perspective',
    );
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.latestCapturedQualitySignal,
      'native_quality',
    );
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.latestCapturedExposureMismatch,
      'native_exposure',
    );
    diagnosticSignal(
      signals,
      diagnostics,
      ReceiptCaptureDiagnosticKeys.photoCoverageStatus,
      'coverage',
    );
    final savedWarning =
        ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(diagnostics);
    if (savedWarning != null) {
      signals
        ..add('saved_photo_warning_${attachmentSignalToken(savedWarning.code)}')
        ..add(
          'saved_photo_action_${attachmentSignalToken(savedWarning.actionCode)}',
        )
        ..add('saved_photo_severity_${savedWarning.severity.name}');
    }
    return List.unmodifiable(signals);
  }

  List<String> photoRiskFlagsFor(String path) {
    final quality = _photoQualityByPath[path];
    final diagnostics = _photoCaptureDiagnosticsByPath[path] ?? const {};
    final flags = <String>{};
    if (quality != null) {
      if (quality.shouldRetakeBeforeOcr) flags.add('retake_before_ocr');
      if (quality.needsReview) flags.add('needs_operator_review');
      if (quality.isTooDark || quality.isUnderexposedForReceipt) {
        flags.add('receipt_photo_dark');
      }
      if (quality.isTooBright || quality.isBrightButReadable) {
        flags.add('receipt_photo_glare_risk');
      }
      if (quality.isSoft || quality.isVerySoft) {
        flags.add('receipt_photo_soft');
      }
      if (quality.isPoorlyFramed) flags.add('possible_partial_receipt');
      if (quality.isLowResolution) flags.add('receipt_text_small');
      if (quality.isLowContrast) flags.add('receipt_low_contrast');
      if (quality.isMissingTextBands) flags.add('receipt_lines_weak');
    }
    final coverageNeedsMorePhotos =
        diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos];
    if (coverageNeedsMorePhotos == true ||
        coverageNeedsMorePhotos?.toString() == 'true') {
      flags.add('possible_partial_receipt');
      flags.add('add_more_photos_recommended');
    }
    final coverageStatus =
        diagnostics[ReceiptCaptureDiagnosticKeys.photoCoverageStatus]
            ?.toString()
            .trim();
    if (coverageStatusNeedsMorePhotos(coverageStatus)) {
      flags.add('possible_partial_receipt');
      flags.add('add_more_photos_recommended');
    }
    final savedWarning =
        ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(diagnostics);
    if (savedWarning != null) {
      flags.add(savedWarning.code);
      if (savedWarning.isCritical) flags.add('native_capture_critical_review');
    }
    return List.unmodifiable(flags);
  }

  void diagnosticSignal(
    Set<String> signals,
    Map<String, Object?> diagnostics,
    String key,
    String prefix,
  ) {
    final value = diagnostics[key]?.toString().trim();
    if (value == null || value.isEmpty) return;
    signals.add('${prefix}_${attachmentSignalToken(value)}');
  }

  String qualityScoreBucket(int score) {
    if (score >= 90) return '90_100';
    if (score >= 80) return '80_89';
    if (score >= 70) return '70_79';
    if (score >= 50) return '50_69';
    return 'under_50';
  }

  String attachmentSignalToken(String value) {
    final token = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return token.isEmpty ? 'unknown' : token;
  }

  String attachmentPhotoEditActionToken(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return 'manual_edit';
    final token = attachmentSignalToken(raw);
    return switch (token) {
      'manual_crop' ||
      'manual_rotate' ||
      'manual_edit' ||
      'auto_crop' ||
      'auto_rotate' ||
      'perspective_correction' ||
      'deskew' ||
      'brightness_cleanup' ||
      'contrast_cleanup' ||
      'shadow_cleanup' ||
      'grayscale_cleanup' => token,
      _ => 'invalid_photo_edit_action',
    };
  }

  bool coverageStatusNeedsMorePhotos(String? status) {
    if (status == null || status.isEmpty) return false;
    if (status == ReceiptPhotoCoverageStatus.likelyCutOff.name ||
        status == ReceiptPhotoCoverageStatus.maybeContinues.name) {
      return true;
    }
    return const {
      'bottom_soft_or_missing',
      'bottom_missing',
      'soft_or_missing',
      'cut_off',
      'possibly_cut_off',
      'needs_next_section',
      'continues',
      'likely_cut_off',
      'maybe_continues',
    }.contains(attachmentSignalToken(status));
  }
}
