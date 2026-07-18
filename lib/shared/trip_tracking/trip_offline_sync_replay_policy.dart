import 'trip_sync_reservation_commit_policy.dart';
import 'trip_tracking_sync_attempt_guard.dart';

enum TripOfflineSyncReplayStatus {
  ready,
  waitingForNetwork,
  waitingForQuota,
  waitingForReservation,
  blockedInvalidRecord,
}

class TripOfflineSyncReplayDecision {
  const TripOfflineSyncReplayDecision({
    required this.status,
    required this.reasonCode,
    required this.canReplayQueuedMirror,
    required this.shouldKeepLocalQueue,
    required this.shouldRetryLater,
    required this.consumesFreeAttempt,
  });

  final TripOfflineSyncReplayStatus status;
  final String reasonCode;
  final bool canReplayQueuedMirror;
  final bool shouldKeepLocalQueue;
  final bool shouldRetryLater;
  final bool consumesFreeAttempt;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canReplayQueuedMirror': canReplayQueuedMirror,
    'shouldKeepLocalQueue': shouldKeepLocalQueue,
    'shouldRetryLater': shouldRetryLater,
    'consumesFreeAttempt': consumesFreeAttempt,
    'replayRequiresValidatedLocalRecord': true,
    'replayRequiresOwnershipCheck': true,
    'freeReplayRequiresReservationBeforeUpload': true,
    'failedReplayCanDeleteLocalQueue': false,
    'successfulReplayCanSilentlyDeleteLocalData': false,
    'remoteBackupCanOverrideLocalDay': false,
    'firestoreMirrorOnly': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'mapboxCanReplaySyncQueue': false,
    'rawTripPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripOfflineSyncReplayPolicy {
  const TripOfflineSyncReplayPolicy._();

  static TripOfflineSyncReplayDecision evaluate({
    required TripTrackingSyncAttemptDecision attempt,
    required TripSyncReservationCommitDecision reservation,
    required bool queuedRecordStillExistsLocally,
    required bool userStillWantsBackup,
  }) {
    if (!queuedRecordStillExistsLocally ||
        !attempt.sourceValid ||
        !attempt.ownerValid) {
      return _decision(
        status: TripOfflineSyncReplayStatus.blockedInvalidRecord,
        reasonCode: 'offline_replay_invalid_local_record',
        canReplayQueuedMirror: false,
        shouldKeepLocalQueue: queuedRecordStillExistsLocally,
        shouldRetryLater: false,
        consumesFreeAttempt: false,
      );
    }
    if (!userStillWantsBackup) {
      return _decision(
        status: TripOfflineSyncReplayStatus.blockedInvalidRecord,
        reasonCode: 'offline_replay_backup_disabled',
        canReplayQueuedMirror: false,
        shouldKeepLocalQueue: true,
        shouldRetryLater: false,
        consumesFreeAttempt: false,
      );
    }
    if (attempt.status == TripTrackingSyncAttemptStatus.blockedNetwork) {
      return _decision(
        status: TripOfflineSyncReplayStatus.waitingForNetwork,
        reasonCode: 'offline_replay_waiting_for_network',
        canReplayQueuedMirror: false,
        shouldKeepLocalQueue: true,
        shouldRetryLater: true,
        consumesFreeAttempt: false,
      );
    }
    if (attempt.status == TripTrackingSyncAttemptStatus.blockedQuota ||
        attempt.status ==
            TripTrackingSyncAttemptStatus.blockedUnverifiedUsage) {
      return _decision(
        status: TripOfflineSyncReplayStatus.waitingForQuota,
        reasonCode: 'offline_replay_waiting_for_quota',
        canReplayQueuedMirror: false,
        shouldKeepLocalQueue: true,
        shouldRetryLater: true,
        consumesFreeAttempt: false,
      );
    }
    if (!reservation.canUploadAfterReservation) {
      return _decision(
        status: TripOfflineSyncReplayStatus.waitingForReservation,
        reasonCode: reservation.shouldRetryLater
            ? 'offline_replay_reservation_retry'
            : 'offline_replay_reservation_blocked',
        canReplayQueuedMirror: false,
        shouldKeepLocalQueue: true,
        shouldRetryLater: reservation.shouldRetryLater,
        consumesFreeAttempt: false,
      );
    }
    return _decision(
      status: TripOfflineSyncReplayStatus.ready,
      reasonCode: 'offline_replay_ready',
      canReplayQueuedMirror: true,
      shouldKeepLocalQueue: true,
      shouldRetryLater: false,
      consumesFreeAttempt: reservation.consumesFreeAttempt,
    );
  }
}

TripOfflineSyncReplayDecision _decision({
  required TripOfflineSyncReplayStatus status,
  required String reasonCode,
  required bool canReplayQueuedMirror,
  required bool shouldKeepLocalQueue,
  required bool shouldRetryLater,
  required bool consumesFreeAttempt,
}) {
  return TripOfflineSyncReplayDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canReplayQueuedMirror: canReplayQueuedMirror,
    shouldKeepLocalQueue: shouldKeepLocalQueue,
    shouldRetryLater: shouldRetryLater,
    consumesFreeAttempt: consumesFreeAttempt,
  );
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'offline_replay_invalid_local_record' =>
      'offline_replay_invalid_local_record',
    'offline_replay_backup_disabled' => 'offline_replay_backup_disabled',
    'offline_replay_waiting_for_network' =>
      'offline_replay_waiting_for_network',
    'offline_replay_waiting_for_quota' => 'offline_replay_waiting_for_quota',
    'offline_replay_reservation_retry' => 'offline_replay_reservation_retry',
    'offline_replay_reservation_blocked' =>
      'offline_replay_reservation_blocked',
    'offline_replay_ready' => 'offline_replay_ready',
    _ => 'offline_replay_invalid_local_record',
  };
}
