import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'trip_tracking_models.dart';

enum TripTrackingSamplingPreset {
  highAccuracy,
  enhancedAccuracy,
  balanced,
  batterySaver,
  extremeOptimized,
  custom,
}

enum TripTrackingBackupNetworkPolicy {
  wifiOnly,
  wifiAndMobileData,
  mobileDataOnly,
}

extension TripTrackingBackupNetworkPolicyDecision
    on TripTrackingBackupNetworkPolicy {
  bool allows({
    required bool wifiAvailable,
    required bool mobileDataAvailable,
  }) {
    return switch (this) {
      TripTrackingBackupNetworkPolicy.wifiOnly => wifiAvailable,
      TripTrackingBackupNetworkPolicy.wifiAndMobileData =>
        wifiAvailable || mobileDataAvailable,
      TripTrackingBackupNetworkPolicy.mobileDataOnly => mobileDataAvailable,
    };
  }
}

class TripTrackingSettings {
  const TripTrackingSettings({
    this.gpsAssistedTrackingEnabled = false,
    this.samplingPreset = TripTrackingSamplingPreset.enhancedAccuracy,
    this.customIntervalSeconds = 15,
    this.adaptiveSamplingEnabled = false,
    this.activityRecognitionEnabled = false,
    this.walkingTransitionReviewEnabled = true,
    this.backgroundTrackingEnabled = false,
    this.organizationMileageSharingEnabled = false,
    this.defaultProfile = TripTrackingProfile.roadVehicle,
    this.bluetoothVehicleRecognitionEnabled = false,
    this.automaticVehicleSwitchEnabled = false,
    this.lowBatteryGpsProtectionEnabled = true,
    this.lowBatteryGpsOverrideEnabled = false,
    this.lowBatteryGpsWarningDismissed = false,
    this.backupNetworkPolicy =
        TripTrackingBackupNetworkPolicy.wifiAndMobileData,
  });

  final bool gpsAssistedTrackingEnabled;
  final TripTrackingSamplingPreset samplingPreset;
  final int customIntervalSeconds;
  final bool adaptiveSamplingEnabled;
  final bool activityRecognitionEnabled;
  final bool walkingTransitionReviewEnabled;
  final bool backgroundTrackingEnabled;
  final bool organizationMileageSharingEnabled;
  final TripTrackingProfile defaultProfile;
  final bool bluetoothVehicleRecognitionEnabled;
  final bool automaticVehicleSwitchEnabled;
  final bool lowBatteryGpsProtectionEnabled;
  final bool lowBatteryGpsOverrideEnabled;
  final bool lowBatteryGpsWarningDismissed;
  final TripTrackingBackupNetworkPolicy backupNetworkPolicy;

  TripTrackingSettings copyWith({
    bool? gpsAssistedTrackingEnabled,
    TripTrackingSamplingPreset? samplingPreset,
    int? customIntervalSeconds,
    bool? adaptiveSamplingEnabled,
    bool? activityRecognitionEnabled,
    bool? walkingTransitionReviewEnabled,
    bool? backgroundTrackingEnabled,
    bool? organizationMileageSharingEnabled,
    TripTrackingProfile? defaultProfile,
    bool? bluetoothVehicleRecognitionEnabled,
    bool? automaticVehicleSwitchEnabled,
    bool? lowBatteryGpsProtectionEnabled,
    bool? lowBatteryGpsOverrideEnabled,
    bool? lowBatteryGpsWarningDismissed,
    TripTrackingBackupNetworkPolicy? backupNetworkPolicy,
  }) {
    final bluetoothEnabled =
        bluetoothVehicleRecognitionEnabled ??
        this.bluetoothVehicleRecognitionEnabled;
    final automaticSwitch =
        automaticVehicleSwitchEnabled ?? this.automaticVehicleSwitchEnabled;
    return TripTrackingSettings(
      gpsAssistedTrackingEnabled:
          gpsAssistedTrackingEnabled ?? this.gpsAssistedTrackingEnabled,
      samplingPreset: samplingPreset ?? this.samplingPreset,
      customIntervalSeconds: _validCustomInterval(
        customIntervalSeconds ?? this.customIntervalSeconds,
      ),
      adaptiveSamplingEnabled:
          adaptiveSamplingEnabled ?? this.adaptiveSamplingEnabled,
      activityRecognitionEnabled:
          activityRecognitionEnabled ?? this.activityRecognitionEnabled,
      walkingTransitionReviewEnabled:
          walkingTransitionReviewEnabled ?? this.walkingTransitionReviewEnabled,
      backgroundTrackingEnabled:
          backgroundTrackingEnabled ?? this.backgroundTrackingEnabled,
      organizationMileageSharingEnabled:
          organizationMileageSharingEnabled ??
          this.organizationMileageSharingEnabled,
      defaultProfile: defaultProfile ?? this.defaultProfile,
      bluetoothVehicleRecognitionEnabled: bluetoothEnabled,
      automaticVehicleSwitchEnabled: bluetoothEnabled && automaticSwitch,
      lowBatteryGpsProtectionEnabled:
          lowBatteryGpsProtectionEnabled ?? this.lowBatteryGpsProtectionEnabled,
      lowBatteryGpsOverrideEnabled:
          lowBatteryGpsOverrideEnabled ?? this.lowBatteryGpsOverrideEnabled,
      lowBatteryGpsWarningDismissed:
          lowBatteryGpsWarningDismissed ?? this.lowBatteryGpsWarningDismissed,
      backupNetworkPolicy: backupNetworkPolicy ?? this.backupNetworkPolicy,
    );
  }

