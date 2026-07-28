part of 'receipt_native_camera_shell.dart';

class _ReceiptNativeCameraPreviewControls extends StatefulWidget {
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
  State<_ReceiptNativeCameraPreviewControls> createState() =>
      _ReceiptNativeCameraPreviewControlsState();
}

class _ReceiptNativeCameraPreviewControlsState
    extends State<_ReceiptNativeCameraPreviewControls> {
  double _gestureStartZoom = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _pinchZoomAvailable
              ? (details) {
                  _gestureStartZoom = widget.currentZoom;
                }
              : null,
          onScaleUpdate: _pinchZoomAvailable
              ? (details) {
                  if (details.pointerCount < 2 || details.scale == 1) return;
                  final nextZoom = (_gestureStartZoom * details.scale).clamp(
                    widget.capabilities.minZoom,
                    widget.capabilities.maxZoom,
                  );
                  widget.onZoomChanged!(nextZoom.toDouble());
                }
              : null,
          child: widget.child,
        );
      },
    );
  }

  bool get _pinchZoomAvailable {
    return widget.settings.pinchZoomEnabled &&
        widget.capabilities.supportsZoom &&
        widget.capabilities.maxZoom > widget.capabilities.minZoom &&
        widget.onZoomChanged != null;
  }
}

class _ReceiptNativeCameraTopBar extends StatelessWidget {
  const _ReceiptNativeCameraTopBar({
    required this.engine,
    required this.torchOn,
    required this.torchSupported,
    required this.onBack,
    required this.onSettings,
    required this.capabilities,
    required this.currentExposureOffset,
    this.onExposureChanged,
    this.onExposureReset,
    required this.uiConfig,
    this.onTorch,
  });

  final ReceiptNativeCameraEngine engine;
  final bool torchOn;
  final bool torchSupported;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final ReceiptNativeCameraCapabilities capabilities;
  final double currentExposureOffset;
  final ValueChanged<double>? onExposureChanged;
  final VoidCallback? onExposureReset;
  final ReceiptNativeCameraUiConfig uiConfig;
  final VoidCallback? onTorch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                _ReceiptNativeCameraIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: uiConfig.backLabel,
                  onPressed: onBack,
                ),
                const Spacer(),
                _ReceiptNativeCameraIconButton(
                  icon: Icons.settings_rounded,
                  label: uiConfig.settingsLabel,
                  onPressed: onSettings,
                ),
                const SizedBox(width: 8),
                _ReceiptNativeCameraIconButton(
                  icon: torchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  label: torchOn
                      ? uiConfig.turnLightOffLabel
                      : uiConfig.turnLightOnLabel,
                  onPressed: torchSupported ? onTorch : null,
                  active: torchOn,
                ),
              ],
            ),
          ),
          if (_showsExposureControls) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: _ReceiptNativeCameraExposureStrip(
                currentExposureOffset: currentExposureOffset,
                minExposureOffset: capabilities.minExposureOffset,
                maxExposureOffset: capabilities.maxExposureOffset,
                onExposureChanged: onExposureChanged!,
                onExposureReset: onExposureReset!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _showsExposureControls {
    return capabilities.supportsExposureCompensation &&
        onExposureChanged != null &&
        onExposureReset != null &&
        capabilities.maxExposureOffset > capabilities.minExposureOffset;
  }
}

class _ReceiptNativeCameraExposureStrip extends StatelessWidget {
  const _ReceiptNativeCameraExposureStrip({
    required this.currentExposureOffset,
    required this.minExposureOffset,
    required this.maxExposureOffset,
    required this.onExposureChanged,
    required this.onExposureReset,
  });

  final double currentExposureOffset;
  final double minExposureOffset;
  final double maxExposureOffset;
  final ValueChanged<double> onExposureChanged;
  final VoidCallback onExposureReset;

  @override
  Widget build(BuildContext context) {
    final range = (maxExposureOffset - minExposureOffset).abs();
    final divisions = (range * 10).round().clamp(8, 60);

    return Row(
      children: [
        const Icon(
          Icons.brightness_6_rounded,
          color: Color(0xFFE8ECEE),
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: Slider(
              value: currentExposureOffset.clamp(
                minExposureOffset,
                maxExposureOffset,
              ),
              min: minExposureOffset,
              max: maxExposureOffset,
              divisions: divisions <= 0 ? null : divisions,
              onChanged: onExposureChanged,
              activeColor: const Color(0xFFE8ECEE),
              thumbColor: const Color(0xFFFFD166),
              secondaryActiveColor: const Color(0xFF9DA7AE),
              label: 'Brightness',
            ),
          ),
        ),
        Tooltip(
          message: 'Reset brightness',
          child: IconButton(
            onPressed: onExposureReset,
            key: const ValueKey('receipt-exposure-reset'),
            tooltip: 'Reset brightness',
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size(42, 42),
              foregroundColor: const Color(0xFFE8ECEE),
              backgroundColor: const Color(0x3D11181B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
