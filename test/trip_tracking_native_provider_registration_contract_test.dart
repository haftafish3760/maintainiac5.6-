import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';

void main() {
  test(
    'native starting status is accepted without being presented as live',
    () {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'status',
        'status': 'starting',
      });

      expect(event.type, TripTrackingPlatformEventType.status);
      expect(event.status, 'starting');
    },
  );

  test('Android reports tracking only after fused provider registration', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/'
      'TripTrackingForegroundService.kt',
    ).readAsStringSync();
    final registration = source.indexOf('.addOnSuccessListener');
    final liveStatus = source.indexOf('"status" to "tracking"', registration);
    final startingStatus = source.indexOf('"status" to "starting"');

    expect(startingStatus, greaterThanOrEqualTo(0));
    expect(registration, greaterThan(startingStatus));
    expect(liveStatus, greaterThan(registration));
    expect(source, contains('var isStarting = false'));
    expect(source, contains('val isCollectorActive: Boolean'));
  });

  test(
    'iOS waits for a credible Core Location callback before live status',
    () {
      final bridge = File(
        'ios/Runner/TripTrackingNativeBridge.swift',
      ).readAsStringSync();
      final delegate = File(
        'ios/Runner/TripTrackingLocationDelegate.swift',
      ).readAsStringSync();
      final start = bridge.substring(
        bridge.indexOf('private func start('),
        bridge.indexOf('private func update('),
      );

      expect(start, contains('providerRegistered = false'));
      expect(start, contains('"status", "status": "starting"'));
      expect(start, isNot(contains('"status", "status": "tracking"')));
      expect(bridge, contains('func confirmProviderRegistration()'));
      expect(
        bridge,
        contains('tracking ? (providerRegistered ? "tracking" : "starting")'),
      );
      expect(
        delegate,
        contains(
          'guard location.timestamp >= trackingStartedAt else { continue }',
        ),
      );
      expect(delegate, contains('confirmProviderRegistration()'));
    },
  );

  test('Android replaces a sampling update received during registration', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/'
      'TripTrackingForegroundService.kt',
    ).readAsStringSync();

    expect(source, contains('if (samplingUpdate && !isCollectorActive)'));
    expect(
      source,
      contains('isRunning = false\n        stopLocationUpdates()'),
    );
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
      contains(
        '_nativeProviderRegistered = false;\n              _platformStatus',
      ),
    );
  });

  test('recovery probe waits for provider status before live GPS', () {
    final lifecycle = File(
      'lib/shared/trip_tracking/trip_tracking_controller_session_lifecycle.dart',
    ).readAsStringSync();
    final recovery = lifecycle.substring(
      lifecycle.indexOf('} else if (providerRunning) {'),
      lifecycle.indexOf('final sampling = _nativeSampling;'),
    );

    expect(recovery, contains('_nativeProviderRegistered = false;'));
    expect(
      recovery,
      contains("_platformStatus = 'awaiting_provider_registration';"),
    );
    expect(recovery, isNot(contains('_nativeProviderRegistered = true;')));
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
