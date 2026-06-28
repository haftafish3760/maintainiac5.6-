class ReceiptPhotoReviewResult {
  ReceiptPhotoReviewResult({
    required List<String> photoPaths,
    required List<String> ocrSourcePhotoPaths,
    required this.dataSaverLevel,
    required this.stitchResult,
    Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> preparationDiagnosticsByOcrPath =
        const {},
    Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath = const {},
  }) : photoPaths = List.unmodifiable(photoPaths),
       ocrSourcePhotoPaths = List.unmodifiable(ocrSourcePhotoPaths),
       photoQualityChecksByPath = Map.unmodifiable(photoQualityChecksByPath),
       preparationDiagnosticsByOcrPath = _immutableDiagnosticsMap(
         preparationDiagnosticsByOcrPath,
       ),
       captureDiagnosticsByPhotoPath = _immutableDiagnosticsMap(
         captureDiagnosticsByPhotoPath,
       );

  final List<String> photoPaths;
  final List<String> ocrSourcePhotoPaths;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptStitchResult stitchResult;
  final Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath;
  final Map<String, Map<String, Object?>> preparationDiagnosticsByOcrPath;
  final Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath;

  List<String> get scannerDecisionCodes {
    final codes = <String>[];
    for (final diagnostics in preparationDiagnosticsByOcrPath.values) {
      final rawCodes = diagnostics['scannerDecisionCodes'];
      if (rawCodes is Iterable) {
        for (final rawCode in rawCodes) {
          final code = rawCode.toString().trim();
          if (code.isNotEmpty) codes.add(code);
        }
      }
    }
    return List.unmodifiable(codes);
  }

  Map<String, int> get scannerDecisionCounts {
    final counts = <String, int>{};
    for (final code in scannerDecisionCodes) {
      counts[code] = (counts[code] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  bool get scannerKeptOriginalForQuality => scannerDecisionCounts.containsKey(
    'ocr_source_original_selected_quality_guard',
  );

  bool get scannerUsedEnhancedOcrSource =>
      scannerDecisionCounts.containsKey('ocr_source_enhanced_selected');

  bool get scannerNeedsOperatorReview {
    return scannerDecisionCodes.any(
      (code) =>
          code.endsWith('_quality_guard') ||
          code == 'decode_failed' ||
          (code.startsWith('crop_skipped_') &&
              code != 'crop_skipped_setting_off') ||
          (code.startsWith('perspective_skipped_') &&
              code != 'perspective_skipped_setting_off'),
    );
  }

  String get savedProofCountLabel {
    final count = photoPaths.length;
    return count == 1 ? '1 saved proof photo' : '$count saved proof photos';
  }

  String get ocrSourceCountLabel {
    final count = ocrSourcePhotoPaths.length;
    if (count <= 0) return 'no clear OCR source';
    final source = stitchResult.didStitch ? 'combined OCR image' : 'OCR photo';
    return count == 1 ? '1 clear $source' : '$count clear ${source}s';
  }

  static Map<String, Map<String, Object?>> _immutableDiagnosticsMap(
    Map<String, Map<String, Object?>> values,
  ) {
    if (values.isEmpty) return const {};
    return Map.unmodifiable({
      for (final entry in values.entries)
        entry.key: Map<String, Object?>.unmodifiable(entry.value),
    });
  }
}

enum ReceiptStitchStatus { notNeeded, stitched, fallback }

class ReceiptStitchPairResult {
  const ReceiptStitchPairResult({
    required this.pairIndex,
    required this.overlapPixels,
    required this.confidence,
    this.usedManualAdjustment = false,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
  });

  final int pairIndex;
  final int overlapPixels;
  final double confidence;
  final bool usedManualAdjustment;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;

  String get pairLabel => 'Photo ${pairIndex + 1} to ${pairIndex + 2}';

  String get summaryLabel {
    final match = overlapPixels <= 0
        ? 'no repeated text'
        : 'repeated text found';
    if (usedManualAdjustment) return '$pairLabel: manual match, $match';
    final rotationText = rotationCorrectionDegrees.abs() >= .5
        ? ', straighten ${rotationCorrectionDegrees.toStringAsFixed(1)} deg'
        : '';
    if ((scaleCorrection - 1).abs() >= .03) {
      return '$pairLabel: ${(confidence * 100).round()}% match, $match, zoom adjusted$rotationText';
    }
    return '$pairLabel: ${(confidence * 100).round()}% match, $match$rotationText';
  }

  String get matchEvidenceLabel {
    if (usedManualAdjustment) return 'manual overlap';
    if (overlapPixels <= 0) return '${(confidence * 100).round()}% no overlap';
    if ((scaleCorrection - 1).abs() >= .03) {
      return '${(confidence * 100).round()}% with zoom fix';
    }
    if (rotationCorrectionDegrees.abs() >= .5) {
      return '${(confidence * 100).round()}% with straightening';
    }
    return '${(confidence * 100).round()}% overlap';
  }

  String get diagnosticCode {
    if (usedManualAdjustment) return 'manual_overlap';
    if (overlapPixels <= 0) return 'no_repeated_text';
    if ((scaleCorrection - 1).abs() >= .03 &&
        rotationCorrectionDegrees.abs() >= .5) {
      return 'zoom_and_straighten_adjusted';
    }
    if ((scaleCorrection - 1).abs() >= .03) return 'zoom_adjusted';
    if (rotationCorrectionDegrees.abs() >= .5) return 'straighten_adjusted';
    return 'overlap_matched';
  }

  String get userCheckLabel {
    if (usedManualAdjustment) {
      return '$pairLabel used your manual overlap. Check repeated lines once.';
    }
    if (overlapPixels <= 0) {
      return '$pairLabel did not show repeated receipt text.';
    }
    final adjustments = <String>[];
    if ((scaleCorrection - 1).abs() >= .03) {
      adjustments.add('zoom difference');
    }
    if (rotationCorrectionDegrees.abs() >= .5) {
      adjustments.add('slight tilt');
    }
    if (adjustments.isEmpty) {
      return '$pairLabel matched repeated receipt text.';
    }
    return '$pairLabel matched repeated text after fixing ${adjustments.join(' and ')}.';
  }
}

class ReceiptStitchResult {
  const ReceiptStitchResult({
    required this.status,
    required this.inputPaths,
    required this.ocrSourcePaths,
    this.stitchedPath,
    this.confidence = 0,
    this.overlapPixels = const [],
    this.pairs = const [],
    this.failedPairIndex,
    this.stitchedWidth = 0,
    this.stitchedHeight = 0,
    this.warning = '',
    this.usedManualAdjustment = false,
    this.fallbackReasonCode = '',
  });

  const ReceiptStitchResult.notNeeded(List<String> paths)
    : this(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: paths,
        ocrSourcePaths: paths,
      );

  const ReceiptStitchResult.fallback({
    required List<String> inputPaths,
    required String warning,
    String fallbackReasonCode = 'unknown',
    double confidence = 0,
    int? failedPairIndex,
    List<ReceiptStitchPairResult> pairs = const [],
    int stitchedWidth = 0,
    int stitchedHeight = 0,
  }) : this(
         status: ReceiptStitchStatus.fallback,
         inputPaths: inputPaths,
         ocrSourcePaths: inputPaths,
         warning: warning,
         confidence: confidence,
         failedPairIndex: failedPairIndex,
         pairs: pairs,
         stitchedWidth: stitchedWidth,
         stitchedHeight: stitchedHeight,
         fallbackReasonCode: fallbackReasonCode,
       );

  final ReceiptStitchStatus status;
  final List<String> inputPaths;
  final List<String> ocrSourcePaths;
  final String? stitchedPath;
  final double confidence;
  final List<int> overlapPixels;
  final List<ReceiptStitchPairResult> pairs;
  final int? failedPairIndex;
  final int stitchedWidth;
  final int stitchedHeight;
  final String warning;
  final bool usedManualAdjustment;
  final String fallbackReasonCode;

  bool get didStitch => status == ReceiptStitchStatus.stitched;
  bool get usedFallback => status == ReceiptStitchStatus.fallback;
  bool get hasMultipleSections => inputPaths.length > 1;
  int get pairCount => inputPaths.length <= 1 ? 0 : inputPaths.length - 1;
  int get stitchedPixelCount => stitchedWidth * stitchedHeight;
  String get stitchedSizeLabel => stitchedWidth > 0 && stitchedHeight > 0
      ? '$stitchedWidth x $stitchedHeight'
      : '';

  String get failedPairLabel {
    final index = failedPairIndex;
    if (index == null) return '';
    return 'Photo ${index + 1} to ${index + 2}';
  }

  String get diagnosticReasonLabel {
    if (!usedFallback) return status.name;
    return fallbackReasonCode.trim().isEmpty ? 'unknown' : fallbackReasonCode;
  }

  String get userFallbackReasonLabel {
    if (!usedFallback) return '';
    return switch (diagnosticReasonLabel) {
      'decode_failed' => 'One photo could not be read',
      'manual_overlap_unsafe' => 'Manual overlap was outside the safe range',
      'overlap_confidence_low' => 'Overlap was not clear enough',
      'output_too_large' => 'Receipt is too long for this device',
      'stitch_exception' => 'Stitching hit a safe fallback',
      _ => 'Stitching was not trusted',
    };
  }

  String get matchConfidenceLabel {
    if (!hasMultipleSections || status == ReceiptStitchStatus.notNeeded) {
      return 'Match not needed';
    }
    if (usedManualAdjustment) return 'Manual match';
    return '${(confidence * 100).round()}% match';
  }

  String get pairDiagnosticsLabel {
    if (pairs.isEmpty) return '';
    return pairs.map((pair) => pair.userCheckLabel).join(' ');
  }

  String get diagnosticCodeLabel {
    if (usedFallback) return diagnosticReasonLabel;
    if (pairs.isEmpty) return status.name;
    return pairs.map((pair) => pair.diagnosticCode).join(',');
  }

  String get reviewPathLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? '1 photo to review'
            : '${inputPaths.length} photos to review',
      ReceiptStitchStatus.stitched => '1 combined receipt image',
      ReceiptStitchStatus.fallback =>
        '${inputPaths.length} photos top to bottom',
    };
  }

  String get reviewDecisionLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => reviewPathLabel,
      ReceiptStitchStatus.stitched => '$reviewPathLabel, $matchConfidenceLabel',
      ReceiptStitchStatus.fallback => '$reviewPathLabel, $matchConfidenceLabel',
    };
  }

  String get nextStepLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Next reviews this receipt photo.'
            : 'Next reviews these receipt sections in order.',
      ReceiptStitchStatus.stitched =>
        'Next reviews one combined receipt image.',
      ReceiptStitchStatus.fallback =>
        'Next opens the filled receipt review from each section, top to bottom.',
    };
  }

  String get stitchSafetyLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => 'No stitch needed',
      ReceiptStitchStatus.stitched =>
        usedManualAdjustment
            ? 'Manual match accepted'
            : 'Automatic match accepted',
      ReceiptStitchStatus.fallback => 'Stitch not trusted',
    };
  }

  String get summaryLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Single receipt photo ready for review.'
            : 'Receipt photos ready for review.',
      ReceiptStitchStatus.stitched =>
        'Receipt photos combined for app-assisted review.',
      ReceiptStitchStatus.fallback =>
        'Receipt photos will be reviewed separately.',
    };
  }

  String get detailLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'One photo was prepared for receipt review.'
            : '${inputPaths.length} photos were prepared for receipt review.',
      ReceiptStitchStatus.stitched =>
        '${inputPaths.length} photos became 1 receipt image${stitchedSizeLabel.isEmpty ? '' : ' ($stitchedSizeLabel)'}. ${usedManualAdjustment ? 'Manual match was used.' : 'Photo match confidence ${(confidence * 100).round()}%.'}${pairDiagnosticsLabel.isEmpty ? '' : ' $pairDiagnosticsLabel'}',
      ReceiptStitchStatus.fallback =>
        warning.trim().isEmpty
            ? '${inputPaths.length} photos stayed separate because stitching confidence was too low.'
            : failedPairLabel.isEmpty
            ? warning
            : '$failedPairLabel: $warning',
    };
  }

  ReceiptStitchResult copyForFinalOcr({
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    String? stitchedPath,
  }) {
    return ReceiptStitchResult(
      status: status,
      inputPaths: inputPaths,
      ocrSourcePaths: ocrSourcePaths,
      stitchedPath: stitchedPath ?? this.stitchedPath,
      confidence: confidence,
      overlapPixels: overlapPixels,
      pairs: pairs,
      failedPairIndex: failedPairIndex,
      stitchedWidth: stitchedWidth,
      stitchedHeight: stitchedHeight,
      warning: warning,
      usedManualAdjustment: usedManualAdjustment,
      fallbackReasonCode: fallbackReasonCode,
    );
  }
}

