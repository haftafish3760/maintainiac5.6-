part of 'receipt_photo_review_screen.dart';

class _ReceiptPreviewActionTray extends StatelessWidget {
  const _ReceiptPreviewActionTray({
    required this.uiConfig,
    required this.photoPaths,
    required this.selectedIndex,
    required this.selectedQualityCheck,
    required this.selectedCaptureDiagnostics,
    required this.stitchPreview,
    required this.stitchPreviewInFlight,
    required this.openingCamera,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onPhotoSelected,
    required this.onModeChanged,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onContinue,
  });

  final ReceiptPhotoReviewUiConfig uiConfig;
  final List<String> photoPaths;
  final int selectedIndex;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final Map<String, Object?>? selectedCaptureDiagnostics;
  final ReceiptStitchResult? stitchPreview;
  final bool stitchPreviewInFlight;
  final bool openingCamera;
  final bool savingPhotos;
  final String continueLabel;
  final ValueChanged<int> onPhotoSelected;
  final ValueChanged<_ReceiptReviewMode> onModeChanged;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final interactionLocked = openingCamera || savingPhotos;
    final effectiveSelectedIndex = photoPaths.isEmpty
        ? 0
        : selectedIndex.clamp(0, photoPaths.length - 1);
    final statusText = this.statusText;
    final statusIcon = this.statusIcon;
    final statusColor = this.statusColor;
    final photoCount = photoPaths.length;
    final hasMultiplePhotos = photoCount > 1;
    final nativeWarning = nativeCaptureReviewWarning;
    final coverageDecision = coverageDecisionForSelectedPhoto;
    final hasCriticalQualityIssue =
        selectedQualityCheck?.hasCriticalIssue == true ||
        nativeWarning?.isCritical == true;
    final hasQualityWarning =
        selectedQualityCheck?.needsReview == true ||
        selectedQualityCheck?.hasCriticalIssue == true ||
        nativeWarning != null ||
        coverageDecision.shouldPromptForMorePhotos;
    final deviceCapability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    final isOverLocalPhotoLimit =
        hasMultiplePhotos && photoCount > deviceCapability.maxLocalPhotoCount;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: uiConfig.controlsBackgroundColor,
        border: Border(top: BorderSide(color: uiConfig.controlsBorderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactControls =
                constraints.maxHeight.isFinite && constraints.maxHeight < 104;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (uiConfig.showDecisionGuidance) ...[
                  _ReceiptReviewDecisionHeader(
                    photoCount: photoCount,
                    coverageDecision: coverageDecision,
                    continueLabel: continueLabel,
                    compact: compactControls,
                  ),
                  SizedBox(height: compactControls ? 5 : 7),
                ],
                _ReceiptPreviewPrimaryRow(
                  uiConfig: uiConfig,
                  current: effectiveSelectedIndex + 1,
                  total: photoCount,
                  statusIcon: statusIcon,
                  statusColor: statusColor,
                  statusText: statusText,
                  compact: compactControls,
                  coverageDecision: coverageDecision,
                  savingPhotos: savingPhotos,
                  continueLabel: continueLabel,
                  onRetake: interactionLocked ? null : onRetake,
                  onAddPhoto: interactionLocked ? null : onAddPhoto,
                  onContinue: onContinue,
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    primary: false,
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOverLocalPhotoLimit) ...[
                          const SizedBox(height: 5),
                          _ReceiptLocalPhotoLimitStrip(
                            photoCount: photoCount,
                            deviceCapability: deviceCapability,
                          ),
                        ],
                        if (hasMultiplePhotos &&
                            uiConfig.showSecondaryTools) ...[
                          const SizedBox(height: 5),
                          _ReceiptMultiPhotoActionRail(
                            selectedIndex: selectedIndex,
                            total: photoCount,
                            onAddPhoto: interactionLocked ? null : onAddPhoto,
                            onOrder: interactionLocked
                                ? null
                                : () => onModeChanged(_ReceiptReviewMode.order),
                            onMatch: interactionLocked
                                ? null
                                : () =>
                                      onModeChanged(_ReceiptReviewMode.stitch),
                            onCrop: interactionLocked
                                ? null
                                : () => onModeChanged(_ReceiptReviewMode.crop),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: compactControls
                                ? 42
                                : uiConfig.photoThumbnailHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: photoPaths.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                return _ReceiptOrderThumbnail(
                                  path: photoPaths[index],
                                  index: index,
                                  total: photoPaths.length,
                                  selected: index == effectiveSelectedIndex,
                                  onTap: interactionLocked
                                      ? null
                                      : () => onPhotoSelected(index),
                                );
                              },
                            ),
                          ),
                        ],
                        if (!hasMultiplePhotos && hasQualityWarning) ...[
                          const SizedBox(height: 5),
                          _ReceiptPhotoQualityRecoveryStrip(
                            quality: selectedQualityCheck,
                            nativeWarning: nativeWarning,
                            compact: compactControls,
                            hasCriticalQualityIssue: hasCriticalQualityIssue,
                            openingCamera: interactionLocked,
                            onAddPhoto: onAddPhoto,
                            onRetake: onRetake,
                            onCrop: interactionLocked
                                ? null
                                : () => onModeChanged(_ReceiptReviewMode.crop),
                            coverageDecision: coverageDecision,
                          ),
                        ],
                        if (!hasMultiplePhotos && !hasQualityWarning) ...[
                          const SizedBox(height: 5),
                          _ReceiptSinglePhotoActionRow(
                            openingCamera: interactionLocked,
                            onAddPhoto: onAddPhoto,
                            onRetake: onRetake,
                            onModeChanged: onModeChanged,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
