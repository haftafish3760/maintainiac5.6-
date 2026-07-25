import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TripTrackingSessionRecord session(String id, {int startingOdometer = 1000}) =>
      TripTrackingSessionRecord(
        id: id,
        vehicleId: 'vehicle_1',
        startingOdometer: startingOdometer,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 23, 12),
        updatedAt: DateTime.utc(2026, 7, 23, 12),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
      );

  test(
    'one memory store atomically accepts only one simultaneous start',
    () async {
      final store = TripTrackingSessionStore.memory();

      final results = await Future.wait([
        store.createIfNoSessionEvidence(session('trip_memory_a')),
        store.createIfNoSessionEvidence(session('trip_memory_b')),
      ]);

      expect(results.where((accepted) => accepted), hasLength(1));
      expect(
        store.activeSession?.id,
        results.first ? 'trip_memory_a' : 'trip_memory_b',
      );
    },
  );

  test(
    'failed memory reservation does not block a later valid start',
    () async {
      final store = TripTrackingSessionStore.memory();
      final invalid = session('trip_memory_invalid', startingOdometer: -1);

      await expectLater(
        store.createIfNoSessionEvidence(invalid),
        throwsArgumentError,
      );

      expect(store.activeSession, isNull);
      expect(
        await store.createIfNoSessionEvidence(session('trip_memory_valid')),
        isTrue,
      );
      expect(store.activeSession?.id, 'trip_memory_valid');
    },
  );

  test(
    'multiple controller instances cannot create duplicate sessions',
    () async {
      final store = TripTrackingSessionStore.memory();
      final first = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      final second = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      final results = await Future.wait([
        first.start(
          tripId: 'trip_controller_a',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
        ),
        second.start(
          tripId: 'trip_controller_b',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
        ),
      ]);

      expect(results.where((accepted) => accepted), hasLength(1));
      expect(
        store.activeSession?.id,
        results.first ? 'trip_controller_a' : 'trip_controller_b',
      );
      final loser = results.first ? second : first;
      expect(loser.isTracking, isFalse);
      expect(loser.platformStatus, 'trip_already_active');
    },
  );

  test(
    'two Hive store instances atomically accept only one simultaneous start',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'trip_atomic_session_start_',
      );
      Hive.init(directory.path);
      final firstStore = await TripTrackingSessionStore.create(
        storageCheck: _allowStorage,
      );
      final secondStore = await TripTrackingSessionStore.create(
        storageCheck: _allowStorage,
      );
      addTearDown(() async {
        await Hive.close();
        if (directory.existsSync()) await directory.delete(recursive: true);
      });

      final results = await Future.wait([
        firstStore.createIfNoSessionEvidence(session('trip_hive_a')),
        secondStore.createIfNoSessionEvidence(session('trip_hive_b')),
      ]);

      expect(results.where((accepted) => accepted), hasLength(1));
      expect(
        firstStore.activeSession?.id,
        results.first ? 'trip_hive_a' : 'trip_hive_b',
      );
      expect(secondStore.activeSession?.id, firstStore.activeSession?.id);
      expect(firstStore.pendingWriteState, TripTrackingPendingWriteState.none);
    },
  );

  test('failed Hive reservation does not leave a phantom session', () async {
    final directory = await Directory.systemTemp.createTemp(
      'trip_failed_session_reservation_',
    );
    Hive.init(directory.path);
    final store = await TripTrackingSessionStore.create(
      storageCheck: _allowStorage,
    );
    addTearDown(() async {
      await Hive.close();
      if (directory.existsSync()) await directory.delete(recursive: true);
    });
    final invalid = session('trip_hive_invalid', startingOdometer: -1);

    await expectLater(
      store.createIfNoSessionEvidence(invalid),
      throwsArgumentError,
    );

    expect(store.activeSession, isNull);
    expect(store.hasUnreadableActiveEvidence, isFalse);
    expect(store.pendingWriteState, TripTrackingPendingWriteState.none);
    expect(
      await store.createIfNoSessionEvidence(session('trip_hive_valid')),
      isTrue,
    );
    expect(store.activeSession?.id, 'trip_hive_valid');
  });
}

Future<AppStorageCheck> _allowStorage() async => const AppStorageCheck(
  availableBytes: 1024 * 1024 * 1024,
  operationBytes: 1,
  requiredBytes: 1,
  purpose: AppStoragePurpose.mileageTracking,
);
