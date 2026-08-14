part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentReviewReadActions
    on _SharedReceiptAttachmentPanelState {
  Future<ReceiptImportActionResult> reviewPickedPhotoPaths(
    List<String> paths, {
    ReceiptNativeCaptureStagingResult? stagedCapture,
    Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> initialCaptureDiagnosticsByPath =
        const {},
  }) async {
    final importOrder = ReceiptPhotoImportOrderPlan.build(
      existingPhotoPaths: _photoPaths,
      importedPhotoPaths: paths,
    );
    if (!importOrder.hasNewPhotos) {
      return const ReceiptImportActionResult.completed();
    }
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
    if (result == null || !mounted) {
      return const ReceiptImportActionResult.stayOnChooser();
    }
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      result.outcome,
      assistedReceiptFill: _appAssistedReceiptFillEnabled,
    );
    if (plan.discardStagedPhotos && stagedCapture != null) {
      try {
        await stagedCapture.discardStagedPhotos();
      } catch (_) {
        if (mounted) {
          showPickerError(
            'The staged receipt copy could not be discarded safely. It remains recoverable on this device.',
          );
        }
        return const ReceiptImportActionResult.stayOnChooser();
      }
    }
    if (plan.retainReviewedSources && stagedCapture != null) {
      try {
        await const ReceiptNativeCaptureStaging().checkpointReviewedCapture(
          stagedCapture,
          result,
        );
      } catch (_) {
        if (mounted) {
          showPickerError(
            'The reviewed receipt order could not be kept safely. Your staged photos remain recoverable; review them again before continuing.',
          );
        }
        return const ReceiptImportActionResult.stayOnChooser();
      }
    }
    final completed = await _completeReviewedPhotoResult(
      result,
      previousPhotoIdByPath: previousPhotoIdByPath,
      previousPhotoReadStateByPath: previousPhotoReadStateByPath,
    );
    if (!completed || !mounted) {
      return const ReceiptImportActionResult.stayOnChooser();
    }
    if (plan.retainReviewedSources && stagedCapture != null) {
      widget.controller?._retainNativeRecoveryManifest(
        stagedCapture.recoveryManifestPath,
      );
    }
    return ReceiptImportActionResult.reviewCompleted(result);
  }

  Future<bool> _completeReviewedPhotoResult(
    ReceiptPhotoReviewResult result, {
    Map<String, String>? previousPhotoIdByPath,
    Map<String, ReceiptAttachmentReadState>? previousPhotoReadStateByPath,
  }) async {
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      result.outcome,
      assistedReceiptFill: _appAssistedReceiptFillEnabled,
    );
    if (!plan.installReviewedPhotos) return true;
    if (plan.retainReviewedSources) {
      widget.controller?._retainAcceptedReceiptSources(result);
    }
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
    if (!plan.notifyReceiptDetails) return true;
    if (!_notifyReviewedPhotoAccepted(result)) return false;
    if (!plan.startReceiptRead) return true;
    if (_pauseReviewedPhotoReadUntilNextSection(result)) return true;
    final readResult = await _readAcceptedPhotosForReceiptForm(result);
    if (readResult == null) return true;
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
    final completed = await _completeReviewedPhotoResult(
      result,
      previousPhotoIdByPath: previousPhotoIdByPath,
      previousPhotoReadStateByPath: previousPhotoReadStateByPath,
    );
    if (completed && mounted && result.exitsReceiptFlow) {
      await _notifyReviewedPhotoExitRequested(result);
    }
  }

  Future<bool> _notifyReviewedPhotoExitRequested(
    ReceiptPhotoReviewResult result,
  ) async {
    if (!result.exitsReceiptFlow) return true;
    final onExitRequested = widget.onReceiptPhotoReviewExitRequested;
    if (onExitRequested == null) return true;
    try {
      await onExitRequested(result);
      return true;
    } catch (_) {
      if (!mounted) return false;
      showPickerError(
        'The receipt could not close safely. Your receipt photos are still on this device.',
      );
      return false;
    }
  }

  Future<_ReceiptAttachmentReadResult?> _readAcceptedPhotosForReceiptForm(
    ReceiptPhotoReviewResult result,
  ) async {
    if (_reviewedPhotoReadInFlight) {
      showPickerMessage('Receipt details are already being prepared.');
      return null;
    }
    _reviewedPhotoReadInFlight = true;
    try {
      _startReviewedPhotoReadStatus(result);
      return await _readReviewedPhotosForReceiptForm(result);
    } finally {
      _reviewedPhotoReadInFlight = false;
      if (widget.controller == null) {
        unawaited(
          deleteTemporaryOcrPhotos(
            result.ocrSourcePhotoPaths,
            keptReceiptPhotoPaths: result.photoPaths,
          ),
        );
      }
    }
  }

  void _startReviewedPhotoReadStatus(ReceiptPhotoReviewResult result) {
    if (widget.onImportedText == null &&
        widget.onReceiptOcrResultForReview == null) {
      return;
    }
    if (!_appAssistedReceiptFillEnabled) return;
    // This only presents the accepted-photo status. The actual OCR operation
    // reports its start in _readAttachmentsForReceiptForm, so the parent does
    // not receive two competing "reading" transitions for one receipt.
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

  bool _notifyReviewedPhotoAccepted(ReceiptPhotoReviewResult result) {
    final onAccepted = widget.onReceiptPhotoReviewAccepted;
    if (onAccepted == null) return true;
    try {
      onAccepted(result);
      return true;
    } catch (_) {
      if (!mounted) return false;
      updateAttachmentState(() {
        _readingForReview = false;
        _receiptReadStatus = _ReceiptReadStatusKind.failed;
        _receiptReadProgressPhase = _ReceiptReadProgressPhase.idle;
        _receiptReadStatusMessage =
            'Receipt photo saved, but the receipt details screen could not open. Keep the photo and continue filling the receipt by hand.';
      });
      showPickerError(
        'Receipt photo saved, but receipt details could not open. Keep the photo and continue filling the receipt by hand.',
      );
      return false;
    }
  }

  bool _pauseReviewedPhotoReadUntilNextSection(
    ReceiptPhotoReviewResult result,
  ) {
    if (!result.needsAnotherReceiptSectionBeforeDetails) return false;
    if (result.userConfirmedPossiblePartialReceiptComplete) return false;
    // Coverage detection is advisory evidence, never permission to withhold
    // the editable receipt.  A person may have a complete long receipt whose
    // footer is difficult to recognize, and the safe recovery is to show the
    // existing proof and editable form while offering another section there.
    final evidence = result.finalReceiptSectionContinuationEvidenceLabel;
    _publishReceiptCaptureDiagnostic({
      'captureFlow': 'maintainiac_native_receipt_camera',
      'receiptPhotoReviewCoverageWarningBeforeOcr': true,
      'receiptPhotoReviewCoverageWarningReason':
          result.firstPossiblePartialReceiptReasonCode,
      'receiptPhotoReviewCoverageWarningAction':
          'open_editable_receipt_and_offer_next_section',
      'receiptPhotoReviewCoverageEvidence': evidence,
      ...result.privacySafeReceiptReaderHandoffMetadata,
    });
    // Returning false is intentional: every accepted receipt proceeds to the
    // same editable review whether or not the app suggests another photo.
    return false;
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
    if (!_appAssistedReceiptFillEnabled ||
        (widget.onImportedText == null &&
            widget.onReceiptOcrResultForReview == null)) {
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved. Automatic receipt filling is turned off for this area.';
      });
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
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    final now = DateTime.now();
    final ocrAttachments = [
      for (var index = 0; index < result.ocrSourcePhotoPaths.length; index++)
        ReceiptAttachmentRecord(
          id: 'RCOCR-${now.microsecondsSinceEpoch}-$index',
          path: result.ocrSourcePhotoPaths[index],
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: result.dataSaverLevel,
          createdAt: now,
          byteSize: receiptAttachmentFileSize(
            result.ocrSourcePhotoPaths[index],
          ),
          sourceLabel: 'Maintainiac clear receipt photo',
          linkedModule: _receiptAttachmentLinkedModule,
          storageState: ReceiptAttachmentStorageState.staged,
          documentSignals: ocrSourceDocumentSignalsFor(result, index),
          riskFlags: ocrSourceRiskFlagsFor(result, index),
        ).withPhotoQuality(qualityForOcrSourceIndex(result, index)),
    ];
    return _readAttachmentsForReceiptForm(
      ocrAttachments,
      successMessage: reviewedPhotoReadSuccessMessage(result.stitchResult),
      showDisabledMessage: false,
      showNoTextMessage: true,
    );
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
