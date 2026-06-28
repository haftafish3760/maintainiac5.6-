import 'receipt_assistance_policy.dart';
import 'receipt_capture_models.dart';

enum ReceiptNativeCameraEngine {
  cameraX('CameraX'),
  avFoundation('AVFoundation'),
  unavailable('Native camera unavailable');

  const ReceiptNativeCameraEngine(this.label);

  final String label;
}

enum ReceiptNativeSettingGroup {
  capture('Capture'),
  cameraControl('Camera controls'),
  receiptGuidance('Receipt guidance'),
  cleanup('Cleanup'),
  longReceipt('Long receipt'),
  storage('Storage safety'),
  review('Review');

  const ReceiptNativeSettingGroup(this.label);

  final String label;
}

enum ReceiptNativeSettingType { toggle, slider, segmented, action, automatic }

enum ReceiptNativeFocusMode { auto, continuous, locked, manual }

enum ReceiptNativeExposureMode { auto, locked, manual }

enum ReceiptNativeWhiteBalanceMode { auto, locked, manual }

enum ReceiptNativeFlashMode { off, on, auto }

enum ReceiptNativeImageFormat { jpeg, yuvLiveFrame, rawFuture }

enum ReceiptNativeReviewDepth { pricesOnly, detailedLines }

class ReceiptNativeCameraSettingDescriptor {
  const ReceiptNativeCameraSettingDescriptor({
    required this.id,
    required this.label,
    required this.description,
    required this.group,
    required this.type,
    this.defaultEnabled,
    this.defaultValueLabel = '',
    this.requiresNativeSupport = false,
    this.advanced = false,
  });

  final String id;
  final String label;
  final String description;
  final ReceiptNativeSettingGroup group;
  final ReceiptNativeSettingType type;
  final bool? defaultEnabled;
  final String defaultValueLabel;
  final bool requiresNativeSupport;
  final bool advanced;
}

class ReceiptNativeCameraCapabilities {
  const ReceiptNativeCameraCapabilities({
    required this.engine,
    this.available = false,
    this.cameraPermissionGranted = false,
    this.cameraCount = 0,
    this.hasRearCamera = false,
    this.hasFrontCamera = false,
    this.supportsTapFocus = false,
    this.supportsContinuousFocus = false,
    this.supportsFocusLock = false,
    this.supportsManualFocusDistance = false,
    this.supportsExposureCompensation = false,
    this.supportsExposureLock = false,
    this.supportsManualShutter = false,
    this.supportsIsoControl = false,
    this.supportsWhiteBalanceLock = false,
    this.supportsManualWhiteBalance = false,
    this.supportsTorch = false,
    this.supportsFlashAuto = false,
    this.supportsZoom = false,
    this.supportsMacroSelection = false,
    this.supportsYuvLiveFrames = false,
    this.supportsRaw = false,
    this.supportsNativeEdgeSignals = false,
    this.minZoom = 1,
    this.maxZoom = 1,
    this.minExposureOffset = 0,
    this.maxExposureOffset = 0,
    this.maxStillWidth = 0,
    this.maxStillHeight = 0,
  });

  const ReceiptNativeCameraCapabilities.unavailable()
    : this(engine: ReceiptNativeCameraEngine.unavailable);

  final ReceiptNativeCameraEngine engine;
  final bool available;
  final bool cameraPermissionGranted;
  final int cameraCount;
  final bool hasRearCamera;
  final bool hasFrontCamera;
  final bool supportsTapFocus;
  final bool supportsContinuousFocus;
  final bool supportsFocusLock;
  final bool supportsManualFocusDistance;
  final bool supportsExposureCompensation;
  final bool supportsExposureLock;
  final bool supportsManualShutter;
  final bool supportsIsoControl;
  final bool supportsWhiteBalanceLock;
  final bool supportsManualWhiteBalance;
  final bool supportsTorch;
  final bool supportsFlashAuto;
  final bool supportsZoom;
  final bool supportsMacroSelection;
  final bool supportsYuvLiveFrames;
  final bool supportsRaw;
  final bool supportsNativeEdgeSignals;
  final double minZoom;
  final double maxZoom;
  final double minExposureOffset;
  final double maxExposureOffset;
  final int maxStillWidth;
  final int maxStillHeight;

