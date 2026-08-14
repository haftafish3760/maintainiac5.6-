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
    await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles(
      paths,
      keptPaths: keptReceiptPhotoPaths,
    );
  }
}
