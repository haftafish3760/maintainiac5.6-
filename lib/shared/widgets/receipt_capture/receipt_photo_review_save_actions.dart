part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSaveActions on _ReceiptPhotoReviewScreenState {
  Future<void> continueReceiptPhotoReview() async {
    if (_savingPhotos || _closingReview) return;
    if (_photoPaths.isEmpty) return;
    final completionDecision = await _confirmReceiptCompleteIfNeeded();
    if (completionDecision != _ReceiptContinueDecision.continueAnyway ||
        !_reviewWorkActive) {
      return;
    }
    if (_needsStitchReviewBeforeSave) {
      if (_reviewMode != _ReceiptReviewMode.stitch) {
        _updateReviewState(() {
          _reviewMode = _ReceiptReviewMode.stitch;
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
    // A regular, unedited receipt has a single source image. Let the receipt
    // form open immediately; its reader owns preparation and shows progress
    // there. This keeps the user from waiting behind backup or stitch work.
    if (_canOpenSinglePhotoReceiptDetailsImmediately) {
      await _openSinglePhotoReceiptDetailsImmediately();
      return;
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
      _forgetAcceptedReceiptPrepArtifacts(generatedPrepArtifacts, {
        ...savedPaths,
        ...stitch.ocrSourcePaths,
        if (stitch.stitchedPath != null) stitch.stitchedPath!,
      });
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      final navigator = Navigator.of(context);
      if (!beginReceiptReviewClose()) return;
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

  bool get _canOpenSinglePhotoReceiptDetailsImmediately =>
      !widget.bestShotCandidateMode &&
      _photoPaths.length == 1 &&
      _generatedEditPaths.isEmpty;

  Future<void> _openSinglePhotoReceiptDetailsImmediately() async {
    final photoPath = _photoPaths.single;
    final navigator = Navigator.of(context);
    if (!await File(photoPath).exists()) {
      if (_reviewWorkActive) {
        _showCameraError(
          'This receipt photo is no longer available. Retake it or add the image again.',
        );
      }
      return;
    }
    if (!_reviewWorkActive) return;
    if (!beginReceiptReviewClose()) return;
    navigator.pop(
      ReceiptPhotoReviewResult(
        photoPaths: [photoPath],
        ocrSourcePhotoPaths: [photoPath],
        dataSaverLevel: _dataSaverLevel,
        stitchResult: ReceiptStitchResult.notNeeded([photoPath]),
        photoQualityChecksByPath: {photoPath: ?_qualityChecksByPath[photoPath]},
        captureDiagnosticsByPhotoPath: {
          photoPath: {
            ...?_captureDiagnosticsByPath[photoPath],
            'receiptReviewOpeningRoute': 'single_photo_details_immediate',
            'receiptPreparationOwner': 'receipt_reader_after_form_open',
          },
        },
      ),
    );
  }
}
