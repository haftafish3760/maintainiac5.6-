part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchSurface on _ReceiptPhotoReviewScreenState {
  Widget _buildStitchSurface() {
    final preview = _stitchPreviewResult;
    final stitchedPath = preview?.stitchedPath;
    if (preview?.didStitch == true && stitchedPath != null) {
      return _ReceiptStitchedReceiptSurface(
        path: stitchedPath,
        onTap: _resetPhotoPreviewZoom,
      );
    }
    if (_stitchPreviewInFlight || preview == null) {
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
    );
  }
}
