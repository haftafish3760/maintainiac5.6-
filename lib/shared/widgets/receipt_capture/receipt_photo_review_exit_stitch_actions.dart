part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewExitStitchActions
    on _ReceiptPhotoReviewScreenState {
  List<String> _receiptImagePathsForAcceptedSave(List<String> inputPaths) {
    final preview = _stitchPreviewResult;
    final previewMatchesCurrentReceipt =
        _stitchPreviewKey == _currentStitchPreviewKey() &&
        _sameReceiptPhotoOrder(inputPaths, _photoPaths);
    return acceptedReceiptImageSourcePaths(
      inputPaths: inputPaths,
      stitchResult: preview,
      stitchMatchesCurrentReceipt: previewMatchesCurrentReceipt,
    );
  }

  Future<void> _deleteUnusedBestShotCandidatePhotos(
    Set<String> keptPaths,
  ) async {
    if (!widget.bestShotCandidateMode) return;
    for (final path in _photoPaths) {
      if (_keptReceiptArtifactPathsContain(keptPaths, path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created Guided Capture candidates.
      }
    }
  }

  Future<void> _deleteGeneratedEditPhotos(Set<String> keptPaths) async {
    final generatedPaths = _generatedEditPaths.toList(growable: false);
    for (final path in generatedPaths) {
      if (_keptReceiptArtifactPathsContain(keptPaths, path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created edited receipt photos.
      } finally {
        _generatedEditPaths.remove(path);
      }
    }
  }

  bool _keptReceiptArtifactPathsContain(
    Set<String> keptPaths,
    String candidatePath,
  ) {
    return receiptPhotoPathSetContains(keptPaths, candidatePath);
  }

  Future<ReceiptStitchResult> _finalStitchResultForOcr({
    required List<String> inputPaths,
    required List<String> preparedOcrPaths,
  }) async {
    final preview = _stitchPreviewResult;
    final currentPathOrderMatches = _sameReceiptPhotoOrder(
      inputPaths,
      _photoPaths,
    );
    final previewCanBeUsed =
        preview != null &&
        _stitchPreviewKey == _currentStitchPreviewKey() &&
        currentPathOrderMatches;
    if (previewCanBeUsed && preview.didStitch && preparedOcrPaths.length == 1) {
      return preview.copyForFinalOcr(
        inputPaths: inputPaths,
        ocrSourcePaths: preparedOcrPaths,
        stitchedPath: preparedOcrPaths.single,
      );
    }
    if (previewCanBeUsed &&
        (preview.usedFallback ||
            preview.status == ReceiptStitchStatus.notNeeded)) {
      return preview.copyForFinalOcr(
        inputPaths: preparedOcrPaths,
        ocrSourcePaths: preparedOcrPaths,
      );
    }
    if (!previewCanBeUsed) {
      // Ordered original sections are the default OCR source. Do not hold a
      // complete long receipt hostage to a derived-image operation.
      return ReceiptStitchResult.notNeeded(preparedOcrPaths);
    }
    final previewPath = preview.stitchedPath;
    final stitchedPreviewCanBeCopied =
        preview.didStitch && previewPath != null && previewCanBeUsed;
    if (stitchedPreviewCanBeCopied && await File(previewPath).exists()) {
      final finalPath = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: previewPath,
      );
      return preview.copyForFinalOcr(
        inputPaths: preparedOcrPaths,
        ocrSourcePaths: [finalPath],
        stitchedPath: finalPath,
      );
    }

    // A new combine attempt here used to make Continue wait and could send a
    // perfectly usable receipt into the failure screen. The reviewed preview
    // above is safe to reuse when it exists; otherwise read the original
    // sections in order and keep moving.
    return ReceiptStitchResult.notNeeded(preparedOcrPaths);
  }

  bool _sameReceiptPhotoOrder(List<String> expected, List<String> current) {
    return receiptPhotoPathOrderMatches(expected, current);
  }

  Map<String, Map<String, Object?>> _preparationDiagnosticsForFinalOcrSources({
    required ReceiptStitchResult stitch,
    required Map<String, Map<String, Object?>> perSourceDiagnostics,
  }) {
    if (!stitch.didStitch || stitch.ocrSourcePaths.length != 1) {
      return Map.unmodifiable(perSourceDiagnostics);
    }
    final stitchedPath = stitch.ocrSourcePaths.single;
    final scannerDecisionCodes = <String>{
      for (final diagnostics in perSourceDiagnostics.values)
        ..._stringListFromDiagnostics(diagnostics['scannerDecisionCodes']),
      'ocr_source_stitched_selected',
    };
    final sourcePaths = [
      for (final path in stitch.inputPaths)
        if (path.trim().isNotEmpty) path.trim(),
    ];
    return Map.unmodifiable({
      ...perSourceDiagnostics,
      stitchedPath: {
        'ocrSourcePath': stitchedPath,
        'scannerDecisionCodes': scannerDecisionCodes.toList(growable: false),
        'stitchedOcrSource': true,
        'stitchedInputCount': stitch.inputPaths.length,
        'stitchedConfidence': stitch.confidence,
        'stitchedOverlapPixels': stitch.overlapPixels,
        'sourceOcrPaths': sourcePaths,
      },
    });
  }

  List<String> _stringListFromDiagnostics(Object? value) {
    if (value is! Iterable) return const [];
    return [
      for (final item in value)
        if (item.toString().trim().isNotEmpty) item.toString().trim(),
    ];
  }
}
