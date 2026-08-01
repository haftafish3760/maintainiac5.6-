import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sync_reservation_commit_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';

void main() {
  test('free sync upload requires successful local reservation first', () {
    final ready = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(syncsUsed: 0),
      reservationWriteSucceeded: true,
    );
    final failed = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(syncsUsed: 0),
      reservationWriteSucceeded: false,
    );

    expect(ready.status, TripSyncReservationCommitStatus.readyToUpload);
    expect(ready.consumesFreeAttempt, isTrue);
    expect(ready.reservationCommittedBeforeUpload, isTrue);
    expect(
      failed.status,
      TripSyncReservationCommitStatus.blockedReservationFailed,
    );
    expect(failed.canUploadAfterReservation, isFalse);
    expect(failed.shouldRetryLater, isTrue);
  });

  test('paid sync can upload without consuming free quota', () {
    final decision = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(accountTier: TripTrackingSyncAccountTier.paid),
      reservationWriteSucceeded: false,
    );

    expect(decision.status, TripSyncReservationCommitStatus.readyToUpload);
    expect(decision.consumesFreeAttempt, isFalse);
    expect(decision.canUploadAfterReservation, isTrue);
  });

  test('blocked attempts never consume quota or upload', () {
    final decision = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(
        syncsUsed: HostedUsageLimits.freeUserSyncsPer24HourWindow,
      ),
      reservationWriteSucceeded: true,
    );

    expect(
      decision.status,
      TripSyncReservationCommitStatus.blockedAttemptNotReady,
    );
    expect(decision.canUploadAfterReservation, isFalse);
    expect(decision.consumesFreeAttempt, isFalse);
  });

  test('safe summary preserves local truth and token boundaries', () {
    final safe = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(syncsUsed: 0),
      reservationWriteSucceeded: true,
    ).toSafeSummary();

    expect(
      safe['freePlanSyncLimitPer24Hours'],
      HostedUsageLimits.freeUserSyncsPer24HourWindow,
    );
    expect(safe['blockedAttemptConsumesFreeSync'], isFalse);
    expect(safe['uploadWithoutReservationAllowed'], isFalse);
    expect(safe['reservationMustCommitBeforeNetworkUpload'], isTrue);
    expect(safe['reservationRequiresLocalLedgerWrite'], isTrue);
    expect(safe['reservationRequiresAccountDeviceModuleScope'], isTrue);
    expect(safe['reservationRequiresSameValidatedUser'], isTrue);
    expect(safe['reservationRequiresSameValidatedDevice'], isTrue);
    expect(safe['reservationRequiresSameLocalAttempt'], isTrue);
    expect(safe['reservationCannotBeRevivedAfterExpiry'], isTrue);
    expect(safe['reservationCannotBeCommittedByRemoteCounter'], isTrue);
    expect(safe['authenticationAloneAuthorizesReservation'], isFalse);
    expect(safe['reservationFailureKeepsLocalQueue'], isTrue);
    expect(safe['reservationSuccessDoesNotConfirmRemoteBackup'], isTrue);
    expect(safe['reservationSuccessDoesNotConfirmMirrorWrite'], isTrue);
    expect(safe['successfulMirrorWriteStillNeedsValidatedAck'], isTrue);
    expect(safe['reservationCanDeleteLocalData'], isFalse);
    expect(safe['reservationCanUploadRawTripData'], isFalse);
    expect(safe['reservationCanUploadRawGpsPings'], isFalse);
    expect(safe['reservationCanCreateStops'], isFalse);
    expect(safe['reservationCanConfirmMileage'], isFalse);
    expect(safe['reservationCanModifyOdometer'], isFalse);
    expect(safe['reservationCanSetGlobalTruth'], isFalse);
    expect(safe['reservationCanChangeOfficialMileage'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['remoteCounterCanOverrideLocalLedger'], isFalse);
    expect(safe['remoteReservationCanOverrideLocalUsage'], isFalse);
    expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawTripPayloadIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
  });

  test('safe reservation summary validates local-ledger boundary', () {
    final summary = TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(syncsUsed: 0),
      reservationWriteSucceeded: true,
    ).toSafeSummary();

    final validation = TripSyncReservationCommitSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test('forged reservation summary cannot bypass local ledger reservation', () {
    final summary =
        TripSyncReservationCommitPolicy.evaluate(
          attemptDecision: attempt(syncsUsed: 0),
          reservationWriteSucceeded: true,
        ).toSafeSummary()..addAll({
          'blockedAttemptConsumesFreeSync': true,
          'uploadWithoutReservationAllowed': true,
          'reservationMustCommitBeforeNetworkUpload': false,
          'reservationRequiresLocalLedgerWrite': false,
          'reservationRequiresAccountDeviceModuleScope': false,
          'reservationRequiresSameValidatedUser': false,
          'reservationRequiresSameValidatedDevice': false,
          'reservationRequiresSameLocalAttempt': false,
          'reservationCannotBeRevivedAfterExpiry': false,
          'reservationCannotBeCommittedByRemoteCounter': false,
          'authenticationAloneAuthorizesReservation': true,
          'reservationFailureKeepsLocalQueue': false,
          'reservationSuccessDoesNotConfirmRemoteBackup': false,
          'reservationSuccessDoesNotConfirmMirrorWrite': false,
          'successfulMirrorWriteStillNeedsValidatedAck': false,
        });

    final validation = TripSyncReservationCommitSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('reservation_upload_boundary_missing'));
  });

  test('forged reservation summary cannot mutate local trip state', () {
    final summary =
        TripSyncReservationCommitPolicy.evaluate(
          attemptDecision: attempt(syncsUsed: 0),
          reservationWriteSucceeded: true,
        ).toSafeSummary()..addAll({
          'reservationCanDeleteLocalData': true,
          'reservationCanPurgeLocalRecordsSilently': true,
          'reservationCanUploadRawTripData': true,
          'reservationCanUploadRawGpsPings': true,
          'reservationCanCreateStops': true,
          'reservationCanConfirmMileage': true,
          'reservationCanModifyOdometer': true,
          'reservationCanSetGlobalTruth': true,
          'reservationCanChangeOfficialMileage': true,
          'hiveRemainsOperationalSourceOfTruth': false,
          'firestoreMirrorOnly': false,
          'remoteCounterCanOverrideLocalLedger': true,
          'remoteReservationCanOverrideLocalUsage': true,
          'remoteBackupCanOverrideLocalDay': true,
          'remoteBackupCanPurgeLocalRecordsSilently': true,
          'odometerRemainsOfficialMileageTruth': false,
          'rawTripPayloadIncluded': true,
          'preciseLocationIncluded': true,
          'tokensIncluded': true,
          'debug': 'sk.secret 35.123456,-80.123456',
        });

    final validation = TripSyncReservationCommitSummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('reservation_local_truth_boundary_missing'),
    );
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_reservation_material'),
    );
  });
}

TripTrackingSyncAttemptDecision attempt({
  TripTrackingSyncAccountTier accountTier = TripTrackingSyncAccountTier.free,
  int? syncsUsed = 0,
}) {
  return TripTrackingSyncAttemptGuard.evaluate(
    TripTrackingSyncAttemptRequest(
      accountTier: accountTier,
      authenticatedUid: 'user-1',
      source: TripTrackingSyncSourceRecord(
        schemaVersion: 1,
        recordId: 'record-1',
        ownerUid: 'user-1',
        deviceId: 'device-1',
        kind: TripTrackingSyncSourceKind.reviewedMileage,
        updatedAtUtc: DateTime.utc(2026, 7, 18),
        localRevision: 1,
        localPersisted: true,
        tripDayKey: '2026-07-18',
        distanceMiles: 12.4,
      ),
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: syncsUsed,
      storageAvailableForSmallRecordWrite: true,
    ),
  );
}
