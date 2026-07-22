part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewBuild on _ReceiptPhotoReviewScreenState {
  Widget _buildPhotoReviewScaffold(BuildContext context, String photoPath) {
    final effectiveSelectedIndex = _photoPaths.isEmpty
        ? 0
        : _selectedIndex.clamp(0, _photoPaths.length - 1);
    final dataSaverPreviewPath =
        _dataSaverPreviewPaths[_dataSaverPreviewKey(photoPath)];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leaveReceiptReviewWithoutSaving();
      },
      child: Scaffold(
        backgroundColor: widget.uiConfig.previewBackgroundColor,
        body: SafeArea(
          top: true,
          bottom: true,
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              if (widget.uiConfig.showTopBar)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: widget.uiConfig.topBarBottomSpacing,
                  ),
                  child: _ReceiptReviewTopBar(
                    current: effectiveSelectedIndex + 1,
                    total: _photoPaths.length,
                    reviewMode: _reviewMode,
                    bestShotCandidateMode: widget.bestShotCandidateMode,
                    openingCamera: _openingCamera,
                    savingPhotos: _savingPhotos,
                    onClose: _reviewMode == _ReceiptReviewMode.crop
                        ? _cancelCropReview
                        : leaveReceiptReviewWithoutSaving,
                    onOpenSettings: openReceiptReviewSettings,
                    onMenuSelected: handleReviewMenuAction,
                  ),
                ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _reviewMode == _ReceiptReviewMode.crop
                        ? _buildCropSurface(photoPath)
                        : _reviewMode == _ReceiptReviewMode.stitch &&
                              _photoPaths.length > 1
                        ? _buildStitchSurface()
                        : _buildPhotoSurface(
                            _reviewMode == _ReceiptReviewMode.dataSaver
                                ? dataSaverPreviewPath ?? photoPath
                                : photoPath,
                            waitingForDataSaverPreview:
                                _reviewMode == _ReceiptReviewMode.dataSaver &&
                                dataSaverPreviewPath == null,
                          ),
                  ],
                ),
              ),
              if (_showThumbnailStrip)
                _ReceiptReviewThumbnailStrip(
                  photoPaths: _photoPaths,
                  selectedIndex: effectiveSelectedIndex,
                  onPhotoSelected: (index) {
                    _resetPhotoPreviewZoom();
                    _updateReviewState(() => _selectedIndex = index);
                  },
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _reviewBottomControlsMaxHeight(context),
                ),
                child: _buildReviewBottomControls(photoPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
