part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewBottomControls extends StatelessWidget {
  const _ReceiptReviewBottomControls({
    required this.uiConfig,
    required this.photoPaths,
    required this.selectedIndex,
    required this.dataSaverLevel,
    required this.storagePreview,
    required this.selectedQualityCheck,
    required this.selectedCaptureDiagnostics,
    required this.reviewMode,
    required this.stitchPreview,
    required this.stitchPreviewInFlight,
    required this.stitchPairIndex,
    required this.manualOverlapFraction,
    required this.toolControlsScrollController,
    required this.bestShotCandidateMode,
    required this.canRemove,
    required this.openingCamera,
    required this.cropProcessing,
    required this.savingPhotos,
    required this.onPhotoSelected,
    required this.onDataSaverSelected,
    required this.askSavedProofSizeEachReceipt,
    required this.onAskSavedProofSizeEachReceiptChanged,
    required this.onModeChanged,
    required this.onStitchPairSelected,
    required this.onManualOverlapChanged,
    required this.onClearManualOverlap,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onStraightenLeft,
    required this.onStraightenRight,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onRemove,
    required this.onContinue,
  });

  final ReceiptPhotoReviewUiConfig uiConfig;
  final List<String> photoPaths;
  final int selectedIndex;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final Map<String, Object?>? selectedCaptureDiagnostics;
  final _ReceiptReviewMode reviewMode;
  final ReceiptStitchResult? stitchPreview;
  final bool stitchPreviewInFlight;
  final int stitchPairIndex;
  final double? manualOverlapFraction;
  final ScrollController toolControlsScrollController;
  final bool bestShotCandidateMode;
  final bool canRemove;
  final bool openingCamera;
  final bool cropProcessing;
  final bool savingPhotos;
  final ValueChanged<int> onPhotoSelected;
  final ValueChanged<ReceiptDataSaverLevel> onDataSaverSelected;
  final bool askSavedProofSizeEachReceipt;
  final ValueChanged<bool> onAskSavedProofSizeEachReceiptChanged;
  final ValueChanged<_ReceiptReviewMode> onModeChanged;
  final ValueChanged<int> onStitchPairSelected;
  final ValueChanged<double> onManualOverlapChanged;
  final VoidCallback onClearManualOverlap;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onStraightenLeft;
  final VoidCallback onStraightenRight;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback onRemove;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final hasCapturedPhotos = photoPaths.isNotEmpty;
    final effectiveSavingPhotos = savingPhotos && hasCapturedPhotos;
    final continueLabel = _continueLabel;
    final displayedContinueLabel = uiConfig.labelFor('continue', continueLabel);
    final waitingForStitch =
        reviewMode == _ReceiptReviewMode.stitch &&
        photoPaths.length > 1 &&
        stitchPreview == null;
    final continueEnabled = !effectiveSavingPhotos && !waitingForStitch;
    if (reviewMode == _ReceiptReviewMode.crop) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xD8050607),
            border: Border(top: BorderSide(color: Color(0x55344047))),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: _ReceiptCropActions(
              cropProcessing: cropProcessing,
              onStraightenLeft: onStraightenLeft,
              onStraightenRight: onStraightenRight,
              onRotateLeft: onRotateLeft,
              onRotateRight: onRotateRight,
              onResetCrop: onResetCrop,
              onApplyCrop: onApplyCrop,
              onCancelCrop: onCancelCrop,
            ),
          ),
        ),
      );
    }
    if (reviewMode == _ReceiptReviewMode.preview) {
      return _ReceiptPreviewActionTray(
        uiConfig: uiConfig,
        photoPaths: photoPaths,
        selectedIndex: selectedIndex,
        selectedQualityCheck: selectedQualityCheck,
        selectedCaptureDiagnostics: selectedCaptureDiagnostics,
        stitchPreview: stitchPreview,
        stitchPreviewInFlight: stitchPreviewInFlight,
        openingCamera: openingCamera || effectiveSavingPhotos,
        savingPhotos: effectiveSavingPhotos,
        continueLabel: continueLabel,
        onModeChanged: onModeChanged,
        onAddPhoto: onAddPhoto,
        onRetake: onRetake,
        onContinue: continueEnabled ? onContinue : null,
      );
    }
    // Data Saver has its own narrow side drawer and a dedicated Continue bar.
    // Repeating the choices here used to cover too much of the receipt and
    // made it difficult to judge whether the selected saved image was clear.
    if (reviewMode == _ReceiptReviewMode.dataSaver) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xE8050607),
        border: Border(top: BorderSide(color: Color(0x99344047))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Scrollbar(
                controller: toolControlsScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: toolControlsScrollController,
                  primary: false,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reviewMode != _ReceiptReviewMode.stitch) ...[
                        _ReceiptReviewStepStrip(
                          selected: reviewMode,
                          photoCount: photoPaths.length,
                          enabled: !openingCamera && !savingPhotos,
                          onSelected: onModeChanged,
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (reviewMode != _ReceiptReviewMode.stitch ||
                          stitchPreview?.usedFallback == true) ...[
                        _ReceiptToolModeHeader(
                          reviewMode: reviewMode,
                          photoCount: photoPaths.length,
                          previewEnabled: !openingCamera && !savingPhotos,
                          onBackToPreview: () =>
                              onModeChanged(_ReceiptReviewMode.preview),
                        ),
                        const SizedBox(height: 6),
                      ],
                      _ReceiptReviewContextRow(
                        selectedIndex: selectedIndex,
                        photoCount: photoPaths.length,
                        reviewMode: reviewMode,
                        dataSaverLevel: dataSaverLevel,
                        storagePreview: storagePreview,
                        selectedQualityCheck: selectedQualityCheck,
                        selectedCaptureDiagnostics: selectedCaptureDiagnostics,
                        stitchPreview: stitchPreview,
                        bestShotCandidateMode: bestShotCandidateMode,
                        openingCamera: openingCamera || effectiveSavingPhotos,
                        canRemove: canRemove,
                        onAddPhoto: onAddPhoto,
                        onRetake: onRetake,
                        onRemove: onRemove,
                      ),
                      if (reviewMode == _ReceiptReviewMode.dataSaver) ...[
                        const SizedBox(height: 6),
                        _ReceiptOcrProofLaneCard(
                          selected: dataSaverLevel,
                          storagePreview: storagePreview,
                          selectedQualityCheck: selectedQualityCheck,
                        ),
                        const SizedBox(height: 6),
                        _ReceiptDataSaverPreviewCard(preview: storagePreview),
                        const SizedBox(height: 6),
                        _ReceiptDataSaverStrip(
                          selected: dataSaverLevel,
                          enabled: !openingCamera && !savingPhotos,
                          onSelected: onDataSaverSelected,
                        ),
                        const SizedBox(height: 6),
                        _ReceiptSavedProofFrequencyChoice(
                          askEveryReceipt: askSavedProofSizeEachReceipt,
                          enabled: !openingCamera && !savingPhotos,
                          onChanged: onAskSavedProofSizeEachReceiptChanged,
                        ),
                      ],
                      if (reviewMode == _ReceiptReviewMode.order) ...[
                        const SizedBox(height: 6),
                        _ReceiptOrderToolControls(
                          photoPaths: photoPaths,
                          selectedIndex: selectedIndex,
                          openingCamera: openingCamera || savingPhotos,
                          onPhotoSelected: onPhotoSelected,
                          onMoveEarlier: onMoveEarlier,
                          onMoveLater: onMoveLater,
                          onAddPhoto: onAddPhoto,
                          onRetake: onRetake,
                        ),
                      ],
                      if (openingCamera || effectiveSavingPhotos) ...[
                        const SizedBox(height: 6),
                        effectiveSavingPhotos
                            ? const ReceiptPickerStatus(
                                label: 'Opening receipt details...',
                              )
                            : const ReceiptPickerStatus(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _ReceiptPersistentContinueButton(
              enabled: continueEnabled,
              savingPhotos: effectiveSavingPhotos,
              label: displayedContinueLabel,
              onContinue: onContinue,
            ),
          ],
        ),
      ),
    );
  }

  String get _continueLabel {
    if (reviewMode == _ReceiptReviewMode.dataSaver) {
      return askSavedProofSizeEachReceipt
          ? 'Use this size and ask next time'
          : 'Use this size for future receipts';
    }
    if (reviewMode == _ReceiptReviewMode.preview && photoPaths.length == 1) {
      return 'Choose Saved Image Size';
    }
    if (!bestShotCandidateMode &&
        reviewMode != _ReceiptReviewMode.stitch &&
        photoPaths.length > 1) {
      return 'Continue';
    }
    if (reviewMode == _ReceiptReviewMode.stitch &&
        stitchPreview?.didStitch == true) {
      return 'Use combined receipt';
    }
    if (reviewMode == _ReceiptReviewMode.stitch &&
        stitchPreview?.usedFallback == true) {
      return 'Use receipt sections';
    }
    if (reviewMode == _ReceiptReviewMode.stitch &&
        (stitchPreviewInFlight || stitchPreview == null)) {
      return 'Putting receipt together';
    }
    return 'Continue';
  }
}
