import 'package:flutter/material.dart';

import 'receipt_native_camera_contract.dart';
import 'receipt_native_camera_ui_config.dart';

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
    this.onReviewCapturedPhotos,
    this.onAddPhoto,
    this.onTorch,
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
    this.capturedPhotoCount = 0,
    this.longReceiptMode = false,
    this.children = const [],
    this.uiConfig = const ReceiptNativeCameraUiConfig(),
  });

  final Widget preview;
  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback? onReviewCapturedPhotos;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onTorch;
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
  final int capturedPhotoCount;
  final bool longReceiptMode;
  final List<Widget> children;
  final ReceiptNativeCameraUiConfig uiConfig;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onBack();
      },
      child: ColoredBox(
        color: uiConfig.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _ReceiptNativeCameraPreviewControls(
                capabilities: capabilities,
                settings: settings,
                currentZoom: currentZoom,
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
            if (uiConfig.showVignette)
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
                capabilities: capabilities,
                currentExposureOffset: currentExposureOffset,
                onExposureChanged: onExposureChanged,
                onExposureReset: onExposureReset,
                uiConfig: uiConfig,
              ),
            ),
            if (uiConfig.showGuidance)
              Positioned(
                left: 12,
                right: 12,
                bottom:
                    MediaQuery.viewPaddingOf(context).bottom +
                    _guidanceBottomOffset,
                child: _ReceiptNativeCameraGuidance(
                  title: guidanceTitle,
                  message: guidanceMessage,
                  status: guidanceStatus,
                  sectionLabel: sectionLabel,
                  capabilities: capabilities,
                ),
              ),
            ...children,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ReceiptNativeCameraBottomBar(
                capturing: capturing,
                capabilities: capabilities,
                settings: settings,
                qualityLabel: qualityLabel,
                capturedPhotoCount: capturedPhotoCount,
                longReceiptMode: longReceiptMode,
                onReviewCapturedPhotos: onReviewCapturedPhotos,
                onAddPhoto: onAddPhoto,
                onCapture: onCapture,
                uiConfig: uiConfig,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _guidanceBottomOffset {
    if (capturedPhotoCount > 0 && onReviewCapturedPhotos != null) {
      return 152;
    }
    return 92;
  }
}
