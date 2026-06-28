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
                        onSelected: onModeChanged,
                      ),
                      const SizedBox(height: 6),
                      _ReceiptToolModeHeader(
                        reviewMode: reviewMode,
                        photoCount: photoPaths.length,
                        onBackToPreview: () =>
                            onModeChanged(_ReceiptReviewMode.preview),
                      ),
                      const SizedBox(height: 6),
                      _ReceiptReviewContextRow(
                        photoCount: photoPaths.length,
                        reviewMode: reviewMode,
                        dataSaverLevel: dataSaverLevel,
                        storagePreview: storagePreview,
                        selectedQualityCheck: selectedQualityCheck,
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
                          disabled: savingPhotos,
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
                                label: 'Preparing receipt details...',
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
    if (reviewMode == _ReceiptReviewMode.preview &&
        selectedQualityCheck?.hasCriticalIssue == true) {
      return 'Next Anyway';
    }
    if (bestShotCandidateMode || photoPaths.length == 1) {
      return 'Next';
    }
    if (reviewMode != _ReceiptReviewMode.stitch) {
      return photoPaths.length > 1 ? 'Check Match' : 'Next';
    }
    if (stitchPreviewInFlight || stitchPreview == null) {
      return 'Checking Match';
    }
    if (stitchPreview?.didStitch == true) {
      return 'Next';
    }
    if (stitchPreview?.usedFallback == true) {
      return 'Next';
    }
    return 'Next';
  }
}

