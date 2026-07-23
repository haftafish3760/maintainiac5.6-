import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'system-paused trip rejects late GPS callbacks without mutation',
    () async {
      final startedAt = DateTime.utc(2026, 7, 23, 10);
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle-1',
        initialReading: 12000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => startedAt.add(const Duration(minutes: 1)),
      );
      addTearDown(controller.dispose);
      expect(
        await controller.start(
          tripId: 'paused-trip',
          vehicleId: 'vehicle-1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
        ),
        isTrue,
      );
      expect(
        await controller.tryTransitionForTest(
          TripTrackingSessionLifecycleState.paused,
          reasonCode: 'test_system_pause',
          source: 'test',
        ),
        isTrue,
      );
      final paused = controller.activeSession!;
      expect(
        paused.effectiveContractState,
        TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM,
      );

      final decision = await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: startedAt.add(const Duration(seconds: 30)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 8,
          speedAccuracyMetersPerSecond: 1,
        ),
      );

      expect(decision, isNull);
      expect(controller.activeSession?.revision, paused.revision);
      expect(controller.activeSession?.engineSnapshot, paused.engineSnapshot);
      expect(store.pendingSampleFor('paused-trip'), isNull);
      expect(controller.acceptedMeters, 0);
      expect(odometer.confirmedReading, 12000);
      expect(odometer.reading, 12000);
    },
  );

  test('recovered user pause rejects GPS until explicit resume', () async {
    final startedAt = DateTime.utc(2026, 7, 23, 10);
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'user-paused-trip',
        vehicleId: 'vehicle-1',
        startingOdometer: 12000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
        updatedAt: startedAt.add(const Duration(minutes: 1)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
        lifecycleState: TripTrackingSessionLifecycleState.paused,
        pauseKind: TripTrackingPauseKind.user,
        persistedContractState:
            TripTrackingSessionLifecycleContractState.PAUSED_BY_USER,
      ),
    );
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle-1',
      initialReading: 12000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      clockNow: () => startedAt.add(const Duration(minutes: 2)),
    );
    addTearDown(controller.dispose);
    expect(await controller.restore(), isTrue);
    final paused = controller.activeSession!;
    expect(paused.pauseKind, TripTrackingPauseKind.user);

    expect(
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: startedAt.add(const Duration(seconds: 90)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 8,
          speedAccuracyMetersPerSecond: 1,
        ),
      ),
      isNull,
    );
    expect(controller.activeSession?.revision, paused.revision);
    expect(store.pendingSampleFor('user-paused-trip'), isNull);
    expect(controller.acceptedMeters, 0);
    expect(odometer.reading, 12000);
  });
}
