import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_offline_sync_replay_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sync_reservation_commit_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 8);

  TripTrackingSyncAttemptDecision attempt({
    int? used = 0,
    bool wifi = true,
    bool storageAvailable = true,
    bool localPersisted = true,
    String owner = 'owner123',
    String auth = 'owner123',
  }) {
    return TripTrackingSyncAttemptGuard.evaluate(
      TripTrackingSyncAttemptRequest(
        accountTier: TripTrackingSyncAccountTier.free,
        authenticatedUid: auth,
        source: TripTrackingSyncSourceRecord(
          schemaVersion: 1,
          recordId: 'trip123',
          ownerUid: owner,
          deviceId: 'device123',
          kind: TripTrackingSyncSourceKind.reviewedMileage,
          updatedAtUtc: now,
          localRevision: 1,
          localPersisted: localPersisted,
          tripDayKey: '2026-07-18',
          distanceMiles: 42,
        ),
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
        wifiAvailable: wifi,
        mobileDataAvailable: false,
        syncsUsedInWindow: used,
        storageAvailableForSmallRecordWrite: storageAvailable,
      ),
    );
  }

  TripSyncReservationCommitDecision reservation(
    TripTrackingSyncAttemptDecision attempt, {
    bool success = true,
  }) {
    return TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt,
      reservationWriteSucceeded: success,
    );
  }

  TripOfflineSyncReplayDecision evaluate({
    TripTrackingSyncAttemptDecision? sync,
    TripSyncReservationCommitDecision? reserve,
    bool exists = true,
    bool wantsBackup = true,
  }) {
    final current = sync ?? attempt();
    return TripOfflineSyncReplayPolicy.evaluate(
      attempt: current,
      reservation: reserve ?? reservation(current),
      queuedRecordStillExistsLocally: exists,
      userStillWantsBackup: wantsBackup,
    );
  }

  test('ready replay keeps local queue and consumes reserved free attempt', () {
    final decision = evaluate();

    expect(decision.status, TripOfflineSyncReplayStatus.ready);
    expect(decision.canReplayQueuedMirror, isTrue);
    expect(decision.shouldKeepLocalQueue, isTrue);
    expect(decision.consumesFreeAttempt, isTrue);
  });

  test('network and quota delays keep local queue for retry', () {
    final network = evaluate(sync: attempt(wifi: false));
    final quota = evaluate(sync: attempt(used: 6));

    expect(network.status, TripOfflineSyncReplayStatus.waitingForNetwork);
    expect(network.shouldRetryLater, isTrue);
    expect(network.shouldKeepLocalQueue, isTrue);
    expect(quota.status, TripOfflineSyncReplayStatus.waitingForQuota);
    expect(quota.canReplayQueuedMirror, isFalse);
  });

  test(
    'reservation failure waits without consuming quota or deleting queue',
    () {
      final sync = attempt();
      final decision = evaluate(
        sync: sync,
        reserve: reservation(sync, success: false),
      );

      expect(
        decision.status,
        TripOfflineSyncReplayStatus.waitingForReservation,
      );
      expect(decision.reasonCode, 'offline_replay_reservation_retry');
      expect(decision.consumesFreeAttempt, isFalse);
      expect(decision.shouldKeepLocalQueue, isTrue);
    },
  );

  test('storage blocked replay keeps local queue for later retry', () {
    final decision = evaluate(sync: attempt(storageAvailable: false));

    expect(decision.status, TripOfflineSyncReplayStatus.waitingForStorage);
    expect(decision.reasonCode, 'offline_replay_waiting_for_storage');
    expect(decision.canReplayQueuedMirror, isFalse);
    expect(decision.shouldKeepLocalQueue, isTrue);
    expect(decision.shouldRetryLater, isTrue);
    expect(decision.consumesFreeAttempt, isFalse);
    expect(
      decision.toSafeSummary()['successfulReplayCanSilentlyDeleteLocalData'],
      isFalse,
    );
  });

  test('invalid local record or owner mismatch blocks replay closed', () {
    final missing = evaluate(exists: false);
    final ownerMismatch = evaluate(sync: attempt(auth: 'other'));

    expect(missing.status, TripOfflineSyncReplayStatus.blockedInvalidRecord);
    expect(missing.canReplayQueuedMirror, isFalse);
    expect(
      ownerMismatch.status,
      TripOfflineSyncReplayStatus.blockedInvalidRecord,
    );
  });

  test('safe summary denies deletion, override, raw payloads, and tokens', () {
    final safe = evaluate().toSafeSummary();

    expect(safe['replayRequiresValidatedLocalRecord'], isTrue);
    expect(safe['replayRequiresDeviceMatch'], isTrue);
    expect(safe['replayRequiresDayKeyMatch'], isTrue);
    expect(safe['replayRequiresMonotonicLocalRevision'], isTrue);
    expect(safe['replayRequiresLocalDurableCheckpoint'], isTrue);
    expect(safe['replayRequiresSameBackupPreference'], isTrue);
    expect(safe['replayRequiresFreshReservationAttempt'], isTrue);
    expect(safe['authenticationAloneAuthorizesReplay'], isFalse);
    expect(safe['failedReplayCanDeleteLocalQueue'], isFalse);
    expect(safe['successfulReplayCanSilentlyDeleteLocalData'], isFalse);
    expect(safe['replaySuccessRequiresExplicitQueueCleanup'], isTrue);
    expect(safe['replayCannotUploadIfLocalRecordDisappears'], isTrue);
    expect(safe['replayCannotUploadAfterBackupOptOut'], isTrue);
    expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
    expect(safe['remoteReplayCanReviveDeletedLocalTrip'], isFalse);
    expect(safe['remoteReplayCanAdvanceLocalRevision'], isFalse);
    expect(safe['remoteReplayCanChangeOdometer'], isFalse);
    expect(safe['remoteReplayCanCreateStops'], isFalse);
    expect(safe['cloudFunctionCanReplayWithoutLocalQueue'], isFalse);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['rawTripPayloadIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('safe replay summary validates local-first replay boundary', () {
    final validation = TripOfflineSyncReplaySummaryValidation.fromSummary(
      evaluate().toSafeSummary(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged replay summaries cannot delete, override, or leak data', () {
    final validation = TripOfflineSyncReplaySummaryValidation.fromSummary(
      evaluate().toSafeSummary()..addAll({
        'replayRequiresValidatedLocalRecord': false,
        'replayRequiresOwnershipCheck': false,
        'replayRequiresDeviceMatch': false,
        'replayRequiresDayKeyMatch': false,
        'replayRequiresMonotonicLocalRevision': false,
        'replayRequiresLocalDurableCheckpoint': false,
        'replayRequiresSameBackupPreference': false,
        'replayRequiresFreshReservationAttempt': false,
        'authenticationAloneAuthorizesReplay': true,
        'freeReplayRequiresReservationBeforeUpload': false,
        'replayCannotUploadIfLocalRecordDisappears': false,
        'replayCannotUploadAfterBackupOptOut': false,
        'failedReplayCanDeleteLocalQueue': true,
        'successfulReplayCanSilentlyDeleteLocalData': true,
        'successfulReplayCanPurgeLocalDaytimeData': true,
        'remoteConflictCanSilentlyWin': true,
        'remoteReplayCanReviveDeletedLocalTrip': true,
        'remoteReplayCanAdvanceLocalRevision': true,
        'remoteReplayCanChangeOdometer': true,
        'remoteReplayCanCreateStops': true,
        'replaySuccessRequiresExplicitQueueCleanup': false,
        'remoteBackupCanOverrideLocalDay': true,
        'firestoreMirrorOnly': false,
        'hiveRemainsOperationalSourceOfTruth': false,
        'odometerRemainsOfficialMileageTruth': false,
        'mapboxCanReplaySyncQueue': true,
        'mapboxCanRepairReplayRecords': true,
        'mapboxCanFillReplayGaps': true,
        'cloudFunctionCanReplayWithoutLocalQueue': true,
        'rawTripPayloadIncluded': true,
        'preciseLocationIncluded': true,
        'routeGeometryIncluded': true,
        'tokensIncluded': true,
        'debug': 'sk.secret 35.123456,-80.123456',
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('replay_upload_boundary_missing'));
    expect(validation.reasons, contains('remote_replay_can_mutate_local_data'));
    expect(validation.reasons, contains('source_of_truth_boundary_missing'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_replay_material'),
    );
  });

  test('forged replay summaries cannot use auth-only replay authority', () {
    final summary = evaluate().toSafeSummary()
      ..addAll({
        'replayRequiresDeviceMatch': false,
        'replayRequiresDayKeyMatch': false,
        'replayRequiresMonotonicLocalRevision': false,
        'authenticationAloneAuthorizesReplay': true,
      });

    final validation = TripOfflineSyncReplaySummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('replay_upload_boundary_missing'));
  });
}
