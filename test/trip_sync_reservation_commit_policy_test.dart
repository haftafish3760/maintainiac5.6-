import 'package:flutter_test/flutter_test.dart';
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
      attemptDecision: attempt(syncsUsed: 6),
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

    expect(safe['freePlanSyncLimitPer24Hours'], 6);
    expect(safe['blockedAttemptConsumesFreeSync'], isFalse);
    expect(safe['uploadWithoutReservationAllowed'], isFalse);
    expect(safe['reservationCanDeleteLocalData'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['remoteCounterCanOverrideLocalLedger'], isFalse);
    expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawTripPayloadIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
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
