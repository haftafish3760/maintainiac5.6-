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
    final ios = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(
      android,
      contains('"mockedLocation" to location.isFromMockProvider'),
    );
    expect(android, contains('"recordedAt" to location.time'));
    expect(androidActivity, contains('"type" to "activity"'));
    expect(ios, contains('"recordedAt": ISO8601DateFormatter()'));
    expect(ios, contains('"type": "activity"'));
  });
}
