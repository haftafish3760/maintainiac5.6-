import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android permission flow never loops after a denied location request', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    expect(source, contains('private var locationPermissionRequested = false'));
    expect(source, contains('if (locationPermissionRequested) {'));
    expect(source, contains('completeAuthorizationRequest()'));
  });

  test('Android asks for a visible tracking notification without gating GPS', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final service = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(
      source,
      contains('private var notificationPermissionRequested = false'),
    );
    expect(source, contains('Manifest.permission.POST_NOTIFICATIONS'));
    expect(source, contains('hasNotificationPermission()'));
    expect(source, contains('A denial must never silently block mileage'));
    expect(
      service,
      contains(
        'getBooleanExtra(activityRecognitionEnabledExtra, false) == true',
      ),
    );
    expect(
      source,
      isNot(
        contains(
          'notificationPermissionRequested = false\n        pendingAuthorizationResult',
        ),
      ),
    );
  });

  test(
    'iOS escalates location authorization only after foreground approval',
    () {
      final source = File(
        'ios/Runner/TripTrackingNativeBridge.swift',
      ).readAsStringSync();
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(source, contains('state == "whileInUse" && allowBackground'));
      expect(
        source,
        contains('locationManager.requestWhenInUseAuthorization()'),
      );
      expect(source, contains('locationManager.requestAlwaysAuthorization()'));
      expect(
        source,
        contains('arguments?["activityRecognitionEnabled"] as? Bool ?? false'),
      );
      expect(plist, contains('NSMotionUsageDescription'));
    },
  );

  test('native bridges preserve the evidence needed for safe GPS filtering', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final androidActivity = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingActivityReceiver.kt',
    ).readAsStringSync();
    final androidBridge = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      android,
      contains('"mockedLocation" to location.isFromMockProvider'),
    );
    expect(android, contains('"recordedAt" to location.time'));
    expect(android, contains('trip_tracking_foreground_service_denied'));
    expect(androidBridge, contains('catch (error: IllegalStateException)'));
    expect(android, contains('trip_tracking_location_registration_failed'));
    expect(android, contains('trip_tracking_activity_unavailable'));
    expect(androidActivity, contains('"type" to "activity"'));
    expect(ios, contains('"recordedAt": ISO8601DateFormatter()'));
    expect(ios, contains('"type": "activity"'));
    expect(ios, contains('"mockedLocation": simulated'));
    expect(ios, contains('isSimulatedBySoftware'));
  });

  test('native capabilities expose battery and low-power availability', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(android, contains('Context.BATTERY_SERVICE'));
    expect(android, contains('Context.POWER_SERVICE'));
    expect(android, contains('"batteryStateAvailable"'));
    expect(android, contains('"lowPowerModeAvailable"'));
    expect(ios, contains('UIDevice.current.isBatteryMonitoringEnabled = true'));
    expect(ios, contains('"batteryStateAvailable"'));
    expect(ios, contains('"lowPowerModeAvailable"'));
  });

  test('native bridges expose validated battery snapshots for GPS safety', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(android, contains('"readBatterySnapshot"'));
    expect(android, contains('BATTERY_PROPERTY_CAPACITY'));
    expect(android, contains('Intent.ACTION_BATTERY_CHANGED'));
    expect(android, contains('"batteryPercent"'));
    expect(android, contains('"isCharging"'));
    expect(android, contains('"lowPowerModeEnabled"'));
    expect(ios, contains('case "readBatterySnapshot"'));
    expect(ios, contains('UIDevice.current.batteryLevel'));
    expect(ios, contains('ProcessInfo.processInfo.isLowPowerModeEnabled'));
    expect(ios, contains('"batteryPercent"'));
    expect(ios, contains('"isCharging"'));
    expect(ios, contains('"lowPowerModeEnabled"'));
  });

  test(
    'iOS applies the requested sampling tier instead of hardcoding GPS best',
    () {
      final ios = File(
        'ios/Runner/TripTrackingNativeBridge.swift',
      ).readAsStringSync();

      expect(ios, contains('intervalMillis'));
      expect(ios, contains('applySampling(intervalMillis: intervalMillis'));
      expect(ios, contains('kCLLocationAccuracyBestForNavigation'));
      expect(ios, contains('kCLLocationAccuracyNearestTenMeters'));
      expect(ios, contains('kCLLocationAccuracyHundredMeters'));
      expect(
        ios,
        isNot(
          contains(
            'locationManager.desiredAccuracy = kCLLocationAccuracyBest\n',
          ),
        ),
      );
    },
  );

  test('native collectors emit revocation errors and release resources', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(android, contains('trip_tracking_location_denied'));
    expect(android, contains('trip_tracking_gps_disabled'));
    expect(
      android,
      contains(RegExp(r'trip_tracking_gps_disabled[\s\S]{0,500}stopSelf\(\)')),
    );
    expect(android, contains('override fun onDestroy()'));
    expect(android, contains('locationManager.removeUpdates(this)'));
    expect(android, contains('removeActivityUpdates(activityPendingIntent)'));
    expect(android, contains('"status" to "stopped"'));
    expect(ios, contains('func locationManagerDidChangeAuthorization'));
    expect(
      ios,
      contains('if tracking && (state == "denied" || state == "restricted")'),
    );
    expect(ios, contains('"errorCode": "trip_tracking_location_denied"'));
    expect(ios, contains('trip_tracking_location_error'));
    expect(ios, contains('locationError.code == .denied'));
    expect(ios, contains('locationManager.stopUpdatingLocation()'));
  });

  test(
    'Android tracking notification gives the driver a direct stop control',
    () {
      final android = File(
        'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
      ).readAsStringSync();

      expect(android, contains('private const val stopAction'));
      expect(android, contains('intent?.action == stopAction'));
      expect(android, contains('"Stop trip tracking"'));
      expect(android, contains('PendingIntent.getService'));
    },
  );

  test('Android native sampling updates never request zero displacement', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();

    expect(android, contains('coerceIn(1f, 100f)'));
    expect(android, isNot(contains('coerceIn(0f, 100f)')));
  });

  test('iOS native sampling never requests zero displacement', () {
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      ios,
      contains(
        'locationManager.distanceFilter = min(max(1, displacement), 100)',
      ),
    );
    expect(
      ios,
      isNot(contains('locationManager.distanceFilter = max(0, displacement)')),
    );
  });
}