  bool get canOpenReceiptCamera =>
      available && cameraPermissionGranted && hasRearCamera;

  String get userSafeSummary {
    if (!available) return 'Maintainiac camera is not available yet.';
    if (!cameraPermissionGranted) return 'Camera permission is needed.';
    if (!hasRearCamera) return 'No rear camera was found.';
    return 'Receipt camera ready.';
  }

  factory ReceiptNativeCameraCapabilities.fromMap(Map<dynamic, dynamic> map) {
    final engineName = map['engine']?.toString();
    final engine = ReceiptNativeCameraEngine.values.firstWhere(
      (value) => value.name == engineName,
      orElse: () => ReceiptNativeCameraEngine.unavailable,
    );
    return ReceiptNativeCameraCapabilities(
      engine: engine,
      available: map['available'] == true,
      cameraPermissionGranted: map['cameraPermissionGranted'] == true,
      cameraCount: _intValue(map['cameraCount']),
      hasRearCamera: map['hasRearCamera'] == true,
      hasFrontCamera: map['hasFrontCamera'] == true,
      supportsTapFocus: map['supportsTapFocus'] == true,
      supportsContinuousFocus: map['supportsContinuousFocus'] == true,
      supportsFocusLock: map['supportsFocusLock'] == true,
      supportsManualFocusDistance: map['supportsManualFocusDistance'] == true,
      supportsExposureCompensation: map['supportsExposureCompensation'] == true,
      supportsExposureLock: map['supportsExposureLock'] == true,
      supportsManualShutter: map['supportsManualShutter'] == true,
      supportsIsoControl: map['supportsIsoControl'] == true,
      supportsWhiteBalanceLock: map['supportsWhiteBalanceLock'] == true,
      supportsManualWhiteBalance: map['supportsManualWhiteBalance'] == true,
      supportsTorch: map['supportsTorch'] == true,
      supportsFlashAuto: map['supportsFlashAuto'] == true,
      supportsZoom: map['supportsZoom'] == true,
      supportsMacroSelection: map['supportsMacroSelection'] == true,
      supportsYuvLiveFrames: map['supportsYuvLiveFrames'] == true,
      supportsRaw: map['supportsRaw'] == true,
      supportsNativeEdgeSignals: map['supportsNativeEdgeSignals'] == true,
      minZoom: _doubleValue(map['minZoom'], fallback: 1),
      maxZoom: _doubleValue(map['maxZoom'], fallback: 1),
      minExposureOffset: _doubleValue(map['minExposureOffset']),
      maxExposureOffset: _doubleValue(map['maxExposureOffset']),
      maxStillWidth: _intValue(map['maxStillWidth']),
      maxStillHeight: _intValue(map['maxStillHeight']),
    );
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return 0;
  }

  static double _doubleValue(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }
}

class ReceiptNativeCameraSettings {
  const ReceiptNativeCameraSettings({
    this.assistedReceiptFill = true,
    this.reviewDepth = ReceiptNativeReviewDepth.pricesOnly,
    this.longReceiptMode = true,
    this.manualShutterAlwaysAvailable = true,
    this.autoCaptureEnabled = false,
    this.tapFocusEnabled = true,
    this.pinchZoomEnabled = true,
    this.exposureSliderEnabled = true,
    this.exposureResetEnabled = true,
    this.autoExposureAssistEnabled = true,
    this.focusMode = ReceiptNativeFocusMode.continuous,
    this.exposureMode = ReceiptNativeExposureMode.auto,
    this.whiteBalanceMode = ReceiptNativeWhiteBalanceMode.auto,
    this.flashMode = ReceiptNativeFlashMode.off,
    this.preferMacroWhenHelpful = true,
    this.imageFormat = ReceiptNativeImageFormat.jpeg,
    this.liveYuvAnalysisEnabled = true,
    this.edgeDetectionEnabled = true,
    this.edgeOverlayEnabled = true,
    this.perspectiveCorrectionEnabled = true,
    this.motionBlurWarningEnabled = true,
    this.glareWarningEnabled = true,
    this.lowLightWarningEnabled = true,
    this.shadowWarningEnabled = true,
    this.tooFarTooCloseWarningEnabled = true,
    this.receiptFullyVisibleWarningEnabled = true,
    this.textTooSmallWarningEnabled = true,
    this.previousSectionGhostGuideEnabled = true,
    this.manualCropAfterCapture = true,
    this.autoCropSuggestionEnabled = true,
    this.grayscalePreviewEnabled = true,
    this.contrastBoostEnabled = true,
    this.sharpeningEnabled = true,
    this.shadowReductionEnabled = true,
    this.adaptiveThresholdEnabled = true,
    this.orientationCorrectionEnabled = true,
    this.saveOriginalTemporarily = true,
    this.queueAcceptedCaptureLocally = true,
    this.ocrUsesOriginalFirst = true,
    this.dataSaverLevel = ReceiptDataSaverLevel.balanced,
  });

