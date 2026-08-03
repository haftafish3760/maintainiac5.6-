part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSaveActions on _ReceiptPhotoReviewScreenState {
  void _requestStitchPreview() {
    if (!_reviewInteractiveControlsActive || _photoPaths.length <= 1) return;
    _updateReviewState(() => _stitchPreviewRequested = true);
    unawaited(_ensureStitchPreview(force: true));
  }

  Future<void> continueReceiptPhotoReview() async {
    if (_savingPhotos || _closingReview) return;
    if (_photoPaths.isEmpty) return;
    final completionDecision = await _confirmReceiptCompleteIfNeeded();
    if (completionDecision != _ReceiptContinueDecision.continueAnyway ||
        !_reviewWorkActive) {
      return;
    }
    if (_reviewMode != _ReceiptReviewMode.dataSaver &&
        _needsStitchReviewBeforeSave) {
      if (_reviewMode != _ReceiptReviewMode.stitch) {
        _setReviewMode(_ReceiptReviewMode.stitch);
        _requestStitchPreview();
        return;
      }
      if (_stitchPreviewResult == null) {
        await _ensureStitchPreview(force: true);
        return;
      }
      if (_stitchPreviewInFlight && _stitchPreviewResult == null) {
        _showCameraError(
          'Your receipt photos are still being combined. This can take a moment.',
        );
        return;
      }
      final stitchPreview = _stitchPreviewResult;
      if (stitchPreview != null &&
          (stitchPreview.fallbackReasonCode == 'duplicate_section_image' ||
              stitchPreview.fallbackReasonCode == 'duplicate_input_paths')) {
        final duplicateIndex = ((stitchPreview.failedPairIndex ?? 0) + 1).clamp(
          0,
          _photoPaths.length - 1,
        );
        _updateReviewState(() {
          _selectedIndex = duplicateIndex;
          _reviewMode = _ReceiptReviewMode.order;
        });
        _showCameraError(
          'These photos appear identical. Remove or replace the highlighted duplicate before continuing.',
        );
        return;
      }
    }
    // Every receipt gets a visible saved-image choice.  Lighting, faded ink,
    // and fine print differ from one receipt to the next, so a remembered
    // size is only the starting selection—not permission to skip its preview.
    if (!mounted || _reviewDisposed || _closingReview) return;
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (_reviewMode != _ReceiptReviewMode.dataSaver) {
      _updateReviewState(() {
        _reviewMode = _ReceiptReviewMode.dataSaver;
        _dataSaverOptionsVisible = true;
      });
      return;
    }
    if (_reviewMode == _ReceiptReviewMode.dataSaver && settings != null) {
      // Retain the last choice as a convenient starting point for the next
      // preview; it never suppresses the next saved-image step.
      await settings.setDefaultDataSaverLevel(_dataSaverLevel);
      if (!_reviewWorkActive || _closingReview) return;
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
      final stitchFuture = _finalStitchResultForOcr(
        inputPaths: pathsToSave,
        preparedOcrPaths: ocrSourcePaths,
      );
      final stitch = await stitchFuture.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // A stale preview can force a final assembly attempt. Never trap a
          // person on this screen because that work is slow: use the already
          // prepared clear sections in order, and remove a late temporary
          // composite if the isolate finishes after the fallback is accepted.
          unawaited(
            stitchFuture.then(
              (lateStitch) => _deleteStitchPreviewPath(lateStitch.stitchedPath),
              onError: (Object _) {},
            ),
          );
          return ReceiptStitchResult.fallback(
            inputPaths: ocrSourcePaths,
            warning:
                'Putting these photos together took too long. Receipt details will use them from top to bottom.',
            fallbackReasonCode: 'stitch_timeout',
          );
        },
      );
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
      _forgetAcceptedReceiptPrepArtifacts(generatedPrepArtifacts, {
        ...savedPaths,
        ...stitch.ocrSourcePaths,
        if (stitch.stitchedPath != null) stitch.stitchedPath!,
      });
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      await finishReceiptReview(
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
        'Preparing this receipt took too long. Your original photo is still open—try again, retake it, or continue by hand.',
      );
    } catch (_) {
      if (!_reviewWorkActive) return;
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError(
        'Could not prepare these receipt photos. Your original photo is still open—try again or return to review.',
      );
    }
  }

  void _stopReceiptReviewSave() {
    if (!_reviewWorkActive) return;
    _updateReviewState(() => _savingPhotos = false);
  }
}
