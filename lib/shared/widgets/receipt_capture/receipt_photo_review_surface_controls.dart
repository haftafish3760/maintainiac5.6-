part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSurfaceControls on _ReceiptPhotoReviewScreenState {
  Widget _buildReviewBottomControls(String photoPath) {
    final controls = _ReceiptReviewBottomControls(
      uiConfig: widget.uiConfig,
      photoPaths: _photoPaths,
      selectedIndex: _selectedIndex,
      dataSaverLevel: _dataSaverLevel,
      storagePreview: _storagePreviews[_previewKey(photoPath)],
      selectedQualityCheck: _qualityChecksByPath[photoPath],
      selectedCaptureDiagnostics: _captureDiagnosticsByPath[photoPath],
      reviewMode: _reviewMode,
      stitchPreview: _stitchPreviewResult,
      stitchPreviewInFlight: _stitchPreviewInFlight,
      stitchPairIndex: _selectedStitchPairIndex,
      manualOverlapFraction: _manualOverlapFractions.isEmpty
          ? null
          : _manualOverlapFractions[_selectedStitchPairIndex],
      toolControlsScrollController: _toolControlsScrollController,
      bestShotCandidateMode: widget.bestShotCandidateMode,
      canRemove: _photoPaths.length > 1,
      openingCamera: _openingCamera,
      cropProcessing: _cropProcessing,
      savingPhotos: _savingPhotos,
      onPhotoSelected: (index) {
        _resetPhotoPreviewZoom();
        _updateReviewState(() => _selectedIndex = index);
      },
      onDataSaverSelected: (level) =>
          _updateReviewState(() => _dataSaverLevel = level),
      onModeChanged: _setReviewMode,
      onStitchPairSelected: _selectStitchPairIndex,
      onManualOverlapChanged: _setManualOverlapFraction,
      onClearManualOverlap: _clearManualOverlapFraction,
      onMoveEarlier: () => moveCurrentReceiptPhoto(-1),
      onMoveLater: () => moveCurrentReceiptPhoto(1),
      onStraightenLeft: () => _rotateCurrentPhoto(-1.5),
      onStraightenRight: () => _rotateCurrentPhoto(1.5),
      onRotateLeft: () => _rotateCurrentPhoto(-90),
      onRotateRight: () => _rotateCurrentPhoto(90),
      onResetCrop: _resetCrop,
      onApplyCrop: _applyCrop,
      onCancelCrop: _cancelCropReview,
      onAddPhoto: addAnotherReceiptPhoto,
      onRetake: retakeCurrentReceiptPhoto,
      onRemove: () => unawaited(removeCurrentReceiptPhoto()),
      onContinue: continueReceiptPhotoReview,
    );
    return controls;
  }

  double _reviewBottomControlsMaxHeight(BuildContext context) {
    if (_reviewMode == _ReceiptReviewMode.crop) {
      // Crop actions must remain fully reachable even on short screens. The
      // crop toolbar is intentionally compact, so a fractional cap would only
      // clip controls instead of preserving more useful preview space.
      return widget.uiConfig.cropControlsHeight;
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeHeight =
        screenHeight -
        MediaQuery.viewPaddingOf(context).top -
        MediaQuery.viewPaddingOf(context).bottom;
    // Keep the receipt dominant while making the core actions visible without
    // relying on a hidden scroll-only continuation path.
    final proportional =
        safeHeight *
        switch (_reviewMode) {
          _ReceiptReviewMode.preview =>
            widget.uiConfig.previewControlsHeightFraction,
          _ReceiptReviewMode.crop => .10,
          _ReceiptReviewMode.order => .18,
          _ReceiptReviewMode.stitch => .20,
          _ReceiptReviewMode.dataSaver => .20,
        };
    final absolute = switch (_reviewMode) {
      _ReceiptReviewMode.preview =>
        _photoPaths.length > 1
            ? widget.uiConfig.previewControlsMultiPhotoHeight
            : widget.uiConfig.previewControlsSinglePhotoHeight,
      _ReceiptReviewMode.crop => widget.uiConfig.cropControlsHeight,
      _ReceiptReviewMode.order => widget.uiConfig.orderControlsHeight,
      _ReceiptReviewMode.stitch => widget.uiConfig.stitchControlsHeight,
      _ReceiptReviewMode.dataSaver => widget.uiConfig.dataSaverControlsHeight,
    };
    return proportional < absolute ? proportional : absolute;
  }

  String _reviewTopBarContinueLabel(String photoPath) {
    final strings = MaintaniacLocalizations.of(context);
    if (_savingPhotos) return strings.openingReceiptReview;
    final quality = _qualityChecksByPath[photoPath];
    final coverageDecision = _coverageDecisionForPhotoPath(photoPath);
    if (_reviewMode == _ReceiptReviewMode.preview &&
        coverageDecision.shouldPromptForMorePhotos) {
      return strings.useReceipt;
    }
    if (_reviewMode == _ReceiptReviewMode.preview &&
        quality?.hasCriticalIssue == true) {
      return strings.useAnyway;
    }
    if (_reviewMode == _ReceiptReviewMode.stitch &&
        _photoPaths.length > 1 &&
        (_stitchPreviewInFlight || _stitchPreviewResult == null)) {
      return strings.checkingReceiptPhotos;
    }
    if (_reviewMode == _ReceiptReviewMode.preview) {
      return strings.useReceipt;
    }
    return strings.useReceipt;
  }

  ReceiptPhotoCoverageDecision _coverageDecisionForPhotoPath(String photoPath) {
    return ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityChecksByPath[photoPath],
      diagnostics: _captureDiagnosticsByPath[photoPath],
    );
  }
}
