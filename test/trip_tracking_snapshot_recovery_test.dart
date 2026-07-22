import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Box<dynamic> box;
  late TripTrackingSessionStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'maintainiac_trip_snapshot_',
    );
    Hive.init(tempDirectory.path);
    store = await TripTrackingSessionStore.create();
    box = Hive.box<dynamic>(TripTrackingSessionStore.boxName);
  });

  tearDown(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  TripTrackingSessionRecord session(int revision) => TripTrackingSessionRecord(
    id: 'snapshot_trip',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 20, 12),
    updatedAt: DateTime.utc(2026, 7, 20, 12, revision),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: revision * 100,
      walkingReviewSuggested: false,
    ),
    revision: revision,
  );

  test(
    'corrupt latest checksum falls back and records one diagnostic',
    () async {
      await store.save(session(1));
      await store.save(session(2));
      final corrupt = Map<dynamic, dynamic>.from(
        box.get('activeSession') as Map,
      )..['checksum'] = 'corrupt';
      await box.put('activeSession', corrupt);

      expect(store.activeSession?.revision, 1);
      expect((await store.recoverActive())?.revision, 1);
      expect((await store.recoverActive())?.revision, 1);
      expect(store.recoveryDiagnostics, hasLength(1));
      expect(
        store.recoveryDiagnostics.single.code,
        'corrupt_latest_snapshot_fallback',
      );
    },
  );

  test(
    'complete interrupted pending generation wins over older active',
    () async {
      await store.save(session(1));
      final first = box.get('activeSession');
      await store.save(session(2));
      final second = box.get('activeSession');
      await box.putAll({
        'activeSession': first,
        'previousCommittedSession': first,
        'pendingSessionWrite': second,
      });

      expect(
        store.pendingWriteState,
        TripTrackingPendingWriteState.interrupted,
      );
      expect(store.activeSession?.revision, 2);
      expect((await store.recoverActive())?.revision, 2);
    },
  );
}
