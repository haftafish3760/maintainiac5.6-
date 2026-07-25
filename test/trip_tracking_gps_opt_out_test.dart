import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'withdrawing GPS consent pauses assistance without changing mileage',
    () async {
      final platform = _OptOutGateway();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 12000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: platform,
        clockNow: () => DateTime.utc(2026, 7, 24, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(platform.close);
      await controller.start(
        tripId: 'trip_opt_out',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 24, 12),
      );
      final nativeStarted = await controller.startNativeTracking(
        allowBackground: false,
      );
      expect(
        nativeStarted,
        isTrue,
        reason:
            '${controller.platformStatus}: ${controller.platformError}; '
            '${controller.lifecycleState}',
      );
      final confirmedBefore = odometer.confirmedReading;

      await controller.applyGpsAssistanceConsent(enabled: false);

      expect(platform.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(controller.activeSession?.pauseKind, TripTrackingPauseKind.user);
      expect(controller.platformStatus, 'gps_assistance_disabled');
      expect(odometer.confirmedReading, confirmedBefore);

      await controller.applyGpsAssistanceConsent(enabled: false);
      await controller.applyGpsAssistanceConsent(enabled: true);

      expect(platform.stopCalls, 1);
      expect(platform.startCalls, 1);
      expect(controller.nativeTracking, isFalse);
    },
  );

  test(
    'active accuracy and privacy reductions apply without mileage changes',
    () async {
      final platform = _OptOutGateway();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 12000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: platform,
        clockNow: () => DateTime.utc(2026, 7, 24, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(platform.close);
      await controller.start(
        tripId: 'trip_runtime_settings',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 24, 12),
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: true,
          samplingPreset: TripTrackingSamplingPreset.highAccuracy,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );
      final confirmedBefore = odometer.confirmedReading;

      expect(
        await controller.applyActiveTrackingSettings(
          const TripTrackingSettings(
            tripTrackingSetupCompleted: true,
            gpsAssistedTrackingEnabled: true,
            samplingPreset: TripTrackingSamplingPreset.batterySaver,
            backgroundTrackingEnabled: false,
            activityRecognitionEnabled: false,
            adaptiveSamplingEnabled: false,
            lowBatteryGpsProtectionEnabled: false,
          ),
        ),
        isTrue,
      );

      expect(platform.updateCalls, 1);
      expect(
        platform.lastUpdate?.sampling.interval,
        const Duration(seconds: 30),
      );
      expect(platform.lastUpdate?.allowBackground, isFalse);
      expect(platform.lastUpdate?.activityRecognitionEnabled, isFalse);
      expect(
        controller.activeSession?.nativeSampling?.interval,
        const Duration(seconds: 30),
      );
      expect(controller.activeSession?.backgroundTrackingAllowed, isFalse);
      expect(controller.activeSession?.activityRecognitionEnabled, isFalse);
      expect(controller.activeSession?.adaptiveSamplingEnabled, isFalse);
      expect(controller.activeSession?.lowBatteryProtectionEnabled, isFalse);
      expect(controller.nativeTracking, isTrue);
      expect(odometer.confirmedReading, confirmedBefore);
    },
  );

  test(
    'rejected live settings update preserves trip in system pause',
    () async {
      final platform = _OptOutGateway()..updateResult = false;
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 12000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: platform,
        clockNow: () => DateTime.utc(2026, 7, 24, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      addTearDown(platform.close);
      await controller.start(
        tripId: 'trip_runtime_settings_rejected',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 24, 12),
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          samplingPreset: TripTrackingSamplingPreset.highAccuracy,
        ),
        isTrue,
      );
      final confirmedBefore = odometer.confirmedReading;

      expect(
        await controller.applyActiveTrackingSettings(
          const TripTrackingSettings(
            tripTrackingSetupCompleted: true,
            gpsAssistedTrackingEnabled: true,
            samplingPreset: TripTrackingSamplingPreset.batterySaver,
          ),
        ),
        isFalse,
      );

      expect(platform.updateCalls, 1);
      expect(platform.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(controller.activeSession?.pauseKind, TripTrackingPauseKind.system);
      expect(controller.platformStatus, 'gps_settings_update_failed');
      expect(odometer.confirmedReading, confirmedBefore);
    },
  );
}

class _OptOutGateway implements TripTrackingNativeGateway {
  final StreamController<TripTrackingPlatformEvent> _events =
      StreamController<TripTrackingPlatformEvent>.broadcast();

  var running = false;
  var startCalls = 0;
  var stopCalls = 0;
  var updateCalls = 0;
  var updateResult = true;
  TripTrackingNativeRequest? lastUpdate;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> get isTracking async => running;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
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
    state: TripTrackingAuthorizationState.always,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    startCalls += 1;
    running = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    updateCalls += 1;
    lastUpdate = request;
    return running && updateResult;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    running = false;
  }

  Future<void> close() => _events.close();
}