  final bool assistedReceiptFill;
  final ReceiptNativeReviewDepth reviewDepth;
  final bool longReceiptMode;
  final bool manualShutterAlwaysAvailable;
  final bool autoCaptureEnabled;
  final bool tapFocusEnabled;
  final bool pinchZoomEnabled;
  final bool exposureSliderEnabled;
  final bool exposureResetEnabled;
  final bool autoExposureAssistEnabled;
  final ReceiptNativeFocusMode focusMode;
  final ReceiptNativeExposureMode exposureMode;
  final ReceiptNativeWhiteBalanceMode whiteBalanceMode;
  final ReceiptNativeFlashMode flashMode;
  final bool preferMacroWhenHelpful;
  final ReceiptNativeImageFormat imageFormat;
  final bool liveYuvAnalysisEnabled;
  final bool edgeDetectionEnabled;
  final bool edgeOverlayEnabled;
  final bool perspectiveCorrectionEnabled;
  final bool motionBlurWarningEnabled;
  final bool glareWarningEnabled;
  final bool lowLightWarningEnabled;
  final bool shadowWarningEnabled;
  final bool tooFarTooCloseWarningEnabled;
  final bool receiptFullyVisibleWarningEnabled;
  final bool textTooSmallWarningEnabled;
  final bool previousSectionGhostGuideEnabled;
  final bool manualCropAfterCapture;
  final bool autoCropSuggestionEnabled;
  final bool grayscalePreviewEnabled;
  final bool contrastBoostEnabled;
  final bool sharpeningEnabled;
  final bool shadowReductionEnabled;
  final bool adaptiveThresholdEnabled;
  final bool orientationCorrectionEnabled;
  final bool saveOriginalTemporarily;
  final bool queueAcceptedCaptureLocally;
  final bool ocrUsesOriginalFirst;
  final ReceiptDataSaverLevel dataSaverLevel;

  bool get protectsInterruptedCapture =>
      saveOriginalTemporarily && queueAcceptedCaptureLocally;

  ReceiptNativeCameraSessionConfig sessionFor({
    required ReceiptDeviceCapability deviceCapability,
    required ReceiptNativeCameraCapabilities nativeCapabilities,
    String? previousSectionGuidePhotoPath,
  }) {
    final lightDevice = deviceCapability.tier == ReceiptCapabilityTier.light;
    final storageSafetyLevel = _strongerDataSaverLevel(
      dataSaverLevel,
      deviceCapability.recommendedDataSaverLevel,
    );
    final storageConstrained =
        storageSafetyLevel == ReceiptDataSaverLevel.strong ||
        storageSafetyLevel == ReceiptDataSaverLevel.maximum;
    final maxSectionCount = _sectionLimitForStorage(
      deviceCapability.maxLocalPhotoCount,
      storageSafetyLevel,
    );
    final autoCaptureAllowed =
        edgeDetectionEnabled &&
        nativeCapabilities.supportsNativeEdgeSignals &&
        !lightDevice &&
        !storageConstrained;
    return ReceiptNativeCameraSessionConfig(
      settings: this,
      nativeCapabilities: nativeCapabilities,
      storageSafetyLevel: storageSafetyLevel,
      storageConstrained: storageConstrained,
      autoCaptureAllowed: autoCaptureAllowed,
      liveAnalysisEnabled:
          liveYuvAnalysisEnabled &&
          nativeCapabilities.supportsYuvLiveFrames &&
          !lightDevice,
      edgeDetectionEnabled:
          edgeDetectionEnabled &&
          (nativeCapabilities.supportsNativeEdgeSignals || !lightDevice),
      autoCaptureEnabled: autoCaptureEnabled && autoCaptureAllowed,
      maxSectionCount: maxSectionCount,
      analysisGapMs: lightDevice
          ? deviceCapability.liveAnalysisGapMs + 240
          : deviceCapability.liveAnalysisGapMs,
      previousSectionGuidePhotoPath:
          previousSectionGhostGuideEnabled &&
              longReceiptMode &&
              previousSectionGuidePhotoPath != null &&
              previousSectionGuidePhotoPath.trim().isNotEmpty
          ? previousSectionGuidePhotoPath.trim()
          : null,
    );
  }

