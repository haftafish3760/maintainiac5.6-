import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 23, 10);

  TripLocationSample sample(int seconds) => TripLocationSample(
    latitude: 35,
    longitude: -80 + (seconds * 0.0001),
    recordedAt: startedAt.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: 5,
    speedMetersPerSecond: 8,
    speedAccuracyMetersPerSecond: 1,
  );

  Future<TripTrackingController> startController(
    TripTrackingSessionStore store,
    GlobalOdometerController odometer,
  ) async {
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      clockNow: () => startedAt.add(const Duration(minutes: 1)),
    );
    expect(
      await controller.start(
        tripId: 'trip-1',
        vehicleId: 'vehicle-1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      ),
      isTrue,
    );
    return controller;
  }

  test('pending-sample write failure accepts no GPS evidence', () async {
    final store = _IngestionFailureStore()..failPendingWrite = true;
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle-1',
      initialReading: 12000,
    );
    final controller = await startController(store, odometer);
    addTearDown(controller.dispose);

    expect(await controller.ingest(sample(10)), isNull);
    expect(controller.platformStatus, 'storage_failed');
    expect(controller.acceptedMeters, 0);
    expect(controller.activeSession?.engineSnapshot.lastObservedAt, isNull);
    expect(odometer.reading, 12000);
  });

  test('accepted-session write failure rolls engine evidence back', () async {
    final store = _IngestionFailureStore();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle-1',
      initialReading: 12000,
    );
    final controller = await startController(store, odometer);
    addTearDown(controller.dispose);
    store.failSessionWrite = true;

    expect(await controller.ingest(sample(10)), isNull);
    expect(controller.platformStatus, 'storage_failed');
    expect(controller.acceptedMeters, 0);
    expect(controller.activeSession?.engineSnapshot.lastObservedAt, isNull);
    expect(store.activeSession?.engineSnapshot.lastObservedAt, isNull);
    expect(store.pendingSampleFor('trip-1'), isNotNull);
    expect(odometer.reading, 12000);

    store.failSessionWrite = false;
    expect(await controller.ingest(sample(20)), isNotNull);
    expect(controller.platformStatus, isNull);
    expect(controller.activeSession?.engineSnapshot.lastObservedAt, isNotNull);
  });

  test(
    'pending cleanup failure retains the accepted durable checkpoint',
    () async {
      final store = _IngestionFailureStore()..failPendingCleanup = true;
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle-1',
        initialReading: 12000,
      );
      final controller = await startController(store, odometer);
      addTearDown(controller.dispose);

      final decision = await controller.ingest(sample(10));
      expect(decision, isNotNull);
      expect(controller.platformStatus, 'pending_cleanup_failed');
      expect(
        controller.activeSession?.engineSnapshot.lastObservedAt,
        isNotNull,
      );
      expect(store.activeSession?.engineSnapshot.lastObservedAt, isNotNull);
      expect(store.pendingSampleFor('trip-1'), isNotNull);
      expect(odometer.confirmedReading, 12000);
    },
  );
}

class _IngestionFailureStore extends TripTrackingSessionStore {
  _IngestionFailureStore() : super.memory();

  var failPendingWrite = false;
  var failSessionWrite = false;
  var failPendingCleanup = false;

  @override
  Future<void> savePending(TripTrackingPendingSample pending) {
    if (failPendingWrite) {
      return Future<void>.error(StateError('pending write unavailable'));
    }
    return super.savePending(pending);
  }

  @override
  Future<void> save(TripTrackingSessionRecord session) {
    if (failSessionWrite) {
      return Future<void>.error(StateError('session write unavailable'));
    }
    return super.save(session);
  }

  @override
  Future<void> clearPending(String sessionId) {
    if (failPendingCleanup) {
      return Future<void>.error(StateError('pending cleanup unavailable'));
    }
    return super.clearPending(sessionId);
  }
}
