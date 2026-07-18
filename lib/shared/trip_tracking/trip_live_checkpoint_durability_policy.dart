import 'trip_sync_reservation_commit_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_sync_attempt_guard.dart';

enum TripLiveCheckpointDurabilityStatus {
  localWriteRequired,
  localWriteDeferred,
  backupReady,
  backupDeferred,
  blockedInvalidCheckpoint,
}

class TripLiveCheckpointDurabilityDecision {
  const TripLiveCheckpointDurabilityDecision({
    required this.status,
    required this.reasonCode,
    required this.shouldWriteLocalCheckpointNow,
    required this.mayUploadBackupMirror,
    required this.shouldRetryBackupLater,
    required this.minimumNextLocalWriteSeconds,
  });

  final TripLiveCheckpointDurabilityStatus status;
  final String reasonCode;
  final bool shouldWriteLocalCheckpointNow;
  final bool mayUploadBackupMirror;
  final bool shouldRetryBackupLater;
  final int minimumNextLocalWriteSeconds;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'shouldWriteLocalCheckpointNow': shouldWriteLocalCheckpointNow,
    'mayUploadBackupMirror': mayUploadBackupMirror,
    'shouldRetryBackupLater': shouldRetryBackupLater,
    'minimumNextLocalWriteSeconds': _safeSeconds(minimumNextLocalWriteSeconds),
    'localCheckpointRequiredBeforeBackup': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanDeleteLocalData': false,
    'checkpointPolicyCanDeleteLocalData': false,
    'backupFailureCanStopGpsTracking': false,
    'backupFailureCanDropCurrentCheckpoint': false,
    'freePlanReservationRequiredBeforeUpload': true,
    'localDaytimeDataNeverSilentlyOverwritten': true,
    'odometerRemainsOfficialMileageTruth': true,
    'mapboxCanCreateCheckpoint': false,
    'mapboxCanUploadBackup': false,
    'tokensIncluded': false,
    'preciseLocationIncluded': false,
    'rawTripRecordsIncluded': false,
  };
}

class TripLiveCheckpointDurabilityPolicy {
  const TripLiveCheckpointDurabilityPolicy._();

  static TripLiveCheckpointDurabilityDecision evaluate({
    required TripTrackingSessionLifecycleState lifecycle,
    required bool localSessionAvailable,
    required bool checkpointShapeValid,
    required bool localWriteSucceeded,
    required bool userBackupEnabled,
    required TripTrackingSyncAttemptDecision syncAttempt,
    required TripSyncReservationCommitDecision reservation,
    DateTime? lastLocalWriteAtUtc,
    required DateTime nowUtc,
    Duration minimumLocalWriteInterval = const Duration(seconds: 10),
    bool highPriorityCheckpoint = false,
  }) {
    if (!_isTrackingLifecycle(lifecycle) ||
        !localSessionAvailable ||
        !checkpointShapeValid ||
        minimumLocalWriteInterval.isNegative) {
      return _decision(
        status: TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint,
        reasonCode: 'invalid_live_checkpoint_boundary',
        shouldWriteLocalCheckpointNow: false,
        mayUploadBackupMirror: false,
        shouldRetryBackupLater: false,
        minimumNextLocalWriteSeconds: 0,
      );
    }

    final now = nowUtc.toUtc();
    final lastWrite = lastLocalWriteAtUtc?.toUtc();
    final intervalReady =
        lastWrite == null ||
        lastWrite.isAfter(now) ||
        now.difference(lastWrite) >= minimumLocalWriteInterval;
    if (highPriorityCheckpoint || intervalReady) {
      return _localWriteDecision(
        localWriteSucceeded: localWriteSucceeded,
        userBackupEnabled: userBackupEnabled,
        syncAttempt: syncAttempt,
        reservation: reservation,
      );
    }

    return _decision(
      status: TripLiveCheckpointDurabilityStatus.localWriteDeferred,
      reasonCode: 'local_checkpoint_interval_not_due',
      shouldWriteLocalCheckpointNow: false,
      mayUploadBackupMirror: false,
      shouldRetryBackupLater: false,
      minimumNextLocalWriteSeconds:
          minimumLocalWriteInterval.inSeconds -
          now.difference(lastWrite).inSeconds,
    );
  }
}

