import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'receipt_assistance_policy.dart';
import 'receipt_capture_models.dart';
import 'receipt_device_capability_service.dart';

part 'receipt_capture_settings_data_saver.dart';

enum ReceiptCaptureArea {
  expenses('Expenses'),
  materialsInventory('Materials / Inventory'),
  maintenanceRepair('Maintenance / Repairs');

  const ReceiptCaptureArea(this.label);

  final String label;
}

class ReceiptCaptureSettingsController extends ChangeNotifier {
  ReceiptCaptureSettingsController._(
    this._box, {
    required ReceiptHardwareProfile hardwareProfile,
    required ReceiptDeviceCapability deviceCapability,
    ReceiptDeviceCapabilityService capabilityService =
        const ReceiptDeviceCapabilityService(),
  }) : _hardwareProfile = hardwareProfile,
       _deviceCapability = deviceCapability,
       _capabilityService = capabilityService;

  static const boxName = 'receipt_capture_settings';

  static Future<ReceiptCaptureSettingsController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    const service = ReceiptDeviceCapabilityService();
    final mode = ReceiptPerformanceMode.fromName(
      box.get(_Keys.receiptPerformanceMode) as String?,
    );
    final hardware = await service.detectHardwareProfile();
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: hardware,
      mode: mode,
    );
    return ReceiptCaptureSettingsController._(
      box,
      hardwareProfile: hardware,
      deviceCapability: capability,
      capabilityService: service,
    );
  }

  final Box<dynamic> _box;
  final ReceiptDeviceCapabilityService _capabilityService;
  ReceiptHardwareProfile _hardwareProfile;
  ReceiptDeviceCapability _deviceCapability;

  ReceiptHardwareProfile get hardwareProfile => _hardwareProfile;
  ReceiptDeviceCapability get deviceCapability => _deviceCapability;
  ReceiptCapabilityTier get receiptCapabilityTier => _deviceCapability.tier;
  String get privacySafeCapabilityLabel {
    return _hardwareProfile.privacySafeCapabilityLabel(
      mode: receiptPerformanceMode,
    );
  }

  Map<String, Object?> get privacySafeCapabilityDiagnostics {
    return _hardwareProfile.privacySafeCapabilityDiagnostics(
      mode: receiptPerformanceMode,
    );
  }

  ReceiptCameraRuntimeProfile get effectiveCameraRuntimeProfile {
    return _deviceCapability.cameraRuntimeProfileFor(
      guidanceRequested: cameraGuidanceEnabled,
      startAssistedRequested: cameraStartAssisted,
      autoCaptureRequested: cameraAutoCapture,
      longReceiptTipsRequested: cameraLongReceiptTips,
    );
  }

  bool get appAssistedReceiptFill =>
      _readBool(_Keys.appAssistedReceiptFill, false);
  bool get appAssistedExpenses => _readBool(_Keys.appAssistedExpenses, false);
  bool get appAssistedMaterials => _readBool(_Keys.appAssistedMaterials, false);
  bool get appAssistedMaintenance =>
      _readBool(_Keys.appAssistedMaintenance, false);
  bool get cameraSetupComplete => _readBool(_Keys.cameraSetupComplete, false);
  bool hasReceiptAssistChoiceFor(ReceiptCaptureArea area) {
    if (_readBool(_receiptAssistChoiceKey(area), false)) return true;
    return cameraSetupComplete;
  }

  bool get cameraGuidanceEnabled =>
      _readBool(_Keys.cameraGuidanceEnabled, true);
  bool get cameraStartAssisted => _readBool(_Keys.cameraStartAssisted, false);
  bool get cameraAutoCapture => _readBool(_Keys.cameraAutoCapture, false);
  bool get cameraVoiceCapture => _readBool(_Keys.cameraVoiceCapture, false);
  bool get cameraLongReceiptTips =>
      _readBool(_Keys.cameraLongReceiptTips, true);
  bool get cameraDiagnosticsImprovementOptIn =>
      _readBool(_Keys.cameraDiagnosticsImprovementOptIn, false);
  bool get googleVisionAccess => _readBool(_Keys.googleVisionAccess, false);
  int get monthlyGoogleVisionLimit =>
      _readInt(_Keys.monthlyGoogleVisionLimit, 30);
  ReceiptPerformanceMode get receiptPerformanceMode {
    return ReceiptPerformanceMode.fromName(
      _box.get(_Keys.receiptPerformanceMode) as String?,
    );
  }

  bool get defaultDataSaverUsesDeviceRecommendation {
    final saved = _box.get(_Keys.defaultDataSaverLevel) as String?;
    return saved == null || saved.isEmpty;
  }

  Future<void> useRecommendedDataSaverLevel() async {
    await _box.delete(_Keys.defaultDataSaverLevel);
    notifyListeners();
  }

  Future<void> setAppAssistedReceiptFill(bool value) =>
      _writeBool(_Keys.appAssistedReceiptFill, value);
  Future<void> setAppAssistedExpenses(bool value) =>
      _writeBool(_Keys.appAssistedExpenses, value);
  Future<void> setAppAssistedMaterials(bool value) =>
      _writeBool(_Keys.appAssistedMaterials, value);
  Future<void> setAppAssistedMaintenance(bool value) =>
      _writeBool(_Keys.appAssistedMaintenance, value);
  Future<void> setReceiptAssistChoiceMadeFor(
    ReceiptCaptureArea area,
    bool value,
  ) => _writeBool(_receiptAssistChoiceKey(area), value);
  Future<void> setCameraSetupComplete(bool value) =>
      _writeBool(_Keys.cameraSetupComplete, value);
  Future<void> setCameraGuidanceEnabled(bool value) =>
      _writeBool(_Keys.cameraGuidanceEnabled, value);
  Future<void> setCameraStartAssisted(bool value) =>
      _writeBool(_Keys.cameraStartAssisted, value);
  Future<void> setCameraAutoCapture(bool value) =>
      _writeBool(_Keys.cameraAutoCapture, value);
  Future<void> setCameraAutoCapturePreference(bool value) async {
    if (value) await _box.put(_Keys.cameraStartAssisted, true);
    await _box.put(_Keys.cameraAutoCapture, value);
    notifyListeners();
  }

  Future<void> setCameraVoiceCapture(bool value) =>
      _writeBool(_Keys.cameraVoiceCapture, value);
  Future<void> setCameraLongReceiptTips(bool value) =>
      _writeBool(_Keys.cameraLongReceiptTips, value);
  Future<void> setCameraDiagnosticsImprovementOptIn(bool value) =>
      _writeBool(_Keys.cameraDiagnosticsImprovementOptIn, value);
  Future<void> setGoogleVisionAccess(bool value) =>
      _writeBool(_Keys.googleVisionAccess, value);
  Future<void> setMonthlyGoogleVisionLimit(int value) async {
    await _box.put(_Keys.monthlyGoogleVisionLimit, value.clamp(0, 500));
    notifyListeners();
  }

  Future<void> setReceiptPerformanceMode(ReceiptPerformanceMode mode) async {
    await _box.put(_Keys.receiptPerformanceMode, mode.name);
    _hardwareProfile = await _capabilityService.detectHardwareProfile();
    _deviceCapability = ReceiptDeviceCapability.fromHardware(
      hardware: _hardwareProfile,
      mode: mode,
    );
    notifyListeners();
  }

  Future<void> setDefaultDataSaverLevel(ReceiptDataSaverLevel level) async {
    await _box.put(_Keys.defaultDataSaverLevel, level.name);
    notifyListeners();
  }

  Future<void> resetReceiptPhotoDefaultsFor(ReceiptCaptureArea area) async {
    switch (area) {
      case ReceiptCaptureArea.expenses:
        await _box.put(_Keys.appAssistedExpenses, false);
      case ReceiptCaptureArea.materialsInventory:
        await _box.put(_Keys.appAssistedMaterials, false);
      case ReceiptCaptureArea.maintenanceRepair:
        await _box.put(_Keys.appAssistedMaintenance, false);
    }
    await _box.delete(_receiptAssistChoiceKey(area));
    await _box.put(_Keys.cameraGuidanceEnabled, true);
    await _box.put(_Keys.cameraStartAssisted, false);
    await _box.put(_Keys.cameraAutoCapture, false);
    await _box.put(_Keys.cameraVoiceCapture, false);
    await _box.put(_Keys.cameraLongReceiptTips, true);
    await _box.put(_Keys.cameraDiagnosticsImprovementOptIn, false);
    await _box.delete(_Keys.defaultDataSaverLevel);
    await _box.put(
      _Keys.receiptPerformanceMode,
      ReceiptPerformanceMode.automatic.name,
    );
    _hardwareProfile = await _capabilityService.detectHardwareProfile();
    _deviceCapability = ReceiptDeviceCapability.fromHardware(
      hardware: _hardwareProfile,
      mode: ReceiptPerformanceMode.automatic,
    );
    notifyListeners();
  }

  bool appAssistedEnabledFor(ReceiptCaptureArea area) {
    if (!appAssistedReceiptFill) return false;
    return switch (area) {
      ReceiptCaptureArea.expenses => appAssistedExpenses,
      ReceiptCaptureArea.materialsInventory => appAssistedMaterials,
      ReceiptCaptureArea.maintenanceRepair => appAssistedMaintenance,
    };
  }

  bool _readBool(String key, bool fallback) {
    final value = _box.get(key);
    return value is bool ? value : fallback;
  }

  int _readInt(String key, int fallback) {
    final value = _box.get(key);
    return value is int ? value : fallback;
  }

  Future<void> _writeBool(String key, bool value) async {
    await _box.put(key, value);
    notifyListeners();
  }

  String _receiptAssistChoiceKey(ReceiptCaptureArea area) {
    return switch (area) {
      ReceiptCaptureArea.expenses => _Keys.receiptAssistChoiceExpenses,
      ReceiptCaptureArea.materialsInventory =>
        _Keys.receiptAssistChoiceMaterials,
      ReceiptCaptureArea.maintenanceRepair =>
        _Keys.receiptAssistChoiceMaintenance,
    };
  }
}

