import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'active GPS session survives local serialization and can be cleared',
    () async {
      final store = TripTrackingSessionStore.memory();
      final session = TripTrackingSessionRecord(
        id: 'trip_1',
        vehicleId: 'vehicle_work_truck_1',
        startingOdometer: 120000,
        profile: TripTrackingProfile.lowSpeedEquipment,
        startedAt: DateTime.utc(2026, 7, 12, 12),
        updatedAt: DateTime.utc(2026, 7, 12, 12, 5),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 804.672,
          walkingReviewSuggested: false,
        ),
      );

      await store.save(session);

      expect(store.activeSession?.vehicleId, 'vehicle_work_truck_1');
      expect(
        store.activeSession?.profile,
        TripTrackingProfile.lowSpeedEquipment,
      );
      expect(store.activeSession?.engineSnapshot.totalAcceptedMeters, 804.672);
      expect(store.activeSession?.schemaVersion, 1);
      expect(store.activeSession?.engineSnapshot.algorithmVersion, 'gps-v1');

      await store.clear();
      expect(store.activeSession, isNull);
    },
  );

  test('a pending GPS sample is local, bounded, and removable', () async {
    final store = TripTrackingSessionStore.memory();
    final pending = TripTrackingPendingSample(
      sessionId: 'trip_2',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: DateTime.utc(2026, 7, 12, 12),
        horizontalAccuracyMeters: 5,
      ),
    );

    await store.savePending(pending);
    expect(store.pendingSampleFor('trip_2')?.sample.latitude, 35);
    await store.clearPending('trip_2');
    expect(store.pendingSampleFor('trip_2'), isNull);
  });

  test('malformed pending samples are isolated instead of fabricated', () {
    expect(
      TripTrackingPendingSample.tryFromMap({
        'sessionId': 'trip_3',
        'sample': {'latitude': 35},
      }),
      isNull,
    );
  });

  test('legacy GPS records receive safe persistence defaults', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'legacy',
      'vehicleId': 'vehicle_1',
      'engineSnapshot': {'totalAcceptedMeters': 0},
    });

    expect(session.schemaVersion, 1);
    expect(session.engineSnapshot.schemaVersion, 1);
    expect(session.engineSnapshot.algorithmVersion, 'gps-v1');
  });
}
