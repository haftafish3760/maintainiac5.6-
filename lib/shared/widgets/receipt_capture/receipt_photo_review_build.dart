part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewBuild on _ReceiptPhotoReviewScreenState {
  Widget _buildPhotoReviewScaffold(BuildContext context, String photoPath) {
    final effectiveSelectedIndex = _photoPaths.isEmpty
        ? 0
        : _selectedIndex.clamp(0, _photoPaths.length - 1);
    final savedProofSourcePath = _dataSaverPreviewSource(photoPath);
    final dataSaverPreviewPath =
        _dataSaverPreviewPaths[_dataSaverPreviewKey(savedProofSourcePath)];
    final showingLongReceiptMatch =
        _reviewMode == _ReceiptReviewMode.stitch && _photoPaths.length > 1;
    return PopScope(
      // A successful save deliberately closes this route. Without allowing that
      // one controlled pop, PopScope reports a blocked pop and its back handler
      // sends the person from saved-proof selection back to stitch review.
      canPop: _closingReview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_closingReview) handleReceiptReviewBack();
      },
      child: Scaffold(
        backgroundColor: widget.uiConfig.previewBackgroundColor,
        body: SafeArea(
          top: true,
          bottom: true,
          maintainBottomViewPadding: true,
          child: _savingPhotos
              ? const _ReceiptPreparationProgressView()
              : Column(
                  children: [
                    if (widget.uiConfig.showTopBar && !showingLongReceiptMatch)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: widget.uiConfig.topBarBottomSpacing,
                        ),
                        child: _ReceiptReviewTopBar(
                          current: effectiveSelectedIndex + 1,
                          total: _photoPaths.length,
                          reviewMode: _reviewMode,
                          isStitchedReceipt:
                              _reviewMode == _ReceiptReviewMode.stitch &&
                              _stitchPreviewResult?.didStitch == true,
                          stitchWorking:
                              showingLongReceiptMatch &&
                              (_stitchPreviewInFlight ||
                                  _stitchPreviewResult == null),
                          stitchNeedsAlignment:
                              showingLongReceiptMatch &&
                              _stitchPreviewResult?.usedFallback == true,
                          bestShotCandidateMode: widget.bestShotCandidateMode,
                          openingCamera: _openingCamera,
                          savingPhotos: _savingPhotos,
                          onClose: handleReceiptReviewBack,
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
                              : showingLongReceiptMatch
                              ? _buildStitchSurface()
                              : _reviewMode == _ReceiptReviewMode.preview &&
                                    _photoPaths.length > 1
                              ? _buildPhotoReviewPager()
                              : _buildPhotoSurface(
                                  _reviewMode == _ReceiptReviewMode.dataSaver
                                      ? dataSaverPreviewPath ??
                                            savedProofSourcePath
                                      : photoPath,
                                  waitingForDataSaverPreview:
                                      _reviewMode ==
                                          _ReceiptReviewMode.dataSaver &&
                                      dataSaverPreviewPath == null,
                                ),
                          if (showingLongReceiptMatch)
                            Positioned(
                              left: 8,
                              top: 8,
                              child: _ReceiptStitchBackButton(
                                onPressed: () =>
                                    _setReviewMode(_ReceiptReviewMode.preview),
                              ),
                            ),
                          if (_reviewMode == _ReceiptReviewMode.dataSaver)
                            _ReceiptSavedImageSideRail(
                              selected: _dataSaverLevel,
                              preview:
                                  _storagePreviews[_previewKey(
                                    savedProofSourcePath,
                                  )],
                              enabled: !_openingCamera && !_savingPhotos,
                              visible: _dataSaverOptionsVisible,
                              onSelected: (level) => _updateReviewState(
                                () => _dataSaverLevel = level,
                              ),
                              onPreview: () => _updateReviewState(
                                () => _dataSaverOptionsVisible = false,
                              ),
                              onDismiss: () => _updateReviewState(
                                () => _dataSaverOptionsVisible = false,
                              ),
                            ),
                          if (_reviewMode == _ReceiptReviewMode.dataSaver &&
                              !_dataSaverOptionsVisible)
                            Positioned(
                              top: 10,
                              right: 8,
                              child: FilledButton.icon(
                                onPressed: _openingCamera || _savingPhotos
                                    ? null
                                    : () => _updateReviewState(
                                        () => _dataSaverOptionsVisible = true,
                                      ),
                                icon: const Icon(Icons.tune_rounded, size: 17),
                                label: const Text('Show size options'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xF00D1316),
                                  foregroundColor: const Color(0xFFF0F4F2),
                                  side: const BorderSide(
                                    color: Color(0xFF526168),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_reviewMode == _ReceiptReviewMode.preview &&
                        _photoPaths.length > 1)
                      _ReceiptReviewThumbnailStrip(
                        photoPaths: _photoPaths,
                        selectedIndex: effectiveSelectedIndex,
                        onPhotoSelected: _selectPhotoForPreview,
                      ),
                    if (_showThumbnailStrip &&
                        _reviewMode != _ReceiptReviewMode.preview &&
                        _reviewMode != _ReceiptReviewMode.stitch &&
                        _reviewMode != _ReceiptReviewMode.dataSaver)
                      _ReceiptReviewThumbnailStrip(
                        photoPaths: _photoPaths,
                        selectedIndex: effectiveSelectedIndex,
                        onPhotoSelected: (index) {
                          _resetPhotoPreviewZoom();
                          _updateReviewState(() => _selectedIndex = index);
                          // A thumbnail must open its actual original section. In
                          // combined-receipt mode, merely changing selection leaves
                          // the composite on screen and gives no visible feedback.
                          if (_reviewMode == _ReceiptReviewMode.stitch) {
                            _returnToStitchOnPreviewBack = true;
                            _setReviewMode(_ReceiptReviewMode.preview);
                          }
                        },
                      ),
                    if (_reviewMode == _ReceiptReviewMode.dataSaver)
                      _ReceiptSavedImageContinueBar(
                        saving: _savingPhotos,
                        onContinue: continueReceiptPhotoReview,
                      )
                    else if (showingLongReceiptMatch &&
                        _automaticStitchAssemblyVisible)
                      const SizedBox.shrink()
                    else if (showingLongReceiptMatch)
                      _ReceiptStitchReviewActions(
                        ready: _stitchPreviewResult?.didStitch == true,
                        fallback: _stitchPreviewResult?.usedFallback == true,
                        manualAlignmentActive: _manualAlignmentRequested,
                        saving: _savingPhotos,
                        // Ordered source sections are already a complete,
                        // safe receipt.  A failed visual match never turns
                        // Continue into another attempt at the same match.
                        onUse: continueReceiptPhotoReview,
                        // This is a review detour, never a destructive cancel.
                        // Returning must keep every original receipt section.
                        onCancel: () =>
                            _setReviewMode(_ReceiptReviewMode.preview),
                        onRedo: () {
                          if (_stitchPreviewResult?.usedFallback == true) {
                            if (_manualAlignmentRequested) {
                              unawaited(_ensureStitchPreview(force: true));
                              return;
                            }
                            _updateReviewState(
                              () => _manualAlignmentRequested = true,
                            );
                            return;
                          }
                          _returnToStitchOnPreviewBack = true;
                          _setReviewMode(_ReceiptReviewMode.preview);
                        },
                      )
                    else
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
