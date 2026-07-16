import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

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

  test(
    'does not claim an active trip checkpoint when storage is full',
    () async {
      final store = TripTrackingSessionStore.memory(
        storageCheck: () async => const AppStorageCheck(
          availableBytes: 0,
          operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
          requiredBytes: AppStorageGuard.mileageTrackingWriteBytes,
          purpose: AppStoragePurpose.mileageTracking,
        ),
      );
      final session = TripTrackingSessionRecord(
        id: 'trip_storage_full',
        vehicleId: 'vehicle_1',
        startingOdometer: 1,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
      );

      await expectLater(store.save(session), throwsStateError);
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

    expect(
      TripTrackingPendingSample.tryFromMap({
        'sessionId': 'trip_out_of_range',
        'sample': {
          'latitude': 91,
          'longitude': -80,
          'recordedAt': DateTime.utc(2026, 7, 14).toIso8601String(),
          'horizontalAccuracyMeters': 5,
        },
      }),
      isNull,
    );
  });

  test('pending recovery preserves the native mock-location flag', () {
    final sample = TripLocationSample(
      latitude: 35,
      longitude: -80,
      recordedAt: DateTime.utc(2026, 7, 12, 12),
      horizontalAccuracyMeters: 5,
      mockedLocation: true,
    );

    final recovered = TripTrackingPendingSample.tryFromMap(
      TripTrackingPendingSample(
        sessionId: 'trip_mock_recovery',
        sample: sample,
      ).toMap(),
    );

    expect(recovered?.sample.mockedLocation, isTrue);
  });

  test('legacy GPS records receive safe persistence defaults', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'legacy',
      'vehicleId': 'vehicle_1',
      'engineSnapshot': {'totalAcceptedMeters': 0},
    });

    expect(session.schemaVersion, 1);
    expect(session.hasValidTimeline, isFalse);
    expect(session.engineSnapshot.schemaVersion, 1);
    expect(session.engineSnapshot.algorithmVersion, 'gps-v1');
  });

  test('review cloud sync state survives local serialization', () {
    final syncedAt = DateTime.utc(2026, 7, 14, 13, 5);
    final review = TripTrackingReviewRecord(
      id: 'trip_sync_state',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1012,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 19312,
        walkingReviewSuggested: false,
      ),
      cloudSyncState: TripTrackingCloudSyncState.synced,
      cloudAccountUid: 'firebaseUid-1',
      cloudBackupScope: TripTrackingCloudBackupScope.organization,
      cloudOrganizationId: 'org-1',
      cloudSyncedAt: syncedAt,
      confirmedEndingOdometer: 1013,
      odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 6),
    );

    final recovered = TripTrackingReviewRecord.fromMap(review.toMap());

    expect(recovered.cloudSyncState, TripTrackingCloudSyncState.synced);
    expect(recovered.cloudAccountUid, 'firebaseUid-1');
    expect(
      recovered.cloudBackupScope,
      TripTrackingCloudBackupScope.organization,
    );
    expect(recovered.cloudOrganizationId, 'org-1');
    expect(recovered.cloudSyncError, isNull);
    expect(recovered.cloudSyncedAt, syncedAt);
    expect(recovered.confirmedEndingOdometer, 1013);
    expect(recovered.isOdometerConfirmed, isTrue);

    final invalidConfirmation = TripTrackingReviewRecord.fromMap({
      ...review.toMap(),
      'confirmedEndingOdometer': 999,
    });
    expect(invalidConfirmation.isOdometerConfirmed, isFalse);
  });

  test('malformed persisted odometer values cannot crash review recovery', () {
    final review = TripTrackingReviewRecord(
      id: 'trip_corrupt_odometer',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1010,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 100,
        walkingReviewSuggested: false,
      ),
    );

    final restored = TripTrackingReviewRecord.fromMap({
      ...review.toMap(),
      'startingOdometer': double.nan,
      'estimatedEndingOdometer': double.infinity,
      'confirmedEndingOdometer': double.nan,
      'odometerConfirmedAt': DateTime.utc(2026, 7, 14, 13, 1).toIso8601String(),
    });

    expect(restored.startingOdometer, isZero);
    expect(restored.estimatedEndingOdometer, isZero);
    expect(restored.confirmedEndingOdometer, isNull);
    expect(restored.isOdometerConfirmed, isFalse);
  });

  test('malformed active-trip odometer cannot crash session recovery', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'trip_corrupt_active_odometer',
      'vehicleId': 'vehicle_1',
      'startingOdometer': double.infinity,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 14, 13).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
    });

    expect(session.startingOdometer, isZero);
  });
}
