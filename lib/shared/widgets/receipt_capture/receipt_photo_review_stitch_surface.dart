part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchSurface on _ReceiptPhotoReviewScreenState {
  bool get _automaticStitchAssemblyVisible {
    return (_stitchPreviewInFlight || _stitchPreviewResult == null) &&
        !_manualAlignmentActiveForSelectedPair;
  }

  bool get _manualAlignmentActiveForSelectedPair {
    if (_manualOverlapFractions.isEmpty) return false;
    final index = _selectedStitchPairIndex.clamp(
      0,
      _manualOverlapFractions.length - 1,
    );
    return _manualOverlapFractions[index] != null ||
        _manualZeroOverlapPairs[index] ||
        (_manualScaleCorrections[index] - 1).abs() > .001 ||
        _manualRotationCorrectionsDegrees[index].abs() > .001 ||
        _manualHorizontalOffsetFractions[index].abs() > .001;
  }

  Widget _buildStitchSurface() {
    final preview = _stitchPreviewResult;
    final stitchedPath = preview?.stitchedPath;
    if (preview?.didStitch == true && stitchedPath != null) {
      return _ReceiptStitchedReceiptSurface(
        path: stitchedPath,
        onTap: _resetPhotoPreviewZoom,
      );
    }
    if (_automaticStitchAssemblyVisible) {
      return const _ReceiptStitchAssemblySurface();
    }
    if (preview?.usedFallback == true && !_manualAlignmentRequested) {
      return _ReceiptStitchFailureSurface(
        onRetake: _retakeFailedStitchPhoto,
        onAlign: () =>
            _updateReviewState(() => _manualAlignmentRequested = true),
      );
    }
    if (_stitchPreviewInFlight || preview == null) {
      return _ReceiptStitchWorkingSurface(
        photoPaths: _photoPaths,
        pairIndex: _selectedStitchPairIndex,
        matching:
            preview?.usedFallback != true &&
            !_manualAlignmentActiveForSelectedPair,
        manualOverlapFraction: _manualOverlapFractions.isEmpty
            ? null
            : _manualOverlapFractions[_selectedStitchPairIndex],
        manualZeroOverlap:
            _manualZeroOverlapPairs.isNotEmpty &&
            _manualZeroOverlapPairs[_selectedStitchPairIndex],
        manualScaleCorrection: _manualScaleCorrections.isEmpty
            ? 1
            : _manualScaleCorrections[_selectedStitchPairIndex],
        manualRotationCorrectionDegrees:
            _manualRotationCorrectionsDegrees.isEmpty
            ? 0
            : _manualRotationCorrectionsDegrees[_selectedStitchPairIndex],
        manualHorizontalOffsetFraction: _manualHorizontalOffsetFractions.isEmpty
            ? 0
            : _manualHorizontalOffsetFractions[_selectedStitchPairIndex],
        onPhotoSelected: _selectStitchPhoto,
        onPairSelected: _selectStitchPairIndex,
        onManualOverlapChanged: _setManualOverlapFraction,
        onManualZeroOverlapChanged: _setManualZeroOverlap,
        onManualScaleChanged: _setManualScaleCorrection,
        onManualRotationChanged: _setManualRotationCorrection,
        onManualHorizontalOffsetChanged: _setManualHorizontalOffsetFraction,
        onManualGestureChanged: _setManualAlignmentGesture,
        onResetManualAlignment: _resetManualAlignment,
      );
    }
    if (preview.usedFallback) {
      return _ReceiptStitchWorkingSurface(
        photoPaths: _photoPaths,
        pairIndex: _selectedStitchPairIndex,
        matching: false,
        manualOverlapFraction: _manualOverlapFractions.isEmpty
            ? null
            : _manualOverlapFractions[_selectedStitchPairIndex],
        manualZeroOverlap:
            _manualZeroOverlapPairs.isNotEmpty &&
            _manualZeroOverlapPairs[_selectedStitchPairIndex],
        manualScaleCorrection:
            _manualScaleCorrections[_selectedStitchPairIndex],
        manualRotationCorrectionDegrees:
            _manualRotationCorrectionsDegrees[_selectedStitchPairIndex],
        manualHorizontalOffsetFraction:
            _manualHorizontalOffsetFractions[_selectedStitchPairIndex],
        onPhotoSelected: _selectStitchPhoto,
        onPairSelected: _selectStitchPairIndex,
        onManualOverlapChanged: _setManualOverlapFraction,
        onManualZeroOverlapChanged: _setManualZeroOverlap,
        onManualScaleChanged: _setManualScaleCorrection,
        onManualRotationChanged: _setManualRotationCorrection,
        onManualHorizontalOffsetChanged: _setManualHorizontalOffsetFraction,
        onManualGestureChanged: _setManualAlignmentGesture,
        onResetManualAlignment: _resetManualAlignment,
      );
    }
    return _ReceiptStitchWorkingSurface(
      photoPaths: _photoPaths,
      pairIndex: _selectedStitchPairIndex,
      matching: true,
      manualOverlapFraction: _manualOverlapFractions.isEmpty
          ? null
          : _manualOverlapFractions[_selectedStitchPairIndex],
      manualZeroOverlap:
          _manualZeroOverlapPairs.isNotEmpty &&
          _manualZeroOverlapPairs[_selectedStitchPairIndex],
      manualScaleCorrection: _manualScaleCorrections.isEmpty
          ? 1
          : _manualScaleCorrections[_selectedStitchPairIndex],
      manualRotationCorrectionDegrees: _manualRotationCorrectionsDegrees.isEmpty
          ? 0
          : _manualRotationCorrectionsDegrees[_selectedStitchPairIndex],
      manualHorizontalOffsetFraction: _manualHorizontalOffsetFractions.isEmpty
          ? 0
          : _manualHorizontalOffsetFractions[_selectedStitchPairIndex],
      onPhotoSelected: _selectStitchPhoto,
      onPairSelected: _selectStitchPairIndex,
      onManualOverlapChanged: _setManualOverlapFraction,
      onManualZeroOverlapChanged: _setManualZeroOverlap,
      onManualScaleChanged: _setManualScaleCorrection,
      onManualRotationChanged: _setManualRotationCorrection,
      onManualHorizontalOffsetChanged: _setManualHorizontalOffsetFraction,
      onManualGestureChanged: _setManualAlignmentGesture,
      onResetManualAlignment: _resetManualAlignment,
    );
  }

  void _retakeFailedStitchPhoto() {
    final failedPair = _stitchPreviewResult?.failedPairIndex ?? 0;
    final target = (failedPair + 1).clamp(0, _photoPaths.length - 1).toInt();
    _updateReviewState(() => _selectedIndex = target);
    unawaited(retakeCurrentReceiptPhoto());
  }
}
