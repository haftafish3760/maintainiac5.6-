part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentReviewReadActions
    on _SharedReceiptAttachmentPanelState {
  Future<bool> reviewPickedPhotoPaths(
    List<String> paths, {
    Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath = const {},
    Map<String, Map<String, Object?>> initialCaptureDiagnosticsByPath =
        const {},
  }) async {
    final firstNewPhotoIndex = uniqueNormalizedReceiptPhotoPaths(
      _photoPaths,
    ).length;
    final previousPhotoIdByPath = {..._photoIdByPath};
    final result = await Navigator.of(context).push<ReceiptPhotoReviewResult>(
      appNativeRoute(
        context,
        ReceiptPhotoReviewScreen(
          initialPhotoPaths: [..._photoPaths, ...paths],
          initialDataSaverLevel: _dataSaverLevel,
          initialSelectedIndex: firstNewPhotoIndex,
          initialQualityChecksByPath: {
            ..._photoQualityByPath,
            ...initialQualityChecksByPath,
          },
          initialCaptureDiagnosticsByPath: {
            ..._photoCaptureDiagnosticsByPath,
            ...initialCaptureDiagnosticsByPath,
          },
        ),
      ),
    );
    if (result == null || !mounted) return false;
    final accepted = await _acceptReviewedPhotoResult(
      result,
      previousPhotoIdByPath: previousPhotoIdByPath,
    );
    return accepted && mounted;
  }

  Future<bool> _acceptReviewedPhotoResult(
    ReceiptPhotoReviewResult result, {
    Map<String, String>? previousPhotoIdByPath,
  }) async {
    final existingPhotoIdByPath = previousPhotoIdByPath ?? {..._photoIdByPath};
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
            (path) => MapEntry(path, ReceiptAttachmentReadState.notRead),
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
          initialPhotoPaths: _photoPaths,
          initialDataSaverLevel: _dataSaverLevel,
          initialQualityChecksByPath: _photoQualityByPath,
          initialCaptureDiagnosticsByPath: _photoCaptureDiagnosticsByPath,
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
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings?.appAssistedEnabledFor(widget.area) == false) return;
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
      _receiptReadStatusMessage =
          'Next accepted. $processing $proofCount ready. OCR sources: $ocrSourceCount. $qualitySummary $reviewDecision $action';
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
      _receiptReadStatusMessage =
          'Receipt photo saved. Add the bottom receipt section before receipt details open. $evidence $nextStep';
    });
    widget.onReceiptCaptureDiagnostic?.call({
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
      return 'OCR source quality ${weakestQuality.reviewScoreLabel}: looks readable.';
    }
    final sourceLabel = qualities.length == 1
        ? 'OCR source'
        : '$needsReview of ${qualities.length} OCR sources';
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
    final settings = ReceiptCaptureSettingsScope.maybeOf(context);
    if (settings?.appAssistedEnabledFor(widget.area) == false ||
        widget.onImportedText == null) {
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved. App-assisted receipt filling is turned off for this area.';
      });
      return const _ReceiptAttachmentReadResult(
        _ReceiptAttachmentReadOutcome.skipped,
      );
    }
    if (result.ocrSourcePhotoPaths.isEmpty) {
      updateAttachmentState(() {
        _receiptReadStatus = _ReceiptReadStatusKind.warning;
        _receiptReadStatusMessage =
            'Receipt proof saved: ${result.savedProofCountLabel}. No clear OCR source was available for app-assisted receipt filling.';
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
          sourceLabel: 'Maintainiac OCR source photo',
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
