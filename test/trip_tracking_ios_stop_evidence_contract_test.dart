// iOS stop-evidence bridge contracts for GPS-assisted trip tracking.
//
// Owns static parity checks for Core Location and Core Motion payloads. It
// does not emulate Apple hardware, approve a proposal, or create a TripLog
// record; shared native-callback replays cover the Dart evidence engine.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final bridge = File(
    'ios/Runner/TripTrackingNativeBridge.swift',
  ).readAsStringSync();
  final delegate = File(
    'ios/Runner/TripTrackingLocationDelegate.swift',
  ).readAsStringSync();

  test('iOS active tracking wires opted-in motion evidence beside GPS', () {
    final start = bridge.substring(
      bridge.indexOf('private func start('),
      bridge.indexOf('private func startAutomaticEvidence('),
    );

    expect(start, contains('setActivityRecognitionEnabled(activityEnabled)'));
    expect(start, contains('locationManager.startUpdatingLocation()'));
    expect(start, contains('"status", "status": "starting"'));
  });

  test('iOS emits schema-compatible location evidence before Dart review', () {
    expect(delegate, contains('"type": tracking ? "location"'));
    expect(delegate, contains('"latitude": location.coordinate.latitude'));
    expect(delegate, contains('"longitude": location.coordinate.longitude'));
    expect(delegate, contains('"recordedAt": ISO8601DateFormatter()'));
    expect(
      delegate,
      contains('"horizontalAccuracyMeters": location.horizontalAccuracy'),
    );
    expect(delegate, contains('"speedMetersPerSecond": reportedSpeed'));
    expect(delegate, contains('"mockedLocation": simulated'));
    expect(
      delegate,
      contains('guard location.timestamp >= collectionStartedAt'),
    );
  });

  test('iOS motion and pedometer callbacks remain bounded review evidence', () {
    expect(bridge, contains('motionManager.startActivityUpdates(to: .main)'));
    expect(bridge, contains('"type": "activity"'));
    expect(bridge, contains('"activity": self.tripActivity(for: motion)'));
    expect(
      bridge,
      contains('"confidence": self.confidence(for: motion.confidence)'),
    );
    expect(
      bridge,
      contains('self.activityRecognitionGeneration == generation'),
    );
    expect(
      bridge,
      contains('walkingSteps - self.lastPedometerEvidenceSteps >= 5'),
    );
    expect(bridge, contains('"activity": "walking"'));
    expect(bridge, contains('pedometer.stopUpdates()'));
  });

  test(
    'iOS automatic observer stays evidence-only and separate from a trip',
    () {
      final automatic = bridge.substring(
        bridge.indexOf('private func startAutomaticEvidence('),
        bridge.indexOf('private func stopAutomaticEvidenceObservation()'),
      );

      expect(automatic, contains('guard !tracking else'));
      expect(automatic, contains('automaticEvidenceObserving = true'));
      expect(automatic, contains('locationManager.startUpdatingLocation()'));
      expect(automatic, isNot(contains('setActivityRecognitionEnabled')));
    },
  );
}
