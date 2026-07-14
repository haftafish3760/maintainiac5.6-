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
      expect(settings.defaultProfile, TripTrackingProfile.roadVehicle);
      expect(settings.bluetoothVehicleRecognitionEnabled, isFalse);
      expect(settings.automaticVehicleSwitchEnabled, isFalse);
      expect(settings.adaptiveSamplingEnabled, isFalse);
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
      TripTrackingSettings.fromMap({'batteryMode': 'saver'}).samplingPreset,
      TripTrackingSamplingPreset.batterySaver,
    );
  });
}
