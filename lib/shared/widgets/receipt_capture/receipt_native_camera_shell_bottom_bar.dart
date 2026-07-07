part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraBottomBar extends StatelessWidget {
  const _ReceiptNativeCameraBottomBar({
    required this.capturing,
    required this.capabilities,
    required this.settings,
    required this.onCapture,
    required this.capturedPhotoCount,
    required this.longReceiptMode,
    this.qualityLabel,
    this.onReviewCapturedPhotos,
    this.onAddPhoto,
  });

  final bool capturing;
  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onCapture;
  final int capturedPhotoCount;
  final bool longReceiptMode;
  final String? qualityLabel;
  final VoidCallback? onReviewCapturedPhotos;
  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00050607), Color(0xB8050607)],
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showsNextStepStrip) ...[
                  _ReceiptNativeCameraNextStepStrip(
                    capturedPhotoCount: capturedPhotoCount,
                    longReceiptMode: longReceiptMode,
                    onAddPhoto: onAddPhoto,
                    onReviewCapturedPhotos: onReviewCapturedPhotos!,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: SizedBox()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ReceiptNativeCameraShutterButton(
                        capturing: capturing,
                        onPressed: capturing ? null : onCapture,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final assist = settings.assistedReceiptFill
        ? 'receipt assist'
        : 'manual receipt';
    final quality = qualityLabel == null
        ? 'quality pending'
        : 'quality $qualityLabel';
    final engine = capabilities.engine == ReceiptNativeCameraEngine.unavailable
        ? 'backup camera'
        : 'native camera';
    return '$engine shutter, $assist, $quality';
  }

  bool get _showsNextStepStrip =>
      capturedPhotoCount > 0 && onReviewCapturedPhotos != null;
}

class _ReceiptNativeCameraNextStepStrip extends StatelessWidget {
  const _ReceiptNativeCameraNextStepStrip({
    required this.capturedPhotoCount,
    required this.longReceiptMode,
    required this.onReviewCapturedPhotos,
    this.onAddPhoto,
  });

  final int capturedPhotoCount;
  final bool longReceiptMode;
  final VoidCallback onReviewCapturedPhotos;
  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_showAddPhoto) ...[
          Expanded(
            child: _ReceiptNativeCameraActionButton(
              label: 'Add Photo',
              tooltip: 'Add another receipt photo',
              icon: Icons.add_photo_alternate_rounded,
              outlined: true,
              onPressed: onAddPhoto,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _ReceiptNativeCameraActionButton(
            label: _nextLabel,
            tooltip: 'Done: review captured receipt photos in Maintainiac',
            icon: Icons.arrow_forward_rounded,
            onPressed: onReviewCapturedPhotos,
          ),
        ),
      ],
    );
  }

  bool get _showAddPhoto => longReceiptMode && onAddPhoto != null;

  String get _nextLabel {
    if (capturedPhotoCount <= 1) return 'Done';
    return 'Done ($capturedPhotoCount)';
  }
}

class _ReceiptNativeCameraActionButton extends StatelessWidget {
  const _ReceiptNativeCameraActionButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    if (outlined) {
      return Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE8ECEE),
            side: const BorderSide(color: Color(0xFF526168)),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: child,
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE8ECEE),
          foregroundColor: const Color(0xFF101416),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}
