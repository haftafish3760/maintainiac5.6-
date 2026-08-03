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
            // The multi-photo preview tray is intentionally capped so the
            // receipt stays visible. Its normal three-action, arrange, and
            // continue layout needs more than that cap, which previously
            // overflowed below the system navigation bar and made taps hit
            // the wrong action. Use the compact two-row arrangement whenever
            // the available tray height cannot accommodate the full layout.
            final compactControls =
                constraints.maxHeight.isFinite && constraints.maxHeight < 210;
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
                  onCrop: interactionLocked
                      ? null
                      : () => onModeChanged(_ReceiptReviewMode.crop),
                  onArrange: !hasMultiplePhotos || interactionLocked
                      ? null
                      : () => onModeChanged(_ReceiptReviewMode.order),
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
                        if (!hasMultiplePhotos && hasQualityWarning) ...[
                          const SizedBox(height: 5),
                          _ReceiptPhotoQualityRecoveryStrip(
                            quality: selectedQualityCheck,
                            nativeWarning: nativeWarning,
                            compact: compactControls,
                            hasCriticalQualityIssue: hasCriticalQualityIssue,
                            coverageDecision: coverageDecision,
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
