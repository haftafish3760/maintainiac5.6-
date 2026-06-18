import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'receipt_capture_models.dart';

enum ReceiptCaptureArea {
  expenses('Expenses'),
  materialsInventory('Materials / Inventory'),
  maintenanceRepair('Maintenance / Repairs');

  const ReceiptCaptureArea(this.label);

  final String label;
}

class ReceiptCaptureSettingsController extends ChangeNotifier {
  ReceiptCaptureSettingsController._(this._box);

  static const boxName = 'receipt_capture_settings';

  static Future<ReceiptCaptureSettingsController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ReceiptCaptureSettingsController._(box);
  }

  final Box<dynamic> _box;

  bool get appAssistedReceiptFill =>
      _readBool(_Keys.appAssistedReceiptFill, true);
  bool get appAssistedExpenses => _readBool(_Keys.appAssistedExpenses, true);
  bool get appAssistedMaterials => _readBool(_Keys.appAssistedMaterials, true);
  bool get appAssistedMaintenance =>
      _readBool(_Keys.appAssistedMaintenance, true);
  bool get cameraSetupComplete => _readBool(_Keys.cameraSetupComplete, false);
  bool get cameraGuidanceEnabled =>
      _readBool(_Keys.cameraGuidanceEnabled, true);
  bool get cameraStartAssisted => _readBool(_Keys.cameraStartAssisted, true);
  bool get cameraAutoCapture => _readBool(_Keys.cameraAutoCapture, false);
  bool get cameraVoiceCapture => _readBool(_Keys.cameraVoiceCapture, false);
  bool get cameraLongReceiptTips =>
      _readBool(_Keys.cameraLongReceiptTips, true);
  bool get googleVisionAccess => _readBool(_Keys.googleVisionAccess, false);
  int get monthlyGoogleVisionLimit =>
      _readInt(_Keys.monthlyGoogleVisionLimit, 30);
  ReceiptDataSaverLevel get defaultDataSaverLevel {
    return ReceiptDataSaverLevel.fromName(
      _box.get(_Keys.defaultDataSaverLevel) as String?,
    );
  }

  Future<void> setAppAssistedReceiptFill(bool value) =>
      _writeBool(_Keys.appAssistedReceiptFill, value);
  Future<void> setAppAssistedExpenses(bool value) =>
      _writeBool(_Keys.appAssistedExpenses, value);
  Future<void> setAppAssistedMaterials(bool value) =>
      _writeBool(_Keys.appAssistedMaterials, value);
  Future<void> setAppAssistedMaintenance(bool value) =>
      _writeBool(_Keys.appAssistedMaintenance, value);
  Future<void> setCameraSetupComplete(bool value) =>
      _writeBool(_Keys.cameraSetupComplete, value);
  Future<void> setCameraGuidanceEnabled(bool value) =>
      _writeBool(_Keys.cameraGuidanceEnabled, value);
  Future<void> setCameraStartAssisted(bool value) =>
      _writeBool(_Keys.cameraStartAssisted, value);
  Future<void> setCameraAutoCapture(bool value) =>
      _writeBool(_Keys.cameraAutoCapture, value);
  Future<void> setCameraVoiceCapture(bool value) =>
      _writeBool(_Keys.cameraVoiceCapture, value);
  Future<void> setCameraLongReceiptTips(bool value) =>
      _writeBool(_Keys.cameraLongReceiptTips, value);
  Future<void> setGoogleVisionAccess(bool value) =>
      _writeBool(_Keys.googleVisionAccess, value);
  Future<void> setMonthlyGoogleVisionLimit(int value) async {
    await _box.put(_Keys.monthlyGoogleVisionLimit, value.clamp(0, 500));
    notifyListeners();
  }

  Future<void> setDefaultDataSaverLevel(ReceiptDataSaverLevel level) async {
    await _box.put(_Keys.defaultDataSaverLevel, level.name);
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
    return context
        .dependOnInheritedWidgetOfExactType<ReceiptCaptureSettingsScope>()
        ?.notifier;
  }
}

class _Keys {
  const _Keys._();

  static const appAssistedReceiptFill = 'app_assisted_receipt_fill';
  static const appAssistedExpenses = 'app_assisted_expenses';
  static const appAssistedMaterials = 'app_assisted_materials';
  static const appAssistedMaintenance = 'app_assisted_maintenance';
  static const cameraSetupComplete = 'camera_setup_complete';
  static const cameraGuidanceEnabled = 'camera_guidance_enabled';
  static const cameraStartAssisted = 'camera_start_assisted';
  static const cameraAutoCapture = 'camera_auto_capture';
  static const cameraVoiceCapture = 'camera_voice_capture';
  static const cameraLongReceiptTips = 'camera_long_receipt_tips';
  static const defaultDataSaverLevel = 'default_data_saver_level';
  static const googleVisionAccess = 'google_vision_access';
  static const monthlyGoogleVisionLimit = 'monthly_google_vision_limit';
}
