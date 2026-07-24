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
    this.tripTrackingSetupCompleted = false,
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
    this.automaticStartAssistanceEnabled = false,
    this.lowBatteryGpsProtectionEnabled = true,
    this.lowBatteryGpsOverrideEnabled = false,
    this.lowBatteryGpsWarningDismissed = false,
    this.odometerAnomalyAlertsEnabled = false,
    this.gpsOdometerCalibrationAssistEnabled = false,
    this.mapPreviewEnabled = false,
    this.mapRouteHistorySavingEnabled = false,
    this.mapRouteHistoryDailyBudgetMb = 0,
    this.mapRouteHistorySampleIntervalSeconds = 30,
    this.backupNetworkPolicy =
        TripTrackingBackupNetworkPolicy.wifiAndMobileData,
  });

  static const schemaVersion = 2;

  final bool tripTrackingSetupCompleted;
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
  final bool automaticStartAssistanceEnabled;
  final bool lowBatteryGpsProtectionEnabled;
  final bool lowBatteryGpsOverrideEnabled;
  final bool lowBatteryGpsWarningDismissed;
  final bool odometerAnomalyAlertsEnabled;
  final bool gpsOdometerCalibrationAssistEnabled;
  final bool mapPreviewEnabled;
  final bool mapRouteHistorySavingEnabled;
  final double mapRouteHistoryDailyBudgetMb;
  final int mapRouteHistorySampleIntervalSeconds;
  final TripTrackingBackupNetworkPolicy backupNetworkPolicy;

  TripTrackingSettings copyWith({
    bool? tripTrackingSetupCompleted,
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
    bool? automaticStartAssistanceEnabled,
    bool? lowBatteryGpsProtectionEnabled,
    bool? lowBatteryGpsOverrideEnabled,
    bool? lowBatteryGpsWarningDismissed,
    bool? odometerAnomalyAlertsEnabled,
    bool? gpsOdometerCalibrationAssistEnabled,
    bool? mapPreviewEnabled,
    bool? mapRouteHistorySavingEnabled,
    double? mapRouteHistoryDailyBudgetMb,
    int? mapRouteHistorySampleIntervalSeconds,
    TripTrackingBackupNetworkPolicy? backupNetworkPolicy,
  }) {
    final gpsEnabled =
        gpsAssistedTrackingEnabled ?? this.gpsAssistedTrackingEnabled;
    final bluetoothEnabled =
        bluetoothVehicleRecognitionEnabled ??
        this.bluetoothVehicleRecognitionEnabled;
    final automaticSwitch =
        automaticVehicleSwitchEnabled ?? this.automaticVehicleSwitchEnabled;
    final walkingReview =
        walkingTransitionReviewEnabled ?? this.walkingTransitionReviewEnabled;
    final odometerAlerts =
        gpsEnabled &&
        (odometerAnomalyAlertsEnabled ?? this.odometerAnomalyAlertsEnabled);
    return TripTrackingSettings(
      tripTrackingSetupCompleted:
          tripTrackingSetupCompleted ?? this.tripTrackingSetupCompleted,
      gpsAssistedTrackingEnabled: gpsEnabled,
      samplingPreset: samplingPreset ?? this.samplingPreset,
      customIntervalSeconds: _validCustomInterval(
        customIntervalSeconds ?? this.customIntervalSeconds,
      ),
      adaptiveSamplingEnabled:
          adaptiveSamplingEnabled ?? this.adaptiveSamplingEnabled,
      activityRecognitionEnabled:
          gpsEnabled &&
          walkingReview &&
          (activityRecognitionEnabled ?? this.activityRecognitionEnabled),
      walkingTransitionReviewEnabled: walkingReview,
      backgroundTrackingEnabled:
          gpsEnabled &&
          (backgroundTrackingEnabled ?? this.backgroundTrackingEnabled),
      organizationMileageSharingEnabled:
          organizationMileageSharingEnabled ??
          this.organizationMileageSharingEnabled,
      defaultProfile: defaultProfile ?? this.defaultProfile,
      bluetoothVehicleRecognitionEnabled: bluetoothEnabled,
      automaticVehicleSwitchEnabled: bluetoothEnabled && automaticSwitch,
      automaticStartAssistanceEnabled:
          gpsEnabled &&
          (automaticStartAssistanceEnabled ??
              this.automaticStartAssistanceEnabled),
      lowBatteryGpsProtectionEnabled:
          lowBatteryGpsProtectionEnabled ?? this.lowBatteryGpsProtectionEnabled,
      lowBatteryGpsOverrideEnabled:
          gpsEnabled &&
          (lowBatteryGpsOverrideEnabled ?? this.lowBatteryGpsOverrideEnabled),
      lowBatteryGpsWarningDismissed:
          gpsEnabled &&
          (lowBatteryGpsWarningDismissed ?? this.lowBatteryGpsWarningDismissed),
      odometerAnomalyAlertsEnabled: odometerAlerts,
      gpsOdometerCalibrationAssistEnabled:
          odometerAlerts &&
          (gpsOdometerCalibrationAssistEnabled ??
              this.gpsOdometerCalibrationAssistEnabled),
      mapPreviewEnabled:
          gpsEnabled && (mapPreviewEnabled ?? this.mapPreviewEnabled),
      mapRouteHistorySavingEnabled:
          gpsEnabled &&
          (mapPreviewEnabled ?? this.mapPreviewEnabled) &&
          (mapRouteHistorySavingEnabled ?? this.mapRouteHistorySavingEnabled) &&
          _validMapDailyBudgetMb(
                mapRouteHistoryDailyBudgetMb ??
                    this.mapRouteHistoryDailyBudgetMb,
              ) >
              0,
      mapRouteHistoryDailyBudgetMb: _validMapDailyBudgetMb(
        mapRouteHistoryDailyBudgetMb ?? this.mapRouteHistoryDailyBudgetMb,
      ),
      mapRouteHistorySampleIntervalSeconds: _validMapSampleInterval(
        mapRouteHistorySampleIntervalSeconds ??
            this.mapRouteHistorySampleIntervalSeconds,
      ),
      backupNetworkPolicy: backupNetworkPolicy ?? this.backupNetworkPolicy,
    );
  }

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'tripTrackingSetupCompleted': tripTrackingSetupCompleted,
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
    'automaticStartAssistanceEnabled': automaticStartAssistanceEnabled,
    'lowBatteryGpsProtectionEnabled': lowBatteryGpsProtectionEnabled,
    'lowBatteryGpsOverrideEnabled': lowBatteryGpsOverrideEnabled,
    'lowBatteryGpsWarningDismissed': lowBatteryGpsWarningDismissed,
    'odometerAnomalyAlertsEnabled': odometerAnomalyAlertsEnabled,
    'gpsOdometerCalibrationAssistEnabled': gpsOdometerCalibrationAssistEnabled,
    'mapPreviewEnabled': mapPreviewEnabled,
    'mapRouteHistorySavingEnabled': mapRouteHistorySavingEnabled,
    'mapRouteHistoryDailyBudgetMb': _validMapDailyBudgetMb(
      mapRouteHistoryDailyBudgetMb,
    ),
    'mapRouteHistorySampleIntervalSeconds': _validMapSampleInterval(
      mapRouteHistorySampleIntervalSeconds,
    ),
    'backupNetworkPolicy': backupNetworkPolicy.name,
  };

  Map<String, Object?> toSafeDashboardMap() {
    final safe = TripTrackingSettings.fromMap(toMap());
    return {
      'schemaVersion': schemaVersion,
      'tripTrackingSetupCompleted': safe.tripTrackingSetupCompleted,
      'gpsAssistedTrackingEnabled': safe.gpsAssistedTrackingEnabled,
      'samplingPreset': safe.samplingPreset.name,
      'customIntervalSeconds': _validCustomInterval(safe.customIntervalSeconds),
      'adaptiveSamplingEnabled': safe.adaptiveSamplingEnabled,
      'activityRecognitionEnabled': safe.activityRecognitionEnabled,
      'walkingTransitionReviewEnabled': safe.walkingTransitionReviewEnabled,
      'backgroundTrackingEnabled': safe.backgroundTrackingEnabled,
      'organizationMileageSharingEnabled':
          safe.organizationMileageSharingEnabled,
      'defaultProfile': safe.defaultProfile.name,
      'bluetoothVehicleRecognitionEnabled':
          safe.bluetoothVehicleRecognitionEnabled,
      'automaticVehicleSwitchEnabled': safe.automaticVehicleSwitchEnabled,
      'automaticStartAssistanceEnabled': safe.automaticStartAssistanceEnabled,
      'lowBatteryGpsProtectionEnabled': safe.lowBatteryGpsProtectionEnabled,
      'lowBatteryGpsOverrideEnabled': safe.lowBatteryGpsOverrideEnabled,
      'lowBatteryGpsWarningDismissed': safe.lowBatteryGpsWarningDismissed,
      'lowBatteryGpsSafetyCutoffPercent': 15,
      'lowBatteryGpsWarningPercent': 20,
      'lowBatteryGpsChoiceCanBeChanged': true,
      'lowBatteryGpsDefaultAction': 'prompt_or_pause_below_cutoff',
      'odometerAnomalyAlertsEnabled': safe.odometerAnomalyAlertsEnabled,
      'gpsOdometerCalibrationAssistEnabled':
          safe.gpsOdometerCalibrationAssistEnabled,
      'gpsOdometerCalibrationRequiresUserOptIn': true,
      'gpsOdometerCalibrationCanOverwriteConfirmedOdometer': false,
      'odometerIsGlobalTruth': true,
      'calibrationRequiresTrustedGpsWindow': true,
      'poorGpsDaysExcludedFromCalibration': true,
      'settingsCanApplyCalibration': false,
      'settingsCanCreateOfficialMileage': false,
      'settingsCanSetGlobalTruth': false,
      'settingsCanChangeOfficialMileage': false,
      'mapPreviewEnabled': safe.mapPreviewEnabled,
      'mapRouteHistorySavingEnabled': safe.mapRouteHistorySavingEnabled,
      'mapRouteHistoryDailyBudgetMb': _validMapDailyBudgetMb(
        safe.mapRouteHistoryDailyBudgetMb,
      ),
      'mapRouteHistorySampleIntervalSeconds': _validMapSampleInterval(
        safe.mapRouteHistorySampleIntervalSeconds,
      ),
      'backupNetworkPolicy': safe.backupNetworkPolicy.name,
      'requiresGpsConsent': safe.gpsAssistedTrackingEnabled,
      'requiresBackgroundConsent':
          safe.gpsAssistedTrackingEnabled && safe.backgroundTrackingEnabled,
      'requiresMotionConsent':
          safe.gpsAssistedTrackingEnabled && safe.activityRecognitionEnabled,
      'requiresOrganizationSharingConsent':
          safe.organizationMileageSharingEnabled,
      'mapsRequiredForTracking': false,
      'mapsRequireSeparateOptIn': true,
      'mapRouteHistoryRequiresSeparateOptIn': true,
      'gpsTrackingCanRunWithoutMaps': true,
      'freeUserControlsDailyMapStorageBudget': true,
      'odometerRemainsCanonical': true,
      'rawLocationIncluded': false,
      'rawMapRouteIncluded': false,
      'mapboxGeometryIncluded': false,
      'rawSensorPayloadIncluded': false,
      'tokensIncluded': false,
    };
  }

  factory TripTrackingSettings.fromMap(Map<dynamic, dynamic> map) {
    if (_hasUnsupportedSchemaVersion(map)) return const TripTrackingSettings();
    final bluetoothEnabled = map['bluetoothVehicleRecognitionEnabled'] == true;
    final defaultProfile = _profileFromMap(map);
    final hasInvalidDefaultProfile =
        map.containsKey('defaultProfile') && defaultProfile == null;
    final gpsEnabled =
        !hasInvalidDefaultProfile && map['gpsAssistedTrackingEnabled'] == true;
    final walkingReview = map['walkingTransitionReviewEnabled'] != false;
    final odometerAlerts =
        gpsEnabled && map['odometerAnomalyAlertsEnabled'] == true;
    return TripTrackingSettings(
      tripTrackingSetupCompleted: map['tripTrackingSetupCompleted'] == true,
      gpsAssistedTrackingEnabled: gpsEnabled,
      samplingPreset: _presetFromMap(map),
      customIntervalSeconds: _validCustomInterval(
        _safeNumber(map['customIntervalSeconds'])?.round() ?? 15,
      ),
      adaptiveSamplingEnabled: map['adaptiveSamplingEnabled'] == true,
      activityRecognitionEnabled:
          gpsEnabled &&
          walkingReview &&
          map['activityRecognitionEnabled'] == true,
      walkingTransitionReviewEnabled: walkingReview,
      backgroundTrackingEnabled:
          gpsEnabled && map['backgroundTrackingEnabled'] == true,
      organizationMileageSharingEnabled:
          map['organizationMileageSharingEnabled'] == true,
      defaultProfile: defaultProfile ?? TripTrackingProfile.roadVehicle,
      bluetoothVehicleRecognitionEnabled: bluetoothEnabled,
      automaticVehicleSwitchEnabled:
          bluetoothEnabled && map['automaticVehicleSwitchEnabled'] == true,
      automaticStartAssistanceEnabled:
          gpsEnabled && map['automaticStartAssistanceEnabled'] == true,
      lowBatteryGpsProtectionEnabled:
          map['lowBatteryGpsProtectionEnabled'] != false,
      lowBatteryGpsOverrideEnabled:
          gpsEnabled && map['lowBatteryGpsOverrideEnabled'] == true,
      lowBatteryGpsWarningDismissed:
          gpsEnabled && map['lowBatteryGpsWarningDismissed'] == true,
      odometerAnomalyAlertsEnabled: odometerAlerts,
      gpsOdometerCalibrationAssistEnabled:
          odometerAlerts && map['gpsOdometerCalibrationAssistEnabled'] == true,
      mapPreviewEnabled: gpsEnabled && map['mapPreviewEnabled'] == true,
      mapRouteHistorySavingEnabled:
          gpsEnabled &&
          map['mapPreviewEnabled'] == true &&
          map['mapRouteHistorySavingEnabled'] == true &&
          _validMapDailyBudgetMb(
                _safeNumber(map['mapRouteHistoryDailyBudgetMb'])?.toDouble() ??
                    0,
              ) >
              0,
      mapRouteHistoryDailyBudgetMb: _validMapDailyBudgetMb(
        _safeNumber(map['mapRouteHistoryDailyBudgetMb'])?.toDouble() ?? 0,
      ),
      mapRouteHistorySampleIntervalSeconds: _validMapSampleInterval(
        _safeNumber(map['mapRouteHistorySampleIntervalSeconds'])?.round() ?? 30,
      ),
      backupNetworkPolicy: TripTrackingBackupNetworkPolicy.values.firstWhere(
        (value) => value.name == map['backupNetworkPolicy'],
        orElse: () => TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      ),
    );
  }
}

