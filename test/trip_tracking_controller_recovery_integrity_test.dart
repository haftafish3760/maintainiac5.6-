import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('controller quarantines a forged accepted transition audit', () async {
    final now = DateTime.utc(2026, 7, 24, 12);
    final store = TripTrackingSessionStore.memory();
    final firstOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final first = TripTrackingController(
      sessionStore: store,
      odometer: firstOdometer,
      clockNow: () => now,
    );
    await first.start(
      tripId: 'forged_transition_recovery',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: now,
    );
    final active = store.activeSession!;
    await store.save(
      active.copyWith(
        revision: active.revision + 1,
        transitionAudits: [
          TripTrackingSessionTransitionAudit(
            id: '${active.id}:forged',
            sessionId: active.id,
            vehicleId: active.vehicleId,
            profile: active.profile,
            profileId: active.effectiveProfileId,
            fromState: TripTrackingSessionLifecycleState.completed,
            toState: TripTrackingSessionLifecycleState.active,
            eventTimestamp: now,
            sequenceNumber: active.revision + 1,
            reasonCode: 'gps_session_transition_allowed',
            initiatingSource: 'recovery',
            revision: active.revision + 1,
            permissionState: 'permission_granted',
            confidenceState: 'healthy',
            trackingQualityMode: 'high_quality',
          ),
        ],
      ),
    );
    first.dispose();
    firstOdometer.dispose();

    final restoredOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final restored = TripTrackingController(
      sessionStore: store,
      odometer: restoredOdometer,
      clockNow: () => now.add(const Duration(minutes: 1)),
    );
    addTearDown(restored.dispose);
    addTearDown(restoredOdometer.dispose);

    expect(await restored.restore(), isFalse);
    expect(restored.platformStatus, 'session_quarantined');
    expect(restored.isTracking, isFalse);
    expect(restoredOdometer.confirmedReading, 1000);
    expect(store.activeSession, isNull);
    expect(store.quarantinedSessions, hasLength(1));
    expect(
      store.quarantinedSessions.single.sessionId,
      'forged_transition_recovery',
    );
  });

  test('controller preserves a structurally valid multi-day trip', () async {
    final now = DateTime.utc(2026, 7, 24, 12);
    final startedAt = now.subtract(const Duration(days: 4));
    final store = TripTrackingSessionStore.memory();
    final firstOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 2000,
    );
    final first = TripTrackingController(
      sessionStore: store,
      odometer: firstOdometer,
      clockNow: () => startedAt,
    );
    await first.start(
      tripId: 'multi_day_recovery',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );
    first.dispose();
    firstOdometer.dispose();

    final restoredOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 2000,
    );
    final restored = TripTrackingController(
      sessionStore: store,
      odometer: restoredOdometer,
      clockNow: () => now,
    );
    addTearDown(restored.dispose);
    addTearDown(restoredOdometer.dispose);

    expect(await restored.restore(), isTrue);
    expect(restored.activeSession?.id, 'multi_day_recovery');
    expect(restored.isTracking, isTrue);
    expect(restored.nativeTracking, isFalse);
    expect(restoredOdometer.confirmedReading, 2000);
    expect(store.quarantinedSessions, isEmpty);
  });

  test(
    'restore stops a native collector with no attributable session',
    () async {
      final gateway = _OrphanNativeGateway()..running = true;
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 3000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: gateway,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(gateway.close);

      expect(await controller.restore(), isFalse);
      expect(gateway.stopCalls, 1);
      expect(gateway.running, isFalse);
      expect(controller.platformStatus, 'orphaned_native_collector_stopped');
      expect(controller.isTracking, isFalse);
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 3000);
    },
  );

  test('restore reports a native collector that ignores stop', () async {
    final gateway = _OrphanNativeGateway()
      ..running = true
      ..ignoreStop = true;
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 4000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
    );
    addTearDown(controller.dispose);
    addTearDown(odometer.dispose);
    addTearDown(gateway.close);

    expect(await controller.restore(), isFalse);
    expect(gateway.stopCalls, 1);
    expect(gateway.running, isTrue);
    expect(controller.platformStatus, 'orphaned_native_collector_stop_failed');
    expect(controller.isTracking, isFalse);
    expect(controller.acceptedMeters, 0);
    expect(odometer.confirmedReading, 4000);
  });
}

class _OrphanNativeGateway implements TripTrackingNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var running = false;
  var ignoreStop = false;
  var stopCalls = 0;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> get isTracking async => running;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
      );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async => const TripTrackingAuthorization(
    state: TripTrackingAuthorizationState.whileInUse,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    running = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => running;

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (!ignoreStop) running = false;
  }

  Future<void> close() => _events.close();
}
