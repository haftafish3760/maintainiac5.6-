part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewCaptureActions on _ReceiptPhotoReviewScreenState {
  void handleReviewMenuAction(_ReceiptReviewMenuAction action) {
    switch (action) {
      case _ReceiptReviewMenuAction.addAdditionalPhotos:
        addAnotherReceiptPhoto();
      case _ReceiptReviewMenuAction.moveEarlier:
        moveCurrentReceiptPhoto(-1);
      case _ReceiptReviewMenuAction.moveLater:
        moveCurrentReceiptPhoto(1);
      case _ReceiptReviewMenuAction.retake:
        retakeCurrentReceiptPhoto();
      case _ReceiptReviewMenuAction.remove:
        unawaited(removeCurrentReceiptPhoto());
    }
  }

  Future<void> addAnotherReceiptPhoto() async {
    final selectedPhotoIndex = _photoPaths.isEmpty
        ? -1
        : _selectedIndex.clamp(0, _photoPaths.length - 1);
    final guideIndex = _photoPaths.isEmpty ? -1 : selectedPhotoIndex;
    final guidePhotoPath = _photoPaths.isEmpty
        ? null
        : _photoPaths[selectedPhotoIndex];
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: guidePhotoPath,
      showAlignmentGuide: false,
    );
    if (picked.paths.isEmpty || !_reviewWorkActive) return;
    final insertPlan = guidePhotoPath == null
        ? null
        : ReceiptPhotoInsertAfterOrderPlan.build(
            currentPhotoPaths: _photoPaths,
            anchorIndex: guideIndex,
            anchorPhotoPath: guidePhotoPath,
            insertedPhotoPaths: picked.paths,
          );
    if (guidePhotoPath != null && insertPlan == null) return;
    final insertDiagnostics =
        insertPlan?.captureDiagnosticsForInsertedPhotoPaths(picked.paths) ??
        const <String, Map<String, Object?>>{};
    _updateReviewState(() {
      final insertIndex = insertPlan?.selectedIndex ?? _photoPaths.length;
      if (insertPlan == null) {
        _photoPaths.addAll(picked.paths);
      } else {
        _photoPaths
          ..clear()
          ..addAll(insertPlan.photoPaths);
      }
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _captureDiagnosticsByPath.addAll(
        _mergeOrderCaptureDiagnostics(
          picked.captureDiagnosticsByPath,
          insertDiagnostics,
        ),
      );
      _selectedIndex = insertIndex;
    });
    _recoverReviewAfterPhotoSetChanged();
  }

  Future<void> retakeCurrentReceiptPhoto() async {
    if (_photoPaths.isEmpty) return;
    final selectedPhotoIndex = _selectedIndex.clamp(0, _photoPaths.length - 1);
    final targetPhotoPath = _photoPaths[selectedPhotoIndex];
    final retakeContext = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: _photoPaths,
      targetPhotoPath: targetPhotoPath,
    );
    final picked = await _pickReceiptPhotos(
      alignmentGuidePhotoPath: retakeContext?.preferredGuidePhotoPath,
      nextSectionGuidePhotoPath: retakeContext?.nextSectionGuidePhotoPath,
      alignmentReasonCode: retakeContext?.guidanceCode,
      alignmentGuidance: retakeContext?.guidanceText,
    );
    if (picked.paths.isEmpty || !_reviewWorkActive) return;
    final retakePlan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: _photoPaths,
      targetPhotoPath: targetPhotoPath,
      replacementPhotoPaths: picked.paths,
    );
    if (retakePlan == null) return;
    String? replacedGeneratedPath;
    final retakeDiagnostics = retakePlan.captureDiagnosticsForReplacementPaths(
      picked.paths,
    );
    _updateReviewState(() {
      _selectedIndex = retakePlan.selectedIndex;
      final replacedPath = retakePlan.replacedPhotoPath;
      if (_generatedEditPaths.contains(replacedPath)) {
        replacedGeneratedPath = replacedPath;
      }
      final firstPath = picked.paths.first;
      _replaceCurrentPhotoPath(
        firstPath,
        picked.qualityChecksByPath[firstPath],
      );
      _photoPaths
        ..clear()
        ..addAll(retakePlan.photoPaths);
      _qualityChecksByPath.addAll(picked.qualityChecksByPath);
      _captureDiagnosticsByPath.addAll(
        _mergeRetakeCaptureDiagnostics(
          picked.captureDiagnosticsByPath,
          retakeDiagnostics,
        ),
      );
    });
    _recoverReviewAfterPhotoSetChanged();
    if (replacedGeneratedPath != null) {
      await _deleteGeneratedEditPhotos(_photoPaths.toSet());
    }
  }

  Future<_PickedReceiptPhotos> _pickReceiptPhotos({
    String? alignmentGuidePhotoPath,
    String? nextSectionGuidePhotoPath,
    String? alignmentReasonCode,
    String? alignmentGuidance,
    bool showAlignmentGuide = true,
  }) async {
    if (_openingCamera) return const _PickedReceiptPhotos.empty();
    _updateReviewState(() => _openingCamera = true);
    ReceiptPhotoCoverageDecision? coverageDecision;
    try {
      if (alignmentGuidePhotoPath != null && showAlignmentGuide) {
        coverageDecision = _coverageDecisionForPhoto(alignmentGuidePhotoPath);
        final shouldContinue = await _showLongReceiptAlignmentGuide(
          alignmentGuidePhotoPath,
          coverageDecision: coverageDecision,
          alignmentReasonCode: alignmentReasonCode,
          alignmentGuidance: alignmentGuidance,
        );
        if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();
        if (!shouldContinue) return const _PickedReceiptPhotos.empty();
      }
      final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
      if (picked.isEmpty) return const _PickedReceiptPhotos.empty();
      return _PickedReceiptPhotos.fromSystemCameraPaths(
        picked.paths,
        hadPreviousSectionGuide: alignmentGuidePhotoPath != null,
        previousSectionReasonCode: alignmentReasonCode,
        previousSectionGuidance: alignmentGuidance,
        previousSectionCoverageDecision: coverageDecision,
      );
    } on MissingPluginException {
      if (_reviewWorkActive) {
        _showCameraError(
          'The phone camera is not available in this build. Use Upload Photos or reinstall the app and try again.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    } on PlatformException catch (error) {
      if (_reviewWorkActive) {
        _showCameraError(_nativeCameraOpenErrorMessage(error));
      }
      return const _PickedReceiptPhotos.empty();
    } catch (_) {
      if (_reviewWorkActive) {
        _showCameraError(
          'The phone camera did not open. Try Add Another Photo again, or choose an existing receipt image.',
        );
      }
      return const _PickedReceiptPhotos.empty();
    } finally {
      if (_reviewWorkActive) _updateReviewState(() => _openingCamera = false);
    }
  }

  ReceiptPhotoCoverageDecision _coverageDecisionForPhoto(String photoPath) {
    return ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityChecksByPath[photoPath],
      diagnostics: _captureDiagnosticsByPath[photoPath],
    );
  }

  Map<String, Object?> _coverageDiagnosticsForPhoto(
    String photoPath, {
    required ReceiptPhotoQualityCheck fallbackQuality,
  }) {
    final cameraDiagnostics = _captureDiagnosticsByPath[photoPath];
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityChecksByPath[photoPath] ?? fallbackQuality,
      diagnostics: cameraDiagnostics,
    );
    return {
      ..._defaultReceiptBrainDiagnosticsForReviewPhoto(
        captureRoute: cameraDiagnostics?['captureFlow']?.toString(),
      ),
      if (cameraDiagnostics != null) ...cameraDiagnostics,
      ReceiptCaptureDiagnosticKeys.photoCoverageStatus: decision.status.name,
      ReceiptCaptureDiagnosticKeys.photoCoverageReason: decision.reasonCode,
      ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos:
          decision.shouldPromptForMorePhotos,
      if (_completionDecisionsByPath.containsKey(photoPath))
        ..._completionDecisionsByPath[photoPath]!,
    };
  }

  Map<String, Map<String, Object?>> _mergeRetakeCaptureDiagnostics(
    Map<String, Map<String, Object?>> pickedDiagnostics,
    Map<String, Map<String, Object?>> retakeDiagnostics,
  ) {
    return _mergeOrderCaptureDiagnostics(pickedDiagnostics, retakeDiagnostics);
  }

  Map<String, Map<String, Object?>> _mergeOrderCaptureDiagnostics(
    Map<String, Map<String, Object?>> pickedDiagnostics,
    Map<String, Map<String, Object?>> orderDiagnostics,
  ) {
    return Map<String, Map<String, Object?>>.unmodifiable({
      for (final entry in pickedDiagnostics.entries)
        entry.key: Map<String, Object?>.unmodifiable(entry.value),
      for (final entry in orderDiagnostics.entries)
        entry.key: Map<String, Object?>.unmodifiable({
          ...?pickedDiagnostics[entry.key],
          ...entry.value,
        }),
    });
  }
}
