import '../firebase/hosted_usage_limits.dart';
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
    'freePlanSyncLimitPer24Hours':
        HostedUsageLimits.freeUserSyncsPer24HourWindow,
    'blockedAttemptConsumesFreeSync': false,
    'uploadWithoutReservationAllowed': false,
    'reservationMustCommitBeforeNetworkUpload': true,
    'reservationRequiresLocalLedgerWrite': true,
    'reservationRequiresAccountDeviceModuleScope': true,
    'reservationRequiresSameValidatedUser': true,
    'reservationRequiresSameValidatedDevice': true,
    'reservationRequiresSameLocalAttempt': true,
    'reservationCannotBeRevivedAfterExpiry': true,
    'reservationCannotBeCommittedByRemoteCounter': true,
    'authenticationAloneAuthorizesReservation': false,
    'reservationFailureKeepsLocalQueue': true,
    'reservationSuccessDoesNotConfirmRemoteBackup': true,
    'reservationSuccessDoesNotConfirmMirrorWrite': true,
    'successfulMirrorWriteStillNeedsValidatedAck': true,
    'reservationCanDeleteLocalData': false,
    'reservationCanPurgeLocalRecordsSilently': false,
    'reservationCanUploadRawTripData': false,
    'reservationCanUploadRawGpsPings': false,
    'reservationCanCreateStops': false,
    'reservationCanConfirmMileage': false,
    'reservationCanModifyOdometer': false,
    'reservationCanSetGlobalTruth': false,
    'reservationCanChangeOfficialMileage': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteCounterCanOverrideLocalLedger': false,
    'remoteReservationCanOverrideLocalUsage': false,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanPurgeLocalRecordsSilently': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'rawTripPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSyncReservationCommitSummaryValidation {
  const TripSyncReservationCommitSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripSyncReservationCommitSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_reservation_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_reservation_reason');
    }
    if (summary['freePlanSyncLimitPer24Hours'] !=
        HostedUsageLimits.freeUserSyncsPer24HourWindow) {
      reasons.add('invalid_free_sync_limit');
    }
    for (final key in const [
      'canUploadAfterReservation',
      'reservationCommittedBeforeUpload',
      'consumesFreeAttempt',
      'shouldRetryLater',
      'blockedAttemptConsumesFreeSync',
      'uploadWithoutReservationAllowed',
      'reservationMustCommitBeforeNetworkUpload',
      'reservationRequiresLocalLedgerWrite',
      'reservationRequiresAccountDeviceModuleScope',
      'reservationRequiresSameValidatedUser',
      'reservationRequiresSameValidatedDevice',
      'reservationRequiresSameLocalAttempt',
      'reservationCannotBeRevivedAfterExpiry',
      'reservationCannotBeCommittedByRemoteCounter',
      'authenticationAloneAuthorizesReservation',
      'reservationFailureKeepsLocalQueue',
      'reservationSuccessDoesNotConfirmRemoteBackup',
      'reservationSuccessDoesNotConfirmMirrorWrite',
      'successfulMirrorWriteStillNeedsValidatedAck',
      'reservationCanDeleteLocalData',
      'reservationCanPurgeLocalRecordsSilently',
      'reservationCanUploadRawTripData',
      'reservationCanUploadRawGpsPings',
      'reservationCanCreateStops',
      'reservationCanConfirmMileage',
      'reservationCanModifyOdometer',
      'reservationCanSetGlobalTruth',
      'reservationCanChangeOfficialMileage',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'remoteCounterCanOverrideLocalLedger',
      'remoteReservationCanOverrideLocalUsage',
      'remoteBackupCanOverrideLocalDay',
      'remoteBackupCanPurgeLocalRecordsSilently',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'rawTripPayloadIncluded',
      'preciseLocationIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['blockedAttemptConsumesFreeSync'] != false ||
        summary['uploadWithoutReservationAllowed'] != false ||
        summary['reservationMustCommitBeforeNetworkUpload'] != true ||
        summary['reservationRequiresLocalLedgerWrite'] != true ||
        summary['reservationRequiresAccountDeviceModuleScope'] != true ||
        summary['reservationRequiresSameValidatedUser'] != true ||
        summary['reservationRequiresSameValidatedDevice'] != true ||
        summary['reservationRequiresSameLocalAttempt'] != true ||
        summary['reservationCannotBeRevivedAfterExpiry'] != true ||
        summary['reservationCannotBeCommittedByRemoteCounter'] != true ||
        summary['authenticationAloneAuthorizesReservation'] != false ||
        summary['reservationFailureKeepsLocalQueue'] != true ||
        summary['reservationSuccessDoesNotConfirmRemoteBackup'] != true ||
        summary['reservationSuccessDoesNotConfirmMirrorWrite'] != true ||
        summary['successfulMirrorWriteStillNeedsValidatedAck'] != true) {
      reasons.add('reservation_upload_boundary_missing');
    }
    if (summary['reservationCanDeleteLocalData'] != false ||
        summary['reservationCanPurgeLocalRecordsSilently'] != false ||
        summary['reservationCanUploadRawTripData'] != false ||
        summary['reservationCanUploadRawGpsPings'] != false ||
        summary['reservationCanCreateStops'] != false ||
        summary['reservationCanConfirmMileage'] != false ||
        summary['reservationCanModifyOdometer'] != false ||
        summary['reservationCanSetGlobalTruth'] != false ||
        summary['reservationCanChangeOfficialMileage'] != false ||
        summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteCounterCanOverrideLocalLedger'] != false ||
        summary['remoteReservationCanOverrideLocalUsage'] != false ||
        summary['remoteBackupCanOverrideLocalDay'] != false ||
        summary['remoteBackupCanPurgeLocalRecordsSilently'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('reservation_local_truth_boundary_missing');
    }
    if (summary['rawTripPayloadIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_reservation_material');
    }

    return TripSyncReservationCommitSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripSyncReservationCommitStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripSyncReservationCommitStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
