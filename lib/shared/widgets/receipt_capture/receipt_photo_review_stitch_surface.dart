part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchSurface on _ReceiptPhotoReviewScreenState {
  Widget _buildStitchSurface() {
    final preview = _stitchPreviewResult;
    final stitchedPath = preview?.stitchedPath;
    if (preview?.didStitch == true && stitchedPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPhotoSurface(stitchedPath),
          Positioned(
            left: 12,
            right: 12,
            top: 88,
            child: _StitchPreviewStatusBanner(
              stitch: preview!,
              rebuilding: _stitchPreviewInFlight,
            ),
          ),
        ],
      );
    }
    if (preview?.usedFallback == true) {
      final pairIndex = _selectedStitchPairIndex.clamp(
        0,
        _photoPaths.length - 2,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          _ReceiptStitchPairPreview(
            firstPath: _photoPaths[pairIndex],
            secondPath: _photoPaths[pairIndex + 1],
            pairIndex: pairIndex,
            totalPairs: _photoPaths.length - 1,
            overlapFraction: _stitchPairOverlapFraction(pairIndex),
            bottomInset: _stitchSurfaceBottomInset(context),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 88,
            child: _StitchFallbackBanner(stitch: preview!),
          ),
        ],
      );
    }
    final pairIndex = _selectedStitchPairIndex.clamp(0, _photoPaths.length - 2);
    return _ReceiptStitchPairPreview(
      firstPath: _photoPaths[pairIndex],
      secondPath: _photoPaths[pairIndex + 1],
      pairIndex: pairIndex,
      totalPairs: _photoPaths.length - 1,
      overlapFraction: _stitchPairOverlapFraction(pairIndex),
      bottomInset: _stitchSurfaceBottomInset(context),
    );
  }

  double _stitchPairOverlapFraction(int pairIndex) {
    return _manualOverlapFractions.isEmpty
        ? .22
        : _manualOverlapFractions[pairIndex] ?? .22;
  }

  double _stitchSurfaceBottomInset(BuildContext _) => 18;
}
