part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewSurfaces on _ReceiptPhotoReviewScreenState {
  Widget _buildEmptyReviewRecovery() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leaveReceiptReviewWithoutSaving();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _OverlayIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Leave photo review',
                    onPressed: leaveReceiptReviewWithoutSaving,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.broken_image_rounded,
                  color: Color(0xFFFFD166),
                  size: 42,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Receipt photo was not available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Go back and take or choose the receipt photo again. No receipt fields were changed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: leaveReceiptReviewWithoutSaving,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Return To Receipt Entry'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropSurface(String photoPath) {
    _ensureCropBytesLoaded(photoPath);
    final imageBytes = _cropImageBytes;
    final imageSize = _cropImageSize;
    if (imageBytes == null ||
        imageSize == null ||
        _cropSourcePath != photoPath) {
      return const Center(child: CircularProgressIndicator());
    }
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF050607)),
      child: ReceiptEdgeCropper(
        imageBytes: imageBytes,
        imageSize: imageSize,
        cropRect: _cropRect,
        suggestedNormalizedCrop: _suggestedCropNormalized,
        onCropRectChanged: _setCropRectFromCropper,
        onDisplayRectChanged: _setCropDisplayRectFromCropper,
      ),
    );
  }

  void _setCropRectFromCropper(Rect rect) {
    if (!_reviewWorkActive || _reviewMode != _ReceiptReviewMode.crop) return;
    if (_cropRect == rect) return;
    _updateReviewState(() => _cropRect = rect);
  }

  void _setCropDisplayRectFromCropper(Rect rect) {
    if (!_reviewWorkActive || _reviewMode != _ReceiptReviewMode.crop) return;
    _cropDisplayRect = rect;
  }
}
