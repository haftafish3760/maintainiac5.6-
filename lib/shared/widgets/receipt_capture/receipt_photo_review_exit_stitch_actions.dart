part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewExitStitchActions
    on _ReceiptPhotoReviewScreenState {
  bool get _needsStitchReviewBeforeSave {
    return !widget.bestShotCandidateMode && _photoPaths.length > 1;
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
    final previewPath = preview?.stitchedPath;
    final currentPathOrderMatches = _sameReceiptPhotoOrder(
      inputPaths,
      _photoPaths,
    );
    final previewCanBeUsed =
        !_stitchPreviewInFlight &&
        preview?.didStitch == true &&
        previewPath != null &&
        _stitchPreviewKey == _currentStitchPreviewKey() &&
        currentPathOrderMatches;
    if (previewCanBeUsed && await File(previewPath).exists()) {
      final finalPath = await ReceiptImageProcessor.copyReceiptOcrArtifact(
        path: previewPath,
      );
      return preview!.copyForFinalOcr(
        inputPaths: preparedOcrPaths,
        ocrSourcePaths: [finalPath],
        stitchedPath: finalPath,
      );
    }

    final manualOverlapFractions = currentPathOrderMatches
        ? _manualOverlapFractions
              .map((value) => value ?? 0)
              .toList(growable: false)
        : const <double>[];
    return ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: preparedOcrPaths,
      manualOverlapFractions: manualOverlapFractions.any((value) => value > 0)
          ? manualOverlapFractions
          : null,
      maxOutputPixels: _stitchDeviceLimits.maxOutputPixels,
      maxOutputHeight: _stitchDeviceLimits.maxOutputHeight,
    );
  }

  bool _sameReceiptPhotoOrder(List<String> expected, List<String> current) {
    if (expected.length != current.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (expected[index] != current[index]) return false;
    }
    return true;
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