enum ReceiptCameraCaptureMode { singleImage, bestShotCandidates }

class ReceiptCameraResult {
  const ReceiptCameraResult({
    required this.photoPaths,
    required this.mode,
    this.qualityChecks = const [],
    this.captureEvidence,
  });

  const ReceiptCameraResult.single(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
    ReceiptCameraCaptureEvidence? captureEvidence,
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.singleImage,
         qualityChecks: qualityChecks,
         captureEvidence: captureEvidence,
       );

  const ReceiptCameraResult.bestShotCandidates(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
    ReceiptCameraCaptureEvidence? captureEvidence,
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.bestShotCandidates,
         qualityChecks: qualityChecks,
         captureEvidence: captureEvidence,
       );

  final List<String> photoPaths;
  final ReceiptCameraCaptureMode mode;
  final List<ReceiptPhotoQualityCheck> qualityChecks;
  final ReceiptCameraCaptureEvidence? captureEvidence;

  bool get isBestShotCandidateSet =>
      mode == ReceiptCameraCaptureMode.bestShotCandidates;

  ReceiptPhotoQualityCheck? get bestQualityCheck {
    if (qualityChecks.isEmpty) return null;
    return qualityChecks.reduce(
      (best, next) => next.reviewScore > best.reviewScore ? next : best,
    );
  }