  Map<String, Object?> toMap() => {
    'gpsAssistedTrackingEnabled': gpsAssistedTrackingEnabled,
    'samplingPreset': samplingPreset.name,
    'customIntervalSeconds': _validCustomInterval(customIntervalSeconds),
    'adaptiveSamplingEnabled': adaptiveSamplingEnabled,
    'activityRecognitionEnabled': activityRecognitionEnabled,
    'walkingTransitionReviewEnabled': walkingTransitionReviewEnabled,
    'backgroundTrackingEnabled': backgroundTrackingEnabled,
    'organizationMileageSharingEnabled': organizationMileageSharingEnabled,
    'defaultProfile': defaultProfile.name,
    'bluetoothVehicleRecognitionEnabled': bluetoothVehicleRecognitionEnabled,
    'automaticVehicleSwitchEnabled': automaticVehicleSwitchEnabled,
    'lowBatteryGpsProtectionEnabled': lowBatteryGpsProtectionEnabled,
    'lowBatteryGpsOverrideEnabled': lowBatteryGpsOverrideEnabled,
    'lowBatteryGpsWarningDismissed': lowBatteryGpsWarningDismissed,
    'backupNetworkPolicy': backupNetworkPolicy.name,
  };

  factory TripTrackingSettings.fromMap(Map<dynamic, dynamic> map) {
    final bluetoothEnabled = map['bluetoothVehicleRecognitionEnabled'] == true;
    return TripTrackingSettings(
      gpsAssistedTrackingEnabled: map['gpsAssistedTrackingEnabled'] == true,
      samplingPreset: _presetFromMap(map),
      customIntervalSeconds: _validCustomInterval(
        _safeNumber(map['customIntervalSeconds'])?.round() ?? 15,
      ),
      adaptiveSamplingEnabled: map['adaptiveSamplingEnabled'] == true,
      activityRecognitionEnabled: map['activityRecognitionEnabled'] == true,
      walkingTransitionReviewEnabled:
          map['walkingTransitionReviewEnabled'] != false,
      backgroundTrackingEnabled: map['backgroundTrackingEnabled'] == true,
      organizationMileageSharingEnabled:
          map['organizationMileageSharingEnabled'] == true,
      defaultProfile: TripTrackingProfile.values.firstWhere(
        (value) => value.name == map['defaultProfile'],
        orElse: () => TripTrackingProfile.roadVehicle,
      ),
      bluetoothVehicleRecognitionEnabled: bluetoothEnabled,
      automaticVehicleSwitchEnabled:
          bluetoothEnabled && map['automaticVehicleSwitchEnabled'] == true,
      lowBatteryGpsProtectionEnabled:
          map['lowBatteryGpsProtectionEnabled'] != false,
      lowBatteryGpsOverrideEnabled: map['lowBatteryGpsOverrideEnabled'] == true,
      lowBatteryGpsWarningDismissed:
          map['lowBatteryGpsWarningDismissed'] == true,
      backupNetworkPolicy: TripTrackingBackupNetworkPolicy.values.firstWhere(
        (value) => value.name == map['backupNetworkPolicy'],
        orElse: () => TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      ),
    );
  }
}

int _validCustomInterval(int seconds) => seconds.clamp(3, 600);

num? _safeNumber(Object? value) =>
    value is num && value.isFinite ? value : null;

TripTrackingSamplingPreset _presetFromMap(Map<dynamic, dynamic> map) {
  final rawPreset = map['samplingPreset'];
  if (rawPreset is String) {
    return TripTrackingSamplingPreset.values.firstWhere(
      (value) => value.name == rawPreset,
      orElse: () => TripTrackingSamplingPreset.enhancedAccuracy,
    );
  }
  if (rawPreset != null) return TripTrackingSamplingPreset.enhancedAccuracy;
  // Migration from the earlier, less-specific selector.
  return switch (map['batteryMode']) {
    'precision' => TripTrackingSamplingPreset.highAccuracy,
    'balanced' => TripTrackingSamplingPreset.balanced,
    'saver' => TripTrackingSamplingPreset.batterySaver,
    _ => TripTrackingSamplingPreset.enhancedAccuracy,
  };
}

class TripTrackingSettingsController extends ChangeNotifier {
  TripTrackingSettingsController._(this._box, this._settings);
  TripTrackingSettingsController.memory([TripTrackingSettings? settings])
    : _box = null,
      _settings = settings ?? const TripTrackingSettings();

  static const boxName = 'gps_trip_tracking_settings';
  static const _settingsKey = 'settings';

  final Box<dynamic>? _box;
  TripTrackingSettings _settings;

  TripTrackingSettings get settings => _settings;

  static Future<TripTrackingSettingsController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    final stored = box.get(_settingsKey);
    return TripTrackingSettingsController._(
      box,
      stored is Map
          ? TripTrackingSettings.fromMap(stored)
          : const TripTrackingSettings(),
    );
  }

  Future<void> update(TripTrackingSettings settings) async {
    if (_settings.toMap().toString() == settings.toMap().toString()) return;
    _settings = settings;
    await _box?.put(_settingsKey, settings.toMap());
    notifyListeners();
  }
}

class TripTrackingSettingsScope
    extends InheritedNotifier<TripTrackingSettingsController> {
  const TripTrackingSettingsScope({
    super.key,
    required TripTrackingSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static TripTrackingSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TripTrackingSettingsScope>();
    assert(
      scope != null,
      'TripTrackingSettingsScope is missing above this context.',
    );
    return scope!.notifier!;
  }

  static TripTrackingSettingsController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<TripTrackingSettingsScope>()
          ?.notifier;
}
