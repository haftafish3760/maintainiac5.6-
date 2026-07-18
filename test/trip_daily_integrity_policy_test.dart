import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_daily_integrity_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_field_trial_evidence_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_checkpoint_durability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_location_visibility_consent_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_calibration_prompt_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_odometer_end_review_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_release_gate_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';

void main() {
  const entryValid = TripOdometerEntryValidation(
    status: TripOdometerEntryValidationStatus.valid,
    startingOdometer: 1000,
    endingOdometer: 1120,
    previousConfirmedEndingOdometer: 1000,
    deltaMiles: 120,
    reasonCode: 'odometer_entry_validated',
  );
  const reconAligned = TripOdometerReconciliation(
    status: TripOdometerReconciliationStatus.aligned,
    confirmedOdometerDeltaMiles: 120,
    filteredGpsMiles: 118,
    absoluteDifferenceMiles: 2,
    differencePercent: 1.7,
  );
  const promptHidden = TripOdometerCalibrationPromptDecision(
    surface: TripOdometerCalibrationPromptSurface.hidden,
    reason: TripOdometerCalibrationPromptReason.noPromptNeeded,
    shouldShow: false,
    canApplyAutomatically: false,
    canSnooze: false,
    canDisable: true,
    messageToken: 'calibration_stable',
  );
  const odometerReady = TripOdometerEndReviewDecision(
    status: TripOdometerEndReviewStatus.readyToConfirm,
    reasonCode: 'odometer_ready_to_confirm',
    entryValidation: entryValid,
    reconciliation: reconAligned,
    calibrationPrompt: promptHidden,
    canConfirmOdometer: true,
    shouldShowReviewBeforeConfirm: false,
  );
  const odometerReview = TripOdometerEndReviewDecision(
    status: TripOdometerEndReviewStatus.reviewRecommended,
    reasonCode: 'gps_odometer_difference_review',
    entryValidation: entryValid,
    reconciliation: TripOdometerReconciliation(
      status: TripOdometerReconciliationStatus.reviewRecommended,
      confirmedOdometerDeltaMiles: 120,
      filteredGpsMiles: 100,
      absoluteDifferenceMiles: 20,
      differencePercent: 16.7,
    ),
    calibrationPrompt: promptHidden,
    canConfirmOdometer: true,
    shouldShowReviewBeforeConfirm: true,
  );
  const checkpointReady = TripLiveCheckpointDurabilityDecision(
    status: TripLiveCheckpointDurabilityStatus.backupReady,
    reasonCode: 'local_checkpoint_written_backup_ready',
    shouldWriteLocalCheckpointNow: false,
    mayUploadBackupMirror: true,
    shouldRetryBackupLater: false,
    minimumNextLocalWriteSeconds: 0,
  );
  const checkpointDeferred = TripLiveCheckpointDurabilityDecision(
    status: TripLiveCheckpointDurabilityStatus.backupDeferred,
    reasonCode: 'sync_attempt_not_ready',
    shouldWriteLocalCheckpointNow: false,
    mayUploadBackupMirror: false,
    shouldRetryBackupLater: false,
    minimumNextLocalWriteSeconds: 0,
  );
  const visibilityAllowed = TripLocationVisibilityConsentDecision(
    status: TripLocationVisibilityStatus.allowed,
    mode: TripLocationVisibilityMode.personalBackupOnly,
    reasonCode: 'personal_visibility_only',
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
  const visibilityBlocked = TripLocationVisibilityConsentDecision(
    status: TripLocationVisibilityStatus.blockedNoEmployeeConsent,
    mode: TripLocationVisibilityMode.privateOnly,
    reasonCode: 'employee_location_consent_required',
    canShowLiveLocationToOrganization: false,
    canMirrorReviewedMileageToOrganization: false,
    canShowRouteHistoryToOrganization: false,
  );
  const releaseField = TripReleaseGateDecision(
    status: TripReleaseGateStatus.fieldTrialReady,
    reasonCode: 'release_gate_field_trial_ready',
    canStartSyntheticRegression: true,
    canStartLimitedFieldTrial: true,
    requiresPhysicalDeviceProof: false,
    blocksCommercialClaim: false,
  );
  const fieldEvidenceReady = TripFieldTrialEvidenceDecision(
    status: TripFieldTrialEvidenceStatus.readyToRecord,
    reasonCode: 'field_trial_evidence_ready',
    canAttachToReleaseGate: true,
    canSupportLimitedFieldTrial: true,
    canSupportCommercialClaim: false,
  );

  TripDailyIntegrityDecision evaluate({
    TripOdometerEndReviewDecision odometer = odometerReady,
    TripLiveCheckpointDurabilityDecision checkpoint = checkpointReady,
    TripLocationVisibilityConsentDecision visibility = visibilityAllowed,
    bool localPersisted = true,
    bool stopsResolved = true,
    bool backup = true,
  }) {
    return TripDailyIntegrityPolicy.evaluate(
      odometerReview: odometer,
      checkpoint: checkpoint,
      visibilityConsent: visibility,
      releaseGate: releaseField,
      fieldEvidence: fieldEvidenceReady,
      localTripRecordPersisted: localPersisted,
      reviewedStopsResolved: stopsResolved,
      userRequestedCloudBackup: backup,
    );
  }

  test(
    'clean local day can close and mirror backup when checkpoint is ready',
    () {
      final decision = evaluate();

      expect(decision.status, TripDailyIntegrityStatus.clean);
      expect(decision.canCloseLocalDay, isTrue);
      expect(decision.canMirrorDayBackup, isTrue);
      expect(decision.requiresUserReview, isFalse);
    },
  );

  test('backup pending does not block local day close', () {
    final decision = evaluate(checkpoint: checkpointDeferred);

    expect(decision.status, TripDailyIntegrityStatus.backupPending);
    expect(decision.canCloseLocalDay, isTrue);
    expect(decision.canMirrorDayBackup, isFalse);
  });

  test(
    'stop and odometer review keep local day reviewable but not mirrored',
    () {
      final stopReview = evaluate(stopsResolved: false);
      final odoReview = evaluate(odometer: odometerReview);

      expect(stopReview.status, TripDailyIntegrityStatus.reviewNeeded);
      expect(stopReview.reasonCode, 'daily_integrity_stop_review_needed');
      expect(odoReview.reasonCode, 'daily_integrity_odometer_review_needed');
      expect(odoReview.canCloseLocalDay, isTrue);
    },
  );

  test('missing local record or privacy block fails closed', () {
    final missingLocal = evaluate(localPersisted: false);
    final privacy = evaluate(visibility: visibilityBlocked);

    expect(missingLocal.status, TripDailyIntegrityStatus.blocked);
    expect(missingLocal.reasonCode, 'daily_integrity_missing_local_record');
    expect(privacy.status, TripDailyIntegrityStatus.blocked);
    expect(privacy.reasonCode, 'daily_integrity_privacy_blocked');
  });

  test('safe summary protects local truth and sensitive fields', () {
    final safe = evaluate().toSafeDashboardMap();

    expect(safe['localDayCloseRequiresOdometerReview'], isTrue);
    expect(safe['backupMirrorOptionalForLocalClose'], isTrue);
    expect(safe['freeSyncQuotaCanDelayBackupOnly'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['dailyIntegrityCanApplyCalibration'], isFalse);
    expect(safe['dailyIntegrityCanCreateOfficialMileage'], isFalse);
    expect(safe['dailyIntegrityCanSetGlobalTruth'], isFalse);
    expect(safe['dailyIntegrityCanChangeOfficialMileage'], isFalse);
    expect(safe['dailyIntegrityCanDeleteLocalData'], isFalse);
    expect(safe['dailyIntegrityCanConfirmOdometer'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });
}
