import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('odometer anomaly alerts are opt-in and require GPS assistance', () {
    const disabled = TripTrackingSettings();
    final gpsEnabled = disabled.copyWith(gpsAssistedTrackingEnabled: true);
    final enabled = gpsEnabled.copyWith(odometerAnomalyAlertsEnabled: true);
    final gpsDisabledAgain = enabled.copyWith(
      gpsAssistedTrackingEnabled: false,
    );

    expect(disabled.odometerAnomalyAlertsEnabled, isFalse);
    expect(enabled.odometerAnomalyAlertsEnabled, isTrue);
    expect(gpsDisabledAgain.odometerAnomalyAlertsEnabled, isFalse);
  });

  test('odometer anomaly alert setting survives local serialization', () {
    final settings = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      odometerAnomalyAlertsEnabled: true,
    );

    final restored = TripTrackingSettings.fromMap(settings.toMap());

    expect(restored.gpsAssistedTrackingEnabled, isTrue);
    expect(restored.odometerAnomalyAlertsEnabled, isTrue);
  });

  test('restored odometer anomaly alerts fail closed without GPS opt-in', () {
    final restored = TripTrackingSettings.fromMap(const {
      'gpsAssistedTrackingEnabled': false,
      'odometerAnomalyAlertsEnabled': true,
    });

    expect(restored.gpsAssistedTrackingEnabled, isFalse);
    expect(restored.odometerAnomalyAlertsEnabled, isFalse);
  });

  test('odometer calibration assist requires GPS and anomaly review opt-in', () {
    final gpsOnly = const TripTrackingSettings().copyWith(
      gpsAssistedTrackingEnabled: true,
      gpsOdometerCalibrationAssistEnabled: true,
    );
    final enabled = gpsOnly.copyWith(
      odometerAnomalyAlertsEnabled: true,
      gpsOdometerCalibrationAssistEnabled: true,
    );
    final alertsDisabledAgain = enabled.copyWith(
      odometerAnomalyAlertsEnabled: false,
    );

    expect(gpsOnly.gpsOdometerCalibrationAssistEnabled, isFalse);
    expect(enabled.gpsOdometerCalibrationAssistEnabled, isTrue);
    expect(alertsDisabledAgain.gpsOdometerCalibrationAssistEnabled, isFalse);
    expect(
      enabled
          .toSafeDashboardMap()['gpsOdometerCalibrationCanOverwriteConfirmedOdometer'],
      isFalse,
    );
  });

  test('restored calibration assist fails closed without anomaly alerts', () {
    final restored = TripTrackingSettings.fromMap(const {
      'schemaVersion': TripTrackingSettings.schemaVersion,
      'gpsAssistedTrackingEnabled': true,
      'odometerAnomalyAlertsEnabled': false,
      'gpsOdometerCalibrationAssistEnabled': true,
    });

    expect(restored.odometerAnomalyAlertsEnabled, isFalse);
    expect(restored.gpsOdometerCalibrationAssistEnabled, isFalse);
  });
}
