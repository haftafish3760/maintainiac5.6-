part of 'receipt_capture_models.dart';

class ReceiptImageStoragePreview {
  const ReceiptImageStoragePreview({
    required this.originalBytes,
    required this.estimatedBytes,
    required this.level,
    required this.quality,
  });

  final int originalBytes;
  final int estimatedBytes;
  final ReceiptDataSaverLevel level;
  final ReceiptPhotoQualityCheck quality;

  int get savedBytes =>
      (originalBytes - estimatedBytes).clamp(0, originalBytes);
  double get savedPercent =>
      originalBytes <= 0 ? 0 : savedBytes / originalBytes;

  String get originalLabel =>
      ReceiptStorageFormatter.formatBytes(originalBytes);
  String get estimatedLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedBytes);
  String get savedLabel => ReceiptStorageFormatter.formatBytes(savedBytes);
}

class ReceiptPhotoQualityCheck {
  const ReceiptPhotoQualityCheck({
    required this.width,
    required this.height,
    required this.focusScore,
    required this.isLikelyReadable,
    this.brightness = 128,
    this.contrast = 28,
    this.cropScore = .72,
    this.textBandScore = 12,
  });

  final int width;
  final int height;
  final double focusScore;
  final bool isLikelyReadable;
  final double brightness;
  final double contrast;
  final double cropScore;
  final double textBandScore;

  String get resolutionLabel => '${width}x$height';
  int get reviewScore {
    if (width <= 0 || height <= 0) return 0;
    final focusPoints = (focusScore / 18 * 42).clamp(0, 42).round();
    final shortestSide = width < height ? width : height;
    final resolutionPoints = (shortestSide / 1600 * 22).clamp(0, 22).round();
    final contrastPoints = (contrast / 34 * 16).clamp(0, 16).round();
    final cropPoints = (cropScore * 12).clamp(0, 12).round();
    final textPoints = (textBandScore / 12 * 8).clamp(0, 8).round();
    final lightPenalty = isTooDark || isTooBright ? 18 : 0;
    final rawScore =
        (focusPoints +
                resolutionPoints +
                contrastPoints +
                cropPoints +
                textPoints -
                lightPenalty)
            .clamp(0, 100)
            .toInt();
    if (isLikelyReadable && !isTooDark && !isTooBright && !isVerySoft) {
      return rawScore < 82 ? 82 : rawScore;
    }
    return rawScore;
  }

  String get reviewScoreLabel => '$reviewScore%';
  bool get isTooDark => brightness < 68;
  bool get isUnderexposedForReceipt => brightness < 92;
  bool get isTooBright => brightness > 246;
  bool get isBrightButReadable => brightness > 224 && !isTooBright;
  bool get isLowContrast => contrast < 16;
  bool get isPoorlyFramed => cropScore < .30;
  bool get isMissingTextBands => textBandScore < 6;
  bool get isLowResolution => width < 900 || height < 900;
  bool get isSoft => focusScore < 8;
  bool get isVerySoft => focusScore < 5.5;
  bool get isUnreadableImage => width <= 0 || height <= 0;
  bool get hasCriticalIssue =>
      isUnreadableImage || isTooDark || isTooBright || isVerySoft;
  bool get isReadableScore => reviewScore >= 70;
  bool get isExcellentScore => reviewScore >= 85;
  double get brightnessDistanceFromReceiptIdeal => (brightness - 150).abs();
  bool get needsReview {
    if (hasCriticalIssue) return true;
    if (qualityWarnings.isNotEmpty) return true;
    if (isReadableScore && isLikelyReadable) return false;
    if (reviewScore >= 80 && !isSoft && !isLowResolution) return false;
    return !isLikelyReadable || reviewScore < 70 || qualityWarnings.isNotEmpty;
  }

  bool get canContinueWithReview => !hasCriticalIssue;
  bool get shouldRetakeBeforeOcr => hasCriticalIssue || reviewScore < 50;
  String get reviewActionCode {
    if (shouldRetakeBeforeOcr) return 'retake_recommended_continue_allowed';
    if (isPoorlyFramed && !isLikelyReadable) return 'crop_or_retake_then_next';
    if (isLowResolution || isMissingTextBands) {
      return 'check_readability_or_add_closer_photo';
    }
    if (needsReview) return 'check_photo_then_next';
    return 'continue_to_receipt_details';
  }

  String get reviewActionFamily {
    if (reviewActionCode.startsWith('retake')) return 'retake';
    if (reviewActionCode.startsWith('continue')) return 'continue';
    return 'review';
  }

