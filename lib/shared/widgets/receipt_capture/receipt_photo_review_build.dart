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
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _controlsVisible && widget.uiConfig.showTopBar
                    ? Padding(
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
                          continueLabel: _reviewTopBarContinueLabel(photoPath),
                          onClose: _reviewMode == _ReceiptReviewMode.crop
                              ? _cancelCropReview
                              : leaveReceiptReviewWithoutSaving,
                          onContinue: _reviewMode == _ReceiptReviewMode.crop
                              ? null
                              : continueReceiptPhotoReview,
                        ),
                      )
                    : const SizedBox.shrink(),
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
                    if (!_controlsVisible)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _ReceiptShowReviewControlsButton(
                            onPressed: () => _updateReviewState(
                              () => _controlsVisible = true,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: _controlsVisible
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _reviewBottomControlsMaxHeight(context),
                        ),
                        child: _buildReviewBottomControls(photoPath),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