class _ReceiptPreviewActionTray extends StatelessWidget {
  const _ReceiptPreviewActionTray({
    required this.photoPaths,
    required this.selectedIndex,
    required this.selectedQualityCheck,
    required this.selectedCaptureDiagnostics,
    required this.openingCamera,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onPhotoSelected,
    required this.onModeChanged,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onContinue,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final Map<String, Object?>? selectedCaptureDiagnostics;
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
    final statusText = _statusText;
    final statusIcon = _statusIcon;
    final statusColor = _statusColor;
    final photoCount = photoPaths.length;
    final hasMultiplePhotos = photoCount > 1;
    final nativeWarning = _nativeCaptureReviewWarning;
    final hasCriticalQualityIssue =
        selectedQualityCheck?.hasCriticalIssue == true ||
        nativeWarning?.isCritical == true;
    final hasQualityWarning =
        selectedQualityCheck?.needsReview == true ||
        selectedQualityCheck?.hasCriticalIssue == true ||
        nativeWarning != null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xE8050607),
        border: Border(top: BorderSide(color: Color(0x99344047))),
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
                _ReceiptPreviewPrimaryRow(
                  current: selectedIndex + 1,
                  total: photoCount,
                  statusIcon: statusIcon,
                  statusColor: statusColor,
                  statusText: statusText,
                  compact: compactControls,
                  savingPhotos: savingPhotos,
                  continueLabel: continueLabel,
                  onContinue: onContinue,
                ),
                if (hasMultiplePhotos) ...[
                  const SizedBox(height: 5),
                  _ReceiptSectionStripHeader(
                    selectedIndex: selectedIndex,
                    total: photoCount,
                    onAddPhoto: openingCamera ? null : onAddPhoto,
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: compactControls ? 50 : 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPaths.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        return _ReceiptOrderThumbnail(
                          path: photoPaths[index],
                          index: index,
                          total: photoPaths.length,
                          selected: index == selectedIndex,
                          onTap: () => onPhotoSelected(index),
                        );
                      },
                    ),
                  ),
                ],
                if (!hasMultiplePhotos && hasQualityWarning) ...[
                  const SizedBox(height: 5),
                  _ReceiptPhotoQualityRecoveryStrip(
                    quality: selectedQualityCheck,
                    compact: compactControls,
                    hasCriticalQualityIssue: hasCriticalQualityIssue,
                    openingCamera: openingCamera,
                    onAddPhoto: onAddPhoto,
                    onRetake: onRetake,
                    onCrop: () => onModeChanged(_ReceiptReviewMode.crop),
                  ),
                ],
                if (!hasMultiplePhotos && !hasQualityWarning) ...[
                  const SizedBox(height: 5),
                  _ReceiptSinglePhotoActionRow(
                    openingCamera: openingCamera,
                    onAddPhoto: onAddPhoto,
                    onRetake: onRetake,
                    onModeChanged: onModeChanged,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  IconData get _statusIcon {
    final nativeWarning = _nativeCaptureReviewWarning;
    if (nativeWarning != null) return nativeWarning.icon;
    final quality = selectedQualityCheck;
    if (quality?.hasCriticalIssue == true) {
      if (quality!.isTooDark) return Icons.light_mode_rounded;
      if (quality.isTooBright) return Icons.flare_rounded;
      return Icons.warning_amber_rounded;
    }
    if (quality?.needsReview == true) return Icons.info_outline_rounded;
    if (photoPaths.length > 1) return Icons.layers_rounded;
    return Icons.receipt_long_rounded;
  }

  Color get _statusColor {
    final nativeWarning = _nativeCaptureReviewWarning;
    if (nativeWarning != null) return nativeWarning.color;
    final quality = selectedQualityCheck;
    if (quality?.hasCriticalIssue == true) return const Color(0xFFFFB020);
    if (quality != null && quality.reviewScore >= 70) {
      return const Color(0xFF8EF6A4);
    }
    if (quality?.needsReview == true) return const Color(0xFFFFD166);
    return const Color(0xFF8EF6A4);
  }

  String get _statusText {
    final photoCount = photoPaths.length;
    if (photoCount > 1) {
      return '$photoCount receipt photos ready. Check order, add the next section if needed, or tap Next to review item prices.';
    }
    final nativeWarning = _nativeCaptureReviewWarning;
    if (nativeWarning != null) return nativeWarning.message;
    final quality = selectedQualityCheck;
    if (quality != null) {
      return '${quality.userFacingStatusLabel} ${quality.qualityEvidenceLabel}. Add a photo if the receipt continues, or tap Next to review item prices.';
    }
    return 'Photo captured. Add a photo if the receipt continues, crop or retake if needed, or tap Next to review item prices.';
  }

  _NativeCaptureReviewWarning? get _nativeCaptureReviewWarning {
    final diagnostics = selectedCaptureDiagnostics;
    if (diagnostics == null || diagnostics.isEmpty) return null;
    final mismatch = diagnostics['latestCapturedExposureMismatch'];
    final qualitySignal = diagnostics['latestCapturedQualitySignal'];
    final brightnessBucket = diagnostics['latestCapturedBrightnessBucket'];
    final sharpnessBucket = diagnostics['latestCapturedSharpnessBucket'];
    if (mismatch == 'live_ok_capture_too_dark' ||
        qualitySignal == 'retake_brightness_risk' ||
        brightnessBucket == 'captured_too_dark') {
      return const _NativeCaptureReviewWarning(
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFFB020),
        isCritical: true,
        message:
            'Photo saved darker than the camera preview. Retake with more light or raise Brightness before Next.',
      );
    }
    if (mismatch == 'live_ok_capture_dim' ||
        brightnessBucket == 'captured_dim') {
      return const _NativeCaptureReviewWarning(
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFFD166),
        message:
            'Photo saved a little dimmer than preview. Check the receipt text, retake, or tap Next if it is readable.',
      );
    }
    if (qualitySignal == 'retake_blur_risk' ||
        sharpnessBucket == 'captured_soft') {
      return const _NativeCaptureReviewWarning(
        icon: Icons.motion_photos_pause_rounded,
        color: Color(0xFFFFB020),
        isCritical: true,
        message:
            'Photo may be too soft for receipt reading. Retake while holding steady, then tap Next.',
      );
    }
    if (brightnessBucket == 'captured_glare_risk') {
      return const _NativeCaptureReviewWarning(
        icon: Icons.flare_rounded,
        color: Color(0xFFFFD166),
        message:
            'Photo may have glare. Tilt the receipt or lighting, retake, or tap Next if the text is readable.',
      );
    }
    return null;
  }
}

class _NativeCaptureReviewWarning {
  const _NativeCaptureReviewWarning({
    required this.icon,
    required this.color,
    required this.message,
    this.isCritical = false,
  });

  final IconData icon;
  final Color color;
  final String message;
  final bool isCritical;
}

class _ReceiptPreviewPrimaryRow extends StatelessWidget {
  const _ReceiptPreviewPrimaryRow({
    required this.current,
    required this.total,
    required this.statusIcon,
    required this.statusColor,
    required this.statusText,
    required this.compact,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onContinue,
  });

