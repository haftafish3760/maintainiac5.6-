import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_heartbeat_watchdog_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 17, 12);

  test(
    'background GPS cannot start when native capability is unavailable',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: false,
          activityRecognitionAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: "vehicle_1",
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_background_unavailable',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );

      expect(
        await controller.startNativeTracking(allowBackground: true),
        isFalse,
      );
      expect(native.requestAuthorizationCalls, 0);
      expect(native.startCalls, 0);
      expect(
        controller.platformError,
        contains('Background GPS tracking is unavailable'),
      );
    },
  );

  test(
    'unavailable activity recognition is stripped before native start',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: false,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: "vehicle_1",
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_motion_unavailable',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );

      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );
      expect(native.authorizationActivityRecognitionEnabled, isFalse);
      expect(native.startedRequest?.activityRecognitionEnabled, isFalse);
    },
  );

  test(
    'unavailable activity recognition stays stripped during sampling updates',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: false,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: "vehicle_1",
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => startedAt.add(const Duration(seconds: 20)),
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_motion_unavailable_update',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );

      native.addLocation(_sample(-80, startedAt, 0, speed: 8));
      native.addLocation(_sample(-79.999, startedAt, 20, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.updatedRequest?.activityRecognitionEnabled, isFalse);
    },
  );

  test(
    'selected GPS cadence is resolved after native capability validation',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
          batteryStateAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_selected_cadence',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: startedAt,
      );

      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          samplingPreset: TripTrackingSamplingPreset.batterySaver,
        ),
        isTrue,
      );
      expect(
        native.startedRequest?.sampling.interval,
        const Duration(seconds: 30),
      );
      expect(native.startedRequest?.sampling.minimumDisplacementMeters, 20);

      native.addLocation(_sample(-80, startedAt, 0, speed: 18));
      native.addLocation(_sample(-79.995, startedAt, 20, speed: 18));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.updatedRequest, isNull);
    },
  );

  test(
    'native start durably records explicit background tracking consent',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_durable_background_consent',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );

      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );
      expect(store.activeSession?.backgroundTrackingAllowed, isTrue);
      expect(native.startCalls, 1);
    },
  );

  test(
    'unconsented native motion events cannot create walking stop evidence',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: false,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_unconsented_motion',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: startedAt,
      );
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );

      native.addLocation(_sample(-80, startedAt, 0, speed: 8));
      native.addLocation(_sample(-79.999, startedAt, 20, speed: 8));
      for (final seconds in [35, 50, 65]) {
        native.addActivity(_walking(startedAt, seconds));
        native.addLocation(_sample(-79.999, startedAt, seconds, speed: 0));
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.startedRequest?.activityRecognitionEnabled, isFalse);
      expect(controller.needsWalkingReview, isFalse);
    },
  );

  test(
    'a stale native heartbeat degrades without creating trip truth',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_stale_heartbeat',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );
      native.throwOnIsTracking = true;

      final decision = await controller.checkNativeHeartbeat(
        nowUtc: DateTime.now().toUtc().add(const Duration(minutes: 4)),
      );

      expect(
        decision?.status,
        TripTrackingHeartbeatWatchdogStatus.staleButRecoverable,
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.degraded,
      );
      expect(controller.healthState, TripTrackingHealthState.reduced);
      expect(controller.platformStatus, 'native_heartbeat_stale');
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 1000);
      expect(native.startCalls, 1);
    },
  );

  test(
    'a long missing native heartbeat interrupts a degraded trip safely',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_interrupted_heartbeat',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );
      native.throwOnIsTracking = true;
      await controller.checkNativeHeartbeat(
        nowUtc: DateTime.now().toUtc().add(const Duration(minutes: 4)),
      );

      final decision = await controller.checkNativeHeartbeat(
        nowUtc: DateTime.now().toUtc().add(const Duration(minutes: 11)),
      );

      expect(
        decision?.status,
        TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformStatus, 'interrupted');
      expect(native.startCalls, 1);
    },
  );

  test(
    'a live provider heartbeat on resume prevents a false interruption',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_resume_heartbeat',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      await controller.handleAppLifecycleState(
        AppLifecycleState.resumed,
        backgroundTrackingAllowed: true,
      );

      final decision = await controller.checkNativeHeartbeat(
        nowUtc: DateTime.now().toUtc().add(const Duration(minutes: 11)),
      );
      expect(decision?.status, TripTrackingHeartbeatWatchdogStatus.healthy);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(controller.healthState, TripTrackingHealthState.healthy);
      expect(controller.nativeTracking, isTrue);
      expect(controller.platformStatus, 'tracking');
    },
  );

  test(
    'a native status heartbeat helps only when a direct probe is unavailable',
    () async {
      var now = DateTime.utc(2026, 7, 18, 8);
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        heartbeatNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_status_heartbeat',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      now = now.add(const Duration(minutes: 4));
      native.throwOnIsTracking = true;
      native.nativeRunning = false;
      native.addStatus('tracking');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      now = now.add(const Duration(minutes: 2));
      final decision = await controller.checkNativeHeartbeat(nowUtc: now);

      expect(decision?.status, TripTrackingHeartbeatWatchdogStatus.healthy);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.degraded,
      );
      expect(controller.platformStatus, 'gps_signal_stale');
    },
  );

  test(
    'a direct stopped probe overrides a stale native status heartbeat',
    () async {
      var now = DateTime.utc(2026, 7, 18, 8);
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        heartbeatNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_stopped_probe',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      now = now.add(const Duration(minutes: 4));
      native.nativeRunning = false;
      native.addStatus('tracking');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final decision = await controller.checkNativeHeartbeat(nowUtc: now);

      expect(
        decision?.status,
        TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.nativeTracking, isFalse);
    },
  );

  test(
    'revoked live background permission interrupts without creating miles',
    () async {
      final native = _NativeCapabilityProbeFake(
        capabilities: const TripTrackingPlatformCapabilities(
          locationAvailable: true,
          backgroundTrackingAvailable: true,
          activityRecognitionAvailable: true,
        ),
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_permission_revoked',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      native.addAuthorization(
        const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.whileInUse,
          preciseLocation: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformStatus, 'interrupted');
      expect(
        controller.platformError,
        contains('Background location permission'),
      );
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 1000);
    },
  );
}

