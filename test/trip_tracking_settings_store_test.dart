import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'GPS tracking stays opt-in with adaptive battery behavior by default',
    () {
      const settings = TripTrackingSettings();

      expect(settings.gpsAssistedTrackingEnabled, isFalse);
      expect(
        settings.samplingPreset,
        TripTrackingSamplingPreset.enhancedAccuracy,
      );
      expect(settings.backgroundTrackingEnabled, isFalse);
      expect(settings.organizationMileageSharingEnabled, isFalse);
      expect(settings.defaultProfile, TripTrackingProfile.roadVehicle);
      expect(settings.bluetoothVehicleRecognitionEnabled, isFalse);
      expect(settings.automaticVehicleSwitchEnabled, isFalse);
      expect(settings.adaptiveSamplingEnabled, isFalse);
      expect(settings.activityRecognitionEnabled, isFalse);
      expect(settings.lowBatteryGpsProtectionEnabled, isTrue);
      expect(settings.lowBatteryGpsOverrideEnabled, isFalse);
      expect(settings.lowBatteryGpsWarningDismissed, isFalse);
      expect(
        settings.backupNetworkPolicy,
        TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      );
    },
  );

  test(
    'automatic vehicle switching cannot be enabled without Bluetooth consent',
    () {
      const settings = TripTrackingSettings();

      final withoutBluetooth = settings.copyWith(
        automaticVehicleSwitchEnabled: true,
      );
      final withBluetooth = settings.copyWith(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      );

      expect(withoutBluetooth.automaticVehicleSwitchEnabled, isFalse);
      expect(withBluetooth.automaticVehicleSwitchEnabled, isTrue);
    },
  );

  test(
    'local settings controller updates preferences without a cloud dependency',
    () async {
      final controller = TripTrackingSettingsController.memory();

      await controller.update(
        controller.settings.copyWith(
          gpsAssistedTrackingEnabled: true,
          samplingPreset: TripTrackingSamplingPreset.highAccuracy,
        ),
      );

      expect(controller.settings.gpsAssistedTrackingEnabled, isTrue);
      expect(
        controller.settings.samplingPreset,
        TripTrackingSamplingPreset.highAccuracy,
      );
    },
  );

  test(
    'settings controller normalizes unsafe local values before use',
    () async {
      final controller = TripTrackingSettingsController.memory();

      await controller.update(
        const TripTrackingSettings(
          samplingPreset: TripTrackingSamplingPreset.custom,
          customIntervalSeconds: -10,
        ),
      );

      expect(
        controller.settings.samplingPreset,
        TripTrackingSamplingPreset.custom,
      );
      expect(controller.settings.customIntervalSeconds, 3);
    },
  );

  test(
    'driver profile choices persist for onboarding and dashboard defaults',
    () {
      for (final profile in TripTrackingProfile.values) {
        final settings = TripTrackingSettings(defaultProfile: profile);

        expect(
          TripTrackingSettings.fromMap(settings.toMap()).defaultProfile,
          profile,
          reason: profile.name,
        );
      }
    },
  );

  test('corrupted default profile disables GPS assisted tracking', () {
    final restored = TripTrackingSettings.fromMap(const {
      'gpsAssistedTrackingEnabled': true,
      'defaultProfile': 'silentTracker',
    });

    expect(restored.defaultProfile, TripTrackingProfile.roadVehicle);
    expect(restored.gpsAssistedTrackingEnabled, isFalse);
  });

  test('organization mileage sharing is a separately persisted opt-in', () {
    const settings = TripTrackingSettings();
    final enabled = settings.copyWith(organizationMileageSharingEnabled: true);

    expect(enabled.organizationMileageSharingEnabled, isTrue);
    expect(
      TripTrackingSettings.fromMap(
        enabled.toMap(),
      ).organizationMileageSharingEnabled,
      isTrue,
    );
  });

  test('trip backup network preference is persisted separately', () {
    for (final policy in TripTrackingBackupNetworkPolicy.values) {
      final settings = const TripTrackingSettings().copyWith(
        backupNetworkPolicy: policy,
      );

      expect(
        TripTrackingSettings.fromMap(settings.toMap()).backupNetworkPolicy,
        policy,
        reason: policy.name,
      );
    }

    expect(
      TripTrackingSettings.fromMap(const {
        'backupNetworkPolicy': 'satelliteOnly',
      }).backupNetworkPolicy,
      TripTrackingBackupNetworkPolicy.wifiAndMobileData,
    );
  });

  test('trip backup network policy evaluates wifi and mobile availability', () {
    expect(
      TripTrackingBackupNetworkPolicy.wifiOnly.allows(
        wifiAvailable: true,
        mobileDataAvailable: false,
      ),
      isTrue,
    );
    expect(
      TripTrackingBackupNetworkPolicy.wifiOnly.allows(
        wifiAvailable: false,
        mobileDataAvailable: true,
      ),
      isFalse,
    );
    expect(
      TripTrackingBackupNetworkPolicy.wifiAndMobileData.allows(
        wifiAvailable: false,
        mobileDataAvailable: true,
      ),
      isTrue,
    );
    expect(
      TripTrackingBackupNetworkPolicy.mobileDataOnly.allows(
        wifiAvailable: true,
        mobileDataAvailable: false,
      ),
      isFalse,
    );
  });

  test('sampling presets persist and bound a custom interval', () {
    const custom = TripTrackingSettings(
      samplingPreset: TripTrackingSamplingPreset.custom,
      customIntervalSeconds: 15,
    );

    final restored = TripTrackingSettings.fromMap({
      ...custom.toMap(),
      'customIntervalSeconds': 1,
    });

    expect(restored.samplingPreset, TripTrackingSamplingPreset.custom);
    expect(restored.customIntervalSeconds, 3);
    expect(
      const TripTrackingSettings(
        samplingPreset: TripTrackingSamplingPreset.custom,
        customIntervalSeconds: -10,
      ).toMap()['customIntervalSeconds'],
      3,
    );
    expect(
      TripTrackingSettings.fromMap({
        ...custom.toMap(),
        'customIntervalSeconds': 'fast',
      }).customIntervalSeconds,
      15,
    );
    expect(
      TripTrackingSettings.fromMap({'batteryMode': 'saver'}).samplingPreset,
      TripTrackingSamplingPreset.batterySaver,
    );
  });

  test('malformed sampling preset falls back to enhanced accuracy', () {
    expect(
      TripTrackingSettings.fromMap(const {
        'samplingPreset': 'rocket',
        'customIntervalSeconds': 30,
      }).samplingPreset,
      TripTrackingSamplingPreset.enhancedAccuracy,
    );
    expect(
      TripTrackingSettings.fromMap(const {'samplingPreset': 1}).samplingPreset,
      TripTrackingSamplingPreset.enhancedAccuracy,
    );
    expect(
      TripTrackingSettings.fromMap(const {
        'samplingPreset': 'custom',
        'customIntervalSeconds': 30,
      }).samplingPreset,
      TripTrackingSamplingPreset.custom,
    );
  });

  test('motion activity recognition is a separately persisted opt-in', () {
    const settings = TripTrackingSettings();
    final enabled = settings.copyWith(
      gpsAssistedTrackingEnabled: true,
      activityRecognitionEnabled: true,
    );

    expect(enabled.activityRecognitionEnabled, isTrue);
    expect(
      TripTrackingSettings.fromMap(enabled.toMap()).activityRecognitionEnabled,
      isTrue,
    );
    expect(
      TripTrackingSettings.fromMap(const {}).activityRecognitionEnabled,
      isFalse,
    );
  });

  test('motion and background helpers require GPS tracking opt-in', () {
    final restored = TripTrackingSettings.fromMap(const {
      'gpsAssistedTrackingEnabled': false,
      'activityRecognitionEnabled': true,
      'backgroundTrackingEnabled': true,
    });
    final disabled = const TripTrackingSettings(
      gpsAssistedTrackingEnabled: true,
      activityRecognitionEnabled: true,
      backgroundTrackingEnabled: true,
    ).copyWith(gpsAssistedTrackingEnabled: false);

    expect(restored.activityRecognitionEnabled, isFalse);
    expect(restored.backgroundTrackingEnabled, isFalse);
    expect(disabled.activityRecognitionEnabled, isFalse);
    expect(disabled.backgroundTrackingEnabled, isFalse);
  });

  test('low battery GPS protection is persisted and reversible', () {
    const settings = TripTrackingSettings(gpsAssistedTrackingEnabled: true);
    final bypassed = settings.copyWith(
      lowBatteryGpsOverrideEnabled: true,
      lowBatteryGpsWarningDismissed: true,
    );
    final reset = bypassed.copyWith(
      lowBatteryGpsOverrideEnabled: false,
      lowBatteryGpsWarningDismissed: false,
    );

    expect(
      TripTrackingSettings.fromMap(
        bypassed.toMap(),
      ).lowBatteryGpsOverrideEnabled,
      isTrue,
    );
    expect(
      TripTrackingSettings.fromMap(
        bypassed.toMap(),
      ).lowBatteryGpsWarningDismissed,
      isTrue,
    );
    expect(reset.lowBatteryGpsOverrideEnabled, isFalse);
    expect(reset.lowBatteryGpsWarningDismissed, isFalse);
  });

  test('GPS opt-out clears saved low battery bypass state', () {
    final disabled = const TripTrackingSettings(
      gpsAssistedTrackingEnabled: true,
      lowBatteryGpsOverrideEnabled: true,
      lowBatteryGpsWarningDismissed: true,
    ).copyWith(gpsAssistedTrackingEnabled: false);
    final restored = TripTrackingSettings.fromMap(const {
      'gpsAssistedTrackingEnabled': false,
      'lowBatteryGpsOverrideEnabled': true,
      'lowBatteryGpsWarningDismissed': true,
    });

    expect(disabled.gpsAssistedTrackingEnabled, isFalse);
    expect(disabled.lowBatteryGpsOverrideEnabled, isFalse);
    expect(disabled.lowBatteryGpsWarningDismissed, isFalse);
    expect(restored.lowBatteryGpsOverrideEnabled, isFalse);
    expect(restored.lowBatteryGpsWarningDismissed, isFalse);
  });

  test('low battery GPS decision requires explicit user choice by default', () {
    const policy = TripTrackingPolicy();
    const settings = TripTrackingSettings();

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(decision.allowsGps, isFalse);
    expect(decision.reasonCode, 'low_battery_requires_user_choice');
  });

  test('malformed low battery GPS cutoff uses the safe default', () {
    const policy = TripTrackingPolicy(lowBatteryGpsCutoffPercent: -1);

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(decision.reasonCode, 'low_battery_requires_user_choice');
  });

  test('low battery override allows GPS only after user opt-in', () {
    const policy = TripTrackingPolicy();
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      lowBatteryGpsOverrideEnabled: true,
      lowBatteryGpsWarningDismissed: true,
    );

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 5,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.allowed);
    expect(decision.reasonCode, 'user_override_low_battery');
  });

  test('low power mode asks before GPS unless the user overrides it', () {
    const policy = TripTrackingPolicy();
    const settings = TripTrackingSettings();

    final prompt = policy.gpsBatteryDecision(
      batteryPercent: 80,
      isCharging: false,
      lowPowerModeEnabled: true,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );
    final override = policy.gpsBatteryDecision(
      batteryPercent: 80,
      isCharging: false,
      lowPowerModeEnabled: true,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: true,
      lowBatteryWarningDismissed: false,
    );

    expect(prompt.status, TripGpsBatteryDecisionStatus.userPromptRequired);
    expect(prompt.reasonCode, 'low_power_mode_requires_user_choice');
    expect(override.status, TripGpsBatteryDecisionStatus.allowed);
    expect(override.reasonCode, 'user_override_low_power_mode');
  });

  test('cancel and do-not-show-again keeps low battery GPS blocked', () {
    const policy = TripTrackingPolicy();
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      lowBatteryGpsOverrideEnabled: false,
      lowBatteryGpsWarningDismissed: true,
    );

    final decision = policy.gpsBatteryDecision(
      batteryPercent: 19,
      isCharging: false,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
    );

    expect(decision.status, TripGpsBatteryDecisionStatus.blocked);
    expect(decision.reasonCode, 'low_battery_gps_blocked_by_saved_choice');
  });

  test('charging device or unknown battery reading does not block GPS', () {
    const policy = TripTrackingPolicy();

    final charging = policy.gpsBatteryDecision(
      batteryPercent: 1,
      isCharging: true,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );
    final unknown = policy.gpsBatteryDecision(
      batteryPercent: null,
      isCharging: false,
      lowBatteryProtectionEnabled: true,
      lowBatteryOverrideEnabled: false,
      lowBatteryWarningDismissed: false,
    );

    expect(charging.status, TripGpsBatteryDecisionStatus.allowed);
    expect(charging.reasonCode, 'device_charging');
    expect(unknown.status, TripGpsBatteryDecisionStatus.allowed);
    expect(unknown.reasonCode, 'battery_unknown');
  });
}