  final int current;
  final int total;
  final IconData statusIcon;
  final Color statusColor;
  final String statusText;
  final bool compact;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1316),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 5 : 7, 8, compact ? 5 : 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ReceiptPhotoCountBadge(current: current, total: total),
            const SizedBox(width: 8),
            Icon(statusIcon, color: statusColor, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                statusText,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 11,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 92),
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: savingPhotos
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  savingPhotos ? 'Preparing' : continueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(92, 38),
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSectionStripHeader extends StatelessWidget {
  const _ReceiptSectionStripHeader({
    required this.selectedIndex,
    required this.total,
    required this.onAddPhoto,
  });

  final int selectedIndex;
  final int total;
  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Row(
          children: [
            const Icon(
              Icons.format_list_numbered_rounded,
              color: Color(0xFFFFD166),
              size: 16,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ReceiptPhotoSectionLabels.orderedStripTitle(total: total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    _ReceiptPhotoSectionLabels.orderedStripHint(
                      selectedIndex: selectedIndex,
                      total: total,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _ReceiptMiniRecoveryButton(
              icon: Icons.add_a_photo_rounded,
              label: _ReceiptPhotoSectionLabels.addNextSectionLabel(
                total: total,
              ),
              onPressed: onAddPhoto,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptSinglePhotoActionRow extends StatelessWidget {
  const _ReceiptSinglePhotoActionRow({
    required this.openingCamera,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onModeChanged,
  });

  final bool openingCamera;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final ValueChanged<_ReceiptReviewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.add_a_photo_rounded,
            label: 'Add Another Photo',
            emphasized: true,
            onPressed: openingCamera ? null : onAddPhoto,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.camera_alt_rounded,
            label: 'Retake',
            onPressed: openingCamera ? null : onRetake,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onPressed: () => onModeChanged(_ReceiptReviewMode.crop),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _ReceiptActionRailButton(
            icon: Icons.storage_rounded,
            label: 'Save Space',
            onPressed: () => onModeChanged(_ReceiptReviewMode.dataSaver),
          ),
        ),
      ],
    );
  }
}

class _ReceiptPhotoCountBadge extends StatelessWidget {
  const _ReceiptPhotoCountBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111A1F),
        border: Border.all(color: const Color(0xFF43515A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          '$current/$total',
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ReceiptPhotoQualityRecoveryStrip extends StatelessWidget {
  const _ReceiptPhotoQualityRecoveryStrip({
    required this.quality,
    required this.compact,
    required this.hasCriticalQualityIssue,
    required this.openingCamera,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onCrop,
  });

  final ReceiptPhotoQualityCheck? quality;
  final bool compact;
  final bool hasCriticalQualityIssue;
  final bool openingCamera;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) {
    final photoQuality = quality;
    final title = hasCriticalQualityIssue
        ? 'Retake Recommended'
        : photoQuality?.nextReviewActionLabel ?? 'Check Photo Before Next';
    final detail = photoQuality == null
        ? null
        : '${photoQuality.reviewGuidance} ${photoQuality.qualityEvidenceLabel}.';
    final fallbackDetail =
        'Make sure the store, date, total, and item prices are readable.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasCriticalQualityIssue
            ? const Color(0xFF2B1F11)
            : const Color(0xFF1D261B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasCriticalQualityIssue
              ? const Color(0xFFFFB020)
              : const Color(0xFF8EF6A4),
          width: .9,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 5 : 7, 8, compact ? 5 : 7),
        child: Row(
          children: [
            Icon(
              hasCriticalQualityIssue
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: hasCriticalQualityIssue
                  ? const Color(0xFFFFB020)
                  : const Color(0xFF8EF6A4),
              size: 18,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (!compact)
                    Text(
                      detail ?? fallbackDetail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ReceiptMiniRecoveryButton(
              icon: Icons.camera_alt_rounded,
              label: 'Retake',
              onPressed: openingCamera ? null : onRetake,
              emphasized: hasCriticalQualityIssue,
            ),
            const SizedBox(width: 6),
            _ReceiptMiniRecoveryButton(
              icon: Icons.crop_rounded,
              label: 'Crop',
              onPressed: onCrop,
            ),
            const SizedBox(width: 6),
            _ReceiptMiniRecoveryButton(
              icon: Icons.add_a_photo_rounded,
              label: 'Add Photo',
              onPressed: openingCamera ? null : onAddPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMiniRecoveryButton extends StatelessWidget {
  const _ReceiptMiniRecoveryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: emphasized
            ? const Color(0xFFFFB020)
            : const Color(0xFF2D3A40),
        foregroundColor: emphasized ? const Color(0xFF101416) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReceiptPersistentContinueButton extends StatelessWidget {
  const _ReceiptPersistentContinueButton({
    required this.enabled,
    required this.savingPhotos,
    required this.label,
    required this.onContinue,
  });

  final bool enabled;
  final bool savingPhotos;
  final String label;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onContinue : null,
      icon: savingPhotos
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.document_scanner_rounded),
      label: Text(savingPhotos ? 'Preparing Review' : label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReceiptActionRailButton extends StatelessWidget {
  const _ReceiptActionRailButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        backgroundColor: emphasized
            ? const Color(0xFFFFD166)
            : const Color(0xFF172126),
        disabledBackgroundColor: const Color(0xFF283137),
        foregroundColor: emphasized
            ? const Color(0xFF101416)
            : const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF758188),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReceiptReviewStepStrip extends StatelessWidget {
  const _ReceiptReviewStepStrip({
    required this.selected,
    required this.photoCount,
    required this.onSelected,
  });

  final _ReceiptReviewMode selected;
  final int photoCount;
  final ValueChanged<_ReceiptReviewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StepStripButton(
            label: 'Review',
            icon: Icons.visibility_rounded,
            selected: selected == _ReceiptReviewMode.preview,
            onTap: () => onSelected(_ReceiptReviewMode.preview),
          ),
          const SizedBox(width: 6),
          _StepStripButton(
            label: 'Crop',
            icon: Icons.crop_rounded,
            selected: selected == _ReceiptReviewMode.crop,
            onTap: () => onSelected(_ReceiptReviewMode.crop),
          ),
          const SizedBox(width: 6),
          _StepStripButton(
            label: 'Photo Order',
            icon: Icons.swap_vert_rounded,
            selected: selected == _ReceiptReviewMode.order,
            onTap: photoCount > 1
                ? () => onSelected(_ReceiptReviewMode.order)
                : null,
          ),
          const SizedBox(width: 6),
          _StepStripButton(
            label: 'Match Photos',
            icon: Icons.join_full_rounded,
            selected: selected == _ReceiptReviewMode.stitch,
            onTap: photoCount > 1
                ? () => onSelected(_ReceiptReviewMode.stitch)
                : null,
          ),
          const SizedBox(width: 6),
          _StepStripButton(
            label: 'Save Space',
            icon: Icons.storage_rounded,
            selected: selected == _ReceiptReviewMode.dataSaver,
            onTap: () => onSelected(_ReceiptReviewMode.dataSaver),
          ),
        ],
      ),
    );
  }
}

class _StepStripButton extends StatelessWidget {
  const _StepStripButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFFFFD166)
            : const Color(0xFF172126),
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        minimumSize: const Size(92, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ReceiptToolModeHeader extends StatelessWidget {
  const _ReceiptToolModeHeader({
    required this.reviewMode,
    required this.photoCount,
    required this.onBackToPreview,
  });

  final _ReceiptReviewMode reviewMode;
  final int photoCount;
  final VoidCallback onBackToPreview;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = switch (reviewMode) {
      _ReceiptReviewMode.crop => (
        Icons.crop_rounded,
        'Crop Receipt',
        'Adjust the image edges, rotate, or straighten before review.',
      ),
      _ReceiptReviewMode.order => (
        Icons.swap_vert_rounded,
        'Check Photo Order',
        'Photo 1 is the top; each next photo continues lower.',
      ),
      _ReceiptReviewMode.stitch => (
        Icons.join_full_rounded,
        'Long Receipt Match',
        photoCount > 1
            ? 'Match photos only when safe; otherwise Next reviews top to bottom.'
            : 'Add another photo before matching.',
      ),
      _ReceiptReviewMode.dataSaver => (
        Icons.storage_rounded,
        'Cleanup And Backup',
        'Preview the backup image. Receipt reading still uses the clearest source first.',
      ),
      _ReceiptReviewMode.preview => (
        Icons.visibility_rounded,
        'Review Receipt',
        'Check the photo before opening the receipt details.',
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD166), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onBackToPreview,
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('Preview'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD166),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptReviewContextRow extends StatelessWidget {
  const _ReceiptReviewContextRow({
    required this.photoCount,
    required this.reviewMode,
    required this.dataSaverLevel,
    required this.storagePreview,
    required this.selectedQualityCheck,
    required this.bestShotCandidateMode,
    required this.openingCamera,
    required this.canRemove,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onRemove,
  });

  final int photoCount;
  final _ReceiptReviewMode reviewMode;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final bool bestShotCandidateMode;
  final bool openingCamera;
  final bool canRemove;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final status = _statusText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1316),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: const Color(0xFFFFD166), size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _MiniReceiptActionButton(
                    icon: Icons.add_a_photo_rounded,
                    label: photoCount > 1
                        ? 'Add Next Section'
                        : 'Add Another Photo',
                    emphasized: true,
                    onPressed: openingCamera ? null : onAddPhoto,
                  ),
                  const SizedBox(width: 6),
                  _MiniReceiptActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Retake',
                    onPressed: openingCamera ? null : onRetake,
                  ),
                  const SizedBox(width: 6),
                  _MiniReceiptActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    onPressed: canRemove ? onRemove : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _statusIcon {
    return switch (reviewMode) {
      _ReceiptReviewMode.preview => Icons.receipt_long_rounded,
      _ReceiptReviewMode.crop => Icons.crop_rounded,
      _ReceiptReviewMode.order => Icons.swap_vert_rounded,
      _ReceiptReviewMode.stitch => Icons.join_full_rounded,
      _ReceiptReviewMode.dataSaver => Icons.storage_rounded,
    };
  }

  String get _statusText {
    if (reviewMode == _ReceiptReviewMode.dataSaver) {
      final preview = storagePreview;
      if (preview == null) return 'Checking backup image size.';
      final mode = preview.level.usesGrayscale ? 'black and white' : 'color';
      return 'Backup image: ${preview.estimatedLabel}, $mode. OCR uses the clear photo first.';
    }
    if (reviewMode == _ReceiptReviewMode.stitch && photoCount > 1) {
      return 'Review how the receipt photos connect before the app fills the receipt review.';
    }
    if (reviewMode == _ReceiptReviewMode.order && photoCount > 1) {
      return 'Photo 1 should be the top of the receipt, then continue downward.';
    }
    if (photoCount > 1) {
      return 'Photo 1 starts at the top. Use Order if the photos are mixed up.';
    }
    final quality = selectedQualityCheck;
    if (quality != null && quality.needsReview) {
      return quality.reviewGuidance;
    }
    return 'If the receipt continues, add another photo. Otherwise tap Next to review item prices.';
  }
}

class _MiniReceiptActionButton extends StatelessWidget {
  const _MiniReceiptActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 32),
        backgroundColor: emphasized
            ? const Color(0xFFFFD166)
            : const Color(0xFF172126),
        disabledBackgroundColor: const Color(0xFF11181B),
        foregroundColor: emphasized
            ? const Color(0xFF101416)
            : const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF6F7A80),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MiniReceiptIconButton extends StatelessWidget {
  const _MiniReceiptIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF172126),
          disabledBackgroundColor: const Color(0xFF11181B),
          foregroundColor: const Color(0xFFE8ECEE),
          disabledForegroundColor: const Color(0xFF6F7A80),
          minimumSize: const Size(35, 35),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }
}

class _ReceiptOcrProofLaneCard extends StatelessWidget {
  const _ReceiptOcrProofLaneCard({
    required this.selected,
    required this.storagePreview,
    required this.selectedQualityCheck,
  });

  final ReceiptDataSaverLevel selected;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;

  @override
  Widget build(BuildContext context) {
    final quality = selectedQualityCheck ?? storagePreview?.quality;
    final sourceStatus = quality == null
        ? 'Preparing OCR source'
        : quality.hasCriticalIssue
        ? 'OCR source needs review'
        : quality.needsReview
        ? 'OCR source usable with review'
        : 'OCR source looks readable';
    final backupStatus = storagePreview == null
        ? 'Checking backup image size'
        : '${storagePreview!.estimatedLabel} ${selected.backupStyleLabel}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Receipt Details And Backup Image',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _ReceiptLaneChip(
                    icon: Icons.document_scanner_rounded,
                    title: 'Read First',
                    detail: sourceStatus,
                    emphasized: !(quality?.hasCriticalIssue ?? false),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ReceiptLaneChip(
                    icon: Icons.savings_rounded,
                    title: 'Save After',
                    detail: backupStatus,
                    emphasized: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              selected.cleanupLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLaneChip extends StatelessWidget {
  const _ReceiptLaneChip({
    required this.icon,
    required this.title,
    required this.detail,
    required this.emphasized,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? const Color(0xFF58D67D)
        : const Color(0xFFFFD166);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? const Color(0x221CB85C) : const Color(0x22FFD166),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptOrderToolControls extends StatelessWidget {
  const _ReceiptOrderToolControls({
    required this.photoPaths,
    required this.selectedIndex,
    required this.openingCamera,
    required this.onPhotoSelected,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onAddPhoto,
    required this.onRetake,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final bool openingCamera;
  final ValueChanged<int> onPhotoSelected;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final canMoveEarlier = selectedIndex > 0;
    final canMoveLater = selectedIndex < photoPaths.length - 1;
    final sectionLabel = _ReceiptPhotoSectionLabels.label(
      index: selectedIndex,
      total: photoPaths.length,
    );
    final sectionHint = _ReceiptPhotoSectionLabels.orderHint(
      index: selectedIndex,
      total: photoPaths.length,
    );
    final countLabel = _ReceiptPhotoSectionLabels.countLabel(
      index: selectedIndex,
      total: photoPaths.length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$sectionLabel, $countLabel. $sectionHint Next reviews photos in this order.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  return _ReceiptOrderThumbnail(
                    path: photoPaths[index],
                    index: index,
                    total: photoPaths.length,
                    selected: index == selectedIndex,
                    onTap: () => onPhotoSelected(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveEarlier ? onMoveEarlier : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                    label: Text(
                      _ReceiptPhotoSectionLabels.moveEarlierLabel(
                        index: selectedIndex,
                      ),
                    ),
                    style: _orderButtonStyle(),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveLater ? onMoveLater : null,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 17),
                    label: Text(
                      _ReceiptPhotoSectionLabels.moveLaterLabel(
                        index: selectedIndex,
                        total: photoPaths.length,
                      ),
                    ),
                    style: _orderButtonStyle(),
                  ),
                ),
                const SizedBox(width: 7),
                _MiniReceiptIconButton(
                  icon: Icons.add_a_photo_rounded,
                  label: _ReceiptPhotoSectionLabels.addNextPhotoLabel(
                    index: selectedIndex,
                    total: photoPaths.length,
                  ),
                  onPressed: openingCamera ? null : onAddPhoto,
                ),
                const SizedBox(width: 5),
                _MiniReceiptIconButton(
                  icon: Icons.camera_alt_rounded,
                  label: _ReceiptPhotoSectionLabels.retakeLabel(
                    index: selectedIndex,
                    total: photoPaths.length,
                  ),
                  onPressed: openingCamera ? null : onRetake,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _orderButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE8ECEE),
      disabledForegroundColor: const Color(0xFF76848A),
      side: const BorderSide(color: Color(0xFF526168), width: .9),
      minimumSize: const Size(0, 39),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
    );
  }
}

class _ReceiptOrderThumbnail extends StatelessWidget {
  const _ReceiptOrderThumbnail({
    required this.path,
    required this.index,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String path;
  final int index;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF172126),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? const Color(0xFFFFD166) : const Color(0xFF344047),
            width: selected ? 2 : 1,
          ),
        ),
        child: SizedBox(
          width: 66,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFF050607),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF76848A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xDD050607),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      _ReceiptPhotoSectionLabels.label(
                        index: index,
                        total: total,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xDD050607),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      _ReceiptPhotoSectionLabels.sectionNumberLabel(
                        index: index,
                        total: total,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptManualStitchControls extends StatelessWidget {
  const _ReceiptManualStitchControls({
    required this.pairIndex,
    required this.totalPairs,
    required this.manualOverlapFraction,
    required this.stitchPreview,
    required this.stitchPreviewInFlight,
    required this.disabled,
    required this.onPairSelected,
    required this.onOverlapChanged,
    required this.onClear,
    required this.onOpenOrder,
  });

  final int pairIndex;
  final int totalPairs;
  final double? manualOverlapFraction;
  final ReceiptStitchResult? stitchPreview;
  final bool stitchPreviewInFlight;
  final bool disabled;
  final ValueChanged<int> onPairSelected;
  final ValueChanged<double> onOverlapChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final overlap = manualOverlapFraction ?? .22;
    final percent = (overlap * 100).round();
    final pairCountLabel =
        'Sections ${pairIndex + 1}-${pairIndex + 2} of ${totalPairs + 1}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled || pairIndex == 0
                        ? null
                        : () => onPairSelected(pairIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('Previous Pair'),
                    style: _smallStitchButtonStyle(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pairCountLabel,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled || pairIndex >= totalPairs - 1
                        ? null
                        : () => onPairSelected(pairIndex + 1),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: const Text('Next Pair'),
                    style: _smallStitchButtonStyle(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.join_full_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    manualOverlapFraction == null
                        ? 'Automatic match. If repeated receipt text does not line up, adjust this pair.'
                        : 'Manual match: $percent%. Line up the repeated receipt text.',
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: disabled || manualOverlapFraction == null
                      ? null
                      : onClear,
                  child: const Text('Use Auto'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Slide until the bottom of the first section matches the top of the next section.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _ReceiptStitchGuideChip(
                    label: 'Bottom of section ${pairIndex + 1}',
                    icon: Icons.vertical_align_bottom_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ReceiptStitchGuideChip(
                    label: 'Top of section ${pairIndex + 2}',
                    icon: Icons.vertical_align_top_rounded,
                  ),
                ),
                const SizedBox(width: 6),
                _ReceiptStitchGuideChip(
                  label: '$percent%',
                  icon: Icons.compare_arrows_rounded,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Slider(
              value: overlap,
              min: .08,
              max: .48,
              divisions: 20,
              activeColor: const Color(0xFFFFD166),
              inactiveColor: const Color(0xFF526168),
              label: '$percent%',
              onChanged: disabled ? null : onOverlapChanged,
            ),
            _ReceiptStitchReadinessCard(
              stitchPreview: stitchPreview,
              rebuilding: stitchPreviewInFlight,
              selectedPairIndex: pairIndex,
              onOpenOrder: disabled ? null : onOpenOrder,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _smallStitchButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE8ECEE),
      disabledForegroundColor: const Color(0xFF76848A),
      side: const BorderSide(color: Color(0xFF526168), width: .9),
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
    );
  }
}

class _ReceiptStitchReadinessCard extends StatelessWidget {
  const _ReceiptStitchReadinessCard({
    required this.stitchPreview,
    required this.rebuilding,
    required this.selectedPairIndex,
    required this.onOpenOrder,
  });

  final ReceiptStitchResult? stitchPreview;
  final bool rebuilding;
  final int selectedPairIndex;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final preview = stitchPreview;
    final readyColor = preview?.didStitch == true
        ? const Color(0xFF28A745)
        : const Color(0xFFFFD166);
    final label = rebuilding
        ? 'Checking receipt photos...'
        : _stitchReadinessLabel(preview);
    final detail = rebuilding
        ? 'Maintainiac is testing whether one readable receipt image can be made.'
        : _stitchReadinessDetail(preview);
    ReceiptStitchPairResult? selectedPair;
    final pairs = preview?.pairs ?? const <ReceiptStitchPairResult>[];
    for (final pair in pairs) {
      if (pair.pairIndex == selectedPairIndex) {
        selectedPair = pair;
        break;
      }
    }
    final failedPairLabel = preview?.failedPairLabel ?? '';
    final selectedPairLabel = selectedPair == null
        ? failedPairLabel.isEmpty
              ? ''
              : '$failedPairLabel needs adjustment.'
        : selectedPair.summaryLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: readyColor.withValues(alpha: .75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                rebuilding
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: readyColor,
                        ),
                      )
                    : Icon(
                        preview?.didStitch == true
                            ? Icons.done_all_rounded
                            : Icons.call_split_rounded,
                        color: readyColor,
                        size: 19,
                      ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (selectedPairLabel.isNotEmpty) ...[
                        Text(
                          selectedPairLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        detail,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Decision: ${preview.reviewDecisionLabel}. ${preview.nextStepLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FD3FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _ReceiptStitchEvidenceChip(
                              label: preview.stitchSafetyLabel,
                              icon: preview.didStitch
                                  ? Icons.verified_rounded
                                  : Icons.report_problem_rounded,
                            ),
                            _ReceiptStitchEvidenceChip(
                              label: preview.reviewPathLabel,
                              icon: Icons.receipt_long_rounded,
                            ),
                            if (preview.usedFallback)
                              _ReceiptStitchEvidenceChip(
                                label: preview.userFallbackReasonLabel,
                                icon: Icons.info_outline_rounded,
                              ),
                            if (selectedPair != null)
                              _ReceiptStitchEvidenceChip(
                                label: selectedPair.matchEvidenceLabel,
                                icon: Icons.analytics_rounded,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (preview?.usedFallback == true) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _ReceiptMatchRecoveryPill(
                      icon: Icons.swap_vert_rounded,
                      label: 'Fix Photo Order',
                      onTap: onOpenOrder,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: _ReceiptMatchRecoveryPill(
                      icon: Icons.keyboard_double_arrow_down_rounded,
                      label: 'Next Reviews Top To Bottom',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stitchReadinessLabel(ReceiptStitchResult? preview) {
    if (preview == null) return 'Checking receipt photos...';
    if (preview.didStitch) return 'Combined Receipt Ready';
    if (preview.usedFallback) return 'Safe Fallback Ready';
    return preview.summaryLabel;
  }

  String _stitchReadinessDetail(ReceiptStitchResult? preview) {
    if (preview == null) {
      return 'The app will use one stitched image only when the match is safe.';
    }
    if (preview.didStitch) {
      final pairDiagnostics = preview.pairDiagnosticsLabel;
      return pairDiagnostics.isEmpty
          ? 'Photo overlap matched safely. Next reviews one combined receipt image.'
          : 'Photo overlap matched safely. $pairDiagnostics Next reviews one combined receipt image.';
    }
    if (preview.usedFallback) {
      return preview.warning.trim().isEmpty
          ? '${preview.userFallbackReasonLabel}. Next still works by reviewing each photo from top to bottom.'
          : '${preview.userFallbackReasonLabel}. ${preview.warning} Next still works by reviewing each photo from top to bottom.';
    }
    return preview.detailLabel;
  }
}

class _ReceiptStitchGuideChip extends StatelessWidget {
  const _ReceiptStitchGuideChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF243036),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFFFD166)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptStitchEvidenceChip extends StatelessWidget {
  const _ReceiptStitchEvidenceChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF243036),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF8FD3FF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptMatchRecoveryPill extends StatelessWidget {
  const _ReceiptMatchRecoveryPill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: onTap == null
            ? const Color(0xFF243036)
            : const Color(0xFF2D3A40),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFFFFD166)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: child,
    );
  }
}

class _ReceiptCropActions extends StatelessWidget {
  const _ReceiptCropActions({
    required this.cropProcessing,
    required this.onStraightenLeft,
    required this.onStraightenRight,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetCrop,
    required this.onApplyCrop,
    required this.onCancelCrop,
  });

  final bool cropProcessing;
  final VoidCallback onStraightenLeft;
  final VoidCallback onStraightenRight;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetCrop;
  final VoidCallback onApplyCrop;
  final VoidCallback onCancelCrop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ReceiptCropInstructionStrip(),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              _CropTextAction(
                icon: Icons.close_rounded,
                label: 'Cancel',
                onPressed: cropProcessing ? null : onCancelCrop,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CompactEditButton(
                      icon: Icons.rotate_left_rounded,
                      label: 'Straighten Left',
                      onPressed: cropProcessing ? null : onStraightenLeft,
                    ),
                    _CompactEditButton(
                      icon: Icons.rotate_right_rounded,
                      label: 'Straighten Right',
                      onPressed: cropProcessing ? null : onStraightenRight,
                    ),
                    _CompactEditButton(
                      icon: Icons.undo_rounded,
                      label: 'Rotate Left',
                      onPressed: cropProcessing ? null : onRotateLeft,
                    ),
                    _CompactEditButton(
                      icon: Icons.redo_rounded,
                      label: 'Rotate Right',
                      onPressed: cropProcessing ? null : onRotateRight,
                    ),
                    _CompactEditButton(
                      icon: Icons.fit_screen_rounded,
                      label: 'Reset Edges',
                      onPressed: cropProcessing ? null : onResetCrop,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: cropProcessing ? null : onApplyCrop,
                icon: cropProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(cropProcessing ? 'Cropping' : 'Apply Crop'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(112, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptCropInstructionStrip extends StatelessWidget {
  const _ReceiptCropInstructionStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF526168), width: .8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.crop_rounded, size: 17, color: Color(0xFFFFD166)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Drag the yellow edges until the full receipt is inside the frame.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropTextAction extends StatelessWidget {
  const _CropTextAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF76848A),
        side: const BorderSide(color: Color(0xFF526168), width: .9),
        minimumSize: const Size(96, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CompactEditButton extends StatelessWidget {
  const _CompactEditButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8ECEE),
          side: const BorderSide(color: Color(0xFF526168)),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ReceiptDataSaverStrip extends StatelessWidget {
  const _ReceiptDataSaverStrip({
    required this.selected,
    required this.onSelected,
  });

  final ReceiptDataSaverLevel selected;
  final ValueChanged<ReceiptDataSaverLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _cameraReceiptLevels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _cameraReceiptLevels[index];
          final active = level == selected;
          return SizedBox(
            width: 126,
            child: InkWell(
              onTap: () => onSelected(level),
              borderRadius: BorderRadius.circular(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF172126),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFFFE2A1)
                        : const Color(0xFF526168),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${level.label}: ${level.shortLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF101416)
                              : const Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        level.reviewChoiceLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF263238)
                              : const Color(0xFFC7D0D4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const _cameraReceiptLevels = [
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.maximum,
  ];
}

extension _ReceiptDataSaverReviewCopy on ReceiptDataSaverLevel {
  String get backupStyleLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original => 'local source',
      ReceiptDataSaverLevel.light => 'high quality proof',
      ReceiptDataSaverLevel.balanced => 'normal proof',
      ReceiptDataSaverLevel.strong => 'low-storage proof',
      ReceiptDataSaverLevel.maximum => 'tiny proof',
    };
  }

  String get reviewChoiceLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original => 'Full source stays local only.',
      ReceiptDataSaverLevel.light => 'Best proof for manual review.',
      ReceiptDataSaverLevel.balanced => 'Black-and-white everyday proof.',
      ReceiptDataSaverLevel.strong => 'Stronger contrast, less space.',
      ReceiptDataSaverLevel.maximum => 'Smallest backup; review first.',
    };
  }

  String get cleanupLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original =>
        'No backup compression is applied. The full source is kept locally only when explicitly allowed.',
      ReceiptDataSaverLevel.light =>
        'Cleanup keeps color and detail for review. Use this when the receipt is faint, wrinkled, or hard to inspect.',
      ReceiptDataSaverLevel.balanced =>
        'Cleanup uses black-and-white receipt proof with normal contrast so backup stays smaller without changing the OCR source.',
      ReceiptDataSaverLevel.strong =>
        'Cleanup uses black-and-white plus stronger contrast for low-storage users while preserving the clear OCR source separately.',
      ReceiptDataSaverLevel.maximum =>
        'Cleanup makes the smallest proof copy. Use only after checking the preview is still readable.',
    };
  }
}