  static ReceiptDataSaverLevel _strongerDataSaverLevel(
    ReceiptDataSaverLevel selected,
    ReceiptDataSaverLevel recommended,
  ) {
    return _dataSaverRank(recommended) > _dataSaverRank(selected)
        ? recommended
        : selected;
  }

  static int _dataSaverRank(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 0,
      ReceiptDataSaverLevel.light => 1,
      ReceiptDataSaverLevel.balanced => 2,
      ReceiptDataSaverLevel.strong => 3,
      ReceiptDataSaverLevel.maximum => 4,
    };
  }

  static int _sectionLimitForStorage(
    int deviceSectionLimit,
    ReceiptDataSaverLevel storageSafetyLevel,
  ) {
    final safeDeviceLimit = deviceSectionLimit <= 0 ? 1 : deviceSectionLimit;
    final storageLimit = switch (storageSafetyLevel) {
      ReceiptDataSaverLevel.maximum => 4,
      ReceiptDataSaverLevel.strong => 6,
      ReceiptDataSaverLevel.original ||
      ReceiptDataSaverLevel.light ||
      ReceiptDataSaverLevel.balanced => safeDeviceLimit,
    };
    return safeDeviceLimit < storageLimit ? safeDeviceLimit : storageLimit;
  }

  static List<ReceiptNativeCameraSettingDescriptor> get descriptors => const [
    ReceiptNativeCameraSettingDescriptor(
      id: 'assisted_receipt_fill',
      label: 'Help fill my receipt',
      description:
          'Maintainiac reads the receipt and opens the review form for you.',
      group: ReceiptNativeSettingGroup.capture,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'review_depth',
      label: 'Receipt review detail',
      description:
          'Choose prices-only for fast review or detailed lines for more fields.',
      group: ReceiptNativeSettingGroup.review,
      type: ReceiptNativeSettingType.segmented,
      defaultValueLabel: 'Prices only',
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'auto_capture',
      label: 'Automatic photo capture',
      description:
          'Optional and off by default. Maintainiac waits for several steady, readable receipt frames before taking a photo. The shutter button still works anytime.',
      group: ReceiptNativeSettingGroup.capture,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: false,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'tap_focus',
      label: 'Tap receipt text to focus',
      description: 'Tap the printed receipt text to set focus and exposure.',
      group: ReceiptNativeSettingGroup.cameraControl,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
      requiresNativeSupport: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'pinch_zoom',
      label: 'Pinch to zoom',
      description: 'Use two fingers to zoom while taking receipt photos.',
      group: ReceiptNativeSettingGroup.cameraControl,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
      requiresNativeSupport: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'exposure_slider',
      label: 'Brightness slider',
      description:
          'Quickly brighten or darken a receipt without leaving the camera.',
      group: ReceiptNativeSettingGroup.cameraControl,
      type: ReceiptNativeSettingType.slider,
      defaultEnabled: true,
      requiresNativeSupport: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'auto_exposure_assist',
      label: 'Auto brightness assist',
      description:
          'Make small safe brightness corrections when the receipt preview is clearly too dark or has glare.',
      group: ReceiptNativeSettingGroup.cameraControl,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
      requiresNativeSupport: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'focus_lock',
      label: 'Lock focus when sharp',
      description: 'Stop focus hunting after the receipt text is clear.',
      group: ReceiptNativeSettingGroup.cameraControl,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
      requiresNativeSupport: true,
      advanced: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'edge_detection',
      label: 'Find receipt edges',
      description:
          'Show receipt edges and use them for crop and perspective correction.',
      group: ReceiptNativeSettingGroup.receiptGuidance,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'readability_warnings',
      label: 'Receipt readability warnings',
      description:
          'Warn about blur, glare, low light, shadows, tiny text, or missing receipt sections.',
      group: ReceiptNativeSettingGroup.receiptGuidance,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'long_receipt_mode',
      label: 'Long receipt photos',
      description:
          'Capture receipts in sections with overlap guidance and section order review.',
      group: ReceiptNativeSettingGroup.longReceipt,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'image_cleanup',
      label: 'Clean receipt image',
      description:
          'Prepare a cleaner OCR source using crop, straighten, contrast, grayscale, and shadow cleanup.',
      group: ReceiptNativeSettingGroup.cleanup,
      type: ReceiptNativeSettingType.toggle,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'safe_capture_queue',
      label: 'Protect captured photos',
      description:
          'Save accepted receipt photos locally right away in case a call, crash, or app switch interrupts the flow.',
      group: ReceiptNativeSettingGroup.storage,
      type: ReceiptNativeSettingType.automatic,
      defaultEnabled: true,
    ),
    ReceiptNativeCameraSettingDescriptor(
      id: 'save_space_preview',
      label: 'Saved copy size',
      description:
          'Preview the smaller proof copy used for storage after receipt reading uses the clearest source.',
      group: ReceiptNativeSettingGroup.storage,
      type: ReceiptNativeSettingType.segmented,
      defaultValueLabel: 'Normal 200-300 KB',
    ),
  ];
}

