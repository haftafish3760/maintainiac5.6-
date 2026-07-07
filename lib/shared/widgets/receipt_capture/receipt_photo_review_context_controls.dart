part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewContextRow extends StatelessWidget {
  const _ReceiptReviewContextRow({
    required this.selectedIndex,
    required this.photoCount,
    required this.reviewMode,
    required this.dataSaverLevel,
    required this.storagePreview,
    required this.selectedQualityCheck,
    required this.selectedCaptureDiagnostics,
    required this.bestShotCandidateMode,
    required this.openingCamera,
    required this.canRemove,
    required this.onAddPhoto,
    required this.onRetake,
    required this.onRemove,
  });

  final int selectedIndex;
  final int photoCount;
  final _ReceiptReviewMode reviewMode;
  final ReceiptDataSaverLevel dataSaverLevel;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;
  final Map<String, Object?>? selectedCaptureDiagnostics;
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
                    label: 'Add Another Photo',
                    emphasized: true,
                    onPressed: openingCamera ? null : onAddPhoto,
                  ),
                  const SizedBox(width: 6),
                  _MiniReceiptActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: _ReceiptPhotoSectionLabels.retakeLabel(
                      index: selectedIndex,
                      total: photoCount,
                    ),
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
      if (preview == null) return 'Checking saved proof size.';
      final mode = preview.level.usesGrayscale ? 'black and white' : 'color';
      return 'Saved proof: ${preview.estimatedLabel}, $mode. OCR uses the clear photo first.';
    }
    if (reviewMode == _ReceiptReviewMode.stitch && photoCount > 1) {
      return 'Review how the receipt photos connect before the app opens receipt details.';
    }
    if (reviewMode == _ReceiptReviewMode.order && photoCount > 1) {
      return _ReceiptPhotoSectionLabels.selectedReviewGuidance(
        selectedIndex: selectedIndex,
        total: photoCount,
      );
    }
    if (photoCount > 1) {
      return _ReceiptPhotoSectionLabels.selectedReviewGuidance(
        selectedIndex: selectedIndex,
        total: photoCount,
      );
    }
    final readinessCopy = _ReceiptCaptureReadinessReviewCopy.fromDiagnostics(
      selectedCaptureDiagnostics,
    );
    if (readinessCopy != null) return readinessCopy.contextStatus;
    final quality = selectedQualityCheck;
    if (quality != null && quality.needsReview) {
      return '${quality.reviewGuidance} If the store, date, total, and item prices are readable, use this photo.';
    }
    return 'Photo captured locally. Use this photo, retake it, or add another photo if the receipt continues.';
  }
}

class _ReceiptCaptureReadinessReviewCopy {
  const _ReceiptCaptureReadinessReviewCopy._({
    required this.contextStatus,
    required this.previewStatus,
  });

  final String contextStatus;
  final String previewStatus;

  static _ReceiptCaptureReadinessReviewCopy? fromDiagnostics(
    Map<String, Object?>? diagnostics,
  ) {
    final rawCode =
        diagnostics?[ReceiptCaptureDiagnosticKeys.captureReadinessCode]
            ?.toString()
            .trim() ??
        '';
    if (rawCode.isEmpty) return null;
    return switch (rawCode) {
      'auto_capture_ready' => const _ReceiptCaptureReadinessReviewCopy._(
        contextStatus:
            'Receipt looked steady at capture. Use this photo, or add another photo only if the receipt continues.',
        previewStatus:
            'Receipt looked steady at capture. Use this photo, or add another photo only if the receipt continues.',
      ),
      'manual_only_check_framing' => const _ReceiptCaptureReadinessReviewCopy._(
        contextStatus:
            'Check that every receipt line is visible. Retake if the edges are cut off, or use this photo if the full receipt is readable.',
        previewStatus:
            'Check that every receipt line is visible. Retake if the edges are cut off, or use this photo if the full receipt is readable.',
      ),
      'manual_only_quality_retake_recommended' =>
        const _ReceiptCaptureReadinessReviewCopy._(
          contextStatus:
              'Retake is safer for OCR quality. Use this photo only if the store, date, total, and item prices are readable.',
          previewStatus:
              'Retake is safer for receipt reading. Use this photo only if the store, date, total, and item prices are readable.',
        ),
      'manual_only_quality_review' => const _ReceiptCaptureReadinessReviewCopy._(
        contextStatus:
            'Check sharpness, light, and receipt text before relying on automatic capture. Retake if prices look fuzzy, or use this photo if the receipt is readable.',
        previewStatus:
            'Check sharpness, light, and receipt text. Retake if prices look fuzzy, or use this photo if the receipt is readable.',
      ),
      'auto_capture_waiting_for_stability' =>
        const _ReceiptCaptureReadinessReviewCopy._(
          contextStatus:
              'This capture was taken before automatic capture considered the frame steady. Check sharpness, then retake or use this photo.',
          previewStatus:
              'This capture was taken before automatic capture considered the frame steady. Check sharpness, then retake or use this photo.',
        ),
      'manual_ready_auto_capture_off' => const _ReceiptCaptureReadinessReviewCopy._(
        contextStatus:
            'Manual capture was used. Use this photo, or add another photo only if the receipt continues.',
        previewStatus:
            'Manual capture was used. Use this photo, or add another photo only if the receipt continues.',
      ),
      _ => null,
    };
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
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 19, semanticLabel: semanticLabel ?? label),
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
