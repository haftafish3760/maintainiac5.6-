part of 'receipt_camera_screen.dart';

class _ReceiptCameraTopBar extends StatelessWidget {
  const _ReceiptCameraTopBar({
    required this.torchOn,
    required this.onClose,
    required this.onTorch,
    this.onSettings,
  });

  final bool torchOn;
  final VoidCallback onClose;
  final VoidCallback onTorch;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CameraIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: onClose,
            ),
            Row(
              children: [
                if (onSettings != null) ...[
                  _CameraIconButton(
                    icon: Icons.settings_rounded,
                    label: 'Receipt camera settings',
                    onPressed: onSettings!,
                  ),
                  const SizedBox(width: 8),
                ],
                _CameraIconButton(
                  icon: torchOn
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  label: torchOn ? 'Turn torch off' : 'Turn torch on',
                  onPressed: onTorch,
                  active: torchOn,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCameraBottomBar extends StatelessWidget {
  const _ReceiptCameraBottomBar({
    required this.capturing,
    required this.assistedScanning,
    required this.assistedMode,
    required this.autoCaptureEnabled,
    required this.longReceiptTipsEnabled,
    required this.onCapture,
  });

  final bool capturing;
  final bool assistedScanning;
  final bool assistedMode;
  final bool autoCaptureEnabled;
  final bool longReceiptTipsEnabled;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00050607), Color(0xCC050607)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: _CameraModeBadge(
                  icon: assistedMode
                      ? Icons.document_scanner_rounded
                      : Icons.camera_alt_rounded,
                  label: assistedMode ? 'Assisted' : 'Manual',
                  detail: assistedMode && autoCaptureEnabled
                      ? 'Tap anytime'
                      : 'Tap shutter',
                ),
              ),
            ),
            _CameraShutterButton(
              capturing: capturing || assistedScanning,
              assistedMode: assistedMode,
              onPressed: capturing ? null : onCapture,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: _CameraModeBadge(
                  icon: longReceiptTipsEnabled
                      ? Icons.receipt_long_rounded
                      : Icons.touch_app_rounded,
                  label: longReceiptTipsEnabled ? 'Long Receipt' : 'Focus',
                  detail: longReceiptTipsEnabled ? 'Use photos' : 'Tap text',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraModeBadge extends StatelessWidget {
  const _CameraModeBadge({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 118),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xC9050607),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x663D4A50)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFFFD166), size: 17),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
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
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 10,
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
      ),
    );
  }
}

class _CameraShutterButton extends StatelessWidget {
  const _CameraShutterButton({
    required this.capturing,
    required this.assistedMode,
    required this.onPressed,
  });

  final bool capturing;
  final bool assistedMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Capture receipt photo',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPressed == null
                  ? const Color(0xFF6D7478)
                  : const Color(0xFFFFFFFF),
              border: Border.all(color: const Color(0xFF050607), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: capturing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF101416),
                      ),
                    )
                  : Icon(
                      assistedMode
                          ? Icons.document_scanner_rounded
                          : Icons.camera_alt_rounded,
                      color: Color(0xFF101416),
                      size: 34,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
