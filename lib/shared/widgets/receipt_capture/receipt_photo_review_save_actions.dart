part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSaveActions on _ReceiptPhotoReviewScreenState {
  Future<void> _acceptCurrentStitchAndContinue() async {
    final preview = _stitchPreviewResult;
    final key = _stitchPreviewKey;
    if (preview == null || !preview.didStitch || key == null) return;
    if (key != _currentStitchPreviewKey()) return;
    _stitchDecisionState.accept(key);
    await continueReceiptPhotoReview();
  }

  Future<void> _rejectCurrentStitch() async {
    final preview = _stitchPreviewResult;
    final key = _stitchPreviewKey;
    if (preview == null || !preview.didStitch || key == null) return;
    if (key != _currentStitchPreviewKey()) return;
    _stitchDecisionState.reject(key);
    final rejectedPath = preview.stitchedPath;
    _updateReviewState(() {
      _stitchPreviewResult = ReceiptStitchResult.fallback(
        inputPaths: _photoPaths,
        warning:
            'You rejected the combined image. Your original photos are unchanged and will remain in order.',
        fallbackReasonCode: 'user_rejected_stitch',
        confidence: preview.confidence,
        failedPairIndex: preview.failedPairIndex,
        pairs: preview.pairs,
        stitchedWidth: preview.stitchedWidth,
        stitchedHeight: preview.stitchedHeight,
      );
      _manualAlignmentRequested = false;
    });
    await _deleteStitchPreviewPath(rejectedPath);
  }

  Future<void> continueReceiptPhotoReview() async {
    if (_savingPhotos || _closingReview) return;
    if (_photoPaths.isEmpty) return;
    if (_reviewMode == _ReceiptReviewMode.stitch &&
        _stitchPreviewResult?.didStitch == true &&
        !_stitchDecisionState.isAccepted(_stitchPreviewKey)) {
      _showCameraError(
        'Choose Use Combined Receipt, or reject it and continue with the original photos.',
      );
      return;
    }
    final completionDecision = await _confirmReceiptCompleteIfNeeded();
    if (completionDecision != _ReceiptContinueDecision.continueAnyway ||
        !_reviewWorkActive) {
      return;
    }
    final nextStep = receiptPhotoPipelineNextStep(
      sourcePhotoCount: _photoPaths.length,
      reviewingSavedImage: _reviewMode == _ReceiptReviewMode.dataSaver,
      reviewingLongReceipt: _reviewMode == _ReceiptReviewMode.stitch,
      stitchResult: _stitchPreviewResult,
    );
    // Every receipt gets a visible saved-image choice.  Lighting, faded ink,
    // and fine print differ from one receipt to the next, so a remembered
    // size is only the starting selection—not permission to skip its preview.
    if (!mounted || _reviewDisposed || _closingReview) return;
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (nextStep == ReceiptPhotoPipelineNextStep.reviewLongReceipt) {
      _setReviewMode(_ReceiptReviewMode.stitch);
      return;
    }
    if (nextStep == ReceiptPhotoPipelineNextStep.reviewSavedImage) {
      _updateReviewState(() {
        _reviewMode = _ReceiptReviewMode.dataSaver;
        _dataSaverOptionsVisible = true;
      });
      return;
    }
    if (nextStep == ReceiptPhotoPipelineNextStep.finalizeReceiptImage &&
        settings != null) {
      // Move to a dedicated, visible progress surface before any storage or
      // image work starts. A tap on Continue must never look like a dead UI.
      _updateReviewState(() => _savingPhotos = true);
      // Retain the last choice as a convenient starting point for the next
      // preview; it never suppresses the next saved-image step.
      await settings.setDefaultDataSaverLevel(_dataSaverLevel);
      if (!_reviewWorkActive || _closingReview) return;
    }
    if (!_savingPhotos) _updateReviewState(() => _savingPhotos = true);
    final pathsToSave = widget.bestShotCandidateMode
        ? [_photoPaths[_selectedIndex]]
        : List<String>.of(_photoPaths);
    final preparationStopwatch = Stopwatch()..start();
    traceReceiptPipelineStage(
      'receipt_photo_preparation_started',
      traceId: _receiptStitchTraceId,
      sourceCount: pathsToSave.length,
      deviceTier: _deviceCapability.tier.name,
      destination: 'editable_receipt_review',
    );
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
      final receiptImagePathsToPrepare = _receiptImagePathsForAcceptedSave(
        pathsToSave,
      );
      final preparedImages = await _prepareAcceptedReceiptImages(
        receiptImagePathsToPrepare,
      );
      for (var index = 0; index < receiptImagePathsToPrepare.length; index++) {
        final path = receiptImagePathsToPrepare[index];
        final prepared = preparedImages[index];
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
      final stitch = await stitchFuture;
      traceReceiptPipelineStage(
        'receipt_photo_preparation_ready_for_review',
        traceId: _receiptStitchTraceId,
        elapsedMs: preparationStopwatch.elapsedMilliseconds,
        sourceCount: pathsToSave.length,
        deviceTier: _deviceCapability.tier.name,
        destination: stitch.ocrSourceContractCode,
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
      traceReceiptPipelineStage(
        'receipt_photo_review_result_ready',
        traceId: _receiptStitchTraceId,
        elapsedMs: preparationStopwatch.elapsedMilliseconds,
        sourceCount: pathsToSave.length,
        deviceTier: _deviceCapability.tier.name,
        destination: 'close_photo_review',
      );
      await finishReceiptReview(
        ReceiptPhotoReviewResult(
          photoPaths: savedPaths,
          ocrSourcePhotoPaths: stitch.ocrSourcePaths,
          dataSaverLevel: _dataSaverLevel,
          stitchResult: stitch,
          photoQualityChecksByPath: savedQualityChecks,
          preparationDiagnosticsByOcrPath: finalPreparationDiagnostics,
          captureDiagnosticsByPhotoPath: captureDiagnostics,
          temporarySourcePhotoPaths: pathsToSave,
        ),
      );
    } on TimeoutException {
      if (!_reviewWorkActive || _closingReview) return;
      traceReceiptPipelineStage(
        'receipt_photo_preparation_timeout',
        traceId: _receiptStitchTraceId,
        elapsedMs: preparationStopwatch.elapsedMilliseconds,
        sourceCount: pathsToSave.length,
        deviceTier: _deviceCapability.tier.name,
        destination: 'return_to_photo_review',
      );
      unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts));
      _updateReviewState(() => _savingPhotos = false);
      _showCameraError(
        'Preparing this receipt took too long. Your original photo is still open—try again, retake it, or continue by hand.',
      );
    } catch (_) {
      if (!_reviewWorkActive) return;
      traceReceiptPipelineStage(
        'receipt_photo_preparation_failed',
        traceId: _receiptStitchTraceId,
        elapsedMs: preparationStopwatch.elapsedMilliseconds,
        sourceCount: pathsToSave.length,
        deviceTier: _deviceCapability.tier.name,
        destination: 'return_to_photo_review',
      );
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

  Future<List<ReceiptPreparedImage>> _prepareAcceptedReceiptImages(
    List<String> paths,
  ) async {
    if (paths.isEmpty) return const [];
    // Scanner cleanup is CPU-heavy. Running it on the UI isolate made the
    // progress screen appear frozen, while preparing every section serially
    // made a two-photo receipt inherit two separate 20-second waits. A low
    // capability device stays sequential; standard and flagship devices use
    // two bounded workers and retain the input order through Future.wait.
    final concurrentWorkers =
        _deviceCapability.tier == ReceiptCapabilityTier.light ? 1 : 2;
    final dataSaverLevel = _dataSaverLevel;
    final prepared = <ReceiptPreparedImage>[];
    for (var start = 0; start < paths.length; start += concurrentWorkers) {
      final end = math.min(start + concurrentWorkers, paths.length);
      var retainBatchResults = true;
      final completedArtifacts = <String>{};
      final tasks = <Future<ReceiptPreparedImage>>[];
      for (var index = start; index < end; index++) {
        final path = paths[index];
        final cleanupSettings = ReceiptImageCleanupSettings.fromDiagnostics(
          _captureDiagnosticsByPath[path],
        );
        final task = Isolate.run(
          () => ReceiptImageProcessor.prepareForOcrAndBackup(
            path: path,
            level: dataSaverLevel,
            cleanupSettings: cleanupSettings,
          ),
        );
        unawaited(
          task.then((result) async {
            final artifacts = {result.backupPath, result.ocrSourcePath};
            if (retainBatchResults) {
              completedArtifacts.addAll(artifacts);
              return;
            }
            await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles(
              artifacts,
              keptPaths: paths,
            );
          }, onError: (_) {}),
        );
        tasks.add(task.timeout(const Duration(seconds: 20)));
      }
      try {
        prepared.addAll(await Future.wait(tasks));
      } catch (_) {
        retainBatchResults = false;
        await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles(
          completedArtifacts,
          keptPaths: paths,
        );
        rethrow;
      }
    }
    return prepared;
  }
}