  bool get hasQuestionablePhoto =>
      qualityChecks.any((quality) => quality.needsReview);

  String get qualitySummaryLabel {
    final best = bestQualityCheck;
    if (best == null) return 'Photo quality not checked';
    final count = qualityChecks.length;
    final prefix = count <= 1 ? 'Photo' : 'Best of $count photos';
    return '$prefix ${best.reviewScoreLabel}: ${best.primaryIssueLabel}';
  }

  ReceiptPhotoQualityCheck? qualityForIndex(int index) {
    if (index < 0 || index >= qualityChecks.length) return null;
    return qualityChecks[index];
  }
}

class ReceiptCameraCaptureEvidence {
  const ReceiptCameraCaptureEvidence({
    required this.captureSurface,
    required this.captureFlow,
    required this.resolutionTier,
    required this.resolutionPreset,
    required this.flashMode,
    required this.exposureMode,
    required this.focusMode,
    required this.exposurePointSupported,
    required this.focusPointSupported,
    required this.exposureOffset,
    required this.minExposureOffset,
    required this.maxExposureOffset,
    required this.zoomLevel,
    required this.minZoomLevel,
    required this.maxZoomLevel,
    required this.previewWidth,
    required this.previewHeight,
    required this.liveBrightness,
    required this.liveContrast,
    required this.liveFocusScore,
    required this.liveReadiness,
    required this.imageStreamActiveAtCapture,
    this.selectedExposureOffset,
    this.candidateExposureOffsets = const [],
  });

