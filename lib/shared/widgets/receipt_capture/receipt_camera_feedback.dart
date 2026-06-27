part of 'receipt_camera_screen.dart';

extension _ReceiptCameraFeedback on _ReceiptCameraScreenState {
  void _showMessage(String message) {
    if (!mounted || _closingCamera) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _showStorageDialog(String message) async {
    if (!mounted || _closingCamera) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2528),
          title: const Text(
            'Storage Space Needed',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptCameraInteractionHint extends StatelessWidget {
  const _ReceiptCameraInteractionHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xD9050607),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x66FFD166)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptFocusReticle extends StatelessWidget {
  const _ReceiptFocusReticle({required this.position, this.label});

  final Offset position;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 28,
      top: position.dy - 28,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD166), width: 2),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: Color(0xFFFFD166),
                      size: 24,
                    ),
                  ),
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xDD050607),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    child: Text(
                      label!,
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCameraGuidancePill extends StatelessWidget {
  const _ReceiptCameraGuidancePill({
    required this.assist,
    required this.liveQuality,
    required this.autoCaptureEnabled,
    required this.autoCaptureReady,
  });

  final _ReceiptCameraAssistState assist;
  final _ReceiptLiveFrameQuality? liveQuality;
  final bool autoCaptureEnabled;
  final bool autoCaptureReady;

  @override
  Widget build(BuildContext context) {
    if (!assist.visible) return const SizedBox.shrink();
    final quality = liveQuality;
    final detail = quality == null
        ? assist.message
        : _qualityDetail(quality, fallback: assist.message);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xC8050607),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: assist.color.withValues(alpha: .55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            child: Row(
              children: [
                Icon(assist.icon, color: assist.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$assistTitlePrefix$detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE7EEF1),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (autoCaptureEnabled) ...[
                  const SizedBox(width: 7),
                  _ReceiptCameraSmallBadge(
                    label: quality?.autoCaptureStatusLabel ?? 'Auto',
                    ready: autoCaptureReady,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get assistTitlePrefix {
    final title = assist.title.trim();
    return title.isEmpty ? '' : '$title: ';
  }

  String _qualityDetail(
    _ReceiptLiveFrameQuality quality, {
    required String fallback,
  }) {
    if (quality.readiness == _ReceiptCameraReadiness.ready) {
      return 'Receipt looks readable. Hold steady or tap capture.';
    }
    if (quality.isTooDark) return 'Too dark. Add light or turn on the torch.';
    if (quality.isTooBright) {
      return 'Glare is hiding print. Tilt the phone or receipt.';
    }
    if (quality.isSoft) return 'Text looks soft. Tap printed lines to focus.';
    if (quality.isPoorlyFramed) {
      return 'Keep the full receipt visible. Tap capture if the text is readable.';
    }
    if (quality.mayBeCutOffAtBottom) {
      return 'Receipt may continue below the view. Move back slightly.';
    }
    if (quality.isSkewed) return 'Square up the phone with the receipt.';
    if (quality.isMissingLineBands) {
      return 'Move closer until receipt text is clear.';
    }
    return fallback;
  }
}

class _ReceiptZoomLevelBadge extends StatelessWidget {
  const _ReceiptZoomLevelBadge({
    required this.zoomLevel,
    required this.minZoom,
  });

  final double zoomLevel;
  final double minZoom;

  @override
  Widget build(BuildContext context) {
    if (zoomLevel <= minZoom + .08) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xC4050607),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x553D4A50)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                '${zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptCameraSmallBadge extends StatelessWidget {
  const _ReceiptCameraSmallBadge({required this.label, this.ready = false});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ready ? const Color(0x3328A745) : const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: ready ? const Color(0xFF58D67D) : const Color(0x44FFFFFF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
