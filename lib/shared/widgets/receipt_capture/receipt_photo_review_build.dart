part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewBuild on _ReceiptPhotoReviewScreenState {
  Widget _buildPhotoReviewScaffold(BuildContext context, String photoPath) {
    final dataSaverPreviewPath =
        _dataSaverPreviewPaths[_dataSaverPreviewKey(photoPath)];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leaveReceiptReviewWithoutSaving();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050607),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _reviewMode == _ReceiptReviewMode.crop
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
            ),
            SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _controlsVisible ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _ReceiptReviewTopBar(
                    current: _selectedIndex + 1,
                    total: _photoPaths.length,
                    reviewMode: _reviewMode,
                    bestShotCandidateMode: widget.bestShotCandidateMode,
                    openingCamera: _openingCamera,
                    savingPhotos: _savingPhotos,
                    continueLabel: _reviewTopBarContinueLabel(photoPath),
                    onClose: _reviewMode == _ReceiptReviewMode.crop
                        ? _cancelCropReview
                        : leaveReceiptReviewWithoutSaving,
                    onHideControls: _openingCamera || _savingPhotos
                        ? null
                        : () => _updateReviewState(() => _controlsVisible = false),
                    onMenuSelected: handleReviewMenuAction,
                    onContinue: _reviewMode == _ReceiptReviewMode.crop
                        ? null
                        : continueReceiptPhotoReview,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  offset: _controlsVisible
                      ? Offset.zero
                      : const Offset(0, 1.08),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: _reviewBottomControlsMaxHeight(context),
                    ),
                    child: _buildReviewBottomControls(photoPath),
                  ),
                ),
              ),
            ),
            if (!_controlsVisible)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _ReceiptShowReviewControlsButton(
                      onPressed: () =>
                          _updateReviewState(() => _controlsVisible = true),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