class ReceiptNativeCameraSessionConfig {
  const ReceiptNativeCameraSessionConfig({
    required this.settings,
    required this.nativeCapabilities,
    required this.storageSafetyLevel,
    required this.storageConstrained,
    required this.autoCaptureAllowed,
    required this.liveAnalysisEnabled,
    required this.edgeDetectionEnabled,
    required this.autoCaptureEnabled,
    required this.maxSectionCount,
    required this.analysisGapMs,
    this.previousSectionGuidePhotoPath,
  });

  final ReceiptNativeCameraSettings settings;
  final ReceiptNativeCameraCapabilities nativeCapabilities;
  final ReceiptDataSaverLevel storageSafetyLevel;
  final bool storageConstrained;
  final bool autoCaptureAllowed;
  final bool liveAnalysisEnabled;
  final bool edgeDetectionEnabled;
  final bool autoCaptureEnabled;
  final int maxSectionCount;
  final int analysisGapMs;
  final String? previousSectionGuidePhotoPath;

  bool get manualCaptureAvailable => settings.manualShutterAlwaysAvailable;
  bool get interruptionSafe => settings.protectsInterruptedCapture;
  bool get ocrSourceProtected => settings.ocrUsesOriginalFirst;
  String get storageSafetyReason {
    if (!storageConstrained) return 'normal';
    return storageSafetyLevel == ReceiptDataSaverLevel.maximum
        ? 'tight_storage_tiny_proofs'
        : 'low_storage_small_proofs';
  }

  bool get hasPreviousSectionGuide =>
      previousSectionGuidePhotoPath != null &&
      previousSectionGuidePhotoPath!.trim().isNotEmpty;
}

class ReceiptNativeCaptureResult {
  const ReceiptNativeCaptureResult({
    required this.engine,
    required this.originalPhotoPaths,
    required this.temporaryCaptureIds,
    required this.capturedAt,
    this.captureDiagnostics = const {},
  });

  final ReceiptNativeCameraEngine engine;
  final List<String> originalPhotoPaths;
  final List<String> temporaryCaptureIds;
  final DateTime capturedAt;
  final Map<String, Object?> captureDiagnostics;

  bool get hasPhotos => originalPhotoPaths.isNotEmpty;
  bool get hasSafeLocalCopies => temporaryCaptureIds.isNotEmpty;
}
