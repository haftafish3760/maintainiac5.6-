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
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
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
    'runtime carries Bluetooth only as vehicle evidence for review',
    () async {
      final at = DateTime.utc(2026, 8, 4, 12);
      final gateway = _EvidenceGateway();
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final tripTracking = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        automaticEvidenceCandidateStore: store,
        clockNow: () => at.add(const Duration(seconds: 45)),
      );
      final runtime = TripAutomaticEvidenceRuntimeController(
        gateway: gateway,
        tripTracking: tripTracking,
        settings: () => const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          automaticStartAssistanceEnabled: true,
        ),
        accessLevel: TripAutomaticStartAccessLevel.paid,
        bluetoothEvidenceVehicleId: () => 'vehicle_1',
      );
      addTearDown(gateway.dispose);
      addTearDown(odometer.dispose);
      addTearDown(tripTracking.dispose);
      addTearDown(runtime.dispose);

      expect(await runtime.synchronize(), isTrue);
      for (var index = 0; index < 3; index += 1) {
        gateway.emit({
          'schemaVersion': 1,
          'type': 'automaticEvidenceLocation',
          'latitude': 35.0 + (index * 0.0004),
          'longitude': -82.0 - (index * 0.0004),
          'recordedAt': at
              .add(Duration(seconds: index * 15))
              .millisecondsSinceEpoch,
          'horizontalAccuracyMeters': 12.0,
          'speedMetersPerSecond': 8.0,
        });
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final candidate = tripTracking.pendingAutomaticEvidenceCandidates.single;
      expect(candidate.suggestedVehicleId, 'vehicle_1');
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
      expect(await runtime.synchronize(), isFalse);
      expect(gateway.stopCalls, 1);
      expect(tripTracking.isTracking, isFalse);
    },
  );

  test(
    'repeated enabled synchronization does not duplicate observation',
    () async {
      final gateway = _EvidenceGateway();
      final odometer = GlobalOdometerController();
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
      expect(await runtime.synchronize(), isTrue);
      expect(gateway.startCalls, 1);
      gateway.stopExternally();
      expect(await runtime.synchronize(), isTrue);
      expect(gateway.startCalls, 2);
      expect(runtime.observationRunning, isTrue);
      expect(tripTracking.isTracking, isFalse);
    },
  );

  test('an active local trip keeps the separate observer stopped', () async {
    final gateway = _EvidenceGateway();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
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
    expect(
      await tripTracking.start(
        tripId: 'trip_1',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 8, 4, 12),
      ),
      isTrue,
    );

    expect(await runtime.synchronize(), isFalse);
    expect(gateway.stopCalls, 1);
    expect(runtime.observationRunning, isFalse);
  });

  test('native evidence failure cannot create or alter a trip', () async {
    final gateway = _EvidenceGateway();
    final odometer = GlobalOdometerController(initialReading: 1000);
    final tripTracking = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      automaticEvidenceCandidateStore:
          TripAutomaticEvidenceCandidateStore.memory(),
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
    gateway.emit({
      'schemaVersion': 1,
      'type': 'automaticEvidenceLocation',
      'latitude': 35.0,
      'longitude': -82.0,
      'recordedAt': DateTime.utc(2026, 8, 4, 12).millisecondsSinceEpoch,
      'horizontalAccuracyMeters': 12.0,
      'speedMetersPerSecond': 8.0,
    });
    await Future<void>.delayed(Duration.zero);
    expect(tripTracking.pendingAutomaticEvidenceCandidates, isEmpty);
    expect(tripTracking.isTracking, isFalse);
    expect(odometer.confirmedReading, 1000);
  });

  test('a queued opt-out wins over an in-flight observer start', () async {
    final gateway = _EvidenceGateway();
    final startBarrier = Completer<void>();
    gateway.startBarrier = startBarrier;
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

    final enabling = runtime.synchronize();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.startCalls, 1);
    settings = const TripTrackingSettings();
    final disabling = runtime.synchronize();
    startBarrier.complete();

    await Future.wait([enabling, disabling]);
    expect(gateway.stopCalls, 1);
    expect(gateway.isRunning, isFalse);
    expect(runtime.observationRunning, isFalse);
    expect(runtime.lastStatus, 'automatic_evidence_observation_stopped');
  });

  test(
    'a failed native stop is never reported as a successful opt-out',
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
      gateway.stopThrows = true;
      settings = const TripTrackingSettings();

      expect(await runtime.synchronize(), isTrue);
      expect(runtime.observationRunning, isTrue);
      expect(
        runtime.lastStatus,
        'automatic_evidence_observation_stop_unconfirmed',
      );
    },
  );

  test('optional activity failure keeps location observation active', () async {
    final gateway = _EvidenceGateway();
    final tripTracking = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(),
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
    addTearDown(tripTracking.dispose);
    addTearDown(runtime.dispose);

    expect(await runtime.synchronize(), isTrue);
    gateway.emit({
      'schemaVersion': 1,
      'type': 'error',
      'errorCode': 'automatic_evidence_activity_permission_removed',
      'errorMessage': 'location only',
    });

    expect(runtime.observationRunning, isTrue);
    expect(runtime.lastStatus, 'automatic_evidence_observing_without_activity');
  });
}

class _EvidenceGateway implements TripAutomaticEvidenceNativeGateway {
  final StreamController<TripTrackingPlatformEvent> _events =
      StreamController<TripTrackingPlatformEvent>.broadcast(sync: true);
  int startCalls = 0;
  int stopCalls = 0;
  bool startResult = true;
  bool stopThrows = false;
  Completer<void>? startBarrier;
  bool _running = false;
  bool get isRunning => _running;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> startAutomaticEvidenceObservation({
    required bool activityRecognitionEnabled,
  }) async {
    startCalls++;
    await startBarrier?.future;
    _running = startResult;
    return startResult;
  }

  @override
  Future<void> stopAutomaticEvidenceObservation() async {
    stopCalls++;
    if (stopThrows) throw StateError('native stop failed');
    _running = false;
  }

  @override
  Future<bool> get isAutomaticEvidenceObservationRunning async => _running;

  void stopExternally() => _running = false;

  void emit(Map<String, Object> payload) =>
      _events.add(TripTrackingPlatformEvent.fromNativePayload(payload));

  Future<void> dispose() => _events.close();
}
