part of 'receipt_camera_screen.dart';

class _ReceiptCameraTopBar extends StatelessWidget {
  const _ReceiptCameraTopBar({
    required this.torchOn,
    required this.onClose,
    required this.onDeviceCamera,
    required this.onTorch,
  });

  final bool torchOn;
  final VoidCallback onClose;
  final VoidCallback onDeviceCamera;
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEE050607),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF56656D), width: .8),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                _CameraIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  onPressed: onClose,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Receipt Camera',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CameraIconButton(
                  icon: Icons.add_a_photo_rounded,
                  label: 'Open device camera',
                  onPressed: onDeviceCamera,
                ),
                const SizedBox(width: 6),
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
          ),
        ),
      ),
    );
  }
}

class _ReceiptCameraBottomBar extends StatelessWidget {
  const _ReceiptCameraBottomBar({
    required this.capturing,
    required this.assistedScanning,
    required this.mode,
    required this.autoCapture,
    required this.autoCaptureAvailable,
    required this.showLongReceiptTips,
    required this.assistState,
    required this.liveQuality,
    required this.onCapture,
    required this.onAssistedScan,
    required this.onAutoCaptureChanged,
  });

  final bool capturing;
  final bool assistedScanning;
  final _ReceiptCameraMode mode;
  final bool autoCapture;
  final bool autoCaptureAvailable;
  final bool showLongReceiptTips;
  final _ReceiptCameraAssistState assistState;
  final _ReceiptLiveFrameQuality? liveQuality;
  final VoidCallback onCapture;
  final VoidCallback onAssistedScan;
  final ValueChanged<bool> onAutoCaptureChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLongReceiptTips) ...[
            const _ReceiptCameraHints(),
            const SizedBox(height: 10),
          ],
          if (mode == _ReceiptCameraMode.assisted) ...[
            _CameraQualityStrip(quality: liveQuality),
            const SizedBox(height: 10),
            if (autoCaptureAvailable) ...[
              _AutoCaptureToggle(
                enabled: autoCapture,
                disabled: capturing,
                onChanged: onAutoCaptureChanged,
              ),
              const SizedBox(height: 10),
            ],
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CameraQuickAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Best Shot',
                active: mode == _ReceiptCameraMode.assisted,
                onPressed: capturing ? null : onAssistedScan,
              ),
              _CameraShutterButton(
                capturing: capturing && !assistedScanning,
                onPressed: capturing ? null : onCapture,
              ),
              _CameraQuickAction(
                icon: Icons.touch_app_rounded,
                label: 'Tap Focus',
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            assistedScanning
                ? assistState.message
                : mode == _ReceiptCameraMode.assisted
                ? assistState.message
                : 'Standard mode: aim, tap text to focus, and capture when ready.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE6EEF1),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoCaptureToggle extends StatelessWidget {
  const _AutoCaptureToggle({
    required this.enabled,
    required this.disabled,
    required this.onChanged,
  });

  final bool enabled;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF56656D), width: .8),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
        value: enabled,
        onChanged: disabled ? null : onChanged,
        activeThumbColor: const Color(0xFF8EF6A4),
        title: const Text(
          'Auto capture',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        subtitle: const Text(
          'Takes best-shot frames when the receipt stays ready.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CameraQualityStrip extends StatelessWidget {
  const _CameraQualityStrip({required this.quality});

  final _ReceiptLiveFrameQuality? quality;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    final readiness = quality?.readiness ?? _ReceiptCameraReadiness.almostReady;
    final color = switch (readiness) {
      _ReceiptCameraReadiness.notReady => const Color(0xFFFF4D5E),
      _ReceiptCameraReadiness.almostReady => const Color(0xFFFFD166),
      _ReceiptCameraReadiness.ready => const Color(0xFF8EF6A4),
    };
    final label = switch (readiness) {
      _ReceiptCameraReadiness.notReady => 'Not ready',
      _ReceiptCameraReadiness.almostReady => 'Almost ready',
      _ReceiptCameraReadiness.ready => 'Ready',
    };
    return Semantics(
      label: 'Receipt camera quality is $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEE050607),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                quality == null ? 'checking' : _qualitySummary(quality),
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _qualitySummary(_ReceiptLiveFrameQuality quality) {
    return 'light ${quality.brightness.round()}  sharp ${quality.focusScore.toStringAsFixed(1)}';
  }
}

class _CameraShutterButton extends StatelessWidget {
  const _CameraShutterButton({
    required this.capturing,
    required this.onPressed,
  });

  final bool capturing;
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
                  : const Icon(
                      Icons.camera_alt_rounded,
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

class _CameraQuickAction extends StatelessWidget {
  const _CameraQuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              backgroundColor: active
                  ? const Color(0xFFFFD166)
                  : enabled
                  ? const Color(0xCC11181B)
                  : const Color(0x6611181B),
              foregroundColor: active
                  ? const Color(0xFF101416)
                  : const Color(0xFFE8ECEE),
              minimumSize: const Size(48, 48),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFFE8ECEE)
                  : const Color(0xFF94A0A6),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
