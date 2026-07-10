part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewPhotoSurface on _ReceiptPhotoReviewScreenState {
  Widget _buildPhotoSurface(
    String photoPath, {
    bool waitingForDataSaverPreview = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTapDown: (details) => _lastPhotoPreviewDoubleTap = details,
          onDoubleTap: _togglePhotoPreviewZoom,
          onTap: () {
            final interactionLocked = _openingCamera || _savingPhotos;
            if (interactionLocked && _controlsVisible) return;
            _updateReviewState(() {
              if (interactionLocked) {
                _controlsVisible = true;
              } else {
                _controlsVisible = !_controlsVisible;
              }
            });
          },
          child: InteractiveViewer(
            transformationController: _photoPreviewTransformController,
            minScale: 1,
            maxScale: 6,
            boundaryMargin: const EdgeInsets.all(48),
            child: SizedBox.expand(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                cacheWidth: _reviewPreviewCacheWidth(context),
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Receipt image could not be previewed.',
                      style: TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (waitingForDataSaverPreview)
          const Positioned(
            left: 14,
            right: 14,
            top: 86,
            child: _DataSaverPreviewLoadingBanner(),
          ),
      ],
    );
  }

  int _reviewPreviewCacheWidth(BuildContext context) {
    final logicalWidth = MediaQuery.sizeOf(context).width;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = (logicalWidth * pixelRatio * 1.35).round();
    return targetWidth.clamp(900, 2600);
  }

  void _togglePhotoPreviewZoom() {
    if (!_reviewWorkActive || _reviewDisposed) return;
    final current = _photoPreviewTransformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _photoPreviewTransformController.value = Matrix4.identity();
      return;
    }
    final tapPosition =
        _lastPhotoPreviewDoubleTap?.localPosition ?? Offset.zero;
    const targetScale = 2.25;
    final zoomMatrix = Matrix4.identity();
    zoomMatrix.storage[0] = targetScale;
    zoomMatrix.storage[5] = targetScale;
    zoomMatrix.storage[12] = -tapPosition.dx * (targetScale - 1);
    zoomMatrix.storage[13] = -tapPosition.dy * (targetScale - 1);
    _photoPreviewTransformController.value = zoomMatrix;
  }

  void _resetPhotoPreviewZoom() {
    _lastPhotoPreviewDoubleTap = null;
    _photoPreviewTransformController.value = Matrix4.identity();
  }
}
