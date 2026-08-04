// Regression coverage for the opt-in App Assistant runtime boundary.
//
// Owns review-only event routing and observation lifecycle checks. It does not
// test native provider registration, user permission prompts, or field GPS.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'runtime routes only dedicated opt-in evidence events to review',
    () async {
      final at = DateTime.utc(2026, 8, 4, 12);
      final gateway = _EvidenceGateway();
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final tripTracking = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        automaticEvidenceCandidateStore: store,
        clockNow: () => at.add(const Duration(seconds: 30)),
      );
      final settings = const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      );
      final runtime = TripAutomaticEvidenceRuntimeController(
        gateway: gateway,
        tripTracking: tripTracking,
        settings: () => settings,
        accessLevel: TripAutomaticStartAccessLevel.paid,
      );
      addTearDown(gateway.dispose);
      addTearDown(odometer.dispose);
      addTearDown(tripTracking.dispose);
      addTearDown(runtime.dispose);

      expect(await runtime.synchronize(), isTrue);
      expect(gateway.startCalls, 1);
      gateway.emit({
        'schemaVersion': 1,
        'type': 'location',
        'latitude': 35.0,
        'longitude': -82.0,
        'recordedAt': at.millisecondsSinceEpoch,
        'horizontalAccuracyMeters': 12.0,
        'speedMetersPerSecond': 8.0,
      });
      gateway.emit({
        'schemaVersion': 1,
        'type': 'automaticEvidenceLocation',
        'latitude': 35.0,
        'longitude': -82.0,
        'recordedAt': at.millisecondsSinceEpoch,
        'horizontalAccuracyMeters': 12.0,
        'speedMetersPerSecond': 8.0,
      });
      gateway.emit({
        'schemaVersion': 1,
        'type': 'automaticEvidenceLocation',
        'latitude': 35.0004,
        'longitude': -82.0004,
        'recordedAt': at
            .add(const Duration(seconds: 15))
            .millisecondsSinceEpoch,
        'horizontalAccuracyMeters': 12.0,
        'speedMetersPerSecond': 8.0,
      });
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(tripTracking.pendingAutomaticEvidenceCandidates, hasLength(1));
      expect(tripTracking.isTracking, isFalse);
      expect(odometer.confirmedReading, 1000);
    },
  );

  test(
    'opt-out stops native observation and clears only transient evidence',
    () async {
      final gateway = _EvidenceGateway();
      final tripTracking = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(),
      );
      var settings = const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      );
      final runtime = TripAutomaticEvidenceRuntimeController(
        gateway: gateway,
        tripTracking: tripTracking,
        settings: () => settings,
      );
      addTearDown(gateway.dispose);
      addTearDown(tripTracking.dispose);
      addTearDown(runtime.dispose);

      expect(await runtime.synchronize(), isTrue);
      settings = const TripTrackingSettings();
      expect(await runtime.synchronize(), isFalse);
      expect(gateway.stopCalls, 1);
      expect(tripTracking.isTracking, isFalse);
    },
  );

  test('native evidence failure cannot create or alter a trip', () async {
    final gateway = _EvidenceGateway();
    final odometer = GlobalOdometerController(initialReading: 1000);
    final tripTracking = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    final runtime = TripAutomaticEvidenceRuntimeController(
      gateway: gateway,
      tripTracking: tripTracking,
      settings: () => const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
    );
    addTearDown(gateway.dispose);
    addTearDown(odometer.dispose);
    addTearDown(tripTracking.dispose);
    addTearDown(runtime.dispose);

    expect(await runtime.synchronize(), isTrue);
    gateway.emit({
      'schemaVersion': 1,
      'type': 'error',
      'errorCode': 'automatic_evidence_location_registration_failed',
      'errorMessage': 'unavailable',
    });

    expect(runtime.observationRunning, isFalse);
    expect(runtime.lastStatus, 'automatic_evidence_observation_unavailable');
    expect(tripTracking.isTracking, isFalse);
    expect(odometer.confirmedReading, 1000);
  });
}

class _EvidenceGateway implements TripAutomaticEvidenceNativeGateway {
  final StreamController<TripTrackingPlatformEvent> _events =
      StreamController<TripTrackingPlatformEvent>.broadcast(sync: true);
  int startCalls = 0;
  int stopCalls = 0;
  bool startResult = true;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> startAutomaticEvidenceObservation({
    required bool activityRecognitionEnabled,
  }) async {
    startCalls++;
    return startResult;
  }

  @override
  Future<void> stopAutomaticEvidenceObservation() async {
    stopCalls++;
  }

  @override
  Future<bool> get isAutomaticEvidenceObservationRunning async => startResult;

  void emit(Map<String, Object> payload) =>
      _events.add(TripTrackingPlatformEvent.fromNativePayload(payload));

  Future<void> dispose() => _events.close();
}
