part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraPreviewControls extends StatelessWidget {
  const _ReceiptNativeCameraPreviewControls({
    required this.capabilities,
    required this.settings,
    required this.currentZoom,
    required this.child,
    this.onZoomChanged,
  });

  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final double currentZoom;
  final Widget child;
  final ValueChanged<double>? onZoomChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
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
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Row(
          children: [
            _ReceiptNativeCameraIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: onBack,
            ),
            const Spacer(),
            _ReceiptNativeCameraIconButton(
              icon: Icons.settings_rounded,
              label: 'Receipt camera settings',
              onPressed: onSettings,
            ),
            const SizedBox(width: 8),
            _ReceiptNativeCameraIconButton(
              icon: torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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
