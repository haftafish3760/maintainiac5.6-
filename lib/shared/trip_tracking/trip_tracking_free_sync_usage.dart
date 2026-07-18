import '../backup/cloud_backup_sync_attempt_store.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_sync_policy.dart';

/// Device-local free-sync usage bridge for trip tracking/dashboard uploads.
///
/// Firestore remains the hosted mirror. This bridge only answers whether this
/// device has already consumed its free local backup attempts in the current
/// rolling 24-hour window, and records an authorized attempt before uploads
/// leave the device. It never accepts remote counters as canonical local truth.
class TripTrackingFreeSyncUsage {
  TripTrackingFreeSyncUsage({
    required CloudBackupSyncAttemptStore attemptStore,
    required String durableScope,
  }) : _attemptStore = attemptStore,
       _durableScope = durableScope;

  final CloudBackupSyncAttemptStore _attemptStore;
  final String _durableScope;
  Future<void> _reservationTail = Future<void>.value();

  int usedInWindowAt(DateTime nowUtc) {
    return _attemptStore.attemptsFor(_durableScope, now: nowUtc.toUtc()).length;
  }

  Future<void> recordAuthorizedAttempt(DateTime nowUtc) {
    return _attemptStore.recordAttempt(_durableScope, at: nowUtc.toUtc());
  }

  int Function() reader({required DateTime Function() nowUtc}) {
    return () => usedInWindowAt(nowUtc().toUtc());
  }

  Future<void> Function(DateTime nowUtc) recorder() {
    return (nowUtc) => recordAuthorizedAttempt(nowUtc);
  }

  TripTrackingBackupSyncDecision evaluate({
    required TripTrackingBackupNetworkPolicy networkPolicy,
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    required DateTime nowUtc,
  }) {
    return TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: networkPolicy,
      wifiAvailable: wifiAvailable,
      mobileDataAvailable: mobileDataAvailable,
      syncsUsedInWindow: usedInWindowAt(nowUtc),
    );
  }

  Future<TripTrackingBackupSyncDecision> reserveAuthorizedAttempt({
    required TripTrackingBackupNetworkPolicy networkPolicy,
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    required DateTime nowUtc,
  }) {
    return _enqueueReservation(() async {
      final decision = evaluate(
        networkPolicy: networkPolicy,
        wifiAvailable: wifiAvailable,
        mobileDataAvailable: mobileDataAvailable,
        nowUtc: nowUtc,
      );
      if (!decision.mayAttemptSync) return decision;
      await recordAuthorizedAttempt(nowUtc);
      return decision;
    });
  }

  Map<String, Object?> toSafeSummary(DateTime nowUtc) => {
    'schemaVersion': 1,
    'durableScope': _safeScopeForSummary(_durableScope),
    'usedInWindow': usedInWindowAt(nowUtc),
    'rollingWindowHours': 24,
    'freeSyncLimitPerWindow': 6,
    'localAttemptLedgerIsCanonical': true,
    'remoteCountersCanOverrideLocalUsage': false,
    'reservationSerializedBeforeUpload': true,
    'blockedAttemptConsumesFreeSync': false,
    'freeSyncQuotaAppliesToTripBackups': true,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'tokensIncluded': false,
    'preciseLocationIncluded': false,
    'rawTripPayloadIncluded': false,
  };

  Future<T> _enqueueReservation<T>(Future<T> Function() task) {
    final result = _reservationTail.then((_) => task());
    _reservationTail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

String _safeScopeForSummary(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.contains(':')) return 'invalid_scope';
  return clean.length <= 80 ? clean : '${clean.substring(0, 77)}...';
}
