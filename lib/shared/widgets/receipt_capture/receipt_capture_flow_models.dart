part of 'receipt_capture_flow.dart';

enum ReceiptCaptureFlowModule {
  expenses('expenses'),
  materialsInventory('materials_inventory'),
  maintenanceRepair('maintenance_repair'),
  shared('shared');

  const ReceiptCaptureFlowModule(this.storageName);

  final String storageName;

  ReceiptCaptureArea? get settingsArea {
    return switch (this) {
      ReceiptCaptureFlowModule.expenses => ReceiptCaptureArea.expenses,
      ReceiptCaptureFlowModule.materialsInventory =>
        ReceiptCaptureArea.materialsInventory,
      ReceiptCaptureFlowModule.maintenanceRepair =>
        ReceiptCaptureArea.maintenanceRepair,
      ReceiptCaptureFlowModule.shared => null,
    };
  }
}

enum ReceiptCaptureFlowStatus {
  accepted,
  canceled,
  permissionDenied,
  nativeUnavailable,
  stagingFailed,
  reviewUnavailable,
}

class ReceiptCaptureFlowOptions {
  const ReceiptCaptureFlowOptions({
    this.module = ReceiptCaptureFlowModule.shared,
    this.initialPhotoPaths = const [],
    this.initialQualityChecksByPath = const {},
    this.initialCaptureDiagnosticsByPath = const {},
    this.initialSelectedIndex = 0,
    this.initialDataSaverLevel,
    this.forceAssistedReceiptFill,
    this.forceLongReceiptMode,
    this.forceAutoCapture,
    this.forceReviewDepth,
    this.previousSectionGuidePhotoPath,
    this.previousSectionReasonCode,
    this.previousSectionGuidance,
    this.previousSectionGhostSourceStartFraction,
    this.previousSectionGhostSourceHeightFraction,
    this.previousSectionGhostOverlayTopFraction,
    this.previousSectionGhostOverlayHeightFraction,
    this.previousSectionGhostOpacity,
  });

  final ReceiptCaptureFlowModule module;
  final List<String> initialPhotoPaths;
  final Map<String, ReceiptPhotoQualityCheck> initialQualityChecksByPath;
  final Map<String, Map<String, Object?>> initialCaptureDiagnosticsByPath;
  final int initialSelectedIndex;
  final ReceiptDataSaverLevel? initialDataSaverLevel;
  final bool? forceAssistedReceiptFill;
  final bool? forceLongReceiptMode;
  final bool? forceAutoCapture;
  final ReceiptNativeReviewDepth? forceReviewDepth;
  final String? previousSectionGuidePhotoPath;
  final String? previousSectionReasonCode;
  final String? previousSectionGuidance;
  final double? previousSectionGhostSourceStartFraction;
  final double? previousSectionGhostSourceHeightFraction;
  final double? previousSectionGhostOverlayTopFraction;
  final double? previousSectionGhostOverlayHeightFraction;
  final double? previousSectionGhostOpacity;

  ReceiptNativeReviewDepth get effectiveReviewDepth {
    if (forceReviewDepth != null) return forceReviewDepth!;
    return switch (module) {
      ReceiptCaptureFlowModule.materialsInventory ||
      ReceiptCaptureFlowModule.maintenanceRepair =>
        ReceiptNativeReviewDepth.detailedLines,
      ReceiptCaptureFlowModule.expenses ||
      ReceiptCaptureFlowModule.shared => ReceiptNativeReviewDepth.pricesOnly,
    };
  }
}

class ReceiptCaptureContinuationGuide {
  const ReceiptCaptureContinuationGuide({
    this.guidePhotoPath,
    this.reasonCode,
    this.guidance,
    this.ghostSourceStartFraction,
    this.ghostSourceHeightFraction,
    this.ghostOverlayTopFraction,
    this.ghostOverlayHeightFraction,
    this.ghostOpacity,
  });

  factory ReceiptCaptureContinuationGuide.fromPreviousPhotos({
    required List<String> previousPhotoPaths,
    String? reasonCode,
    String? guidance,
  }) {
    String? previousGuidePath;
    for (final path in previousPhotoPaths) {
      final normalizedPath = receiptNativeCameraLocalImagePathOrNull(path);
      if (normalizedPath != null) previousGuidePath = normalizedPath;
    }
    final normalizedReason =
        _normalizeContinuationReasonCode(reasonCode) ??
        (previousGuidePath == null ? null : 'manual_add_photo_continuation');
    if (normalizedReason == null) {
      return const ReceiptCaptureContinuationGuide();
    }
    return ReceiptCaptureContinuationGuide(
      guidePhotoPath: previousGuidePath,
      reasonCode: normalizedReason,
      guidance: _trimmedOrNull(guidance),
      ghostSourceStartFraction: _ghostSourceStartFractionFor(normalizedReason),
      ghostSourceHeightFraction: _ghostHeightFractionFor(normalizedReason),
      ghostOverlayTopFraction: 0,
      ghostOverlayHeightFraction: _ghostHeightFractionFor(normalizedReason),
      ghostOpacity: _ghostOpacityFor(normalizedReason),
    );
  }

