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

class TripTrackingSettings {
  const TripTrackingSettings({
    this.gpsAssistedTrackingEnabled = false,
    this.samplingPreset = TripTrackingSamplingPreset.enhancedAccuracy,
    this.customIntervalSeconds = 15,
    this.adaptiveSamplingEnabled = false,
    this.activityRecognitionEnabled = true,
    this.walkingTransitionReviewEnabled = true,
    this.backgroundTrackingEnabled = false,
    this.organizationMileageSharingEnabled = false,
    this.defaultProfile = TripTrackingProfile.roadVehicle,
    this.bluetoothVehicleRecognitionEnabled = false,
    this.automaticVehicleSwitchEnabled = false,
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
    );
  }

  Map<String, Object?> toMap() => {
    'gpsAssistedTrackingEnabled': gpsAssistedTrackingEnabled,
    'samplingPreset': samplingPreset.name,
    'customIntervalSeconds': customIntervalSeconds,
    'adaptiveSamplingEnabled': adaptiveSamplingEnabled,
    'activityRecognitionEnabled': activityRecognitionEnabled,
    'walkingTransitionReviewEnabled': walkingTransitionReviewEnabled,
    'backgroundTrackingEnabled': backgroundTrackingEnabled,
    'organizationMileageSharingEnabled': organizationMileageSharingEnabled,
    'defaultProfile': defaultProfile.name,
    'bluetoothVehicleRecognitionEnabled': bluetoothVehicleRecognitionEnabled,
    'automaticVehicleSwitchEnabled': automaticVehicleSwitchEnabled,
  };

  factory TripTrackingSettings.fromMap(Map<dynamic, dynamic> map) {
    final bluetoothEnabled = map['bluetoothVehicleRecognitionEnabled'] == true;
    return TripTrackingSettings(
      gpsAssistedTrackingEnabled: map['gpsAssistedTrackingEnabled'] == true,
      samplingPreset: _presetFromMap(map),
      customIntervalSeconds: _validCustomInterval(
        (map['customIntervalSeconds'] as num?)?.round() ?? 15,
      ),
      adaptiveSamplingEnabled: map['adaptiveSamplingEnabled'] == true,
      activityRecognitionEnabled: map['activityRecognitionEnabled'] != false,
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
    );
  }
}

int _validCustomInterval(int seconds) => seconds.clamp(3, 600);

TripTrackingSamplingPreset _presetFromMap(Map<dynamic, dynamic> map) {
  final savedPreset = TripTrackingSamplingPreset.values.firstWhere(
    (value) => value.name == map['samplingPreset'],
    orElse: () => TripTrackingSamplingPreset.custom,
  );
  if (map['samplingPreset'] != null) return savedPreset;
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