TripLiveCheckpointDurabilityDecision _localWriteDecision({
  required bool localWriteSucceeded,
  required bool userBackupEnabled,
  required TripTrackingSyncAttemptDecision syncAttempt,
  required TripSyncReservationCommitDecision reservation,
}) {
  if (!localWriteSucceeded) {
    return _decision(
      status: TripLiveCheckpointDurabilityStatus.localWriteRequired,
      reasonCode: 'local_checkpoint_write_required',
      shouldWriteLocalCheckpointNow: true,
      mayUploadBackupMirror: false,
      shouldRetryBackupLater: false,
      minimumNextLocalWriteSeconds: 0,
    );
  }
  if (!userBackupEnabled ||
      !syncAttempt.mayUploadMirror ||
      !reservation.canUploadAfterReservation) {
    return _decision(
      status: TripLiveCheckpointDurabilityStatus.backupDeferred,
      reasonCode: _backupDeferredReason(
        userBackupEnabled,
        syncAttempt,
        reservation,
      ),
      shouldWriteLocalCheckpointNow: false,
      mayUploadBackupMirror: false,
      shouldRetryBackupLater: reservation.shouldRetryLater,
      minimumNextLocalWriteSeconds: 0,
    );
  }
  return _decision(
    status: TripLiveCheckpointDurabilityStatus.backupReady,
    reasonCode: 'local_checkpoint_written_backup_ready',
    shouldWriteLocalCheckpointNow: false,
    mayUploadBackupMirror: true,
    shouldRetryBackupLater: false,
    minimumNextLocalWriteSeconds: 0,
  );
}

TripLiveCheckpointDurabilityDecision _decision({
  required TripLiveCheckpointDurabilityStatus status,
  required String reasonCode,
  required bool shouldWriteLocalCheckpointNow,
  required bool mayUploadBackupMirror,
  required bool shouldRetryBackupLater,
  required int minimumNextLocalWriteSeconds,
}) {
  return TripLiveCheckpointDurabilityDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    shouldWriteLocalCheckpointNow: shouldWriteLocalCheckpointNow,
    mayUploadBackupMirror: mayUploadBackupMirror,
    shouldRetryBackupLater: shouldRetryBackupLater,
    minimumNextLocalWriteSeconds: _safeSeconds(minimumNextLocalWriteSeconds),
  );
}

bool _isTrackingLifecycle(TripTrackingSessionLifecycleState lifecycle) {
  return switch (lifecycle) {
    TripTrackingSessionLifecycleState.starting ||
    TripTrackingSessionLifecycleState.active ||
    TripTrackingSessionLifecycleState.degraded ||
    TripTrackingSessionLifecycleState.interrupted ||
    TripTrackingSessionLifecycleState.recovering ||
    TripTrackingSessionLifecycleState.stopping ||
    TripTrackingSessionLifecycleState.failedRecoverable => true,
    _ => false,
  };
}

String _backupDeferredReason(
  bool userBackupEnabled,
  TripTrackingSyncAttemptDecision syncAttempt,
  TripSyncReservationCommitDecision reservation,
) {
  if (!userBackupEnabled) return 'backup_disabled_by_user';
  if (!syncAttempt.mayUploadMirror) return 'sync_attempt_not_ready';
  if (reservation.shouldRetryLater) return 'backup_reservation_retry_later';
  return 'backup_reservation_not_ready';
}

int _safeSeconds(int value) {
  if (value <= 0) return 0;
  return value > 3600 ? 3600 : value;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'invalid_live_checkpoint_boundary' => 'invalid_live_checkpoint_boundary',
    'local_checkpoint_interval_not_due' => 'local_checkpoint_interval_not_due',
    'local_checkpoint_write_required' => 'local_checkpoint_write_required',
    'backup_disabled_by_user' => 'backup_disabled_by_user',
    'sync_attempt_not_ready' => 'sync_attempt_not_ready',
    'backup_reservation_retry_later' => 'backup_reservation_retry_later',
    'backup_reservation_not_ready' => 'backup_reservation_not_ready',
    'local_checkpoint_written_backup_ready' =>
      'local_checkpoint_written_backup_ready',
    _ => 'invalid_live_checkpoint_boundary',
  };
}
