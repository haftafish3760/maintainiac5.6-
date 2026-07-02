import 'package:flutter/material.dart';

import 'receipt_capture_models.dart';
import 'receipt_native_camera_contract.dart';

part 'receipt_native_camera_shell_top_controls.dart';
part 'receipt_native_camera_shell_bottom_controls.dart';
part 'receipt_native_camera_shell_bottom_bar.dart';
part 'receipt_native_camera_shell_guidance.dart';
part 'receipt_native_camera_shell_ghost_guidance.dart';

class ReceiptNativeCameraShell extends StatelessWidget {
  const ReceiptNativeCameraShell({
    super.key,
    required this.preview,
    required this.capabilities,
    required this.settings,
    required this.onBack,
    required this.onCapture,
    required this.onSettings,
    this.onTorch,
    this.onTapFocus,
    this.onZoomChanged,
    this.onExposureChanged,
    this.onExposureReset,
    this.torchOn = false,
    this.capturing = false,
    this.currentZoom = 1,
    this.currentExposureOffset = 0,
    this.guidanceTitle = 'Line up the receipt',
    this.guidanceMessage = 'Fill the screen with readable receipt text.',
    this.guidanceStatus,
    this.previousSectionPreview,
    this.previousSectionReasonCode,
    this.previousSectionGuidance,
    this.sectionLabel,
    this.qualityLabel,
    this.children = const [],
  });

  final Widget preview;
  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback? onTorch;
  final ValueChanged<Offset>? onTapFocus;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<double>? onExposureChanged;
  final VoidCallback? onExposureReset;
  final bool torchOn;
  final bool capturing;
  final double currentZoom;
  final double currentExposureOffset;
  final String guidanceTitle;
  final String guidanceMessage;
  final String? guidanceStatus;
  final Widget? previousSectionPreview;
  final String? previousSectionReasonCode;
  final String? previousSectionGuidance;
  final String? sectionLabel;
  final String? qualityLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onBack();
      },
      child: ColoredBox(
        color: const Color(0xFF050607),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _ReceiptNativeCameraPreviewControls(
                capabilities: capabilities,
                settings: settings,
                currentZoom: currentZoom,
                onTapFocus: onTapFocus,
                onZoomChanged: onZoomChanged,
                child: preview,
              ),
            ),
            if (previousSectionPreview != null)
              _ReceiptPreviousSectionGhost(
                preview: previousSectionPreview!,
                reasonCode: previousSectionReasonCode,
                guidance: previousSectionGuidance,
              ),
            const Positioned.fill(
              child: IgnorePointer(child: _ReceiptCameraVignette()),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _ReceiptNativeCameraTopBar(
                engine: capabilities.engine,
                torchOn: torchOn,
                torchSupported: capabilities.supportsTorch,
                onBack: onBack,
                onTorch: onTorch,
                onSettings: onSettings,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: MediaQuery.viewPaddingOf(context).top + 68,
              child: _ReceiptNativeCameraGuidance(
                title: guidanceTitle,
                message: guidanceMessage,
                status: guidanceStatus,
                sectionLabel: sectionLabel,
                capabilities: capabilities,
              ),
            ),
            ...children,
            if (_exposureControlAvailable)
              Positioned(
                right: 10,
                top: MediaQuery.sizeOf(context).height * .34,
                bottom: MediaQuery.sizeOf(context).height * .22,
                child: _ReceiptNativeExposureControl(
                  min: capabilities.minExposureOffset,
                  max: capabilities.maxExposureOffset,
                  value: currentExposureOffset,
                  onChanged: onExposureChanged,
                  onReset: onExposureReset,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ReceiptNativeCameraBottomBar(
                capturing: capturing,
                capabilities: capabilities,
                settings: settings,
                qualityLabel: qualityLabel,
                onCapture: onCapture,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _exposureControlAvailable {
    return settings.exposureSliderEnabled &&
        capabilities.supportsExposureCompensation &&
        capabilities.maxExposureOffset > capabilities.minExposureOffset &&
        onExposureChanged != null;
  }
}
