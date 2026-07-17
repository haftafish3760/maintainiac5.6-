import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
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
    'memory settings controller normalizes injected settings before use',
    () {
      final controller = TripTrackingSettingsController.memory(
        const TripTrackingSettings(
          lowBatteryGpsOverrideEnabled: true,
          lowBatteryGpsWarningDismissed: true,
        ),
      );

      expect(controller.settings.gpsAssistedTrackingEnabled, isFalse);
      expect(controller.settings.lowBatteryGpsOverrideEnabled, isFalse);
      expect(controller.settings.lowBatteryGpsWarningDismissed, isFalse);
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

  test('unsupported settings schema version fails closed', () {
    final restored = TripTrackingSettings.fromMap(const {
      'schemaVersion': 99,
      'gpsAssistedTrackingEnabled': true,
      'backgroundTrackingEnabled': true,
      'activityRecognitionEnabled': true,
      'organizationMileageSharingEnabled': true,
      'lowBatteryGpsOverrideEnabled': true,
      'lowBatteryGpsWarningDismissed': true,
      'bluetoothVehicleRecognitionEnabled': true,
      'automaticVehicleSwitchEnabled': true,
      'backupNetworkPolicy': 'mobileDataOnly',
    });
    final malformed = TripTrackingSettings.fromMap(const {
      'schemaVersion': '1',
      'gpsAssistedTrackingEnabled': true,
    });

    expect(
      restored.toMap()['schemaVersion'],
      TripTrackingSettings.schemaVersion,
    );
    expect(restored.gpsAssistedTrackingEnabled, isFalse);
    expect(restored.backgroundTrackingEnabled, isFalse);
    expect(restored.activityRecognitionEnabled, isFalse);
    expect(restored.organizationMileageSharingEnabled, isFalse);
    expect(restored.lowBatteryGpsOverrideEnabled, isFalse);
    expect(restored.lowBatteryGpsWarningDismissed, isFalse);
    expect(restored.bluetoothVehicleRecognitionEnabled, isFalse);
    expect(restored.automaticVehicleSwitchEnabled, isFalse);
    expect(
      restored.backupNetworkPolicy,
      TripTrackingBackupNetworkPolicy.wifiAndMobileData,
    );
    expect(malformed.gpsAssistedTrackingEnabled, isFalse);
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
}
