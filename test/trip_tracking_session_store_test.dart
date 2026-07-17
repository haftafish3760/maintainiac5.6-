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

  test('unknown persisted trip profiles are marked invalid', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'trip_unknown_profile',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': 'silentTracker',
      'startedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 12, 12, 5).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
    });
    final review = TripTrackingReviewRecord.fromMap({
      'id': 'trip_unknown_profile',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1001,
      'profile': 'silentTracker',
      'startedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
      'finishedAt': DateTime.utc(2026, 7, 12, 12, 5).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ).toMap(),
    });

    expect(session.hasValidTimeline, isFalse);
    expect(review.hasValidTimeline, isFalse);
  });

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

  test('active GPS session writes require safe trip and vehicle ids', () async {
    final store = TripTrackingSessionStore.memory();
    TripTrackingSessionRecord session({
      String id = 'trip_safe_identity',
      String vehicleId = 'vehicle_1',
    }) => TripTrackingSessionRecord(
      id: id,
      vehicleId: vehicleId,
      startingOdometer: 1,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 15),
      updatedAt: DateTime.utc(2026, 7, 15),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
    );

    await expectLater(
      store.save(session(id: ' trip_bad_key ')),
      throwsArgumentError,
    );
    await expectLater(
      store.save(session(vehicleId: 'vehicle_\nunsafe')),
      throwsArgumentError,
    );
    expect(store.activeSession, isNull);
  });

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
        'sessionId': '  ',
        'sample': {
          'latitude': 35,
          'longitude': -80,
          'recordedAt': DateTime.utc(2026, 7, 14).toIso8601String(),
          'horizontalAccuracyMeters': 5,
        },
      }),
      isNull,
    );

    expect(
      TripTrackingPendingSample.tryFromMap({
        'sessionId': 'trip_${'x' * 200}',
        'sample': {
          'latitude': 35,
          'longitude': -80,
          'recordedAt': DateTime.utc(2026, 7, 14).toIso8601String(),
          'horizontalAccuracyMeters': 5,
        },
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

  test('pending GPS sample writes require a safe trip id', () async {
    final store = TripTrackingSessionStore.memory();
    final pending = TripTrackingPendingSample(
      sessionId: ' trip_with_spaces ',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: DateTime.utc(2026, 7, 12, 12),
        horizontalAccuracyMeters: 5,
      ),
    );

    await expectLater(store.savePending(pending), throwsArgumentError);
    expect(store.pendingSampleFor(' trip_with_spaces '), isNull);
  });

  test(
    'pending GPS sample writes require valid coordinates and accuracy',
    () async {
      final store = TripTrackingSessionStore.memory();
      TripTrackingPendingSample pending({
        double latitude = 35,
        double longitude = -80,
        double accuracy = 5,
      }) => TripTrackingPendingSample(
        sessionId: 'trip_bad_sample',
        sample: TripLocationSample(
          latitude: latitude,
          longitude: longitude,
          recordedAt: DateTime.utc(2026, 7, 12, 12),
          horizontalAccuracyMeters: accuracy,
        ),
      );

      await expectLater(
        store.savePending(pending(latitude: 91)),
        throwsArgumentError,
      );
      await expectLater(
        store.savePending(pending(longitude: -181)),
        throwsArgumentError,
      );
      await expectLater(
        store.savePending(pending(accuracy: 0)),
        throwsArgumentError,
      );
      expect(store.pendingSampleFor('trip_bad_sample'), isNull);
    },
  );

  test('unsafe pending GPS sample lookup keys are ignored', () {
    final store = TripTrackingSessionStore.memory();

    expect(store.pendingSampleFor(' trip_unsafe '), isNull);
    expect(store.pendingSampleFor('trip_\nunsafe'), isNull);
    expect(store.pendingSampleFor('trip_${'x' * 200}'), isNull);
  });

  test('unsafe pending GPS sample keys are ignored on clear', () async {
    final store = TripTrackingSessionStore.memory();
    final pending = TripTrackingPendingSample(
      sessionId: 'trip_unsafe_clear',
      sample: TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: DateTime.utc(2026, 7, 12, 12),
        horizontalAccuracyMeters: 5,
      ),
    );

    await store.savePending(pending);
    await store.clearPending(' trip_unsafe_clear ');

    expect(store.pendingSampleFor('trip_unsafe_clear'), isNotNull);
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

  test('persisted GPS samples do not write non-finite speed values', () {
    final sample = TripLocationSample(
      latitude: 35,
      longitude: -80,
      recordedAt: DateTime.utc(2026, 7, 12, 12),
      horizontalAccuracyMeters: 5,
      speedMetersPerSecond: double.nan,
    );

    final map = sample.toMap();

    expect(map['speedMetersPerSecond'], isNull);
    expect(TripLocationSample.tryFromMap(map)?.speedMetersPerSecond, isNull);
  });

  test('malformed GPS and activity numeric fields are isolated', () {
    expect(
      TripLocationSample.tryFromMap({
        'latitude': '35.0',
        'longitude': -80,
        'recordedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
        'horizontalAccuracyMeters': 5,
      }),
      isNull,
    );

    expect(
      TripLocationSample.tryFromMap({
        'latitude': 35,
        'longitude': -80,
        'recordedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
        'horizontalAccuracyMeters': 'accurate',
      }),
      isNull,
    );

    expect(
      TripActivityObservation.tryFromMap({
        'activity': 'walking',
        'confidence': 'high',
        'recordedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
      }),
      isNull,
    );
  });

  test('persisted engine snapshots do not write invalid accepted distance', () {
    const snapshot = TripTrackingEngineSnapshot(
      totalAcceptedMeters: double.negativeInfinity,
      walkingReviewSuggested: false,
    );

    final map = snapshot.toMap();

    expect(map['totalAcceptedMeters'], 0);
    expect(TripTrackingEngineSnapshot.fromMap(map).totalAcceptedMeters, 0);
  });

  test('persisted trip diagnostics sanitize impossible counters', () {
    const diagnostics = TripTrackingDiagnostics(
      receivedSamples: 2,
      acceptedSamples: 5,
      dispositionCounts: {
        TripSampleDisposition.acceptedAnchor: 1,
        TripSampleDisposition.rejectedAccuracy: -4,
      },
    );

    final map = diagnostics.toMap();
    final counts = map['dispositionCounts'] as Map<String, Object?>;

    expect(map['receivedSamples'], 2);
    expect(map['acceptedSamples'], 0);
    expect(counts, containsPair('acceptedAnchor', 1));
    expect(counts, isNot(contains('rejectedAccuracy')));
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

  test('unknown persisted active trip lifecycle fields are not trusted', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'trip_bad_lifecycle',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 14, 12, 1).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'lifecycleState': 'ghostTracking',
      'healthState': 'healthy',
    });

    expect(session.lifecycleState, TripTrackingSessionLifecycleState.ready);
    expect(session.hasValidTimeline, isFalse);
  });

  test('non-finite persisted schema versions use safe defaults', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'trip_schema_nan',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 14, 12, 1).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'schemaVersion': double.nan,
    });
    final review = TripTrackingReviewRecord.fromMap({
      'id': 'trip_review_schema_nan',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1001,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'finishedAt': DateTime.utc(2026, 7, 14, 12, 10).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ).toMap(),
      'schemaVersion': double.infinity,
    });

    expect(session.schemaVersion, 1);
    expect(review.schemaVersion, 1);
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

  test('review writes require safe durable trip ids', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord(
      id: ' trip_bad_key ',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
    );

    await expectLater(store.saveReview(review), throwsArgumentError);
    expect(store.reviewForTrip(' trip_bad_key '), isNull);
  });

  test('review cloud sync metadata is bounded and token-safe', () {
    final review = TripTrackingReviewRecord(
      id: 'trip_sync_metadata_bounds',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
      cloudAccountUid: 'firebaseUid_1',
      cloudBackupScope: TripTrackingCloudBackupScope.organization,
      cloudOrganizationId: 'org-1',
      cloudSyncError: 'line one\n${'e' * 260}',
    );

    final restored = TripTrackingReviewRecord.fromMap(review.toMap());
    final unsafe = TripTrackingReviewRecord.fromMap({
      ...review.toMap(),
      'cloudAccountUid': 'firebase uid/../unsafe',
      'cloudOrganizationId': 'org id/../unsafe',
    });

    expect(restored.cloudAccountUid, 'firebaseUid_1');
    expect(restored.cloudOrganizationId, 'org-1');
    expect(restored.cloudSyncError, hasLength(240));
    expect(restored.cloudSyncError, isNot(contains('\n')));
    expect(unsafe.cloudAccountUid, isNull);
    expect(unsafe.cloudOrganizationId, isNull);
  });

  test('unknown persisted cloud backup scope is not trusted', () {
    final review = TripTrackingReviewRecord(
      id: 'trip_unknown_scope',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
    );

    final restored = TripTrackingReviewRecord.fromMap({
      ...review.toMap(),
      'cloudBackupScope': 'fleetGodMode',
      'cloudOrganizationId': 'org-1',
    });

    expect(restored.cloudBackupScope, isNull);
    expect(restored.cloudOrganizationId, isNull);
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

  test('persisted GPS trip records never write negative odometers', () {
    final session = TripTrackingSessionRecord(
      id: 'trip_negative_session_odometer',
      vehicleId: 'vehicle_1',
      startingOdometer: -50,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      updatedAt: DateTime.utc(2026, 7, 14, 12, 1),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
    );
    final review = TripTrackingReviewRecord(
      id: 'trip_negative_review_odometer',
      vehicleId: 'vehicle_1',
      startingOdometer: -100,
      estimatedEndingOdometer: -90,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
      confirmedEndingOdometer: -80,
      odometerConfirmedAt: DateTime.utc(2026, 7, 14, 13, 5),
    );

    final sessionMap = session.toMap();
    final reviewMap = review.toMap();

    expect(sessionMap['startingOdometer'], isZero);
    expect(reviewMap['startingOdometer'], isZero);
    expect(reviewMap['estimatedEndingOdometer'], isZero);
    expect(reviewMap, isNot(contains('confirmedEndingOdometer')));
  });

  test('persisted GPS session identities are trimmed and bounded', () {
    final session = TripTrackingSessionRecord(
      id: ' ${'s' * 220} ',
      vehicleId: ' ${'v' * 220} ',
      startingOdometer: 1000,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      updatedAt: DateTime.utc(2026, 7, 14, 12, 1),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
    );
    final review = TripTrackingReviewRecord.fromMap({
      'id': ' ${'r' * 220} ',
      'vehicleId': ' ${'truck' * 60} ',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1001,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'finishedAt': DateTime.utc(2026, 7, 14, 13).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ).toMap(),
    });

    final sessionMap = session.toMap();

    expect(sessionMap['id'], hasLength(160));
    expect(sessionMap['vehicleId'], hasLength(160));
    expect(review.id, hasLength(160));
    expect(review.vehicleId, hasLength(160));
  });

  test('persisted GPS advisory text fields are trimmed and bounded', () {
    final advisory = TripTrackingAdvisoryEvent.fromMap({
      'id': ' ${'a' * 220} ',
      'type': 'probableStop',
      'sessionId': ' ${'s' * 220} ',
      'vehicleId': ' ${'v' * 220} ',
      'profile': 'roadVehicle',
      'detectedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'evidenceStartedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'evidenceEndedAt': DateTime.utc(2026, 7, 14, 12, 1).toIso8601String(),
      'confidence': 'high',
      'suggestedAction': 'review\n${'x' * 180}',
      'tripLogReference': ' ${'t' * 220} ',
    });
    final map = advisory.toMap();

    expect(map['id'], hasLength(160));
    expect(map['sessionId'], hasLength(160));
    expect(map['vehicleId'], hasLength(160));
    expect(map['suggestedAction'], hasLength(120));
    expect(map['suggestedAction'], isNot(contains('\n')));
    expect(map['tripLogReference'], hasLength(160));
  });

  test('malformed GPS advisory timestamps do not become current time', () {
    final advisory = TripTrackingAdvisoryEvent.fromMap({
      'id': 'advisory_bad_time',
      'type': 'probableStop',
      'sessionId': 'trip_bad_time',
      'vehicleId': 'vehicle_1',
      'profile': 'roadVehicle',
      'detectedAt': 'not-a-date',
      'evidenceStartedAt': 'also-bad',
      'evidenceEndedAt': double.nan,
      'confidence': 'medium',
      'suggestedAction': 'review',
    });

    expect(
      advisory.detectedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(advisory.evidenceStartedAt, advisory.detectedAt);
    expect(advisory.evidenceEndedAt, advisory.detectedAt);
  });

  test('persisted GPS advisories keep only a bounded recent window', () {
    final session = TripTrackingSessionRecord(
      id: 'trip_many_advisories',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      updatedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
      advisories: [
        for (var i = 0; i < 40; i++)
          TripTrackingAdvisoryEvent(
            id: 'advisory_$i',
            type: TripTrackingAdvisoryType.probableStop,
            sessionId: 'trip_many_advisories',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.roadVehicle,
            detectedAt: DateTime.utc(2026, 7, 14, 12, i),
            evidenceStartedAt: DateTime.utc(2026, 7, 14, 12, i),
            evidenceEndedAt: DateTime.utc(2026, 7, 14, 12, i, 30),
            confidence: TripTrackingConfidence.medium,
            suggestedAction: 'review',
          ),
      ],
    );

    final map = session.toMap();
    final restored = TripTrackingSessionRecord.fromMap(map);

    expect(map['advisories'], hasLength(24));
    expect(restored.advisories, hasLength(24));
    expect(restored.advisories.first.id, 'advisory_16');
  });

  test('persisted review identity and odometer ranges are validated', () {
    final base = TripTrackingReviewRecord(
      id: 'trip_review_identity',
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
    ).toMap();

    expect(
      TripTrackingReviewRecord.fromMap({...base, 'id': '   '}).hasValidTimeline,
      isFalse,
    );
    expect(
      TripTrackingReviewRecord.fromMap({
        ...base,
        'vehicleId': '   ',
      }).hasValidTimeline,
      isFalse,
    );
    expect(
      TripTrackingReviewRecord.fromMap({
        ...base,
        'estimatedEndingOdometer': 999,
      }).hasValidTimeline,
      isFalse,
    );
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

  test('negative persisted active-trip odometers recover safely', () {
    final session = TripTrackingSessionRecord.fromMap({
      'id': 'trip_negative_active_odometer',
      'vehicleId': 'vehicle_1',
      'startingOdometer': -120,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 14, 13).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
    });
    final review = TripTrackingReviewRecord.fromMap({
      'id': 'trip_negative_review_recovery',
      'vehicleId': 'vehicle_1',
      'startingOdometer': -10,
      'estimatedEndingOdometer': -5,
      'confirmedEndingOdometer': -1,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 14, 12).toIso8601String(),
      'finishedAt': DateTime.utc(2026, 7, 14, 13).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
    });

    expect(session.startingOdometer, isZero);
    expect(review.startingOdometer, isZero);
    expect(review.estimatedEndingOdometer, isZero);
    expect(review.confirmedEndingOdometer, isNull);
  });
}
