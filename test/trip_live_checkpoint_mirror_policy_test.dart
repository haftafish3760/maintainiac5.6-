import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_checkpoint_durability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_checkpoint_mirror_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sync_reservation_commit_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test(
    'ready durability and sync attempt produce redacted checkpoint mirror',
    () {
      final sync = syncAttempt(now: now);
      final durability = durabilityDecision(now: now, sync: sync);
      final decision = TripLiveCheckpointMirrorPolicy.evaluate(
        durability: durability,
        syncAttempt: sync,
      );
      final payload = decision.payload;
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripLiveCheckpointMirrorStatus.ready);
      expect(decision.mayMirrorLiveCheckpoint, isTrue);
      expect(payload['schema'], 'trip_live_checkpoint_mirror_v1');
      expect(payload['recordId'], 'trip123');
      expect(payload['canonicalSource'], 'hive');
      expect(payload['firestoreRole'], 'mirror_after_local_write');
      expect(payload['deviceIdMatchesLocalRecord'], isTrue);
      expect(payload['tripDayKeyValidated'], isTrue);
      expect(payload['localRevisionMonotonic'], isTrue);
      expect(payload['canOverrideLocalDaytimeData'], isFalse);
      expect(payload['canDeleteLocalData'], isFalse);
      expect(payload['remoteCheckpointCanResolveConflictSilently'], isFalse);
      expect(payload['checkpointMirrorRequiresLocalAckBeforeCleanup'], isTrue);
      expect(payload['localTombstoneBlocksCheckpointMirror'], isTrue);
      expect(payload['remoteCheckpointCannotAdvanceLocalRevision'], isTrue);
      expect(payload['odometerIsGlobalTruth'], isTrue);
      expect(payload['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(payload['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(payload['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(payload['mirrorCanApplyCalibration'], isFalse);
      expect(payload['mirrorCanCreateCalibrationProof'], isFalse);
      expect(payload['mirrorCanCreateOfficialMileage'], isFalse);
      expect(payload['mirrorCanSetGlobalTruth'], isFalse);
      expect(payload['mirrorCanChangeOfficialMileage'], isFalse);
      expect(payload['mirrorCanApplyCalibrationAsGlobalTruth'], isFalse);
      expect(payload['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(payload['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(
        payload['poorGpsCalibrationDaysCanUploadAsCalibrationProof'],
        isFalse,
      );
      expect(payload['rawGpsIncluded'], isFalse);
      expect(payload['preciseLocationIncluded'], isFalse);
      expect(payload['routeGeometryIncluded'], isFalse);
      expect(payload['mapboxDataIncluded'], isFalse);
      expect(payload['tokensIncluded'], isFalse);
      expect(payload.values, isNot(contains('owner123')));
      expect(payload.values, isNot(contains('device123')));
      expect(safe['backupFailureCanDropCurrentCheckpoint'], isFalse);
      expect(safe['checkpointRequiresDeviceMatch'], isTrue);
      expect(safe['checkpointRequiresDayKeyMatch'], isTrue);
      expect(safe['checkpointRequiresMonotonicLocalRevision'], isTrue);
      expect(safe['authenticationAloneAuthorizesCheckpointMirror'], isFalse);
    },
  );

  test('local checkpoint write requirement blocks mirror upload', () {
    final sync = syncAttempt(now: now);
    final durability = durabilityDecision(
      now: now,
      sync: sync,
      localWriteSucceeded: false,
    );
    final decision = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durability,
      syncAttempt: sync,
    );

    expect(decision.status, TripLiveCheckpointMirrorStatus.blockedDurability);
    expect(decision.mayMirrorLiveCheckpoint, isFalse);
    expect(decision.payload, isEmpty);
  });

  test('free quota block prevents checkpoint mirror payload', () {
    final sync = syncAttempt(now: now, used: 6);
    final durability = durabilityDecision(now: now, sync: sync);
    final decision = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durability,
      syncAttempt: sync,
    );

    expect(decision.status, TripLiveCheckpointMirrorStatus.blockedDurability);
    expect(decision.payload, isEmpty);
  });

  test('malformed mirror payload shape is rejected before upload', () {
    final sync = TripTrackingSyncAttemptDecision(
      status: TripTrackingSyncAttemptStatus.ready,
      accountTier: TripTrackingSyncAccountTier.paid,
      sourceValid: true,
      ownerValid: true,
      revisionFresh: true,
      syncDecision: syncAttempt(now: now).syncDecision,
      freeSyncsRemainingBeforeAttempt: null,
      mirrorPayload: const {
        'schemaVersion': 1,
        'recordId': 'bad:id',
        'kind': 'liveTrip',
        'updatedAtUtc': '2026-07-18T12:00:00.000Z',
        'localRevision': 1,
        'localPersisted': true,
        'canonicalSource': 'hive',
        'firestoreRole': 'mirror',
        'canOverrideLocalDaytimeData': false,
        'canDeleteLocalData': false,
        'odometerRemainsOfficialMileageTruth': true,
      },
    );
    final durability = durabilityDecision(now: now, sync: sync);
    final decision = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durability,
      syncAttempt: sync,
    );

    expect(decision.status, TripLiveCheckpointMirrorStatus.blockedPayloadShape);
    expect(decision.reasonCode, 'live_checkpoint_payload_shape_rejected');
    expect(decision.payload, isEmpty);
  });

  test('mirror payload rejects malformed updated timestamps', () {
    final base = syncAttempt(now: now).mirrorPayload;
    final sync = TripTrackingSyncAttemptDecision(
      status: TripTrackingSyncAttemptStatus.ready,
      accountTier: TripTrackingSyncAccountTier.paid,
      sourceValid: true,
      ownerValid: true,
      revisionFresh: true,
      syncDecision: syncAttempt(now: now).syncDecision,
      freeSyncsRemainingBeforeAttempt: null,
      mirrorPayload: {
        ...base,
        'updatedAtUtc': 'tomorrow near 35.123456,-80.123456',
      },
    );
    final decision = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durabilityDecision(now: now, sync: sync),
      syncAttempt: sync,
    );

    expect(decision.status, TripLiveCheckpointMirrorStatus.blockedPayloadShape);
    expect(decision.payload, isEmpty);
  });

  test('safe dashboard summary denies remote checkpoint authority', () {
    final sync = syncAttempt(now: now);
    final safe = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durabilityDecision(now: now, sync: sync),
      syncAttempt: sync,
    ).toSafeDashboardMap();

    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
    expect(safe['remoteBackupCanDeleteLocalData'], isFalse);
    expect(safe['remoteCheckpointCanResolveConflictSilently'], isFalse);
    expect(safe['checkpointMirrorRequiresLocalAckBeforeCleanup'], isTrue);
    expect(safe['localTombstoneBlocksCheckpointMirror'], isTrue);
    expect(safe['remoteCheckpointCannotAdvanceLocalRevision'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['mirrorCanConfirmOdometer'], isFalse);
    expect(safe['mirrorCanSetGlobalTruth'], isFalse);
    expect(safe['mirrorCanChangeOfficialMileage'], isFalse);
    expect(safe['mirrorCanApplyCalibration'], isFalse);
    expect(safe['mirrorCanCreateCalibrationProof'], isFalse);
    expect(safe['mirrorCanCreateOfficialMileage'], isFalse);
    expect(safe['mirrorCanApplyCalibrationAsGlobalTruth'], isFalse);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['mapboxCanCreateCheckpoint'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('safe checkpoint mirror summary validates render boundary', () {
    final sync = syncAttempt(now: now);
    final safe = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durabilityDecision(now: now, sync: sync),
      syncAttempt: sync,
    ).toSafeDashboardMap();

    final validation = TripLiveCheckpointMirrorSummaryValidation.fromSummary(
      safe,
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged checkpoint summary cannot gain auth-only authority', () {
    final sync = syncAttempt(now: now);
    final safe =
        TripLiveCheckpointMirrorPolicy.evaluate(
          durability: durabilityDecision(now: now, sync: sync),
          syncAttempt: sync,
        ).toSafeDashboardMap()..addAll({
          'checkpointRequiresDeviceMatch': false,
          'checkpointRequiresDayKeyMatch': false,
          'checkpointRequiresMonotonicLocalRevision': false,
          'authenticationAloneAuthorizesCheckpointMirror': true,
        });

    final validation = TripLiveCheckpointMirrorSummaryValidation.fromSummary(
      safe,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('checkpoint_upload_boundary_missing'));
  });

  test('forged checkpoint summary cannot mutate local trip truth', () {
    final sync = syncAttempt(now: now);
    final safe =
        TripLiveCheckpointMirrorPolicy.evaluate(
          durability: durabilityDecision(now: now, sync: sync),
          syncAttempt: sync,
        ).toSafeDashboardMap()..addAll({
          'remoteBackupCanOverrideLocalDay': true,
          'remoteBackupCanDeleteLocalData': true,
          'remoteCheckpointCanResolveConflictSilently': true,
          'checkpointMirrorRequiresLocalAckBeforeCleanup': false,
          'localTombstoneBlocksCheckpointMirror': false,
          'remoteCheckpointCannotAdvanceLocalRevision': false,
          'backupFailureCanStopGpsTracking': true,
          'backupFailureCanDropCurrentCheckpoint': true,
          'mirrorCanConfirmOdometer': true,
          'mirrorCanSetGlobalTruth': true,
          'mirrorCanChangeOfficialMileage': true,
          'mirrorCanCreateStop': true,
          'mirrorCanEndTripAutomatically': true,
          'odometerIsGlobalTruth': false,
          'mirrorCanApplyCalibration': true,
          'mirrorCanCreateCalibrationProof': true,
          'mirrorCanCreateOfficialMileage': true,
          'mirrorCanApplyCalibrationAsGlobalTruth': true,
          'calibrationRequiresTrustedGpsWindow': false,
          'poorGpsDaysExcludedFromCalibration': false,
          'mapboxCanCreateCheckpoint': true,
          'payloadContainsRawGps': true,
          'payloadContainsPreciseLocation': true,
          'payloadContainsRouteGeometry': true,
          'payloadContainsMapboxData': true,
          'tokensIncluded': true,
          'debug': 'sk.secret 35.123456,-80.123456',
        });

    final validation = TripLiveCheckpointMirrorSummaryValidation.fromSummary(
      safe,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('checkpoint_local_truth_boundary_missing'),
    );
    expect(validation.reasons, contains('checkpoint_claims_trip_authority'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_checkpoint_material'),
    );
  });

  test('checkpoint mirror summary rejects status authority mismatch', () {
    final sync = syncAttempt(now: now);
    final ready = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durabilityDecision(now: now, sync: sync),
      syncAttempt: sync,
    ).toSafeDashboardMap();
    final blocked = TripLiveCheckpointMirrorPolicy.evaluate(
      durability: durabilityDecision(
        now: now,
        sync: sync,
        localWriteSucceeded: false,
      ),
      syncAttempt: sync,
    ).toSafeDashboardMap();

    final forgedReady = TripLiveCheckpointMirrorSummaryValidation.fromSummary({
      ...ready,
      'mayMirrorLiveCheckpoint': false,
    });
    final forgedBlocked = TripLiveCheckpointMirrorSummaryValidation.fromSummary(
      {...blocked, 'mayMirrorLiveCheckpoint': true},
    );

    expect(forgedReady.isRenderable, isFalse);
    expect(forgedBlocked.isRenderable, isFalse);
    expect(
      forgedReady.reasons,
      contains('checkpoint_mirror_status_conflicts_with_authority'),
    );
    expect(
      forgedBlocked.reasons,
      contains('checkpoint_mirror_status_conflicts_with_authority'),
    );
  });
}

TripTrackingSyncAttemptDecision syncAttempt({
  required DateTime now,
  int? used = 0,
}) {
  return TripTrackingSyncAttemptGuard.evaluate(
    TripTrackingSyncAttemptRequest(
      accountTier: TripTrackingSyncAccountTier.free,
      authenticatedUid: 'owner123',
      source: TripTrackingSyncSourceRecord(
        schemaVersion: 1,
        recordId: 'trip123',
        ownerUid: 'owner123',
        deviceId: 'device123',
        kind: TripTrackingSyncSourceKind.liveTrip,
        updatedAtUtc: now,
        localRevision: 1,
        localPersisted: true,
        tripDayKey: '2026-07-18',
        distanceMiles: 12,
      ),
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: used,
      storageAvailableForSmallRecordWrite: true,
    ),
  );
}

TripLiveCheckpointDurabilityDecision durabilityDecision({
  required DateTime now,
  required TripTrackingSyncAttemptDecision sync,
  bool localWriteSucceeded = true,
}) {
  final reservation = TripSyncReservationCommitPolicy.evaluate(
    attemptDecision: sync,
    reservationWriteSucceeded: true,
  );
  return TripLiveCheckpointDurabilityPolicy.evaluate(
    lifecycle: TripTrackingSessionLifecycleState.active,
    localSessionAvailable: true,
    checkpointShapeValid: true,
    localWriteSucceeded: localWriteSucceeded,
    userBackupEnabled: true,
    syncAttempt: sync,
    reservation: reservation,
    nowUtc: now,
  );
}
