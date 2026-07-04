part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentNativeSignalHelpers
    on _SharedReceiptAttachmentPanelState {
  List<ReceiptNativeSavedPhotoReviewWarning>
  savedPhotoWarningsForOcrSourceIndex(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final diagnostics = diagnosticsForOcrSourceIndex(result, index);
    return diagnostics
        .map(ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics)
        .whereType<ReceiptNativeSavedPhotoReviewWarning>()
        .toList(growable: false);
  }

  List<Map<String, Object?>> diagnosticsForOcrSourceIndex(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    if (result.ocrSourcePhotoPaths.length == 1 &&
        result.photoPaths.length > 1) {
      return [
        for (final path in result.photoPaths)
          ?_previousReceiptPhotoMapValue(
            result.captureDiagnosticsByPhotoPath,
            path,
          ),
      ];
    }
    if (index < 0 || index >= result.ocrSourcePhotoPaths.length) {
      return const [];
    }
    final ocrSourcePath = result.ocrSourcePhotoPaths[index];
    var diagnostics = _previousReceiptPhotoMapValue(
      result.captureDiagnosticsByPhotoPath,
      ocrSourcePath,
    );
    if (diagnostics == null && index < result.photoPaths.length) {
      diagnostics = _previousReceiptPhotoMapValue(
        result.captureDiagnosticsByPhotoPath,
        result.photoPaths[index],
      );
    }
    return diagnostics == null ? const [] : [diagnostics];
  }

  void markReviewedPhotosReadState(
    ReceiptPhotoReviewResult result,
    _ReceiptAttachmentReadResult readResult,
  ) {
    if (readResult.outcome == _ReceiptAttachmentReadOutcome.skipped) return;
    final readState = readResult.didRead
        ? ReceiptAttachmentReadState.readIntoForm
        : ReceiptAttachmentReadState.unreadable;
    updateAttachmentState(() {
      for (final path in result.photoPaths) {
        _photoReadStateByPath[path] = readState;
      }
    });
    publishAttachmentChange();
  }

  void mergeOcrTotalsEvidenceIntoAcceptedPhotoDiagnostics(
    ReceiptPhotoReviewResult result,
    _ReceiptAttachmentReadResult readResult,
  ) {
    final diagnostics = readResult.ocrDiagnostics;
    if (diagnostics == null || result.photoPaths.isEmpty) return;
    final evidence = diagnostics.receiptTotalsCoverageEvidenceDiagnostics;
    if (evidence.isEmpty) return;
    final targetPath = _receiptTotalsEvidenceTargetPhotoPath(result);
    if (targetPath == null) return;
    updateAttachmentState(() {
      final existing = _photoCaptureDiagnosticsByPath[targetPath] ?? const {};
      _photoCaptureDiagnosticsByPath[targetPath] = {
        ...existing,
        ...evidence,
        'receiptOcrTotalsEvidenceMerged': true,
        'receiptOcrTotalsEvidenceSource': 'accepted_photo_ocr_read',
        'receiptOcrTotalsEvidenceTarget': 'final_receipt_section',
        'receiptOcrTotalsEvidencePhotoCount': result.photoPaths.length,
        'receiptOcrTotalsEvidenceOcrSourceCount':
            result.ocrSourcePhotoPaths.length,
      };
    });
    publishAttachmentChange();
  }

  String? _receiptTotalsEvidenceTargetPhotoPath(
    ReceiptPhotoReviewResult result,
  ) {
    for (final path in result.photoPaths.reversed) {
      if (path.trim().isNotEmpty) return path;
    }
    return null;
  }

  ReceiptPhotoQualityCheck? qualityForOcrSourceIndex(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    if (result.ocrSourcePhotoPaths.length == 1 &&
        result.photoPaths.length > 1) {
      return _weakestPhotoQuality(
        result.photoPaths,
        result.photoQualityChecksByPath,
      );
    }
    if (index < 0 || index >= result.ocrSourcePhotoPaths.length) return null;
    final ocrSourcePath = result.ocrSourcePhotoPaths[index];
    final ocrQuality = _previousReceiptPhotoMapValue(
      result.photoQualityChecksByPath,
      ocrSourcePath,
    );
    if (ocrQuality != null) return ocrQuality;
    if (index < result.photoPaths.length) {
      return _previousReceiptPhotoMapValue(
        result.photoQualityChecksByPath,
        result.photoPaths[index],
      );
    }
    return null;
  }

  ReceiptPhotoQualityCheck? _weakestPhotoQuality(
    List<String> paths,
    Map<String, ReceiptPhotoQualityCheck> qualityByPath,
  ) {
    ReceiptPhotoQualityCheck? weakest;
    for (final path in paths) {
      final quality = _previousReceiptPhotoMapValue(qualityByPath, path);
      if (quality == null) continue;
      if (weakest == null || quality.reviewScore < weakest.reviewScore) {
        weakest = quality;
      }
    }
    return weakest;
  }

  String reviewedPhotoReadSuccessMessage(ReceiptStitchResult stitch) {
    if (stitch.didStitch) {
      return 'One combined receipt image was read. Review what Maintainiac filled in below.';
    }
    if (stitch.usedFallback && stitch.hasMultipleSections) {
      return 'Receipt photos were read from top to bottom. Review what Maintainiac filled in below.';
    }
    if (stitch.hasMultipleSections) {
      return 'Receipt photos were read together. Review what Maintainiac filled in below.';
    }
    return 'Receipt photo was read. Review what Maintainiac filled in below.';
  }

  Map<String, ReceiptPhotoQualityCheck> qualityChecksByPathForCameraResult(
    ReceiptCameraResult result,
  ) {
    if (!_cameraResultPhotoPathsAreUniqueAndNormalized(result.photoPaths)) {
      return const {};
    }
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (var index = 0; index < result.photoPaths.length; index++) {
      final quality = result.qualityForIndex(index);
      if (quality != null) checks[result.photoPaths[index]] = quality;
    }
    return checks;
  }

  bool _cameraResultPhotoPathsAreUniqueAndNormalized(List<String> paths) {
    final seen = <String>{};
    for (final path in paths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty || trimmed != path) return false;
      if (!seen.add(path)) return false;
    }
    return true;
  }

  Future<Map<String, ReceiptPhotoQualityCheck>> qualityChecksForPhotoPaths(
    List<String> paths,
  ) async {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (final path in paths) {
      try {
        checks[path] = await ReceiptImageProcessor.qualityCheckFile(path);
      } catch (_) {
        // The receipt can still be reviewed and read without an early badge.
      }
    }
    return checks;
  }

  Future<void> deleteTemporaryOcrPhotos(
    List<String> paths, {
    required List<String> keptReceiptPhotoPaths,
  }) async {
    final keptReceiptPhotos = keptReceiptPhotoPaths
        .map(_normalizedCleanupPath)
        .toSet();
    for (final sourcePath in paths) {
      if (!_shouldDeleteTemporaryOcrPhoto(sourcePath, keptReceiptPhotos)) {
        continue;
      }
      try {
        final file = File(sourcePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for generated OCR artifacts after OCR.
      }
    }
  }

  bool _shouldDeleteTemporaryOcrPhoto(
    String sourcePath,
    Set<String> keptReceiptPhotos,
  ) {
    final normalized = _normalizedCleanupPath(sourcePath);
    if (normalized.isEmpty || keptReceiptPhotos.contains(normalized)) {
      return false;
    }
    if (_isProtectedReceiptStoragePath(normalized)) return false;
    final systemTemp = _normalizedCleanupPath(Directory.systemTemp.path);
    if (systemTemp.isEmpty || !normalized.startsWith('$systemTemp/')) {
      return false;
    }
    final fileName = normalized.split('/').last;
    return fileName.startsWith('maintaniac_receipt_') &&
        fileName.endsWith('.jpg');
  }

  bool _isProtectedReceiptStoragePath(String normalizedPath) {
    return normalizedPath.contains('/receipt_proofs/') ||
        normalizedPath.contains('/receipt_proofs_staging/') ||
        normalizedPath.contains('/native_capture_recovery/');
  }

  String _normalizedCleanupPath(String sourcePath) {
    return sourcePath.trim().replaceAll('\\', '/');
  }
}
