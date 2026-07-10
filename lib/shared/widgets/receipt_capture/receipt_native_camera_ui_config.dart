import 'package:flutter/material.dart';

/// Presentation-only controls for the live receipt camera shell.
class ReceiptNativeCameraUiConfig {
  const ReceiptNativeCameraUiConfig({
    this.backgroundColor = const Color(0xFF050607),
    this.showVignette = true,
    this.showGuidance = true,
    this.showNextStepStrip = true,
    this.backLabel = 'Back',
    this.settingsLabel = 'Receipt camera settings',
    this.turnLightOnLabel = 'Turn light on',
    this.turnLightOffLabel = 'Turn light off',
    this.addPhotoLabel = 'Add Photo',
    this.doneLabel = 'Done',
  });

  final Color backgroundColor;
  final bool showVignette;
  final bool showGuidance;
  final bool showNextStepStrip;
  final String backLabel;
  final String settingsLabel;
  final String turnLightOnLabel;
  final String turnLightOffLabel;
  final String addPhotoLabel;
  final String doneLabel;

  ReceiptNativeCameraUiConfig copyWith({
    Color? backgroundColor,
    bool? showVignette,
    bool? showGuidance,
    bool? showNextStepStrip,
    String? backLabel,
    String? settingsLabel,
    String? turnLightOnLabel,
    String? turnLightOffLabel,
    String? addPhotoLabel,
    String? doneLabel,
  }) {
    return ReceiptNativeCameraUiConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showVignette: showVignette ?? this.showVignette,
      showGuidance: showGuidance ?? this.showGuidance,
      showNextStepStrip: showNextStepStrip ?? this.showNextStepStrip,
      backLabel: backLabel ?? this.backLabel,
      settingsLabel: settingsLabel ?? this.settingsLabel,
      turnLightOnLabel: turnLightOnLabel ?? this.turnLightOnLabel,
      turnLightOffLabel: turnLightOffLabel ?? this.turnLightOffLabel,
      addPhotoLabel: addPhotoLabel ?? this.addPhotoLabel,
      doneLabel: doneLabel ?? this.doneLabel,
    );
  }
}