  final String captureSurface;
  final String captureFlow;
  final String resolutionTier;
  final String resolutionPreset;
  final String flashMode;
  final String exposureMode;
  final String focusMode;
  final bool exposurePointSupported;
  final bool focusPointSupported;
  final double? exposureOffset;
  final double? minExposureOffset;
  final double? maxExposureOffset;
  final double zoomLevel;
  final double minZoomLevel;
  final double maxZoomLevel;
  final int previewWidth;
  final int previewHeight;
  final double? liveBrightness;
  final double? liveContrast;
  final double? liveFocusScore;
  final String liveReadiness;
  final bool imageStreamActiveAtCapture;
  final double? selectedExposureOffset;
  final List<double?> candidateExposureOffsets;

  bool get usesNativeAutoExposure => exposureMode == 'auto';
  bool get exposureAtNativeBaseline {
    final offset = selectedExposureOffset ?? exposureOffset;
    if (offset == null) return true;
    return offset.abs() <= .05;
  }

  bool get hasDarkLiveFrame => (liveBrightness ?? 128) < 72;
  bool get hasUnderexposedLiveFrame => (liveBrightness ?? 128) < 92;
  bool get hasBrightLiveFrame => (liveBrightness ?? 128) > 222;

  String get brightnessSummaryLabel {
    if (liveBrightness == null) return 'Live brightness not measured';
    if (hasDarkLiveFrame) return 'Live preview was dark';
    if (hasUnderexposedLiveFrame) return 'Live preview was darker than ideal';
    if (hasBrightLiveFrame) return 'Live preview had glare';
    return 'Live preview brightness was normal';
  }

