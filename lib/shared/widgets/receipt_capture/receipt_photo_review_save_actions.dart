part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSaveActions on _ReceiptPhotoReviewScreenState {
  Future<void> continueReceiptPhotoReview() async {
    if (_savingPhotos || _closingReview) return;
    if (_photoPaths.isEmpty) return;
    final canProceedFromCoverage = await _confirmReceiptCompleteIfNeeded();
    if (!canProceedFromCoverage) return;
    if (_needsStitchReviewBeforeSave) {
      if (_reviewMode != _ReceiptReviewMode.stitch) {
        _updateReviewState(() {
          _reviewMode = _ReceiptReviewMode.stitch;
          _controlsVisible = true;
        });
        unawaited(_ensureStitchPreview(force: true));
        return;
      }
      if (_stitchPreviewResult == null) {
        await _ensureStitchPreview(force: true);
        return;
      }
      if (_stitchPreviewInFlight) {
        _showCameraError(
          'Wait for the photo match check, then choose how receipt details should be filled.',
        );
        return;
      }
    }
    _updateReviewState(() => _savingPhotos = true);
    final pathsToSave = widget.bestShotCandidateMode
        ? [_photoPaths[_selectedIndex]]
        : List<String>.of(_photoPaths);
    final generatedPrepArtifacts = <String>{};
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!_reviewWorkActive) return;
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _savingPhotos = false);
        await _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.savePhotos),
        );
        return;
      }
      if (!storage.canVerify) {
        _showCameraError(
          storage.unknownMessage(ReceiptStoragePurpose.savePhotos),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showCameraError(storage.warningMessage());
      }
      final savedPaths = <String>[];
      final ocrSourcePaths = <String>[];
      final savedQualityChecks = <String, ReceiptPhotoQualityCheck>{};
      final preparationDiagnostics = <String, Map<String, Object?>>{};
      final captureDiagnostics = <String, Map<String, Object?>>{};
      for (final path in pathsToSave) {
        final cleanupSettings = ReceiptImageCleanupSettings.fromDiagnostics(
          _captureDiagnosticsByPath[path],
        );
        final prepared = await ReceiptImageProcessor.prepareForOcrAndBackup(
          path: path,
          level: _dataSaverLevel,
          cleanupSettings: cleanupSettings,
        ).timeout(const Duration(seconds: 20));
        if (!_reviewWorkActive || _closingReview) {
          _stopReceiptReviewSave();
          unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
          return;
        }
        savedPaths.add(prepared.backupPath);
        ocrSourcePaths.add(prepared.ocrSourcePath);
        generatedPrepArtifacts
          ..add(prepared.backupPath)
          ..add(prepared.ocrSourcePath);
        savedQualityChecks[prepared.backupPath] = prepared.quality;
        captureDiagnostics[prepared.backupPath] = _coverageDiagnosticsForPhoto(
          path,
          fallbackQuality: prepared.quality,
        );
        preparationDiagnostics[prepared.ocrSourcePath] = {
          ...prepared.preparation.toDiagnostics(),
          ...prepared.toStorageContractDiagnostics(),
        };
      }
      final stitch = await _finalStitchResultForOcr(
        inputPaths: pathsToSave,
        preparedOcrPaths: ocrSourcePaths,
      ).timeout(const Duration(seconds: 24));
      final finalPreparationDiagnostics =
          _preparationDiagnosticsForFinalOcrSources(
            stitch: stitch,
            perSourceDiagnostics: preparationDiagnostics,
          );
      if (!_reviewWorkActive || _closingReview) {
        _stopReceiptReviewSave();
        unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
        return;
      }
      await _deleteUnusedBestShotCandidatePhotos(pathsToSave.toSet());
      await _deleteGeneratedStitchPreview();
      await _deleteGeneratedEditPhotos({
        ...pathsToSave,
        ...savedPaths,
        ...ocrSourcePaths,
        ...stitch.ocrSourcePaths,
        if (stitch.stitchedPath != null) stitch.stitchedPath!,
      });
      if (!_reviewWorkActive || _closingReview) {
        _stopReceiptReviewSave();
        unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
        return;
      }
      if (!mounted || _reviewDisposed || _closingReview) {
        _stopReceiptReviewSave();
        unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
        return;
      }
      final navigator = Navigator.of(context);
      beginReceiptReviewClose();
      navigator.pop(
        ReceiptPhotoReviewResult(
          photoPaths: savedPaths,
          ocrSourcePhotoPaths: stitch.ocrSourcePaths,
          dataSaverLevel: _dataSaverLevel,
          stitchResult: stitch,
          photoQualityChecksByPath: savedQualityChecks,
          preparationDiagnosticsByOcrPath: finalPreparationDiagnostics,
          captureDiagnosticsByPhotoPath: captureDiagnostics,
        ),
      );
    } on TimeoutException {
      if (!_reviewWorkActive || _closingReview) return;
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError(
        'Receipt prep took too long. Try again, or retake the photo.',
      );
    } catch (_) {
      if (!_reviewWorkActive) return;
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError('Could not save these receipt photos.');
    }
  }

  void _stopReceiptReviewSave() {
    if (!_reviewWorkActive) return;
    _updateReviewState(() => _savingPhotos = false);
  }
}
