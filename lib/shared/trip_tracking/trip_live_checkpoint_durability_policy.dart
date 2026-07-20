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
    'localCheckpointCanStoreWhileBackupDeferred': true,
    'localCheckpointWriteHasPriorityOverBackup': true,
    'localCheckpointRequiredBeforeBackup': true,
    'backupMirrorRequiresMatchingLocalRevision': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanDeleteLocalData': false,
    'remoteBackupCanConfirmCheckpoint': false,
    'remoteBackupCanSetGlobalTruth': false,
    'remoteBackupCanChangeOfficialMileage': false,
    'checkpointPolicyCanDeleteLocalData': false,
    'backupFailureCanStopGpsTracking': false,
    'backupFailureCanDropCurrentCheckpoint': false,
    'lowStorageCanBlockTextCheckpointAboveReserve': false,
    'freePlanReservationRequiredBeforeUpload': true,
    'localDaytimeDataNeverSilentlyOverwritten': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'checkpointCanApplyCalibration': false,
    'checkpointCanCreateOfficialMileage': false,
    'checkpointCanSetGlobalTruth': false,
    'checkpointCanChangeOfficialMileage': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'mapboxCanCreateCheckpoint': false,
    'mapboxCanUploadBackup': false,
    'tokensIncluded': false,
    'preciseLocationIncluded': false,
    'rawTripRecordsIncluded': false,
  };
}

class TripLiveCheckpointDurabilitySummaryValidation {
  const TripLiveCheckpointDurabilitySummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripLiveCheckpointDurabilitySummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    for (final key in const [
      'shouldWriteLocalCheckpointNow',
      'mayUploadBackupMirror',
      'shouldRetryBackupLater',
      'localCheckpointCanStoreWhileBackupDeferred',
      'localCheckpointWriteHasPriorityOverBackup',
      'localCheckpointRequiredBeforeBackup',
      'backupMirrorRequiresMatchingLocalRevision',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'remoteBackupCanOverrideLocalDay',
      'remoteBackupCanDeleteLocalData',
      'remoteBackupCanConfirmCheckpoint',
      'remoteBackupCanSetGlobalTruth',
      'remoteBackupCanChangeOfficialMileage',
      'checkpointPolicyCanDeleteLocalData',
      'backupFailureCanStopGpsTracking',
      'backupFailureCanDropCurrentCheckpoint',
      'lowStorageCanBlockTextCheckpointAboveReserve',
      'freePlanReservationRequiredBeforeUpload',
      'localDaytimeDataNeverSilentlyOverwritten',
      'odometerIsGlobalTruth',
      'odometerRemainsOfficialMileageTruth',
      'physicalOdometerRequiredForOfficialMileage',
      'confirmedOdometerOverridesExternalMileage',
      'externalMileageCannotBecomeGlobalTruth',
      'gpsDistanceCanOnlyAdviseMileageReview',
      'mapMatchingCanOnlyAdviseMileageReview',
      'optimizationCannotChangeOfficialMileage',
      'checkpointCanApplyCalibration',
      'checkpointCanCreateOfficialMileage',
      'checkpointCanSetGlobalTruth',
      'checkpointCanChangeOfficialMileage',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'mapboxCanCreateCheckpoint',
      'mapboxCanUploadBackup',
      'tokensIncluded',
      'preciseLocationIncluded',
      'rawTripRecordsIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_checkpoint_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_checkpoint_reason');
    }
    if (summary['minimumNextLocalWriteSeconds'] is! int) {
      reasons.add('invalid_checkpoint_interval');
    }
    if (summary['localCheckpointCanStoreWhileBackupDeferred'] != true ||
        summary['localCheckpointWriteHasPriorityOverBackup'] != true ||
        summary['localCheckpointRequiredBeforeBackup'] != true ||
        summary['backupMirrorRequiresMatchingLocalRevision'] != true ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['localDaytimeDataNeverSilentlyOverwritten'] != true) {
      reasons.add('local_checkpoint_truth_boundary_missing');
    }
    if (summary['remoteBackupCanOverrideLocalDay'] != false ||
        summary['remoteBackupCanDeleteLocalData'] != false ||
        summary['remoteBackupCanConfirmCheckpoint'] != false ||
        summary['remoteBackupCanSetGlobalTruth'] != false ||
        summary['remoteBackupCanChangeOfficialMileage'] != false ||
        summary['checkpointPolicyCanDeleteLocalData'] != false ||
        summary['backupFailureCanStopGpsTracking'] != false ||
        summary['backupFailureCanDropCurrentCheckpoint'] != false) {
      reasons.add('remote_or_backup_can_mutate_local_trip');
    }
    if (summary['odometerIsGlobalTruth'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true ||
        summary['checkpointCanApplyCalibration'] != false ||
        summary['checkpointCanCreateOfficialMileage'] != false ||
        summary['checkpointCanSetGlobalTruth'] != false ||
        summary['checkpointCanChangeOfficialMileage'] != false ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['mapboxCanCreateCheckpoint'] != false ||
        summary['mapboxCanUploadBackup'] != false) {
      reasons.add('mapbox_or_gps_can_replace_odometer');
    }
    if (summary['tokensIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['rawTripRecordsIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_checkpoint_material');
    }
    final boundaryRisk = _checkpointStatusBoundaryRisk(summary);
    if (boundaryRisk != null) reasons.add(boundaryRisk);

    return TripLiveCheckpointDurabilitySummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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
    TripTrackingSessionLifecycleState.awaitingInitialFix ||
    TripTrackingSessionLifecycleState.activeTracking ||
    TripTrackingSessionLifecycleState.signalDegraded ||
    TripTrackingSessionLifecycleState.signalLost ||
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

TripLiveCheckpointDurabilityStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLiveCheckpointDurabilityStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

String? _checkpointStatusBoundaryRisk(Map<String, Object?> summary) {
  final status = _safeStatus(summary['status']);
  final writeLocal = summary['shouldWriteLocalCheckpointNow'];
  final upload = summary['mayUploadBackupMirror'];
  final retry = summary['shouldRetryBackupLater'];
  final waitSeconds = summary['minimumNextLocalWriteSeconds'];
  if (status == null ||
      writeLocal is! bool ||
      upload is! bool ||
      retry is! bool ||
      waitSeconds is! int) {
    return null;
  }
  if (status == TripLiveCheckpointDurabilityStatus.localWriteRequired &&
      (!writeLocal || upload || retry || waitSeconds != 0)) {
    return 'checkpoint_status_conflicts_with_authority';
  }
  if (status == TripLiveCheckpointDurabilityStatus.localWriteDeferred &&
      (writeLocal || upload || retry || waitSeconds <= 0)) {
    return 'checkpoint_status_conflicts_with_authority';
  }
  if (status == TripLiveCheckpointDurabilityStatus.backupReady &&
      (writeLocal || !upload || retry || waitSeconds != 0)) {
    return 'checkpoint_status_conflicts_with_authority';
  }
  if (status == TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint &&
      (writeLocal || upload || retry)) {
    return 'checkpoint_status_conflicts_with_authority';
  }
  if (status == TripLiveCheckpointDurabilityStatus.backupDeferred &&
      (writeLocal || upload)) {
    return 'checkpoint_status_conflicts_with_authority';
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.toLowerCase().contains('token') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