ReceiptDeviceStorageClass storageClassForDataSaverLevel(
  ReceiptDataSaverLevel level,
) {
  return switch (level) {
    ReceiptDataSaverLevel.maximum => ReceiptDeviceStorageClass.critical,
    ReceiptDataSaverLevel.strong => ReceiptDeviceStorageClass.low,
    ReceiptDataSaverLevel.original ||
    ReceiptDataSaverLevel.light ||
    ReceiptDataSaverLevel.balanced => ReceiptDeviceStorageClass.comfortable,
  };
}

class ReceiptCaptureSettingsScope
    extends InheritedNotifier<ReceiptCaptureSettingsController> {
  const ReceiptCaptureSettingsScope({
    super.key,
    required ReceiptCaptureSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ReceiptCaptureSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ReceiptCaptureSettingsScope>();
    assert(
      scope != null,
      'ReceiptCaptureSettingsScope is missing above this context.',
    );
    return scope!.notifier!;
  }

  static ReceiptCaptureSettingsController? maybeOf(BuildContext context) {
    try {
      final widget = context
          .getElementForInheritedWidgetOfExactType<
            ReceiptCaptureSettingsScope
          >()
          ?.widget;
      return widget is ReceiptCaptureSettingsScope ? widget.notifier : null;
    } on FlutterError {
      return null;
    }
  }
}

class _Keys {
  const _Keys._();

  static const appAssistedReceiptFill = 'app_assisted_receipt_fill';
  static const appAssistedExpenses = 'app_assisted_expenses';
  static const appAssistedMaterials = 'app_assisted_materials';
  static const appAssistedMaintenance = 'app_assisted_maintenance';
  static const receiptAssistChoiceExpenses = 'receipt_assist_choice_expenses';
  static const receiptAssistChoiceMaterials = 'receipt_assist_choice_materials';
  static const receiptAssistChoiceMaintenance =
      'receipt_assist_choice_maintenance';
  static const cameraSetupComplete = 'camera_setup_complete';
  static const cameraGuidanceEnabled = 'camera_guidance_enabled';
  static const cameraStartAssisted = 'camera_start_assisted';
  static const cameraAutoCapture = 'camera_auto_capture';
  static const cameraVoiceCapture = 'camera_voice_capture';
  static const cameraLongReceiptTips = 'camera_long_receipt_tips';
  static const cameraDiagnosticsImprovementOptIn =
      'camera_diagnostics_improvement_opt_in';
  static const defaultDataSaverLevel = 'default_data_saver_level';
  static const receiptPerformanceMode = 'receipt_performance_mode';
  static const googleVisionAccess = 'google_vision_access';
  static const monthlyGoogleVisionLimit = 'monthly_google_vision_limit';
}
