// Deterministic controller/store lifecycle replay for GPS stress scenarios.
//
// Owns a bounded fake-native replay through the real controller and in-memory
// session store. It does not access devices, cloud services, or production
// storage. The shared stress runner consumes it to protect lifecycle wiring.

import 'dart:async';

import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

import 'trip_stress_scenario.dart';

/// Executes one real controller/store lifecycle without retaining its trace.
final class TripStressControllerReplay {
  const TripStressControllerReplay();

  Future<Map<String, Object?>> replay(TripStressScenario scenario) async {
    final gateway = _ReplayGateway(
      registerDuringStart:
          scenario.providerState == TripStressProviderState.immediate,
    );
    final odometer = GlobalOdometerController(
      vehicleId: scenario.vehicleId,
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
      clockNow: () => DateTime.utc(2026, 7, 28, 12),
    );
    try {
      final started = await controller.start(
        tripId: 'stress_${scenario.scenarioSeed}',
        vehicleId: scenario.vehicleId,
        profile: TripTrackingProfile.roadVehicle,
        profileId: scenario.profileId,
        startedAt: DateTime.utc(2026, 7, 28, 12),
      );
      if (!started) {
        return _failure('session_start_rejected', controller, odometer);
      }
      final nativeStarted = await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: false,
      );
      if (!nativeStarted) {
        return _failure('native_start_rejected', controller, odometer);
      }
      await _drain();
      if (scenario.providerState == TripStressProviderState.delayed ||
          scenario.providerState == TripStressProviderState.late ||
          scenario.providerState == TripStressProviderState.duplicate ||
          scenario.providerState == TripStressProviderState.lost) {
        gateway.emitStatus('tracking');
        if (scenario.providerState == TripStressProviderState.duplicate) {
          gateway.emitStatus('tracking');
        }
        await _drain();
      }
      final duplicateStart = await controller.start(
        tripId: 'duplicate_${scenario.scenarioSeed}',
        vehicleId: scenario.vehicleId,
        profile: TripTrackingProfile.roadVehicle,
        profileId: scenario.profileId,
      );
      final passes =
          controller.activeSession != null &&
          controller.activeSession!.vehicleId == scenario.vehicleId &&
          !duplicateStart &&
          odometer.confirmedReading == 1000;
      return {
        'passed': passes,
        'reason': passes ? null : 'controller_invariant_failed',
        'platformStatus': controller.platformStatus,
        'nativeProviderRegistered': controller.nativeProviderRegistered,
        'duplicateStartAccepted': duplicateStart,
        'confirmedOdometer': odometer.confirmedReading,
        'sessionRevision': controller.activeSession?.revision,
      };
    } finally {
      await controller.stopNativeTracking();
      controller.dispose();
      odometer.dispose();
      await gateway.dispose();
    }
  }

  Map<String, Object?> _failure(
    String reason,
    TripTrackingController controller,
    GlobalOdometerController odometer,
  ) => {
    'passed': false,
    'reason': reason,
    'platformStatus': controller.platformStatus,
    'confirmedOdometer': odometer.confirmedReading,
  };
}

Future<void> _drain() => Future<void>.delayed(Duration.zero);

final class _ReplayGateway implements TripTrackingNativeGateway {
  _ReplayGateway({required this.registerDuringStart});

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
