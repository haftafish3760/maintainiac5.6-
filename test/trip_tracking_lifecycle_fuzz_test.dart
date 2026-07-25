import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'seeded lifecycle races preserve one trip and serialize native commands',
    () async {
      for (final seed in [17011, 17029, 17041, 17053, 17077, 17093]) {
        final random = Random(seed);
        final gateway = _LifecycleFuzzGateway();
        final store = TripTrackingSessionStore.memory();
        final odometer = GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 5000,
        );
        final controller = TripTrackingController(
          sessionStore: store,
          odometer: odometer,
          platform: gateway,
        );
        addTearDown(controller.dispose);
        addTearDown(odometer.dispose);
        addTearDown(gateway.close);
        final tripId = 'lifecycle_fuzz_$seed';
        expect(
          await controller.start(
            tripId: tripId,
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 24),
          ),
          isTrue,
          reason: 'seed=$seed',
        );

        var previousRevision = controller.activeSession!.revision;
        for (var cycle = 0; cycle < 40; cycle += 1) {
          final operations = List<Future<void>>.generate(3, (_) async {
            switch (random.nextInt(5)) {
              case 0:
                await controller.startNativeTracking(allowBackground: false);
              case 1:
                await controller.stopNativeTracking();
              case 2:
                await controller.handleAppLifecycleState(
                  AppLifecycleState.paused,
                  backgroundTrackingAllowed: false,
                );
              case 3:
                await controller.handleAppLifecycleState(
                  AppLifecycleState.resumed,
                  backgroundTrackingAllowed: false,
                );
              case 4:
                await controller.checkNativeHeartbeat();
            }
          });
          await Future.wait(operations);

          final session = controller.activeSession;
          expect(session, isNotNull, reason: 'seed=$seed cycle=$cycle');
          expect(session!.id, tripId, reason: 'seed=$seed cycle=$cycle');
          expect(
            session.revision,
            greaterThanOrEqualTo(previousRevision),
            reason: 'seed=$seed cycle=$cycle',
          );
          previousRevision = session.revision;
          expect(controller.acceptedMeters, 0);
          expect(odometer.confirmedReading, 5000);
        }

        await controller.stopNativeTracking();
        expect(gateway.running, isFalse, reason: 'seed=$seed');
        expect(gateway.maximumConcurrentCommands, 1, reason: 'seed=$seed');
        expect(store.activeSession?.id, tripId, reason: 'seed=$seed');
        expect(odometer.confirmedReading, 5000, reason: 'seed=$seed');
      }
    },
  );
}

class _LifecycleFuzzGateway implements TripTrackingNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var running = false;
  var _activeCommands = 0;
  var maximumConcurrentCommands = 0;

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
    state: TripTrackingAuthorizationState.whileInUse,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) =>
      _command(() => running = true);

  @override
  Future<bool> update(TripTrackingNativeRequest request) =>
      _command(() => running);

  @override
  Future<void> stop() async {
    await _command(() {
      running = false;
      return true;
    });
  }

  Future<T> _command<T>(T Function() operation) async {
    _activeCommands += 1;
    maximumConcurrentCommands = max(maximumConcurrentCommands, _activeCommands);
    try {
      await Future<void>.delayed(const Duration(microseconds: 50));
      return operation();
    } finally {
      _activeCommands -= 1;
    }
  }

  Future<void> close() => _events.close();
}
