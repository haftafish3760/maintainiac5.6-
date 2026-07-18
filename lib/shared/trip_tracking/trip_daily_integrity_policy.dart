import 'trip_field_trial_evidence_policy.dart';
import 'trip_live_checkpoint_durability_policy.dart';
import 'trip_location_visibility_consent_policy.dart';
import 'trip_odometer_end_review_policy.dart';
import 'trip_release_gate_policy.dart';

enum TripDailyIntegrityStatus { clean, reviewNeeded, backupPending, blocked }

class TripDailyIntegrityDecision {
  const TripDailyIntegrityDecision({
    required this.status,
    required this.reasonCode,
    required this.canCloseLocalDay,
    required this.canMirrorDayBackup,
    required this.requiresUserReview,
    required this.canAttachFieldEvidence,
  });

  final TripDailyIntegrityStatus status;
  final String reasonCode;
  final bool canCloseLocalDay;
  final bool canMirrorDayBackup;
  final bool requiresUserReview;
  final bool canAttachFieldEvidence;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canCloseLocalDay': canCloseLocalDay,
    'canMirrorDayBackup': canMirrorDayBackup,
    'requiresUserReview': requiresUserReview,
    'canAttachFieldEvidence': canAttachFieldEvidence,
    'localDayCloseRequiresOdometerReview': true,
    'localDayCloseCanRunWithoutMaps': true,
    'backupMirrorOptionalForLocalClose': true,
    'freeSyncQuotaCanDelayBackupOnly': true,
    'fieldEvidenceRequiresRedactedDeviceRun': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'dailyIntegrityCanApplyCalibration': false,
    'dailyIntegrityCanCreateOfficialMileage': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteBackupCanOverrideLocalDay': false,
    'dailyIntegrityCanDeleteLocalData': false,
    'dailyIntegrityCanConfirmOdometer': false,
    'dailyIntegrityCanCreateOfficialStop': false,
    'rawTripRecordsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripDailyIntegrityPolicy {
  const TripDailyIntegrityPolicy._();

  static TripDailyIntegrityDecision evaluate({
    required TripOdometerEndReviewDecision odometerReview,
    required TripLiveCheckpointDurabilityDecision checkpoint,
    required TripLocationVisibilityConsentDecision visibilityConsent,
    required TripReleaseGateDecision releaseGate,
    required TripFieldTrialEvidenceDecision fieldEvidence,
    required bool localTripRecordPersisted,
    required bool reviewedStopsResolved,
    required bool userRequestedCloudBackup,
  }) {
    if (!localTripRecordPersisted ||
        odometerReview.status ==
            TripOdometerEndReviewStatus.blockedInvalidEntry ||
        visibilityConsent.status != TripLocationVisibilityStatus.allowed) {
      return _decision(
        status: TripDailyIntegrityStatus.blocked,
        reasonCode: !localTripRecordPersisted
            ? 'daily_integrity_missing_local_record'
            : odometerReview.status ==
                  TripOdometerEndReviewStatus.blockedInvalidEntry
            ? 'daily_integrity_odometer_blocked'
            : 'daily_integrity_privacy_blocked',
        canCloseLocalDay: false,
        canMirrorDayBackup: false,
        requiresUserReview: true,
        canAttachFieldEvidence: false,
      );
    }

    if (!reviewedStopsResolved ||
        odometerReview.shouldShowReviewBeforeConfirm ||
        releaseGate.blocksCommercialClaim) {
      return _decision(
        status: TripDailyIntegrityStatus.reviewNeeded,
        reasonCode: !reviewedStopsResolved
            ? 'daily_integrity_stop_review_needed'
            : odometerReview.shouldShowReviewBeforeConfirm
            ? 'daily_integrity_odometer_review_needed'
            : 'daily_integrity_release_review_needed',
        canCloseLocalDay: true,
        canMirrorDayBackup: false,
        requiresUserReview: true,
        canAttachFieldEvidence: fieldEvidence.canAttachToReleaseGate,
      );
    }

    final backupReady =
        !userRequestedCloudBackup ||
        (checkpoint.status == TripLiveCheckpointDurabilityStatus.backupReady &&
            checkpoint.mayUploadBackupMirror);
    if (!backupReady) {
      return _decision(
        status: TripDailyIntegrityStatus.backupPending,
        reasonCode: 'daily_integrity_backup_pending',
        canCloseLocalDay: true,
        canMirrorDayBackup: false,
        requiresUserReview: false,
        canAttachFieldEvidence: fieldEvidence.canAttachToReleaseGate,
      );
    }

    return _decision(
      status: TripDailyIntegrityStatus.clean,
      reasonCode: 'daily_integrity_clean',
      canCloseLocalDay: true,
      canMirrorDayBackup: userRequestedCloudBackup,
      requiresUserReview: false,
      canAttachFieldEvidence: fieldEvidence.canAttachToReleaseGate,
    );
  }
}

TripDailyIntegrityDecision _decision({
  required TripDailyIntegrityStatus status,
  required String reasonCode,
  required bool canCloseLocalDay,
  required bool canMirrorDayBackup,
  required bool requiresUserReview,
  required bool canAttachFieldEvidence,
}) {
  return TripDailyIntegrityDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canCloseLocalDay: canCloseLocalDay,
    canMirrorDayBackup: canMirrorDayBackup,
    requiresUserReview: requiresUserReview,
    canAttachFieldEvidence: canAttachFieldEvidence,
  );
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'daily_integrity_missing_local_record' =>
      'daily_integrity_missing_local_record',
    'daily_integrity_odometer_blocked' => 'daily_integrity_odometer_blocked',
    'daily_integrity_privacy_blocked' => 'daily_integrity_privacy_blocked',
    'daily_integrity_stop_review_needed' =>
      'daily_integrity_stop_review_needed',
    'daily_integrity_odometer_review_needed' =>
      'daily_integrity_odometer_review_needed',
    'daily_integrity_release_review_needed' =>
      'daily_integrity_release_review_needed',
    'daily_integrity_backup_pending' => 'daily_integrity_backup_pending',
    'daily_integrity_clean' => 'daily_integrity_clean',
    _ => 'daily_integrity_missing_local_record',
  };
}
