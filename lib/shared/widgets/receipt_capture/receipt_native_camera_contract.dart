import 'receipt_assistance_policy.dart';
import 'receipt_capture_models.dart';

part 'receipt_native_camera_settings.dart';
part 'receipt_native_camera_settings_session.dart';
part 'receipt_native_camera_settings_policy.dart';
part 'receipt_native_camera_settings_descriptors.dart';
part 'receipt_native_camera_session_config.dart';
part 'receipt_native_camera_session_ghost_guide.dart';

enum ReceiptNativeCameraEngine {
  systemCamera('Phone camera'),
  cameraX('CameraX'),
  avFoundation('AVFoundation'),
  unavailable('Native camera unavailable');

  const ReceiptNativeCameraEngine(this.label);

  final String label;
}

ReceiptNativeCameraEngine receiptNativeCameraEngineFromName(String? name) {
  final normalized = name?.trim() ?? '';
  return ReceiptNativeCameraEngine.values.firstWhere(
    (value) => value.name == normalized,
    orElse: () => ReceiptNativeCameraEngine.unavailable,
  );
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
    final engine = receiptNativeCameraEngineFromName(map['engine']?.toString());
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
    if (value is num && value.isFinite) return value.round();
    return 0;
  }

  static double _doubleValue(Object? value, {double fallback = 0}) {
    if (value is num && value.isFinite) return value.toDouble();
    return fallback;
  }
}

class ReceiptNativeCaptureResult {
  ReceiptNativeCaptureResult({
    required this.engine,
    required List<String> originalPhotoPaths,
    required List<String> temporaryCaptureIds,
    required this.capturedAt,
    Map<String, Object?> captureDiagnostics = const {},
  }) : originalPhotoPaths = List<String>.unmodifiable(originalPhotoPaths),
       temporaryCaptureIds = List<String>.unmodifiable(temporaryCaptureIds),
       captureDiagnostics = Map<String, Object?>.unmodifiable({
         for (final entry in captureDiagnostics.entries)
           entry.key: _freezeNativeCaptureDiagnosticValue(entry.value),
       });

  final ReceiptNativeCameraEngine engine;
  final List<String> originalPhotoPaths;
  final List<String> temporaryCaptureIds;
  final DateTime capturedAt;
  final Map<String, Object?> captureDiagnostics;

  bool get hasPhotos => originalPhotoPaths.isNotEmpty;
  bool get hasSafeLocalCopies => temporaryCaptureIds.isNotEmpty;
}

Object? _freezeNativeCaptureDiagnosticValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key.toString(): _freezeNativeCaptureDiagnosticValue(entry.value),
    });
  }
  if (value is Iterable) {
    return List<Object?>.unmodifiable(
      value.map(_freezeNativeCaptureDiagnosticValue),
    );
  }
  return value;
}
