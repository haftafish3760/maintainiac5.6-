import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';

void main() {
  test('native starting status is accepted without being presented as live', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'status',
      'status': 'starting',
    });

    expect(event.type, TripTrackingPlatformEventType.status);
    expect(event.status, 'starting');
  });

  test('Android reports tracking only after fused provider registration', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/'
      'TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final registration = source.indexOf('.addOnSuccessListener');
    final liveStatus = source.indexOf(
      '"status" to "tracking"',
      registration,
    );
    final startingStatus = source.indexOf('"status" to "starting"');

    expect(startingStatus, greaterThanOrEqualTo(0));
    expect(registration, greaterThan(startingStatus));
    expect(liveStatus, greaterThan(registration));
    expect(source, contains('var isStarting = false'));
    expect(source, contains('val isCollectorActive: Boolean'));
  });

  test('Android replaces a sampling update received during registration', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/'
      'TripTrackingForegroundService.kt',
    ).readAsStringSync();

    expect(source, contains('if (samplingUpdate && !isCollectorActive)'));
    expect(source, contains('isRunning = false\n        stopLocationUpdates()'));
    expect(source, isNot(contains('if (samplingUpdate && !isRunning)')));
  });

  test('Android reconnect reports pending registration truthfully', () {
    final bridge = File(
      'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
    ).readAsStringSync();
    final events = File(
      'lib/shared/trip_tracking/trip_tracking_controller_native_events.dart',
    ).readAsStringSync();

    expect(bridge, contains('TripTrackingForegroundService.isStarting'));
    expect(bridge, contains('-> "starting"'));
    expect(events, contains("status == 'starting'"));
    expect(
      events,
      contains('_nativeProviderRegistered = false;\n              _platformStatus'),
    );
  });

  test('dashboard GPS-live state requires provider registration evidence', () {
    final dashboard = File(
      'lib/screens/dashboard/dashboard.dart',
    ).readAsStringSync();
    final summary = File(
      'lib/screens/dashboard/data/dashboard_trip_tracking_summary.dart',
    ).readAsStringSync();

    expect(dashboard, contains('nativeProviderRegistered == true'));
    expect(summary, contains('nativeProviderRegistered == true'));
  });
}
