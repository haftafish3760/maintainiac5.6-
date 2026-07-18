import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_checkpoint_durability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sync_reservation_commit_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  TripTrackingSyncAttemptDecision syncAttempt({
    TripTrackingSyncAccountTier tier = TripTrackingSyncAccountTier.free,
    String owner = 'owner123',
    String auth = 'owner123',
    int? used = 0,
    bool localPersisted = true,
    bool storageOk = true,
  }) {
    return TripTrackingSyncAttemptGuard.evaluate(
      TripTrackingSyncAttemptRequest(
        accountTier: tier,
        authenticatedUid: auth,
        source: TripTrackingSyncSourceRecord(
          schemaVersion: 1,
          recordId: 'trip123',
          ownerUid: owner,
          deviceId: 'device123',
          kind: TripTrackingSyncSourceKind.liveTrip,
          updatedAtUtc: now,
          localRevision: 1,
          localPersisted: localPersisted,
          tripDayKey: '2026-07-18',
          distanceMiles: 12,
        ),
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: false,
        syncsUsedInWindow: used,
        storageAvailableForSmallRecordWrite: storageOk,
      ),
    );
  }

  TripSyncReservationCommitDecision reservation({
    required TripTrackingSyncAttemptDecision attempt,
    bool reservationWriteSucceeded = true,
  }) {
    return TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt,
      reservationWriteSucceeded: reservationWriteSucceeded,
    );
  }

  TripLiveCheckpointDurabilityDecision evaluate({
    TripTrackingSessionLifecycleState lifecycle =
        TripTrackingSessionLifecycleState.active,
    bool localSessionAvailable = true,
    bool checkpointShapeValid = true,
    bool localWriteSucceeded = true,
    bool backupEnabled = true,
    DateTime? lastWrite,
    bool highPriority = false,
    TripTrackingSyncAttemptDecision? attempt,
    TripSyncReservationCommitDecision? commit,
  }) {
    final sync = attempt ?? syncAttempt();
    return TripLiveCheckpointDurabilityPolicy.evaluate(
      lifecycle: lifecycle,
      localSessionAvailable: localSessionAvailable,
      checkpointShapeValid: checkpointShapeValid,
      localWriteSucceeded: localWriteSucceeded,
      userBackupEnabled: backupEnabled,
      syncAttempt: sync,
      reservation: commit ?? reservation(attempt: sync),
      lastLocalWriteAtUtc: lastWrite,
      nowUtc: now,
      highPriorityCheckpoint: highPriority,
    );
  }

  test('active trip writes local checkpoint before backup mirror', () {
    final decision = evaluate(localWriteSucceeded: false);

    expect(
      decision.status,
      TripLiveCheckpointDurabilityStatus.localWriteRequired,
    );
    expect(decision.shouldWriteLocalCheckpointNow, isTrue);
    expect(decision.mayUploadBackupMirror, isFalse);
  });

  test('backup becomes ready only after local write and reservation', () {
    final decision = evaluate();
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripLiveCheckpointDurabilityStatus.backupReady);
    expect(decision.shouldWriteLocalCheckpointNow, isFalse);
    expect(decision.mayUploadBackupMirror, isTrue);
    expect(safe['localCheckpointCanStoreWhileBackupDeferred'], isTrue);
    expect(safe['localCheckpointWriteHasPriorityOverBackup'], isTrue);
    expect(safe['localCheckpointRequiredBeforeBackup'], isTrue);
    expect(safe['backupMirrorRequiresMatchingLocalRevision'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
  });

  test('interval gate defers routine writes without dropping tracking', () {
    final decision = evaluate(
      lastWrite: now.subtract(const Duration(seconds: 4)),
    );

    expect(
      decision.status,
      TripLiveCheckpointDurabilityStatus.localWriteDeferred,
    );
    expect(decision.minimumNextLocalWriteSeconds, 6);
    expect(decision.mayUploadBackupMirror, isFalse);
  });

  test('high priority checkpoint bypasses interval debounce safely', () {
    final decision = evaluate(
      lastWrite: now.subtract(const Duration(seconds: 4)),
      highPriority: true,
    );

    expect(decision.status, TripLiveCheckpointDurabilityStatus.backupReady);
    expect(decision.mayUploadBackupMirror, isTrue);
  });

  test(
    'free quota or failed reservation defers backup without deleting local',
    () {
      final quotaAttempt = syncAttempt(used: 6);
      final quotaDecision = evaluate(
        attempt: quotaAttempt,
        commit: reservation(attempt: quotaAttempt),
      );
      final readyAttempt = syncAttempt();
      final failedReservation = evaluate(
        attempt: readyAttempt,
        commit: reservation(
          attempt: readyAttempt,
          reservationWriteSucceeded: false,
        ),
      );
      final safe = failedReservation.toSafeDashboardMap();

      expect(
        quotaDecision.status,
        TripLiveCheckpointDurabilityStatus.backupDeferred,
      );
      expect(quotaDecision.mayUploadBackupMirror, isFalse);
      expect(failedReservation.shouldRetryBackupLater, isTrue);
      expect(safe['backupFailureCanDropCurrentCheckpoint'], isFalse);
      expect(safe['remoteBackupCanDeleteLocalData'], isFalse);
      expect(safe['remoteBackupCanConfirmCheckpoint'], isFalse);
      expect(safe['remoteBackupCanSetGlobalTruth'], isFalse);
      expect(safe['remoteBackupCanChangeOfficialMileage'], isFalse);
      expect(safe['localCheckpointCanStoreWhileBackupDeferred'], isTrue);
      expect(safe['localCheckpointWriteHasPriorityOverBackup'], isTrue);
      expect(safe['localDaytimeDataNeverSilentlyOverwritten'], isTrue);
    },
  );

  test('invalid lifecycle or checkpoint boundary fails closed', () {
    final notActive = evaluate(
      lifecycle: TripTrackingSessionLifecycleState.completed,
    );
    final malformed = evaluate(checkpointShapeValid: false);

    expect(
      notActive.status,
      TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint,
    );
    expect(
      malformed.status,
      TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint,
    );
    expect(malformed.mayUploadBackupMirror, isFalse);
  });

  test(
    'safe summary never grants deletion, override, mapbox, or token access',
    () {
      final safe = evaluate().toSafeDashboardMap();

      expect(safe['checkpointPolicyCanDeleteLocalData'], isFalse);
      expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
      expect(safe['localDaytimeDataNeverSilentlyOverwritten'], isTrue);
      expect(safe['backupMirrorRequiresMatchingLocalRevision'], isTrue);
      expect(safe['lowStorageCanBlockTextCheckpointAboveReserve'], isFalse);
      expect(safe['odometerIsGlobalTruth'], isTrue);
      expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
      expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
      expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
      expect(safe['gpsDistanceCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['mapMatchingCanOnlyAdviseMileageReview'], isTrue);
      expect(safe['optimizationCannotChangeOfficialMileage'], isTrue);
      expect(safe['checkpointCanApplyCalibration'], isFalse);
      expect(safe['checkpointCanCreateOfficialMileage'], isFalse);
      expect(safe['checkpointCanSetGlobalTruth'], isFalse);
      expect(safe['checkpointCanChangeOfficialMileage'], isFalse);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['mapboxCanCreateCheckpoint'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
    },
  );

  test('safe summary validates checkpoint local-first mirror contract', () {
    final validation =
        TripLiveCheckpointDurabilitySummaryValidation.fromSummary(
          evaluate().toSafeDashboardMap(),
        );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test(
    'summary rejects remote authority and sensitive checkpoint material',
    () {
      final validation =
          TripLiveCheckpointDurabilitySummaryValidation.fromSummary(
            evaluate().toSafeDashboardMap()..addAll({
              'localCheckpointCanStoreWhileBackupDeferred': false,
              'localCheckpointWriteHasPriorityOverBackup': false,
              'backupMirrorRequiresMatchingLocalRevision': false,
              'remoteBackupCanOverrideLocalDay': true,
              'remoteBackupCanDeleteLocalData': true,
              'remoteBackupCanConfirmCheckpoint': true,
              'remoteBackupCanSetGlobalTruth': true,
              'remoteBackupCanChangeOfficialMileage': true,
              'checkpointPolicyCanDeleteLocalData': true,
              'backupFailureCanStopGpsTracking': true,
              'backupFailureCanDropCurrentCheckpoint': true,
              'odometerIsGlobalTruth': false,
              'odometerRemainsOfficialMileageTruth': false,
              'checkpointCanApplyCalibration': true,
              'checkpointCanCreateOfficialMileage': true,
              'checkpointCanSetGlobalTruth': true,
              'checkpointCanChangeOfficialMileage': true,
              'calibrationRequiresTrustedGpsWindow': false,
              'poorGpsDaysExcludedFromCalibration': false,
              'mapboxCanCreateCheckpoint': true,
              'mapboxCanUploadBackup': true,
              'tokensIncluded': true,
              'preciseLocationIncluded': true,
              'rawTripRecordsIncluded': true,
              'debug': 'pk.public 35.123456,-80.123456',
            }),
          );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('local_checkpoint_truth_boundary_missing'),
      );
      expect(
        validation.reasons,
        contains('remote_or_backup_can_mutate_local_trip'),
      );
      expect(
        validation.reasons,
        contains('mapbox_or_gps_can_replace_odometer'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_checkpoint_material'),
      );
    },
  );
}
