part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewExitActions on _ReceiptPhotoReviewScreenState {
  Future<void> _cleanupFailedReceiptPrepArtifacts(Set<String> paths) async {
    for (final path in paths) {
      if (path.isEmpty || receiptPhotoPathSetContains(_photoPaths, path)) {
        continue;
      }
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best effort cleanup for app-created OCR/backup prep files.
      }
    }
  }

  void _forgetAcceptedReceiptPrepArtifacts(
    Set<String> cleanupCandidates,
    Iterable<String> acceptedPaths,
  ) {
    cleanupCandidates.removeWhere(
      (path) => receiptPhotoPathSetContains(acceptedPaths, path),
    );
  }

  Future<void> leaveReceiptReviewWithoutSaving() async {
    if (_closingReview || _confirmingReviewExit) return;
    if (_openingCamera) {
      _showCameraError('Camera is opening. Wait a moment.');
      return;
    }
    if (_savingPhotos) {
      _showCameraError('Receipt photo is being prepared. Wait a moment.');
      return;
    }
    if (_cropProcessing) {
      _showCameraError('Finish or cancel crop before leaving this review.');
      return;
    }
    final navigator = Navigator.of(context);
    _confirmingReviewExit = true;
    final _ReceiptReviewExitAction action;
    try {
      action = await _confirmReceiptReviewExit();
    } finally {
      _confirmingReviewExit = false;
    }
    if (!mounted || _closingReview) return;
    if (!_reviewWorkActive ||
        action == _ReceiptReviewExitAction.keepReviewing) {
      return;
    }
    if (action == _ReceiptReviewExitAction.saveAndRead) {
      await continueReceiptPhotoReview();
      return;
    }
    final keptForLaterResult = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: _photoPaths,
      dataSaverLevel: _dataSaverLevel,
      photoQualityChecksByPath: _qualityChecksByPath,
      captureDiagnosticsByPhotoPath:
          _captureDiagnosticsWithReceiptBrainDefaults(
            _captureDiagnosticsByPath,
            _photoPaths,
            captureRoute: 'saved_without_filling',
          ),
    );
    if (!beginReceiptReviewClose()) return;
    navigator.pop(keptForLaterResult);
  }

  bool beginReceiptReviewClose() {
    if (!mounted || _reviewDisposed || _closingReview) return false;
    _stitchPreviewDebounce?.cancel();
    _previewKeysInFlight.clear();
    _qualityCheckKeysInFlight.clear();
    _dataSaverPreviewKeysInFlight.clear();
    return _beginClosingReviewState(() {
      _savingPhotos = false;
      _openingCamera = false;
      _cropProcessing = false;
      _confirmingReviewExit = false;
    });
  }

  Future<_ReceiptReviewExitAction> _confirmReceiptReviewExit() async {
    if (!_reviewWorkActive) return _ReceiptReviewExitAction.keepReviewing;
    if (_photoPaths.isEmpty) return _ReceiptReviewExitAction.leaveSafely;
    final hasMultipleSections = _photoPaths.length > 1;
    final hasEditedReviewPhotos = _photoPaths.any(_generatedEditPaths.contains);
    final coverageDecision = _selectedExitCoverageDecision();
    final nextLabel = _exitContinueLabelFor(
      coverageDecision,
      hasMultipleSections: hasMultipleSections,
    );
    final title = hasMultipleSections
        ? 'Keep these receipt photos?'
        : 'Keep this receipt photo?';
    final content = _receiptReviewExitContent(
      hasMultipleSections: hasMultipleSections,
      hasEditedReviewPhotos: hasEditedReviewPhotos,
      coverageDecision: coverageDecision,
      nextLabel: nextLabel,
    );
    final leaveLabel = hasMultipleSections
        ? 'Save Photos Without Filling'
        : 'Save Photo Without Filling';
    final result = await showDialog<_ReceiptReviewExitAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161D20),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ReceiptReviewExitAction.leaveSafely),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFD166),
            ),
            child: Text(leaveLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ReceiptReviewExitAction.keepReviewing),
            child: const Text('Back to Photos'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_ReceiptReviewExitAction.saveAndRead),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
            ),
            child: Text(nextLabel),
          ),
        ],
      ),
    );
    if (!_reviewWorkActive) return _ReceiptReviewExitAction.keepReviewing;
    return result ?? _ReceiptReviewExitAction.keepReviewing;
  }

  String _receiptReviewExitContent({
    required bool hasMultipleSections,
    required bool hasEditedReviewPhotos,
    required ReceiptPhotoCoverageDecision coverageDecision,
    required String nextLabel,
  }) {
    final savedCopy = hasMultipleSections
        ? 'You can return to these photos later.'
        : 'You can return to this photo later.';
    final editCopy = hasEditedReviewPhotos
        ? 'Edited crop/rotation copies currently shown here will also be kept for this review.'
        : '';
    final nextCopy = _receiptReviewExitNextCopy(
      hasMultipleSections: hasMultipleSections,
      coverageDecision: coverageDecision,
      nextLabel: nextLabel,
    );
    return [
      savedCopy,
      if (editCopy.isNotEmpty) editCopy,
      nextCopy,
    ].join(' ');
  }

  ReceiptPhotoCoverageDecision _selectedExitCoverageDecision() {
    if (_photoPaths.isEmpty) {
      return const ReceiptPhotoCoverageDecision(
        status: ReceiptPhotoCoverageStatus.unknown,
        reasonCode: 'no_review_photo',
        title: 'Check Receipt Photo',
        guidance: 'No receipt photo is selected for review.',
      );
    }
    final selected = _selectedIndex.clamp(0, _photoPaths.length - 1);
    return _coverageDecisionForPhotoPath(_photoPaths[selected]);
  }

  String _exitContinueLabelFor(
    ReceiptPhotoCoverageDecision coverageDecision, {
    required bool hasMultipleSections,
  }) {
    if (coverageDecision.isMissingBottomEdgeAndTotals) {
      return 'Add Bottom Section';
    }
    return widget.uiConfig.labelFor(
      'continue',
      widget.uiConfig.useReceiptLabel,
    );
  }

  String _receiptReviewExitNextCopy({
    required bool hasMultipleSections,
    required ReceiptPhotoCoverageDecision coverageDecision,
    required String nextLabel,
  }) {
    final saveWithoutFilling = hasMultipleSections
        ? 'Save Photos Without Filling keeps these photos recoverable on this phone, but Maintainiac will not fill this expense from them yet.'
        : 'Save Photo Without Filling keeps this photo recoverable on this phone, but Maintainiac will not fill this expense from it yet.';
    if (coverageDecision.isMissingBottomEdgeAndTotals) {
      return 'Tap $nextLabel to add the bottom receipt section with the top ghost-slice guide, or continue only if this already shows the full receipt. $saveWithoutFilling';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return 'Tap $nextLabel only if this already shows the full receipt; otherwise add the next receipt section before opening receipt details. $saveWithoutFilling';
    }
    final target = hasMultipleSections ? 'the ordered photos' : 'this photo';
    return 'Tap $nextLabel to use $target and open receipt details. $saveWithoutFilling';
  }

  Map<String, Map<String, Object?>> _captureDiagnosticsWithReceiptBrainDefaults(
    Map<String, Map<String, Object?>> diagnosticsByPath,
    Iterable<String> paths, {
    required String captureRoute,
  }) {
    return {
      for (final path in paths)
        path: {
          ..._defaultReceiptBrainDiagnosticsForReviewPhoto(
            captureRoute:
                diagnosticsByPath[path]?['captureFlow']?.toString() ??
                captureRoute,
          ),
          ...?diagnosticsByPath[path],
        },
    };
  }

  Map<String, Object?> _defaultReceiptBrainDiagnosticsForReviewPhoto({
    String? captureRoute,
  }) {
    final storageClass = storageClassForDataSaverLevel(_dataSaverLevel);
    final cloudAssistPlan = _deviceCapability.cloudAssistPlanFor(
      dataSaverLevel: _dataSaverLevel,
    );
    final receiptBrain = _deviceCapability.receiptBrainRecommendationFor(
      storageClass,
      cloudAssistPlan: cloudAssistPlan,
    );
    final footprint = _deviceCapability.receiptBrainFootprintSummaryFor(
      storageClass,
      cloudAssistPlan: cloudAssistPlan,
    );
    final route = captureRoute == null || captureRoute.trim().isEmpty
        ? 'receipt_review_photo'
        : captureRoute.trim();
    return {
      ...receiptBrain.toPrivacySafeDiagnostics(),
      ...footprint.toPrivacySafeDiagnostics(),
      'receiptBrainDiagnosticsSource':
          'receipt_photo_review_default_local_policy',
      'receiptBrainCaptureRoute': route,
      'receiptBrainCloudAssistExplicitOnly':
          receiptBrain.requiresInternetForAssist,
      'receiptBrainBaseCaptureAvailableWithoutPack':
          receiptBrain.baseCaptureAlwaysAvailable &&
          footprint.baseCaptureWorksWithoutOptionalPacks,
      'receiptBrainOcrReadsBeforeSavedProof': true,
    };
  }
}
