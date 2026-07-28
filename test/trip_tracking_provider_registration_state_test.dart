import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'provider registration status changes never create GPS or odometer truth',
    () async {
      final now = DateTime.utc(2026, 7, 27, 12);
      final gateway = _RegistrationGateway();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: gateway,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(gateway.dispose);

      expect(
        await controller.start(
          tripId: 'provider_state_trip',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
        ),
        isTrue,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: false,
        ),
        isTrue,
      );
      await _drainEvents();

      expect(controller.nativeTracking, isTrue);
      expect(controller.nativeProviderRegistered, isFalse);
      expect(controller.platformStatus, 'awaiting_provider_registration');
      _expectOdometerUntouched(controller, odometer);

      gateway.emitStatus('tracking');
      await _drainEvents();
      expect(controller.nativeProviderRegistered, isTrue);
      expect(controller.platformStatus, 'awaiting_initial_fix');
      _expectOdometerUntouched(controller, odometer);

      final revisionAfterRegistration = controller.activeSession?.revision;
      gateway.emitStatus('tracking');
      await _drainEvents();
      expect(controller.nativeProviderRegistered, isTrue);
      expect(controller.platformStatus, 'awaiting_initial_fix');
      expect(controller.activeSession?.revision, revisionAfterRegistration);
      _expectOdometerUntouched(controller, odometer);

      gateway.emitStatus('starting');
      await _drainEvents();
      expect(controller.nativeTracking, isTrue);
      expect(controller.nativeProviderRegistered, isFalse);
      expect(controller.platformStatus, 'awaiting_provider_registration');
      _expectOdometerUntouched(controller, odometer);

      gateway.emitStatus('tracking');
      await _drainEvents();
      expect(controller.nativeProviderRegistered, isTrue);
      expect(controller.platformStatus, 'awaiting_initial_fix');
      _expectOdometerUntouched(controller, odometer);
    },
  );

  test(
    'immediate provider registration during start remains advisory',
    () async {
      final now = DateTime.utc(2026, 7, 28, 12);
      final gateway = _RegistrationGateway(registerDuringStart: true);
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: gateway,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(gateway.dispose);

      expect(
        await controller.start(
          tripId: 'immediate_provider_state_trip',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
        ),
        isTrue,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: false,
        ),
        isTrue,
      );
      await _drainEvents();

      expect(controller.nativeTracking, isTrue);
      expect(controller.nativeProviderRegistered, isTrue);
      expect(controller.platformStatus, 'awaiting_initial_fix');
      _expectOdometerUntouched(controller, odometer);
    },
  );

  test(
    'unregistered native collector cannot refresh heartbeat liveness',
    () async {
      final now = DateTime.utc(2026, 7, 28, 12);
      final gateway = _RegistrationGateway();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: gateway,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(gateway.dispose);

      expect(
        await controller.start(
          tripId: 'provider_wait_watchdog',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
        ),
        isTrue,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: false,
        ),
        isTrue,
      );
      await _drainEvents();

      final decision = await controller.checkNativeHeartbeat(
        nowUtc: now.add(const Duration(minutes: 4)),
      );

      expect(controller.nativeProviderRegistered, isFalse);
      expect(decision?.reasonCode, 'heartbeat_stale_retry_native');
      expect(controller.platformStatus, 'native_heartbeat_stale');
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.degraded,
      );
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 1000);
    },
  );
}

void _expectOdometerUntouched(
  TripTrackingController controller,
  GlobalOdometerController odometer,
) {
  expect(controller.acceptedMeters, 0);
  expect(odometer.confirmedReading, 1000);
  expect(odometer.reading, 1000);
  expect(odometer.hasLiveTripProjection, isTrue);
}

Future<void> _drainEvents() => Future<void>.delayed(Duration.zero);

class _RegistrationGateway implements TripTrackingNativeGateway {
  _RegistrationGateway({this.registerDuringStart = false});

  final bool registerDuringStart;
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var running = false;

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
        batteryStateAvailable: true,
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
    emitStatus('starting');
    if (registerDuringStart) emitStatus('tracking');
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => running;

  @override
  Future<void> stop() async => running = false;

  void emitStatus(String status) => _events.add(
    TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': status}),
  );

  Future<void> dispose() => _events.close();
}
