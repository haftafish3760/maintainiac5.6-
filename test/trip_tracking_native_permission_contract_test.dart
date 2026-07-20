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

  test('iOS escalates location authorization only after foreground approval', () {
    final source = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(source, contains('state == "whileInUse" && allowBackground'));
    expect(source, contains('locationManager.requestWhenInUseAuthorization()'));
    expect(source, contains('locationManager.requestAlwaysAuthorization()'));
    expect(
      source,
      contains(
        'locationManager.allowsBackgroundLocationUpdates = allowBackground && state == "always"',
      ),
    );
    expect(
      source,
      contains(
        'locationManager.showsBackgroundLocationIndicator = allowBackground && state == "always"',
      ),
    );
    expect(
      source,
      contains(
        'let allowBackground = arguments?["allowBackground"] as? Bool ?? false',
      ),
    );
    expect(
      source,
      contains(
        'Background location permission is required for this tracking mode.',
      ),
    );
    expect(
      source,
      contains('arguments?["activityRecognitionEnabled"] as? Bool ?? false'),
    );
    expect(plist, contains('NSLocationWhenInUseUsageDescription'));
    expect(plist, contains('NSLocationAlwaysAndWhenInUseUsageDescription'));
    expect(plist, contains('NSMotionUsageDescription'));
    expect(plist, contains('<key>UIBackgroundModes</key>'));
    expect(plist, contains('<string>location</string>'));
    expect(source, contains('activityRecognitionIsEligible()'));
    expect(source, contains('status != .denied && status != .restricted'));
    expect(source, contains('activityRecognitionUnavailableReported'));
    expect(source, contains('trip_tracking_activity_unavailable'));
    expect(
      source,
      contains(
        'self.activityRecognitionEnabled && !self.activityRecognitionIsEligible()',
      ),
    );
    expect(
      source,
      contains('CLLocationCoordinate2DIsValid(location.coordinate)'),
    );
    expect(source, contains('location.coordinate.latitude.isFinite'));
    expect(source, contains('location.coordinate.longitude.isFinite'));
    expect(source, contains('location.horizontalAccuracy.isFinite'));
    expect(source, contains('location.timestamp.timeIntervalSince1970 > 0'));
    expect(source, contains('location.speedAccuracy <= 1000'));
    expect(source, contains('"bearingDegrees": reportedBearing ?? NSNull()'));
  });

  test('Android declares only the permissions and service type GPS needs', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(manifest, contains('android.permission.ACCESS_BACKGROUND_LOCATION'));
    expect(manifest, contains('android.permission.FOREGROUND_SERVICE'));
    expect(
      manifest,
      contains('android.permission.FOREGROUND_SERVICE_LOCATION'),
    );
    expect(manifest, contains('android.permission.ACTIVITY_RECOGNITION'));
    expect(manifest, contains('android:foregroundServiceType="location"'));
  });

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
    expect(android, contains('location.hasSpeedAccuracy()'));
    expect(
      ios,
      contains('"speedAccuracyMetersPerSecond": reportedSpeedAccuracy'),
    );
    expect(android, contains('trip_tracking_foreground_service_denied'));
    expect(androidBridge, contains('catch (error: IllegalStateException)'));
    expect(android, contains('trip_tracking_location_registration_failed'));
    expect(android, contains('coerceIn(1f, 100f)'));
    expect(
      android,
      contains('LocationServices.getFusedLocationProviderClient(this)'),
    );
    expect(android, contains('Priority.PRIORITY_HIGH_ACCURACY'));
    expect(android, contains('setMinUpdateDistanceMeters(displacement)'));
    expect(android, contains('stopLocationUpdates()'));
    expect(
      android,
      contains('if (!isRunning || locationCallback !== this) return'),
    );
    expect(android, contains('locationCallback !== callback'));
    expect(android, contains('stopSelf(startId)'));
    expect(android, contains('return START_REDELIVER_INTENT'));
    expect(android, contains('fun retireForExplicitStop()'));
    expect(
      androidBridge,
      contains('TripTrackingForegroundService.retireForExplicitStop()'),
    );
    expect(android, contains('trip_tracking_activity_unavailable'));
    expect(android, contains('stopActivityRecognitionIfPermissionRevoked()'));
    expect(android, contains('reportActivityRecognitionUnavailable'));
    expect(android, contains('activityRecognitionUnavailableReported = false'));
    expect(
      android,
      contains(
        'Activity recognition permission is unavailable; GPS tracking continues without walking-assisted stop evidence.',
      ),
    );
    expect(android, contains('private var trackingStartedAtMillis: Long?'));
    expect(android, contains('trackingStartedAtMillis = System.currentTimeMillis()'));
    expect(android, contains('val startedAtMillis = trackingStartedAtMillis ?: return'));
    expect(android, contains('location.time < startedAtMillis'));
    expect(android, contains('!accuracyMeters.isFinite()'));
    expect(android, contains('!reportedSpeed.isFinite()'));
    expect(
      android,
      contains('"monotonicElapsedNanos" to location.elapsedRealtimeNanos'),
    );
    expect(
      android,
      contains('activityPendingIntent == null || hasActivityRecognition()'),
    );
    expect(androidActivity, contains('"type" to "activity"'));
    expect(
      androidActivity,
      contains('TripTrackingForegroundService.isActivityEpochActive(epoch)'),
    );
    expect(android, contains('const val activityEpochExtra = "activityEpoch"'));
    expect(
      android,
      contains('private var activeActivityEpoch: String? = null'),
    );
    expect(
      android,
      contains('Intent(this, TripTrackingActivityReceiver::class.java)'),
    );
    expect(
      android,
      contains(
        r'.setData(Uri.parse("maintainiac://trip_tracking/activity/$epoch"))',
      ),
    );
    expect(android, contains('.putExtra(activityEpochExtra, epoch)'));
    expect(android, contains('val requestEpoch = activityEpoch'));
    expect(android, contains('!isActivityEpochActive(requestEpoch)'));
    expect(androidActivity, contains('val observedAtMillis = result.time'));
    expect(
      androidActivity,
      contains('observedAtMillis > System.currentTimeMillis() + 120_000L'),
    );
    expect(androidActivity, contains('"recordedAt" to observedAtMillis'));
    expect(ios, contains('let observedAt = motion.startDate'));
    expect(ios, contains('observedAt <= Date().addingTimeInterval(120)'));
    expect(
      ios,
      contains('"recordedAt": ISO8601DateFormatter().string(from: observedAt)'),
    );
    expect(ios, contains('"type": "activity"'));
    expect(ios, contains('"mockedLocation": simulated'));
    expect(ios, contains('isSimulatedBySoftware'));
    expect(
      ios.indexOf(
        'tracking = true\n    locationManager.startUpdatingLocation()',
      ),
      greaterThanOrEqualTo(0),
    );
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

  test('iOS background trip tracking keeps its declared capability contract', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final bridge = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(info, contains('NSLocationAlwaysAndWhenInUseUsageDescription'));
    expect(info, contains('UIBackgroundModes'));
    expect(info, contains('<string>location</string>'));
    expect(
      bridge,
      contains(
        'locationManager.allowsBackgroundLocationUpdates = allowBackground && state == "always"',
      ),
    );
    expect(
      bridge,
      contains(
        'locationManager.showsBackgroundLocationIndicator = allowBackground && state == "always"',
      ),
    );
  });

  test('native collectors emit revocation errors and release resources', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final androidBridge = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(android, contains('trip_tracking_location_denied'));
    expect(android, contains('trip_tracking_gps_disabled'));
    expect(ios, contains('trip_tracking_gps_unavailable'));
    expect(ios, contains('stopForLocationServicesDisabledIfNeeded'));
    expect(ios, contains('trip_tracking_gps_disabled'));
    expect(
      android,
      contains('if (stopForLocationPermissionRevokedIfNeeded()) return'),
    );
    expect(
      android,
      contains(
        'private fun stopForLocationPermissionRevokedIfNeeded(): Boolean',
      ),
    );
    expect(
      androidBridge,
      contains('"locationAvailable" to locationServicesEnabled(manager)'),
    );
    expect(androidBridge, contains('manager.isLocationEnabled'));
    expect(
      android,
      contains(RegExp(r'trip_tracking_gps_disabled[\s\S]{0,500}stopSelf\(\)')),
    );
    expect(android, contains('override fun onDestroy()'));
    expect(android, contains('fusedLocationClient.removeLocationUpdates(it)'));
    expect(android, contains('removeActivityUpdates(pendingIntent)'));
    expect(
      android.indexOf('retireForExplicitStop()\n        stopHeartbeat()'),
      greaterThanOrEqualTo(0),
    );
    expect(
      android,
      contains('"status" to if (userPauseRequested) "paused" else "stopped"'),
    );
    expect(ios, contains('func locationManagerDidChangeAuthorization'));
    expect(
      ios,
      contains('tracking && stopForLocationServicesDisabledIfNeeded()'),
    );
    expect(ios, contains('let hasPreciseLocation'));
    expect(ios, contains('let canKeepBackgroundTracking'));
    expect(ios, contains('trip_tracking_background_location_denied'));
    expect(ios, contains('trip_tracking_location_accuracy_reduced'));
    expect(ios, contains('trip_tracking_location_error'));
    expect(ios, contains('locationError.code == .denied'));
    expect(ios, contains('locationError.code == .locationUnknown'));
    expect(
      ios,
      contains(
        RegExp(
          r'func locationManager\(_ manager: CLLocationManager, didFailWithError error: Error\) \{[\s\S]{0,400}guard tracking else \{ return \}',
        ),
      ),
    );
    expect(
      ios,
      contains(
        'stopNativeCollection()\n    emit([\n      "type": "error",\n      "errorCode": "trip_tracking_location_error"',
      ),
    );
    expect(ios, contains('private func stopNativeCollection()'));
    expect(ios, contains('locationManager.stopUpdatingLocation()'));
    expect(
      ios.indexOf(
        'tracking = false\n    trackingStartedAt = nil\n    stopHeartbeat()',
      ),
      greaterThanOrEqualTo(0),
    );
    expect(ios, contains('private var trackingStartedAt: Date?'));
    expect(
      ios.indexOf('trackingStartedAt = Date()\n    tracking = true'),
      greaterThanOrEqualTo(0),
    );
    expect(
      ios,
      contains(
        RegExp(
          r'func locationManager\(_ manager: CLLocationManager, didUpdateLocations locations: \[CLLocation\]\) \{[\s\S]{0,500}guard tracking, let trackingStartedAt else \{ return \}[\s\S]{0,500}guard location.timestamp >= trackingStartedAt else \{ continue \}',
        ),
      ),
    );
  });

  test('iOS refuses reduced-accuracy GPS before an active session starts', () {
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      ios,
      contains('guard authorization["preciseLocation"] as? Bool == true else'),
    );
    expect(
      ios,
      contains(
        'Precise location permission is required before starting trip tracking.',
      ),
    );
  });

  test('motion collection stops when optional activity assistance is disabled', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      android,
      contains(
        'ActivityRecognition.getClient(this).removeActivityUpdates(pendingIntent)',
      ),
    );
    expect(android, contains('retireActivityRecognitionEpoch()'));
    expect(android, contains('if (!isRunning || !location.hasAccuracy()'));
    expect(ios, contains('private var activityRecognitionEnabled = false'));
    expect(ios, contains('private var activityRecognitionGeneration = 0'));
    expect(ios, contains('private func setActivityRecognitionEnabled'));
    expect(ios, contains('setActivityRecognitionEnabled(activityEnabled)'));
    expect(ios, contains('self.activityRecognitionEnabled,'));
    expect(ios, contains('self.activityRecognitionGeneration == generation'));
    expect(ios, contains('motionManager.stopActivityUpdates()'));
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
    expect(android, contains('trip_tracking_sampling_update_failed'));
    expect(
      android,
      contains('Android could not apply the GPS sampling update'),
    );
  });

  test('native collectors emit coordinate-free liveness heartbeats', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      android,
      contains('private const val heartbeatIntervalMillis = 60_000L'),
    );
    expect(
      android,
      contains('private val heartbeatRunnable = object : Runnable'),
    );
    expect(
      android,
      contains('heartbeatHandler.postDelayed(this, heartbeatIntervalMillis)'),
    );
    expect(android, contains('private fun startHeartbeat()'));
    expect(android, contains('private fun stopHeartbeat()'));
    expect(ios, contains('private var heartbeatTimer: Timer?'));
    expect(
      ios,
      contains('Timer.scheduledTimer(withTimeInterval: 60, repeats: true)'),
    );
    expect(ios, contains('private func startHeartbeat()'));
    expect(ios, contains('private func stopHeartbeat()'));
    expect(ios, contains('deinit {'));
    expect(ios, contains('No coordinates, sensor evidence, stops, or mileage'));
  });

  test(
    'native collectors enforce the critical battery cutoff while Dart sleeps',
    () {
      final android = File(
        'android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt',
      ).readAsStringSync();
      final ios = File(
        'ios/Runner/TripTrackingNativeBridge.swift',
      ).readAsStringSync();

      expect(android, contains('private fun stopForCriticalBatteryIfNeeded()'));
      expect(android, contains('private fun isBatteryCriticallyLow()'));
      expect(android, contains('Intent.ACTION_BATTERY_CHANGED'));
      expect(android, contains('level * 100 / scale < 10'));
      expect(android, contains('"trip_tracking_battery_critical"'));
      expect(android, contains('if (stopForCriticalBatteryIfNeeded()) return'));
      expect(
        ios,
        contains('private func stopForCriticalBatteryIfNeeded() -> Bool'),
      );
      expect(ios, contains('percent < 10'));
      expect(ios, contains('"trip_tracking_battery_critical"'));
      expect(
        ios,
        contains('if self.stopForCriticalBatteryIfNeeded() { return }'),
      );
    },
  );

  test('native start rejects background collection without native permission', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();

    expect(
      android,
      contains(
        'val allowBackground = call.argument<Boolean>("allowBackground") == true',
      ),
    );
    expect(
      android,
      contains('if (allowBackground && !hasBackgroundLocation())'),
    );
    expect(
      android,
      contains(
        'Background location permission is required for this tracking mode.',
      ),
    );
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
