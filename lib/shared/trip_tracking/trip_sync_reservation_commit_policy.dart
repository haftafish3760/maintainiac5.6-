import 'trip_tracking_sync_attempt_guard.dart';

enum TripSyncReservationCommitStatus {
  readyToUpload,
  blockedNoReservationRequired,
  blockedReservationFailed,
  blockedAttemptNotReady,
}

class TripSyncReservationCommitDecision {
  const TripSyncReservationCommitDecision({
    required this.status,
    required this.reasonCode,
    required this.canUploadAfterReservation,
    required this.reservationCommittedBeforeUpload,
    required this.consumesFreeAttempt,
    required this.shouldRetryLater,
  });

  final TripSyncReservationCommitStatus status;
  final String reasonCode;
  final bool canUploadAfterReservation;
  final bool reservationCommittedBeforeUpload;
  final bool consumesFreeAttempt;
  final bool shouldRetryLater;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canUploadAfterReservation': canUploadAfterReservation,
    'reservationCommittedBeforeUpload': reservationCommittedBeforeUpload,
    'consumesFreeAttempt': consumesFreeAttempt,
    'shouldRetryLater': shouldRetryLater,
    'freePlanSyncLimitPer24Hours': 6,
    'blockedAttemptConsumesFreeSync': false,
    'uploadWithoutReservationAllowed': false,
    'reservationMustCommitBeforeNetworkUpload': true,
    'reservationFailureKeepsLocalQueue': true,
    'reservationSuccessDoesNotConfirmRemoteBackup': true,
    'reservationCanDeleteLocalData': false,
    'reservationCanPurgeLocalRecordsSilently': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteCounterCanOverrideLocalLedger': false,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanPurgeLocalRecordsSilently': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawTripPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSyncReservationCommitPolicy {
  const TripSyncReservationCommitPolicy._();

  static TripSyncReservationCommitDecision evaluate({
    required TripTrackingSyncAttemptDecision attemptDecision,
    required bool reservationWriteSucceeded,
  }) {
    if (!attemptDecision.mayUploadMirror) {
      return const TripSyncReservationCommitDecision(
        status: TripSyncReservationCommitStatus.blockedAttemptNotReady,
        reasonCode: 'sync_attempt_not_ready',
        canUploadAfterReservation: false,
        reservationCommittedBeforeUpload: false,
        consumesFreeAttempt: false,
        shouldRetryLater: false,
      );
    }
    if (!attemptDecision.mustReserveFreeAttemptBeforeUpload) {
      return const TripSyncReservationCommitDecision(
        status: TripSyncReservationCommitStatus.readyToUpload,
        reasonCode: 'paid_or_unmetered_sync_ready',
        canUploadAfterReservation: true,
        reservationCommittedBeforeUpload: true,
        consumesFreeAttempt: false,
        shouldRetryLater: false,
      );
    }
    if (!attemptDecision.consumesFreeAttempt) {
      return const TripSyncReservationCommitDecision(
        status: TripSyncReservationCommitStatus.blockedNoReservationRequired,
        reasonCode: 'free_sync_quota_unavailable',
        canUploadAfterReservation: false,
        reservationCommittedBeforeUpload: false,
        consumesFreeAttempt: false,
        shouldRetryLater: false,
      );
    }
    if (!reservationWriteSucceeded) {
      return const TripSyncReservationCommitDecision(
        status: TripSyncReservationCommitStatus.blockedReservationFailed,
        reasonCode: 'free_sync_reservation_failed',
        canUploadAfterReservation: false,
        reservationCommittedBeforeUpload: false,
        consumesFreeAttempt: false,
        shouldRetryLater: true,
      );
    }
    return const TripSyncReservationCommitDecision(
      status: TripSyncReservationCommitStatus.readyToUpload,
      reasonCode: 'free_sync_reserved_before_upload',
      canUploadAfterReservation: true,
      reservationCommittedBeforeUpload: true,
      consumesFreeAttempt: true,
      shouldRetryLater: false,
    );
  }
}

String _safeReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'sync_attempt_not_ready' ||
    'paid_or_unmetered_sync_ready' ||
    'free_sync_quota_unavailable' ||
    'free_sync_reservation_failed' ||
    'free_sync_reserved_before_upload' => clean,
    _ => 'sync_attempt_not_ready',
  };
}