  final String? guidePhotoPath;
  final String? reasonCode;
  final String? guidance;
  final double? ghostSourceStartFraction;
  final double? ghostSourceHeightFraction;
  final double? ghostOverlayTopFraction;
  final double? ghostOverlayHeightFraction;
  final double? ghostOpacity;

  bool get hasGuidePhoto =>
      receiptNativeCameraLocalImagePathOrNull(guidePhotoPath) != null;
  bool get hasReason => _trimmedOrNull(reasonCode) != null;

  ReceiptCaptureFlowOptions applyTo(ReceiptCaptureFlowOptions options) {
    final normalizedReason = _normalizeContinuationReasonCode(reasonCode);
    if (normalizedReason == null) return options;
    return ReceiptCaptureFlowOptions(
      module: options.module,
      initialPhotoPaths: options.initialPhotoPaths,
      initialQualityChecksByPath: options.initialQualityChecksByPath,
      initialCaptureDiagnosticsByPath: options.initialCaptureDiagnosticsByPath,
      initialSelectedIndex: options.initialSelectedIndex,
      initialDataSaverLevel: options.initialDataSaverLevel,
      forceAssistedReceiptFill: options.forceAssistedReceiptFill,
      forceLongReceiptMode: options.forceLongReceiptMode,
      forceAutoCapture: options.forceAutoCapture,
      forceReviewDepth: options.forceReviewDepth,
      previousSectionGuidePhotoPath: receiptNativeCameraLocalImagePathOrNull(
        guidePhotoPath,
      ),
      previousSectionReasonCode: normalizedReason,
      previousSectionGuidance: _trimmedOrNull(guidance),
      previousSectionGhostSourceStartFraction: _boundedOptionalFraction(
        ghostSourceStartFraction,
      ),
      previousSectionGhostSourceHeightFraction: _boundedOptionalFraction(
        ghostSourceHeightFraction,
      ),
      previousSectionGhostOverlayTopFraction: _boundedOptionalFraction(
        ghostOverlayTopFraction,
      ),
      previousSectionGhostOverlayHeightFraction: _boundedOptionalFraction(
        ghostOverlayHeightFraction,
      ),
      previousSectionGhostOpacity: _boundedOptionalFraction(ghostOpacity),
    );
  }

  static double _ghostSourceStartFractionFor(String reasonCode) {
    if (reasonCode == 'retake_top_with_next_context') return 0;
    return .80;
  }

  static double _ghostHeightFractionFor(String reasonCode) {
    return .20;
  }

  static double _ghostOpacityFor(String reasonCode) {
    if (reasonCode == 'missing_bottom_edge_and_totals') return .36;
    return .32;
  }

  static double? _boundedOptionalFraction(double? value) {
    if (value == null || !value.isFinite) return null;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _normalizeContinuationReasonCode(String? value) {
    final trimmed = _trimmedOrNull(value);
    if (trimmed == null) return null;
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class ReceiptCaptureFlowResult {
  const ReceiptCaptureFlowResult._({
    required this.status,
    this.reviewResult,
    this.ocrResult,
    this.message = '',
    this.nativeCapabilities,
    this.recoveryManifestPath = '',
    this.diagnostics = const {},
  });

  factory ReceiptCaptureFlowResult.accepted({
    required ReceiptPhotoReviewResult reviewResult,
    ReceiptOcrResult? ocrResult,
    ReceiptNativeCameraCapabilities? nativeCapabilities,
    String recoveryManifestPath = '',
    Map<String, Object?> diagnostics = const {},
  }) {
    return ReceiptCaptureFlowResult._(
      status: ReceiptCaptureFlowStatus.accepted,
      reviewResult: reviewResult,
      ocrResult: ocrResult,
      nativeCapabilities: nativeCapabilities,
      recoveryManifestPath: recoveryManifestPath,
      diagnostics: diagnostics,
    );
  }

  factory ReceiptCaptureFlowResult.canceled({
    String message = '',
    ReceiptNativeCameraCapabilities? nativeCapabilities,
    Map<String, Object?> diagnostics = const {},
  }) {
    return ReceiptCaptureFlowResult._(
      status: ReceiptCaptureFlowStatus.canceled,
      message: message,
      nativeCapabilities: nativeCapabilities,
      diagnostics: diagnostics,
    );
  }

  factory ReceiptCaptureFlowResult.failed({
    required ReceiptCaptureFlowStatus status,
    required String message,
    ReceiptNativeCameraCapabilities? nativeCapabilities,
    Map<String, Object?> diagnostics = const {},
  }) {
    assert(status != ReceiptCaptureFlowStatus.accepted);
    return ReceiptCaptureFlowResult._(
      status: status,
      message: message,
      nativeCapabilities: nativeCapabilities,
      diagnostics: diagnostics,
    );
  }

  final ReceiptCaptureFlowStatus status;
  final ReceiptPhotoReviewResult? reviewResult;
  final ReceiptOcrResult? ocrResult;
  final String message;
  final ReceiptNativeCameraCapabilities? nativeCapabilities;
  final String recoveryManifestPath;
  final Map<String, Object?> diagnostics;

  bool get accepted => status == ReceiptCaptureFlowStatus.accepted;
  bool get hasOcrText => ocrResult?.hasText == true;
}
