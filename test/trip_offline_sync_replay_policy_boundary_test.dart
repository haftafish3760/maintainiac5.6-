import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_offline_sync_replay_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sync_reservation_commit_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_attempt_guard.dart';

void main() {
  final source = TripTrackingSyncSourceRecord(
    schemaVersion: 1,
    recordId: 'trip_live_1',
    ownerUid: 'driver_1',
    deviceId: 'device_1',
    kind: TripTrackingSyncSourceKind.liveTrip,
    updatedAtUtc: DateTime.utc(2026, 7, 18, 20),
    localRevision: 1,
    localPersisted: true,
    tripDayKey: '2026-07-18',
  );

  TripTrackingSyncAttemptDecision attempt({
    bool networkAvailable = true,
    bool storageAvailable = true,
  }) {
    return TripTrackingSyncAttemptGuard.evaluate(
      TripTrackingSyncAttemptRequest(
        accountTier: TripTrackingSyncAccountTier.free,
        authenticatedUid: 'driver_1',
        source: source,
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: networkAvailable,
        mobileDataAvailable: false,
        syncsUsedInWindow: 1,
        storageAvailableForSmallRecordWrite: storageAvailable,
      ),
    );
  }

  TripSyncReservationCommitDecision reservation({bool reserved = true}) {
    return TripSyncReservationCommitPolicy.evaluate(
      attemptDecision: attempt(),
      reservationWriteSucceeded: reserved,
    );
  }

  test(
    'ready replay summary keeps local queue and local day authoritative',
    () {
      final decision = TripOfflineSyncReplayPolicy.evaluate(
        attempt: attempt(),
        reservation: reservation(),
        queuedRecordStillExistsLocally: true,
        userStillWantsBackup: true,
      );
      final safe = decision.toSafeSummary();

      expect(decision.status, TripOfflineSyncReplayStatus.ready);
      expect(decision.canReplayQueuedMirror, isTrue);
      expect(decision.shouldKeepLocalQueue, isTrue);
      expect(safe['successfulReplayCanSilentlyDeleteLocalData'], isFalse);
      expect(safe['successfulReplayCanPurgeLocalDaytimeData'], isFalse);
      expect(safe['remoteConflictCanSilentlyWin'], isFalse);
      expect(safe['remoteBackupCanOverrideLocalDay'], isFalse);
      expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
      expect(safe['mapboxCanRepairReplayRecords'], isFalse);
    },
  );

  test('network and reservation blockers retain queued local data', () {
    final waitingNetwork = TripOfflineSyncReplayPolicy.evaluate(
      attempt: attempt(networkAvailable: false),
      reservation: reservation(),
      queuedRecordStillExistsLocally: true,
      userStillWantsBackup: true,
    );
    final waitingReservation = TripOfflineSyncReplayPolicy.evaluate(
      attempt: attempt(),
      reservation: reservation(reserved: false),
      queuedRecordStillExistsLocally: true,
      userStillWantsBackup: true,
    );

    expect(
      waitingNetwork.status,
      TripOfflineSyncReplayStatus.waitingForNetwork,
    );
    expect(waitingNetwork.shouldKeepLocalQueue, isTrue);
    expect(waitingNetwork.shouldRetryLater, isTrue);
    expect(
      waitingReservation.status,
      TripOfflineSyncReplayStatus.waitingForReservation,
    );
    expect(waitingReservation.shouldKeepLocalQueue, isTrue);
    expect(waitingReservation.canReplayQueuedMirror, isFalse);
  });
}
