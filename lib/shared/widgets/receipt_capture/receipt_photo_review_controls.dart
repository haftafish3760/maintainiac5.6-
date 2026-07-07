part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewBottomControls extends StatelessWidget {
  const _ReceiptReviewBottomControls({
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
    final continueLabel = _continueLabel;
    final waitingForStitch =
        reviewMode == _ReceiptReviewMode.stitch &&
        photoPaths.length > 1 &&
        (stitchPreviewInFlight || stitchPreview == null);
    final continueEnabled = !savingPhotos && !waitingForStitch;
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
        photoPaths: photoPaths,
        selectedIndex: selectedIndex,
        selectedQualityCheck: selectedQualityCheck,
        selectedCaptureDiagnostics: selectedCaptureDiagnostics,
        stitchPreview: stitchPreview,
        stitchPreviewInFlight: stitchPreviewInFlight,
        openingCamera: openingCamera || savingPhotos,
        savingPhotos: savingPhotos,
        continueLabel: continueLabel,
        onPhotoSelected: onPhotoSelected,
        onModeChanged: onModeChanged,
        onAddPhoto: onAddPhoto,
        onRetake: onRetake,
        onContinue: continueEnabled ? onContinue : null,
      );
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
                      _ReceiptReviewStepStrip(
                        selected: reviewMode,
                        photoCount: photoPaths.length,
                        enabled: !openingCamera && !savingPhotos,
                        onSelected: onModeChanged,
                      ),
                      const SizedBox(height: 6),
                      _ReceiptToolModeHeader(
                        reviewMode: reviewMode,
                        photoCount: photoPaths.length,
                        previewEnabled: !openingCamera && !savingPhotos,
                        onBackToPreview: () =>
                            onModeChanged(_ReceiptReviewMode.preview),
                      ),
                      const SizedBox(height: 6),
                      _ReceiptReviewContextRow(
                        selectedIndex: selectedIndex,
                        photoCount: photoPaths.length,
                        reviewMode: reviewMode,
                        dataSaverLevel: dataSaverLevel,
                        storagePreview: storagePreview,
                        selectedQualityCheck: selectedQualityCheck,
                        selectedCaptureDiagnostics: selectedCaptureDiagnostics,
                        bestShotCandidateMode: bestShotCandidateMode,
                        openingCamera: openingCamera || savingPhotos,
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
                          onSelected: onDataSaverSelected,
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
                      if (reviewMode == _ReceiptReviewMode.stitch &&
                          photoPaths.length > 1) ...[
                        const SizedBox(height: 6),
                        _ReceiptManualStitchControls(
                          pairIndex: stitchPairIndex,
                          totalPairs: photoPaths.length - 1,
                          manualOverlapFraction: manualOverlapFraction,
                          stitchPreview: stitchPreview,
                          stitchPreviewInFlight: stitchPreviewInFlight,
                          disabled: openingCamera || savingPhotos,
                          onPairSelected: onStitchPairSelected,
                          onOverlapChanged: onManualOverlapChanged,
                          onClear: onClearManualOverlap,
                          onOpenOrder: () =>
                              onModeChanged(_ReceiptReviewMode.order),
                        ),
                      ],
                      if (openingCamera || savingPhotos) ...[
                        const SizedBox(height: 6),
                        savingPhotos
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
              savingPhotos: savingPhotos,
              label: continueLabel,
              onContinue: onContinue,
            ),
          ],
        ),
      ),
    );
  }

  String get _continueLabel {
    final coverageDecision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: selectedQualityCheck,
      diagnostics: selectedCaptureDiagnostics,
    );
    if (reviewMode == _ReceiptReviewMode.preview &&
        coverageDecision.isMissingBottomEdgeAndTotals) {
      return 'Add Bottom Section';
    }
    if (reviewMode == _ReceiptReviewMode.preview &&
        coverageDecision.shouldPromptForMorePhotos) {
      return 'Use Receipt';
    }
    if (reviewMode == _ReceiptReviewMode.preview &&
        selectedQualityCheck?.hasCriticalIssue == true) {
      return 'Use Anyway';
    }
    if (bestShotCandidateMode || photoPaths.length == 1) {
      return 'Use Receipt';
    }
    if (reviewMode != _ReceiptReviewMode.stitch) {
      return photoPaths.length > 1 ? 'Check Photo Match' : 'Use Receipt';
    }
    if (stitchPreviewInFlight || stitchPreview == null) {
      return 'Checking Match';
    }
    if (stitchPreview?.didStitch == true) {
      return 'Use Receipt';
    }
    if (stitchPreview?.usedFallback == true) {
      return 'Use Receipt';
    }
    return 'Use Receipt';
  }
}
