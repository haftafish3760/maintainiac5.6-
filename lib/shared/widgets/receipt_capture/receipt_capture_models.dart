class ReceiptPhotoReviewResult {
  const ReceiptPhotoReviewResult({
    required this.photoPaths,
    required this.ocrSourcePhotoPaths,
    required this.dataSaverLevel,
    required this.stitchResult,
    this.photoQualityChecksByPath = const {},
  });

  final List<String> photoPaths;
  final List<String> ocrSourcePhotoPaths;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptStitchResult stitchResult;
  final Map<String, ReceiptPhotoQualityCheck> photoQualityChecksByPath;
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
        '${inputPaths.length} photos became 1 receipt image${stitchedSizeLabel.isEmpty ? '' : ' ($stitchedSizeLabel)'}. ${usedManualAdjustment ? 'Manual match was used.' : 'Photo match confidence ${(confidence * 100).round()}%.'}',
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
    );
  }
}

enum ReceiptCameraCaptureMode { singleImage, bestShotCandidates }

class ReceiptCameraResult {
  const ReceiptCameraResult({
    required this.photoPaths,
    required this.mode,
    this.qualityChecks = const [],
  });

  const ReceiptCameraResult.single(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.singleImage,
         qualityChecks: qualityChecks,
       );

  const ReceiptCameraResult.bestShotCandidates(
    List<String> photoPaths, {
    List<ReceiptPhotoQualityCheck> qualityChecks = const [],
  }) : this(
         photoPaths: photoPaths,
         mode: ReceiptCameraCaptureMode.bestShotCandidates,
         qualityChecks: qualityChecks,
       );

  final List<String> photoPaths;
  final ReceiptCameraCaptureMode mode;
  final List<ReceiptPhotoQualityCheck> qualityChecks;

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
  bool get needsReview => !isLikelyReadable || qualityWarnings.isNotEmpty;
  bool get canContinueWithReview => !hasCriticalIssue;

  String get focusLabel {
    if (focusScore >= 14) return 'sharp';
    if (focusScore >= 8) return 'usable';
    return 'may be blurry';
  }

  String get lightLabel {
    if (isTooDark) return 'too dark';
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
    if (isLowResolution) return 'move closer';
    if (isLowContrast) return 'low contrast';
    if (isPoorlyFramed) return 'check that no text is cut off';
    if (isMissingTextBands) return 'printed lines are weak';
    return 'looks readable';
  }

  String get reviewTitle {
    if (hasCriticalIssue) return 'Retake Recommended';
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
    if (isLowResolution) {
      return 'If item text is too small, add another closer photo. Otherwise continue.';
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
    return 'The receipt looks ready. Tap Next, or add another photo if the receipt continues.';
  }

  List<String> get qualityWarnings {
    return [
      if (isUnreadableImage) 'Image could not be decoded.',
      if (isTooDark) 'Photo is too dark.',
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
  light(
    'High Quality',
    '500-700 KB',
    'Larger saved proof copy for easier review.',
  ),
  balanced(
    'Normal',
    '200-300 KB',
    'Everyday black-and-white saved proof copy.',
  ),
  strong(
    'Low Storage',
    '100-150 KB',
    'Smaller saved proof copy with extra contrast.',
  ),
  maximum('Tiny Backup', '40-100 KB', 'Smallest saved proof. Review first.');

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
