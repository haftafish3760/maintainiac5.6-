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
          child: InteractiveViewer(
            transformationController: _photoPreviewTransformController,
            minScale: 1,
            maxScale: 6,
            boundaryMargin: const EdgeInsets.all(48),
            panEnabled: _photoPreviewZoomed,
            onInteractionUpdate: (_) => _syncPhotoPreviewZoomState(),
            onInteractionEnd: (_) => _syncPhotoPreviewZoomState(),
            child: SizedBox.expand(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                cacheWidth: _reviewPreviewCacheWidth(context),
                cacheHeight: _reviewPreviewCacheHeight(context),
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
    return targetWidth.clamp(900, 1800);
  }

  int _reviewPreviewCacheHeight(BuildContext context) {
    final logicalHeight = MediaQuery.sizeOf(context).height;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetHeight = (logicalHeight * pixelRatio * 1.1).round();
    return targetHeight.clamp(1200, 2800);
  }

  void _togglePhotoPreviewZoom() {
    if (!_reviewWorkActive || _reviewDisposed) return;
    final current = _photoPreviewTransformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _photoPreviewTransformController.value = Matrix4.identity();
      _setPhotoPreviewZoomed(false);
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
    _setPhotoPreviewZoomed(true);
  }

  void _resetPhotoPreviewZoom() {
    _lastPhotoPreviewDoubleTap = null;
    _photoPreviewTransformController.value = Matrix4.identity();
    _setPhotoPreviewZoomed(false);
  }

  void _syncPhotoPreviewZoomState() {
    _setPhotoPreviewZoomed(
      _photoPreviewTransformController.value.getMaxScaleOnAxis() > 1.05,
    );
  }

  void _setPhotoPreviewZoomed(bool value) {
    if (_photoPreviewZoomed == value || !_reviewWorkActive) return;
    _updateReviewState(() => _photoPreviewZoomed = value);
  }

  void _selectPhotoForPreview(int index, {bool animate = true}) {
    if (!_reviewInteractiveControlsActive || _photoPaths.isEmpty) return;
    final selected = index.clamp(0, _photoPaths.length - 1).toInt();
    _resetPhotoPreviewZoom();
    _updateReviewState(() => _selectedIndex = selected);
    if (!_photoReviewPageController.hasClients) return;
    if (animate) {
      unawaited(
        _photoReviewPageController.animateToPage(
          selected,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _photoReviewPageController.jumpToPage(selected);
    }
  }

  void _syncPhotoReviewPagerToSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_reviewWorkActive || !_photoReviewPageController.hasClients) return;
      final selected = _selectedIndex.clamp(0, _photoPaths.length - 1).toInt();
      if (_photoReviewPageController.page?.round() == selected) return;
      _photoReviewPageController.jumpToPage(selected);
    });
  }
}