bool _hasUnsupportedSchemaVersion(Map<dynamic, dynamic> map) {
  if (!map.containsKey('schemaVersion')) return false;
  final rawVersion = map['schemaVersion'];
  if (rawVersion is! int) return true;
  return rawVersion < 1 || rawVersion > TripTrackingSettings.schemaVersion;
}

// Android and iOS both support a maximum sixty-second native cadence.
int _validCustomInterval(int seconds) => seconds.clamp(3, 60);

double _validMapDailyBudgetMb(double value) {
  if (!value.isFinite || value <= 0) return 0;
  if (value > 2) return 2;
  return (value * 100).roundToDouble() / 100;
}

int _validMapSampleInterval(int seconds) => seconds.clamp(15, 300);

num? _safeNumber(Object? value) =>
    value is num && value.isFinite ? value : null;

TripTrackingProfile? _profileFromMap(Map<dynamic, dynamic> map) {
  final rawProfile = map['defaultProfile'];
  if (rawProfile is! String) return null;
  for (final profile in TripTrackingProfile.values) {
    if (profile.name == rawProfile) return profile;
  }
  return null;
}

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
      _settings = _normalized(settings ?? const TripTrackingSettings());

  static const boxName = 'gps_trip_tracking_settings';
  static const _settingsKey = 'settings';

  final Box<dynamic>? _box;
  TripTrackingSettings _settings;

  TripTrackingSettings get settings => _settings;

  static TripTrackingSettings _normalized(TripTrackingSettings settings) =>
      TripTrackingSettings.fromMap(settings.toMap());

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
    final normalized = _normalized(settings);
    if (_settings.toMap().toString() == normalized.toMap().toString()) return;
    _settings = normalized;
    await _box?.put(_settingsKey, normalized.toMap());
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