TripLocationSample _sample(
  double longitude,
  DateTime start,
  int seconds, {
  double? speed,
}) => TripLocationSample(
  latitude: 35,
  longitude: longitude,
  recordedAt: start.add(Duration(seconds: seconds)),
  horizontalAccuracyMeters: 5,
  speedMetersPerSecond: speed,
);

TripActivityObservation _walking(DateTime start, int seconds) =>
    TripActivityObservation(
      activity: TripActivity.walking,
      confidence: 95,
      recordedAt: start.add(Duration(seconds: seconds)),
    );

class _NativeCapabilityProbeFake implements TripTrackingNativeGateway {
  _NativeCapabilityProbeFake({required this.capabilities});

  final TripTrackingPlatformCapabilities capabilities;
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var requestAuthorizationCalls = 0;
  var startCalls = 0;
  bool nativeRunning = true;
  bool throwOnIsTracking = false;
  bool? authorizationActivityRecognitionEnabled;
  TripTrackingNativeRequest? startedRequest;
  TripTrackingNativeRequest? updatedRequest;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      capabilities;

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 100,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    requestAuthorizationCalls += 1;
    authorizationActivityRecognitionEnabled = activityRecognitionEnabled;
    return const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    );
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    startCalls += 1;
    startedRequest = request;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    updatedRequest = request;
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> get isTracking async {
    if (throwOnIsTracking) throw StateError('native probe unavailable');
    return nativeRunning && startCalls > 0;
  }

  void addLocation(TripLocationSample sample) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        ...sample.toMap(),
      }),
    );
  }

  void addActivity(TripActivityObservation observation) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'activity',
        ...observation.toMap(),
      }),
    );
  }

  void addAuthorization(TripTrackingAuthorization authorization) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'authorization',
        'state': authorization.state.name,
        'preciseLocation': authorization.preciseLocation,
      }),
    );
  }

  void addStatus(String status) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': status}),
    );
  }
}
