part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraPreviewControls extends StatelessWidget {
  const _ReceiptNativeCameraPreviewControls({
    required this.capabilities,
    required this.settings,
    required this.currentZoom,
    required this.child,
    this.onTapFocus,
    this.onZoomChanged,
  });

  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final double currentZoom;
  final Widget child;
  final ValueChanged<Offset>? onTapFocus;
  final ValueChanged<double>? onZoomChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _tapFocusAvailable
              ? (details) {
                  final width = constraints.maxWidth <= 0
                      ? 1.0
                      : constraints.maxWidth;
                  final height = constraints.maxHeight <= 0
                      ? 1.0
                      : constraints.maxHeight;
                  onTapFocus!(
                    Offset(
                      (details.localPosition.dx / width).clamp(0.0, 1.0),
                      (details.localPosition.dy / height).clamp(0.0, 1.0),
                    ),
                  );
                }
              : null,
          onScaleUpdate: _pinchZoomAvailable
              ? (details) {
                  if (details.pointerCount < 2 || details.scale == 1) return;
                  final nextZoom = (currentZoom * details.scale).clamp(
                    capabilities.minZoom,
                    capabilities.maxZoom,
                  );
                  onZoomChanged!(nextZoom.toDouble());
                }
              : null,
          child: child,
        );
      },
    );
  }

  bool get _tapFocusAvailable {
    return false;
  }

  bool get _pinchZoomAvailable {
    return settings.pinchZoomEnabled &&
        capabilities.supportsZoom &&
        capabilities.maxZoom > capabilities.minZoom &&
        onZoomChanged != null;
  }
}

class _ReceiptNativeExposureControl extends StatelessWidget {
  const _ReceiptNativeExposureControl({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.onReset,
  });

  final double min;
  final double max;
  final double value;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(min, max).toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC11181B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF526168), width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Reset brightness',
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              color: Colors.white,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  min: min,
                  max: max,
                  value: safeValue,
                  onChanged: onChanged,
                  activeColor: const Color(0xFFFFD166),
                  inactiveColor: const Color(0xFF526168),
                  semanticFormatterCallback: (value) =>
                      'Brightness ${value.toStringAsFixed(1)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraTopBar extends StatelessWidget {
  const _ReceiptNativeCameraTopBar({
    required this.engine,
    required this.torchOn,
    required this.torchSupported,
    required this.onBack,
    required this.onSettings,
    this.onTorch,
  });

  final ReceiptNativeCameraEngine engine;
  final bool torchOn;
  final bool torchSupported;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback? onTorch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            _ReceiptNativeCameraIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Expanded(child: _ReceiptNativeCameraTitlePill(engine: engine)),
            const SizedBox(width: 8),
            _ReceiptNativeCameraIconButton(
              icon: Icons.settings_rounded,
              label: 'Receipt camera settings',
              onPressed: onSettings,
              visibleLabel: 'Settings',
            ),
            const SizedBox(width: 8),
            _ReceiptNativeCameraIconButton(
              icon: torchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              label: torchOn ? 'Turn light off' : 'Turn light on',
              onPressed: torchSupported ? onTorch : null,
              active: torchOn,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraTitlePill extends StatelessWidget {
  const _ReceiptNativeCameraTitlePill({required this.engine});

  final ReceiptNativeCameraEngine engine;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 188),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC11181B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF526168), width: .8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Maintainiac Receipt Camera',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _engineLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD4DEE2),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _engineLabel {
    return switch (engine) {
      ReceiptNativeCameraEngine.cameraX => 'Native receipt controls',
      ReceiptNativeCameraEngine.avFoundation => 'Native receipt controls',
      ReceiptNativeCameraEngine.unavailable => 'Receipt controls',
    };
  }
}
