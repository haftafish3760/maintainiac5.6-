import 'trip_sync_reservation_commit_policy.dart';
import 'trip_tracking_sync_attempt_guard.dart';

enum TripOfflineSyncReplayStatus {
  ready,
  waitingForNetwork,
  waitingForQuota,
  waitingForStorage,
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
    'successfulReplayCanPurgeLocalDaytimeData': false,
    'remoteConflictCanSilentlyWin': false,
    'replaySuccessRequiresExplicitQueueCleanup': true,
    'replayCannotUploadIfLocalRecordDisappears': true,
    'replayCannotUploadAfterBackupOptOut': true,
    'remoteBackupCanOverrideLocalDay': false,
    'firestoreMirrorOnly': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'mapboxCanReplaySyncQueue': false,
    'mapboxCanRepairReplayRecords': false,
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
    if (attempt.status == TripTrackingSyncAttemptStatus.blockedStorage) {
      return _decision(
        status: TripOfflineSyncReplayStatus.waitingForStorage,
        reasonCode: 'offline_replay_waiting_for_storage',
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

class TripOfflineSyncReplaySummaryValidation {
  const TripOfflineSyncReplaySummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripOfflineSyncReplaySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_replay_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_replay_reason');
    }
    for (final key in const [
      'canReplayQueuedMirror',
      'shouldKeepLocalQueue',
      'shouldRetryLater',
      'consumesFreeAttempt',
      'replayRequiresValidatedLocalRecord',
      'replayRequiresOwnershipCheck',
      'freeReplayRequiresReservationBeforeUpload',
      'failedReplayCanDeleteLocalQueue',
      'successfulReplayCanSilentlyDeleteLocalData',
      'successfulReplayCanPurgeLocalDaytimeData',
      'remoteConflictCanSilentlyWin',
      'replaySuccessRequiresExplicitQueueCleanup',
      'replayCannotUploadIfLocalRecordDisappears',
      'replayCannotUploadAfterBackupOptOut',
      'remoteBackupCanOverrideLocalDay',
      'firestoreMirrorOnly',
      'hiveRemainsOperationalSourceOfTruth',
      'odometerRemainsOfficialMileageTruth',
      'mapboxCanReplaySyncQueue',
      'mapboxCanRepairReplayRecords',
      'rawTripPayloadIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['replayRequiresValidatedLocalRecord'] != true ||
        summary['replayRequiresOwnershipCheck'] != true ||
        summary['freeReplayRequiresReservationBeforeUpload'] != true ||
        summary['replayCannotUploadIfLocalRecordDisappears'] != true ||
        summary['replayCannotUploadAfterBackupOptOut'] != true) {
      reasons.add('replay_upload_boundary_missing');
    }
    if (summary['failedReplayCanDeleteLocalQueue'] != false ||
        summary['successfulReplayCanSilentlyDeleteLocalData'] != false ||
        summary['successfulReplayCanPurgeLocalDaytimeData'] != false ||
        summary['remoteConflictCanSilentlyWin'] != false ||
        summary['replaySuccessRequiresExplicitQueueCleanup'] != true ||
        summary['remoteBackupCanOverrideLocalDay'] != false) {
      reasons.add('remote_replay_can_mutate_local_data');
    }
    if (summary['firestoreMirrorOnly'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['mapboxCanReplaySyncQueue'] != false ||
        summary['mapboxCanRepairReplayRecords'] != false) {
      reasons.add('source_of_truth_boundary_missing');
    }
    if (summary['rawTripPayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_replay_material');
    }

    return TripOfflineSyncReplaySummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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
    'offline_replay_waiting_for_storage' =>
      'offline_replay_waiting_for_storage',
    'offline_replay_reservation_retry' => 'offline_replay_reservation_retry',
    'offline_replay_reservation_blocked' =>
      'offline_replay_reservation_blocked',
    'offline_replay_ready' => 'offline_replay_ready',
    _ => 'offline_replay_invalid_local_record',
  };
}

TripOfflineSyncReplayStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripOfflineSyncReplayStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