  String get nextReviewActionLabel {
    if (shouldRetakeBeforeOcr) return 'Retake recommended; Next still works';
    if (reviewActionCode == 'crop_or_retake_then_next') {
      return 'Crop or retake if text is missing; Next still works';
    }
    if (reviewActionCode == 'check_readability_or_add_closer_photo') {
      return 'Check readability or add a closer photo';
    }
    if (needsReview) return 'Check photo, then tap Next';
    return 'Tap Next for receipt details';
  }

  String get userFacingStatusLabel {
    if (shouldRetakeBeforeOcr) {
      return '$reviewTitle: $reviewGuidance';
    }
    if (needsReview) {
      return '$reviewTitle: $reviewGuidance';
    }
    return reviewGuidance;
  }

  String get qualityEvidenceLabel {
    final parts = <String>[
      '$reviewBandLabel; photo check $reviewScoreLabel',
      'light $lightLabel',
      'focus $focusLabel',
      framingLabel,
    ];
    if (textBandScore < 8) parts.add('receipt lines weak');
    return parts.join(' • ');
  }

  String get reviewScoreMeaningLabel {
    if (shouldRetakeBeforeOcr) {
      return 'Retake is safer, but Next is still available if the receipt text is readable.';
    }
    if (needsReview) {
      return 'Photo check is guidance only. If the receipt text is readable, tap Next.';
    }
    return 'Photo check is guidance only. Tap Next if the receipt text is readable.';
  }

  String get reviewBandLabel {
    if (hasCriticalIssue || reviewScore < 50) return 'Retake recommended';
    if (reviewScore < 70) return 'Check before Next';
    if (isExcellentScore) return 'Excellent receipt photo';
    return 'Readable receipt photo';
  }

  String get focusLabel {
    if (focusScore >= 14) return 'sharp';
    if (focusScore >= 8) return 'usable';
    return 'may be blurry';
  }

  String get lightLabel {
    if (isTooDark) return 'too dark';
    if (isUnderexposedForReceipt) return 'a little dark';
    if (isTooBright) return 'glare/too bright';
    if (isBrightButReadable) return 'bright but usable';
    return 'light OK';
  }

  String get framingLabel {
    if (isPoorlyFramed) return 'check that no text is cut off';
    if (cropScore < .50) return 'check framing';
    return 'framed';
  }

  String get primaryIssueLabel {
    if (isUnreadableImage) return 'could not read image';
    if (isTooDark) return 'too dark';
    if (isTooBright) return 'glare or too bright';
    if (isVerySoft) return 'looks blurry';
    if (isSoft) return 'check sharpness';
    if (isUnderexposedForReceipt) return 'could be brighter';
    if (isLowResolution) return 'move closer';
    if (isLowContrast) return 'low contrast';
    if (isPoorlyFramed) return 'check that no text is cut off';
    if (isMissingTextBands) return 'printed lines are weak';
    return 'looks readable';
  }

  String get reviewTitle {
    if (hasCriticalIssue) return 'Retake Recommended';
    if (reviewScore >= 70) return reviewBandLabel;
    if (needsReview) return 'Check Before Continuing';
    return 'Receipt Looks Readable';
  }

  String get reviewGuidance {
    if (isUnreadableImage) {
      return 'The app could not read this image file. Take another photo or choose a different image.';
    }
    if (isTooDark) {
      return 'Add light or turn on the torch so the printed receipt text is readable.';
    }
    if (isTooBright) {
      return 'Reduce glare by tilting the phone or receipt before taking another photo.';
    }
    if (isBrightButReadable) {
      return 'The receipt is bright but usable. Check for glare, then tap Next if the store, date, total, and item prices are readable.';
    }
    if (isVerySoft) {
      return 'Tap the receipt text to focus, hold still, and retake if the store, date, or total is fuzzy.';
    }
    if (isSoft) {
      return 'Zoom in and check the store, date, total, and item prices before continuing.';
    }
    if (isUnderexposedForReceipt) {
      return 'The receipt is readable but darker than ideal. Add light, turn on the torch, or retake if the bottom text looks dim.';
    }
    if (isLowResolution) {
      return 'If item text is too small, add another closer photo. If every line is readable, tap Next.';
    }
    if (isLowContrast) {
      return 'Check that the printed text stands out from the paper before continuing.';
    }
    if (isPoorlyFramed) {
      return 'If every line of the receipt is visible, tap Next. Use crop or retake only if part of the receipt is missing.';
    }
    if (isMissingTextBands) {
      return 'Some printed lines look weak. Check the item prices before saving.';
    }
    if (reviewScore >= 70) {
      return 'This looks readable. Tap Next for receipt details, or use Add Another Photo only if the receipt continues.';
    }
    return 'Check the store, date, total, and item prices. If they are readable, tap Next; otherwise retake or use Add Another Photo.';
  }

