part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentReviewReadActions
    on _SharedReceiptAttachmentPanelState {
  Future<bool> reviewPickedPhotoPaths(
    List<String> paths, {
    Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> initialCaptureDiagnosticsByPath =
        const {},
  }) async {
    final importOrder = ReceiptPhotoImportOrderPlan.build(
      existingPhotoPaths: _photoPaths,
      importedPhotoPaths: paths,
    );
    if (!importOrder.hasNewPhotos) return true;
    final previousPhotoIdByPath = {..._photoIdByPath};
    final previousPhotoReadStateByPath = {..._photoReadStateByPath};
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          uiConfig: widget.uiConfig.review,
          initialPhotoPaths: importOrder.mergedPhotoPaths,
          initialDataSaverLevel: _dataSaverLevel,
          initialSelectedIndex: importOrder.firstImportedPhotoIndex,
          initialQualityChecksByPath: {
            ..._photoQualityByPath,
            ...initialQualityChecksByPath,
          },
          initialCaptureDiagnosticsByPath: {
            ..._photoCaptureDiagnosticsByPath,
            ...initialCaptureDiagnosticsByPath,
          },
          assistedReceiptFill: _appAssistedReceiptFillEnabled,
        ),
      ),
    );
    if (result == null || !mounted) return false;
    final accepted = await _acceptReviewedPhotoResult(
      result,
      previousPhotoIdByPath: previousPhotoIdByPath,
      previousPhotoReadStateByPath: previousPhotoReadStateByPath,
    );
    return accepted && mounted;
  }

  Future<bool> _acceptReviewedPhotoResult(
    ReceiptPhotoReviewResult result, {
    Map<String, String>? previousPhotoIdByPath,
    Map<String, ReceiptAttachmentReadState>? previousPhotoReadStateByPath,
  }) async {
    final existingPhotoIdByPath = previousPhotoIdByPath ?? {..._photoIdByPath};
    final existingPhotoReadStateByPath =
        previousPhotoReadStateByPath ?? {..._photoReadStateByPath};
    updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _photoIdByPath
        ..clear()
        ..addEntries([
          for (final path in result.photoPaths)
            if (_previousReceiptPhotoMapValue(existingPhotoIdByPath, path)
                case final photoId?)
              MapEntry(path, photoId),
        ]);
      _photoQualityByPath
        ..clear()
        ..addAll(result.photoQualityChecksByPath);
      _photoCaptureDiagnosticsByPath
        ..clear()
        ..addAll(result.captureDiagnosticsByPhotoPath);
      _photoReadStateByPath
        ..clear()
        ..addEntries(
          result.photoPaths.map(
            (path) => MapEntry(
              path,
              _previousReceiptPhotoMapValue(
                    existingPhotoReadStateByPath,
                    path,
                  ) ??
                  ReceiptAttachmentReadState.notRead,
            ),
          ),
        );
      _dataSaverLevel = result.dataSaverLevel;
      _needsBottomReceiptSection = false;
    });
    publishAttachmentChange();
    widget.onReceiptPhotoReviewAccepted?.call(result);
    if (_pauseReviewedPhotoReadUntilNextSection(result)) return true;
    _startReviewedPhotoReadStatus(result);
    final readResult = await _readReviewedPhotosForReceiptForm(result);
    unawaited(
      deleteTemporaryOcrPhotos(
        result.ocrSourcePhotoPaths,
        keptReceiptPhotoPaths: result.photoPaths,
      ),
    );
    if (!mounted) return false;
    mergeOcrTotalsEvidenceIntoAcceptedPhotoDiagnostics(result, readResult);
    markReviewedPhotosReadState(result, readResult);
    return true;
  }

  Future<void> reviewReceiptPhotos() async {
    if (_photoPaths.isEmpty) return;
    final previousPhotoIdByPath = {..._photoIdByPath};
    final previousPhotoReadStateByPath = {..._photoReadStateByPath};
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          uiConfig: widget.uiConfig.review,
          initialPhotoPaths: _photoPaths,
          initialDataSaverLevel: _dataSaverLevel,
          initialQualityChecksByPath: _photoQualityByPath,
          initialCaptureDiagnosticsByPath: _photoCaptureDiagnosticsByPath,
          assistedReceiptFill: _appAssistedReceiptFillEnabled,
        ),
      ),
    );
    if (result == null || !mounted) return;
    updateAttachmentState(() {
      _photoPaths
        ..clear()
        ..addAll(result.photoPaths);
      _photoIdByPath
        ..clear()
        ..addEntries([
          for (final path in result.photoPaths)
            if (_previousReceiptPhotoMapValue(previousPhotoIdByPath, path)
                case final photoId?)
              MapEntry(path, photoId),
        ]);
      _photoQualityByPath
        ..clear()
        ..addAll(result.photoQualityChecksByPath);
      _photoCaptureDiagnosticsByPath
        ..clear()
        ..addAll(result.captureDiagnosticsByPhotoPath);
      _photoReadStateByPath
        ..clear()
        ..addEntries(
          result.photoPaths.map(
            (path) => MapEntry(
              path,
              _previousReceiptPhotoMapValue(
                    previousPhotoReadStateByPath,
                    path,
                  ) ??
                  ReceiptAttachmentReadState.notRead,
            ),
          ),
        );
      _dataSaverLevel = result.dataSaverLevel;
      _needsBottomReceiptSection = false;
    });
    publishAttachmentChange();
    widget.onReceiptPhotoReviewAccepted?.call(result);
    if (_pauseReviewedPhotoReadUntilNextSection(result)) return;
    _startReviewedPhotoReadStatus(result);
    final readResult = await _readReviewedPhotosForReceiptForm(result);
    unawaited(
      deleteTemporaryOcrPhotos(
        result.ocrSourcePhotoPaths,
        keptReceiptPhotoPaths: result.photoPaths,
      ),
    );
    if (!mounted) return;
    mergeOcrTotalsEvidenceIntoAcceptedPhotoDiagnostics(result, readResult);
    markReviewedPhotosReadState(result, readResult);
  }

  void _startReviewedPhotoReadStatus(ReceiptPhotoReviewResult result) {
    if (widget.onImportedText == null) return;
    if (!_appAssistedReceiptFillEnabled) return;
    widget.onReceiptReadStarted?.call();
    final reviewDecision = result.nextReviewHandoffLabel;
    final action = result.acceptedPhotoHandoffActionLabel;
    final processing = result.acceptedPhotoHandoffProcessingLabel;
    final proofCount = result.savedProofCountLabel;
    final ocrSourceCount = result.ocrSourceCountLabel;
    final qualitySummary = _reviewedPhotoOcrSourceQualitySummary(result);
    updateAttachmentState(() {
      _readingForReview = true;
      _needsBottomReceiptSection = false;
      _receiptReadStatus = _ReceiptReadStatusKind.reading;
      _receiptReadProgressPhase = _ReceiptReadProgressPhase.accepted;
      _receiptReadStatusMessage =
          'Photo review accepted. $processing $proofCount ready. Clear photo versions: $ocrSourceCount. $qualitySummary $reviewDecision $action';
    });
  }

  bool _pauseReviewedPhotoReadUntilNextSection(
    ReceiptPhotoReviewResult result,
  ) {
    if (!result.needsAnotherReceiptSectionBeforeDetails) return false;
    if (result.userConfirmedPossiblePartialReceiptComplete) return false;
    final nextStep = result.acceptedPhotoHandoffNextStepLabel;
    final evidence = result.finalReceiptSectionContinuationEvidenceLabel;
    final route = result.acceptedPhotoHandoffRoute;
    updateAttachmentState(() {
      _readingForReview = false;
      _needsBottomReceiptSection = true;
      _receiptReadStatus = _ReceiptReadStatusKind.warning;
      _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
      _receiptReadStatusMessage =
          'Receipt photo saved. Add the bottom receipt section before receipt details open. $evidence $nextStep';
    });
    _publishReceiptCaptureDiagnostic({
      'captureFlow': 'maintainiac_native_receipt_camera',
      'receiptPhotoReviewPausedBeforeOcr': true,
      'receiptPhotoReviewPauseRoute': route,
      'receiptPhotoReviewPauseNextScreen':
          result.acceptedPhotoHandoffNextScreen,
      'receiptPhotoReviewPauseReason':
          result.firstPossiblePartialReceiptReasonCode,
      'receiptPhotoReviewPauseAction': result.acceptedPhotoHandoffUserAction,
      'receiptPhotoReviewPauseNextStep': nextStep,
      ...result.privacySafeReceiptReaderHandoffMetadata,
    });
    return true;
  }

  String _reviewedPhotoOcrSourceQualitySummary(
    ReceiptPhotoReviewResult result,
  ) {
    final qualities = <ReceiptPhotoQualityCheck>[
      for (var index = 0; index < result.ocrSourcePhotoPaths.length; index++)
        if (qualityForOcrSourceIndex(result, index) != null)
          qualityForOcrSourceIndex(result, index)!,
    ];
    if (qualities.isEmpty) return 'Photo quality was not measured.';
    var needsReview = 0;
    ReceiptPhotoQualityCheck? weakest;
    for (final quality in qualities) {
      if (quality.needsReview) needsReview += 1;
      if (weakest == null || quality.reviewScore < weakest.reviewScore) {
        weakest = quality;
      }
    }
    final weakestQuality = weakest;
    if (weakestQuality == null) return 'Photo quality was not measured.';
    if (needsReview <= 0) {
      return 'Photo quality ${weakestQuality.reviewScoreLabel}: looks readable.';
    }
    final sourceLabel = qualities.length == 1
        ? 'Clear photo'
        : '$needsReview of ${qualities.length} clear photos';
    return '$sourceLabel may need review: ${weakestQuality.primaryIssueLabel} (${weakestQuality.reviewScoreLabel}).';
  }

  Future<_ReceiptAttachmentReadResult> _readReviewedPhotosForReceiptForm(
    ReceiptPhotoReviewResult result,
  ) async {
    if (_pauseReviewedPhotoReadUntilNextSection(result)) {
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (!_appAssistedReceiptFillEnabled || widget.onImportedText == null) {
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved. Automatic receipt filling is turned off for this area.';
      });
      widget.onReceiptReadFinished?.call(false);
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (result.ocrSourcePhotoPaths.isEmpty) {
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved: ${result.savedProofCountLabel}. No clear photo version was available to fill the receipt details.';
      });
      widget.onReceiptReadFinished?.call(false);
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    final deferredPreparation = _usesDeferredSinglePhotoPreparation(result);
    final preparedArtifacts = <String>[];
    final ocrSourcePaths = [...result.ocrSourcePhotoPaths];
    ReceiptPhotoQualityCheck? preparedOcrQuality;
    var usedPreparedOcrSource = false;
    var usedOriginalOcrFallback = false;
    if (deferredPreparation) {
      final sourcePath = ocrSourcePaths.single;
      final cleanupSettings = ReceiptImageCleanupSettings.fromDiagnostics(
        _previousReceiptPhotoMapValue(
          result.captureDiagnosticsByPhotoPath,
          sourcePath,
        ),
      );
      try {
        updateAttachmentState(() {
          _receiptReadProgressPhase = _ReceiptReadProgressPhase.readingText;
          _receiptReadStatusMessage =
              'Preparing the receipt photo for clearer reading. Your editable receipt is already open.';
        });
        final preparation =
            await ReceiptImageProcessor.prepareReceiptSourceWithReport(
              path: sourcePath,
              cleanupSettings: cleanupSettings,
            );
        if (preparation.ocrSourcePath != sourcePath) {
          ocrSourcePaths[0] = preparation.ocrSourcePath;
          preparedArtifacts.add(preparation.ocrSourcePath);
          usedPreparedOcrSource = true;
        }
        preparedOcrQuality = preparation.ocrQuality;
        _recordDeferredPreparationDiagnostics(
          sourcePath: sourcePath,
          preparation: preparation,
        );
      } catch (_) {
        usedOriginalOcrFallback = true;
        _recordDeferredPreparationFallback(sourcePath);
      }
    }
    final now = DateTime.now();
    final ocrAttachments = [
      for (var index = 0; index < ocrSourcePaths.length; index++)
        ReceiptAttachmentRecord(
          id: 'RCOCR-${now.microsecondsSinceEpoch}-$index',
          path: ocrSourcePaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: result.dataSaverLevel,
          createdAt: now,
          byteSize: receiptAttachmentFileSize(ocrSourcePaths[index]),
          sourceLabel: usedPreparedOcrSource
              ? 'Maintainiac prepared OCR source photo'
              : 'Maintainiac OCR source photo',
          linkedModule: _receiptAttachmentLinkedModule,
          storageState: ReceiptAttachmentStorageState.staged,
          documentSignals: [
            ...ocrSourceDocumentSignalsFor(result, index),
            if (usedPreparedOcrSource)
              'receipt_ocr_source_deferred_preparation',
            if (usedOriginalOcrFallback)
              'receipt_ocr_source_deferred_preparation_fallback',
          ],
          riskFlags: ocrSourceRiskFlagsFor(result, index),
        ).withPhotoQuality(
          preparedOcrQuality ?? qualityForOcrSourceIndex(result, index),
        ),
    ];
    try {
      final successMessage = usedOriginalOcrFallback
          ? '${reviewedPhotoReadSuccessMessage(result.stitchResult)} The original photo was used because its clearer working copy could not be prepared.'
          : reviewedPhotoReadSuccessMessage(result.stitchResult);
      return await _readAttachmentsForReceiptForm(
        ocrAttachments,
        successMessage: successMessage,
        showDisabledMessage: false,
        showNoTextMessage: true,
      );
    } finally {
      unawaited(
        deleteTemporaryOcrPhotos(
          preparedArtifacts,
          keptReceiptPhotoPaths: result.photoPaths,
        ),
      );
    }
  }

  bool _usesDeferredSinglePhotoPreparation(ReceiptPhotoReviewResult result) {
    if (result.photoPaths.length != 1 ||
        result.ocrSourcePhotoPaths.length != 1) {
      return false;
    }
    final diagnostics = _previousReceiptPhotoMapValue(
      result.captureDiagnosticsByPhotoPath,
      result.photoPaths.single,
    );
    return diagnostics?['receiptPreparationOwner'] ==
        'receipt_reader_after_form_open';
  }

  void _recordDeferredPreparationDiagnostics({
    required String sourcePath,
    required ReceiptImagePreparationReport preparation,
  }) {
    if (!mounted) return;
    updateAttachmentState(() {
      final existing = _photoCaptureDiagnosticsByPath[sourcePath] ?? const {};
      _photoCaptureDiagnosticsByPath[sourcePath] = {
        ...existing,
        ...preparation.toDiagnostics(),
        'receiptPreparationOwner': 'receipt_reader_after_form_open',
        'receiptDeferredPreparationCompleted': true,
        'receiptDeferredOcrSourcePath': preparation.ocrSourcePath,
      };
    });
    publishAttachmentChange();
  }

  void _recordDeferredPreparationFallback(String sourcePath) {
    if (!mounted) return;
    updateAttachmentState(() {
      final existing = _photoCaptureDiagnosticsByPath[sourcePath] ?? const {};
      _photoCaptureDiagnosticsByPath[sourcePath] = {
        ...existing,
        'receiptPreparationOwner': 'receipt_reader_after_form_open',
        'receiptDeferredPreparationCompleted': false,
        'receiptDeferredPreparationFallback': 'original_source_used',
      };
    });
    publishAttachmentChange();
  }

  T? _previousReceiptPhotoMapValue<T>(
    Map<String, T> valuesByPath,
    String path,
  ) {
    final normalizedPath = normalizedReceiptPhotoPath(path);
    if (normalizedPath == null) return null;
    for (final entry in valuesByPath.entries) {
      if (normalizedReceiptPhotoPath(entry.key) == normalizedPath) {
        return entry.value;
      }
    }
    return null;
  }
}