  String get exposureSummaryLabel {
    if (selectedExposureOffset == null && exposureOffset == null) {
      return 'Exposure offset not measured';
    }
    if (exposureAtNativeBaseline) return 'Native auto exposure baseline';
    final selected = selectedExposureOffset ?? exposureOffset ?? 0;
    final direction = selected > 0 ? 'brighter' : 'darker';
    return 'Bracketed $direction exposure candidate';
  }
}

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
    return (focusPoints +
            resolutionPoints +
            contrastPoints +
            cropPoints +
            textPoints -
            lightPenalty)
        .clamp(0, 100);
  }

  String get reviewScoreLabel => '$reviewScore%';
  bool get isTooDark => brightness < 68;
  bool get isUnderexposedForReceipt => brightness < 92;
  bool get isTooBright => brightness > 224;
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
    if (isReadableScore && isLikelyReadable) return false;
    if (reviewScore >= 80 && !isSoft && !isLowResolution) return false;
    return !isLikelyReadable || reviewScore < 70 || qualityWarnings.isNotEmpty;
  }

  bool get canContinueWithReview => !hasCriticalIssue;
  bool get shouldRetakeBeforeOcr => hasCriticalIssue || reviewScore < 50;
  String get nextReviewActionLabel {
    if (shouldRetakeBeforeOcr) return 'Retake before receipt review';
    if (needsReview) return 'Check photo, then tap Next';
    return 'Tap Next for filled receipt review';
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
      '$reviewBandLabel ($reviewScoreLabel)',
      'light $lightLabel',
      'focus $focusLabel',
      framingLabel,
    ];
    if (textBandScore < 8) parts.add('receipt lines weak');
    return parts.join(' • ');
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
      return 'This looks readable. Tap Next for the filled receipt review, or add another photo if the receipt continues.';
    }
    return 'Check the store, date, total, and item prices. If they are readable, tap Next; otherwise retake or add another photo.';
  }

  List<String> get qualityWarnings {
    return [
      if (isUnreadableImage) 'Image could not be decoded.',
      if (isTooDark) 'Photo is too dark.',
      if (!isTooDark && isUnderexposedForReceipt)
        'Photo is darker than ideal for receipt reading.',
      if (isTooBright) 'Photo has glare or is too bright.',
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
}

class ReceiptAttachmentRecord {
  const ReceiptAttachmentRecord({
    required this.id,
    required this.path,
    required this.kind,
    required this.dataSaverLevel,
    required this.createdAt,
    this.displayName = '',
    this.originalFileName = '',
    this.mimeType = '',
    this.importedText = '',
    this.byteSize,
    this.fileHash = '',
    this.pageCount,
    this.pageCountStatus = ReceiptPdfPageCountStatus.unknown,
    this.validationStatus = ReceiptPdfValidationStatus.notChecked,
    this.riskFlags = const [],
    this.documentSignals = const [],
    this.sourceLabel = '',
    this.linkedModule = '',
    this.linkedRecordId = '',
    this.isOriginalImmutable = true,
    this.storageState = ReceiptAttachmentStorageState.permanent,
    this.promotedAt,
    this.cleanedUpAt,
    this.readState = ReceiptAttachmentReadState.notRead,
    this.photoQualityScore,
    this.photoQualityIssueLabel = '',
    this.photoQualityWarnings = const [],
    this.photoWidth,
    this.photoHeight,
    this.photoBrightness,
    this.photoContrast,
    this.photoFocusScore,
    this.photoCropScore,
    this.photoTextBandScore,
  });

  factory ReceiptAttachmentRecord.fromMap(Map<dynamic, dynamic> map) {
    return ReceiptAttachmentRecord(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      kind: ReceiptAttachmentKind.fromName(map['kind'] as String?),
      dataSaverLevel: ReceiptDataSaverLevel.fromName(
        map['dataSaverLevel'] as String?,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      displayName: map['displayName'] as String? ?? '',
      originalFileName: map['originalFileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      importedText: map['importedText'] as String? ?? '',
      byteSize: (map['byteSize'] as num?)?.toInt(),
      fileHash: map['fileHash'] as String? ?? '',
      pageCount: (map['pageCount'] as num?)?.toInt(),
      pageCountStatus: ReceiptPdfPageCountStatus.fromName(
        map['pageCountStatus'] as String?,
      ),
      validationStatus: ReceiptPdfValidationStatus.fromName(
        map['validationStatus'] as String?,
      ),
      riskFlags:
          (map['riskFlags'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      documentSignals:
          (map['documentSignals'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      sourceLabel: map['sourceLabel'] as String? ?? '',
      linkedModule: map['linkedModule'] as String? ?? '',
      linkedRecordId: map['linkedRecordId'] as String? ?? '',
      isOriginalImmutable: map['isOriginalImmutable'] as bool? ?? true,
      storageState: ReceiptAttachmentStorageState.fromName(
        map['storageState'] as String?,
      ),
      promotedAt: DateTime.tryParse(map['promotedAt'] as String? ?? ''),
      cleanedUpAt: DateTime.tryParse(map['cleanedUpAt'] as String? ?? ''),
      readState: ReceiptAttachmentReadState.fromName(
        map['readState'] as String?,
      ),
      photoQualityScore: (map['photoQualityScore'] as num?)?.toInt(),
      photoQualityIssueLabel: map['photoQualityIssueLabel'] as String? ?? '',
      photoQualityWarnings:
          (map['photoQualityWarnings'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      photoWidth: (map['photoWidth'] as num?)?.toInt(),
      photoHeight: (map['photoHeight'] as num?)?.toInt(),
      photoBrightness: (map['photoBrightness'] as num?)?.toDouble(),
      photoContrast: (map['photoContrast'] as num?)?.toDouble(),
      photoFocusScore: (map['photoFocusScore'] as num?)?.toDouble(),
      photoCropScore: (map['photoCropScore'] as num?)?.toDouble(),
      photoTextBandScore: (map['photoTextBandScore'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String path;
  final ReceiptAttachmentKind kind;
  final ReceiptDataSaverLevel dataSaverLevel;
  final DateTime createdAt;
  final String displayName;
  final String originalFileName;
  final String mimeType;
  final String importedText;
  final int? byteSize;
  final String fileHash;
  final int? pageCount;
  final ReceiptPdfPageCountStatus pageCountStatus;
  final ReceiptPdfValidationStatus validationStatus;
  final List<String> riskFlags;
  final List<String> documentSignals;
  final String sourceLabel;
  final String linkedModule;
  final String linkedRecordId;
  final bool isOriginalImmutable;
  final ReceiptAttachmentStorageState storageState;
  final DateTime? promotedAt;
  final DateTime? cleanedUpAt;
  final ReceiptAttachmentReadState readState;
  final int? photoQualityScore;
  final String photoQualityIssueLabel;
  final List<String> photoQualityWarnings;
  final int? photoWidth;
  final int? photoHeight;
  final double? photoBrightness;
  final double? photoContrast;
  final double? photoFocusScore;
  final double? photoCropScore;
  final double? photoTextBandScore;

  bool get isPhoto => kind == ReceiptAttachmentKind.photo;
  bool get isPdf => kind == ReceiptAttachmentKind.pdf;
  bool get isImportedText =>
      kind == ReceiptAttachmentKind.emailText ||
      kind == ReceiptAttachmentKind.textMessageText;
  bool get isReadOnlyProof => isOriginalImmutable && !isImportedText;
  bool get canEditProofFileInApp => false;
  bool get hasPhotoQualityReview =>
      isPhoto &&
      (photoQualityScore != null ||
          photoQualityIssueLabel.trim().isNotEmpty ||
          photoQualityWarnings.isNotEmpty);
  bool get photoQualityNeedsReview =>
      hasPhotoQualityReview &&
      ((photoQualityScore ?? 100) < 80 || photoQualityWarnings.isNotEmpty);

  String get photoQualityLabel {
    final score = photoQualityScore;
    if (score == null) return '';
    final issue = photoQualityIssueLabel.trim();
    if (issue.isEmpty) return 'Photo quality $score%';
    return 'Photo quality $score%: $issue';
  }

  String get proofAccessLabel {
    if (isImportedText) return 'editable receipt text';
    if (isPdf) return 'read-only PDF proof';
    return 'read-only receipt photo';
  }

  String get label {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    return switch (kind) {
      ReceiptAttachmentKind.photo => 'Receipt photo',
      ReceiptAttachmentKind.pdf => 'Receipt PDF',
      ReceiptAttachmentKind.emailText => 'Receipt text',
      ReceiptAttachmentKind.textMessageText => 'Receipt text',
    };
  }

  ReceiptAttachmentRecord copyWith({
    String? id,
    String? path,
    ReceiptAttachmentKind? kind,
    ReceiptDataSaverLevel? dataSaverLevel,
    DateTime? createdAt,
    String? displayName,
    String? originalFileName,
    String? mimeType,
    String? importedText,
    int? byteSize,
    String? fileHash,
    int? pageCount,
    ReceiptPdfPageCountStatus? pageCountStatus,
    ReceiptPdfValidationStatus? validationStatus,
    List<String>? riskFlags,
    List<String>? documentSignals,
    String? sourceLabel,
    String? linkedModule,
    String? linkedRecordId,
    bool? isOriginalImmutable,
    ReceiptAttachmentStorageState? storageState,
    DateTime? promotedAt,
    DateTime? cleanedUpAt,
    ReceiptAttachmentReadState? readState,
    int? photoQualityScore,
    String? photoQualityIssueLabel,
    List<String>? photoQualityWarnings,
    int? photoWidth,
    int? photoHeight,
    double? photoBrightness,
    double? photoContrast,
    double? photoFocusScore,
    double? photoCropScore,
    double? photoTextBandScore,
  }) {
    return ReceiptAttachmentRecord(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      dataSaverLevel: dataSaverLevel ?? this.dataSaverLevel,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      originalFileName: originalFileName ?? this.originalFileName,
      mimeType: mimeType ?? this.mimeType,
      importedText: importedText ?? this.importedText,
      byteSize: byteSize ?? this.byteSize,
      fileHash: fileHash ?? this.fileHash,
      pageCount: pageCount ?? this.pageCount,
      pageCountStatus: pageCountStatus ?? this.pageCountStatus,
      validationStatus: validationStatus ?? this.validationStatus,
      riskFlags: riskFlags ?? this.riskFlags,
      documentSignals: documentSignals ?? this.documentSignals,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      linkedModule: linkedModule ?? this.linkedModule,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      isOriginalImmutable: isOriginalImmutable ?? this.isOriginalImmutable,
      storageState: storageState ?? this.storageState,
      promotedAt: promotedAt ?? this.promotedAt,
      cleanedUpAt: cleanedUpAt ?? this.cleanedUpAt,
      readState: readState ?? this.readState,
      photoQualityScore: photoQualityScore ?? this.photoQualityScore,
      photoQualityIssueLabel:
          photoQualityIssueLabel ?? this.photoQualityIssueLabel,
      photoQualityWarnings: photoQualityWarnings ?? this.photoQualityWarnings,
      photoWidth: photoWidth ?? this.photoWidth,
      photoHeight: photoHeight ?? this.photoHeight,
      photoBrightness: photoBrightness ?? this.photoBrightness,
      photoContrast: photoContrast ?? this.photoContrast,
      photoFocusScore: photoFocusScore ?? this.photoFocusScore,
      photoCropScore: photoCropScore ?? this.photoCropScore,
      photoTextBandScore: photoTextBandScore ?? this.photoTextBandScore,
    );
  }

  ReceiptAttachmentRecord withPhotoQuality(ReceiptPhotoQualityCheck? quality) {
    if (quality == null || !isPhoto) return this;
    final qualityReadState = quality.isLikelyReadable
        ? readState
        : readState == ReceiptAttachmentReadState.readIntoForm
        ? readState
        : ReceiptAttachmentReadState.unreadable;
    return copyWith(
      photoQualityScore: quality.reviewScore,
      photoQualityIssueLabel: quality.primaryIssueLabel,
      photoQualityWarnings: quality.qualityWarnings,
      photoWidth: quality.width,
      photoHeight: quality.height,
      photoBrightness: quality.brightness,
      photoContrast: quality.contrast,
      photoFocusScore: quality.focusScore,
      photoCropScore: quality.cropScore,
      photoTextBandScore: quality.textBandScore,
      readState: qualityReadState,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'kind': kind.name,
      'dataSaverLevel': dataSaverLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'displayName': displayName,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'importedText': importedText,
      'byteSize': byteSize,
      'fileHash': fileHash,
      'pageCount': pageCount,
      'pageCountStatus': pageCountStatus.name,
      'validationStatus': validationStatus.name,
      'riskFlags': riskFlags,
      'documentSignals': documentSignals,
      'sourceLabel': sourceLabel,
      'linkedModule': linkedModule,
      'linkedRecordId': linkedRecordId,
      'isOriginalImmutable': isOriginalImmutable,
      'storageState': storageState.name,
      'promotedAt': promotedAt?.toIso8601String(),
      'cleanedUpAt': cleanedUpAt?.toIso8601String(),
      'readState': readState.name,
      'photoQualityScore': photoQualityScore,
      'photoQualityIssueLabel': photoQualityIssueLabel,
      'photoQualityWarnings': photoQualityWarnings,
      'photoWidth': photoWidth,
      'photoHeight': photoHeight,
      'photoBrightness': photoBrightness,
      'photoContrast': photoContrast,
      'photoFocusScore': photoFocusScore,
      'photoCropScore': photoCropScore,
      'photoTextBandScore': photoTextBandScore,
    };
  }
}

enum ReceiptPdfPageCountStatus {
  verified('Verified'),
  estimated('Estimated'),
  unknown('Unknown'),
  failed('Failed');

  const ReceiptPdfPageCountStatus(this.label);

  final String label;

  static ReceiptPdfPageCountStatus fromName(String? name) {
    return ReceiptPdfPageCountStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptPdfPageCountStatus.unknown,
    );
  }
}

enum ReceiptPdfValidationStatus {
  notChecked('Not checked'),
  valid('Valid PDF'),
  missing('Missing'),
  empty('Empty'),
  invalidHeader('Invalid PDF'),
  tooLarge('Too large'),
  pageCountUnknown('Page count unknown'),
  failed('Validation failed');

  const ReceiptPdfValidationStatus(this.label);

  final String label;

  static ReceiptPdfValidationStatus fromName(String? name) {
    return ReceiptPdfValidationStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptPdfValidationStatus.notChecked,
    );
  }
}

enum ReceiptPdfHandlingDisposition {
  blocked('Cannot attach'),
  proofOnly('Save as proof only'),
  assistedReadReady('Can fill receipt'),
  assistedReadWithWarning('Can fill receipt with review');

  const ReceiptPdfHandlingDisposition(this.label);

  final String label;
}

enum ReceiptAttachmentStorageState {
  staged('Staged'),
  permanent('Saved proof'),
  missing('Missing'),
  cleanedUp('Cleaned up');

  const ReceiptAttachmentStorageState(this.label);

  final String label;

  static ReceiptAttachmentStorageState fromName(String? name) {
    return ReceiptAttachmentStorageState.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentStorageState.permanent,
    );
  }
}

enum ReceiptAttachmentReadState {
  notRead('Saved proof only'),
  readIntoForm('Read into form'),
  unreadable('Saved, not readable');

  const ReceiptAttachmentReadState(this.label);

  final String label;

  static ReceiptAttachmentReadState fromName(String? name) {
    return ReceiptAttachmentReadState.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentReadState.notRead,
    );
  }
}

enum ReceiptAttachmentKind {
  photo,
  pdf,
  emailText,
  textMessageText;

  static ReceiptAttachmentKind fromName(String? name) {
    return ReceiptAttachmentKind.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptAttachmentKind.photo,
    );
  }
}

enum ReceiptDataSaverLevel {
  original('Original', 'Local only', 'Keep the full source file locally.'),
  light('High Quality', '500-700 KB', 'Larger backup image for easier review.'),
  balanced('Normal', '200-300 KB', 'Everyday black-and-white backup image.'),
  strong(
    'Low Storage',
    '100-150 KB',
    'Smaller backup image with extra contrast.',
  ),
  maximum('Tiny Backup', '40-100 KB', 'Smallest backup image. Review first.');

  const ReceiptDataSaverLevel(this.label, this.shortLabel, this.description);

  final String label;
  final String shortLabel;
  final String description;

  bool get usesGrayscale =>
      this == ReceiptDataSaverLevel.balanced ||
      this == ReceiptDataSaverLevel.strong ||
      this == ReceiptDataSaverLevel.maximum;

  static ReceiptDataSaverLevel fromName(String? name) {
    return ReceiptDataSaverLevel.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReceiptDataSaverLevel.balanced,
    );
  }
}

class ReceiptStorageFormatter {
  const ReceiptStorageFormatter._();

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
    return '$bytes bytes';
  }
}