  List<String> get qualityWarnings {
    return [
      if (isUnreadableImage) 'Image could not be decoded.',
      if (isTooDark) 'Photo is too dark.',
      if (!isTooDark && isUnderexposedForReceipt)
        'Photo is darker than ideal for receipt assistance.',
      if (isTooBright)
        'Photo has glare or is too bright.'
      else if (isBrightButReadable && !isLikelyReadable)
        'Photo is bright; check for glare before continuing.',
      if (isVerySoft)
        'Photo looks blurry.'
      else if (isSoft)
        'Photo sharpness should be checked.',
      if (isLowResolution) 'Receipt resolution is low.',
      if (isLowContrast) 'Printed text has low contrast.',
      if (isPoorlyFramed) 'Check that every receipt line is visible.',
      if (isMissingTextBands) 'Receipt text lines are hard to detect.',
    ];
  }

  ReceiptCaptureReadinessDecision captureReadiness({
    required bool autoCaptureEnabled,
    int stableFrameCount = 0,
    int requiredStableFrames = 3,
  }) {
    return ReceiptCaptureReadinessDecision.fromQuality(
      this,
      autoCaptureEnabled: autoCaptureEnabled,
      stableFrameCount: stableFrameCount,
      requiredStableFrames: requiredStableFrames,
    );
  }
}

class ReceiptCaptureReadinessDecision {
  const ReceiptCaptureReadinessDecision({
    required this.code,
    required this.label,
    required this.manualCaptureAllowed,
    required this.autoCaptureAllowed,
    required this.autoCaptureEnabled,
    required this.stableFrameCount,
    required this.requiredStableFrames,
  });

  factory ReceiptCaptureReadinessDecision.fromQuality(
    ReceiptPhotoQualityCheck quality, {
    required bool autoCaptureEnabled,
    int stableFrameCount = 0,
    int requiredStableFrames = 3,
  }) {
    final safeRequiredFrames = requiredStableFrames < 1
        ? 1
        : requiredStableFrames;
    final safeStableFrames = stableFrameCount < 0 ? 0 : stableFrameCount;

    if (quality.isUnreadableImage) {
      return ReceiptCaptureReadinessDecision(
        code: 'manual_only_unreadable_image',
        label: 'Take a new photo when the receipt is visible.',
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: autoCaptureEnabled,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (!autoCaptureEnabled) {
      return ReceiptCaptureReadinessDecision(
        code: 'manual_ready_auto_capture_off',
        label: 'Manual capture is ready. Auto capture is off.',
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: false,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (quality.hasCriticalIssue) {
      return ReceiptCaptureReadinessDecision(
        code: 'manual_only_quality_retake_recommended',
        label: quality.reviewGuidance,
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (quality.isPoorlyFramed || quality.isMissingTextBands) {
      return ReceiptCaptureReadinessDecision(
        code: 'manual_only_check_framing',
        label: 'Check that every receipt line is visible before auto capture.',
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    if (safeStableFrames < safeRequiredFrames) {
      return ReceiptCaptureReadinessDecision(
        code: 'auto_capture_waiting_for_stability',
        label: 'Hold steady for automatic capture.',
        manualCaptureAllowed: true,
        autoCaptureAllowed: false,
        autoCaptureEnabled: true,
        stableFrameCount: safeStableFrames,
        requiredStableFrames: safeRequiredFrames,
      );
    }
    return ReceiptCaptureReadinessDecision(
      code: 'auto_capture_ready',
      label: 'Receipt looks steady. Taking photo.',
      manualCaptureAllowed: true,
      autoCaptureAllowed: true,
      autoCaptureEnabled: true,
      stableFrameCount: safeStableFrames,
      requiredStableFrames: safeRequiredFrames,
    );
  }

  final String code;
  final String label;
  final bool manualCaptureAllowed;
  final bool autoCaptureAllowed;
  final bool autoCaptureEnabled;
  final int stableFrameCount;
  final int requiredStableFrames;

  Map<String, Object?> get diagnostics => {
    'captureReadinessCode': code,
    'captureReadinessLabel': label,
    'manualCaptureAllowed': manualCaptureAllowed,
    'autoCaptureAllowed': autoCaptureAllowed,
    'autoCaptureEnabled': autoCaptureEnabled,
    'stableFrameCount': stableFrameCount,
    'requiredStableFrames': requiredStableFrames,
  };
}

enum ReceiptNativeSavedPhotoWarningSeverity { notice, warning, critical }
