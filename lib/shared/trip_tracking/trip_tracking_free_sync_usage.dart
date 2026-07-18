import '../backup/cloud_backup_sync_attempt_store.dart';
import '../firebase/hosted_usage_limits.dart';
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

  static String durableScopeForDevice({
    required String accountUid,
    required String deviceId,
    String moduleToken = 'trip-dashboard',
  }) {
    final safeModule = _safeScopeComponent(moduleToken, maxLength: 40);
    final safeAccount = _safeScopeComponent(accountUid, maxLength: 80);
    final safeDevice = _safeScopeComponent(deviceId, maxLength: 80);
    if (safeModule == null || safeAccount == null || safeDevice == null) {
      throw ArgumentError.value(
        'redacted',
        'scope',
        'Trip backup free-sync scope requires safe module, account, and device ids.',
      );
    }
    return '$safeModule.$safeAccount.$safeDevice';
  }

  int usedInWindowAt(DateTime nowUtc) {
    return _attemptStore.attemptsFor(_durableScope, now: nowUtc.toUtc()).length;
  }

  int? safeUsedInWindowAt(DateTime nowUtc) {
    try {
      return usedInWindowAt(nowUtc);
    } on ArgumentError {
      return null;
    }
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
      final TripTrackingBackupSyncDecision decision;
      try {
        decision = evaluate(
          networkPolicy: networkPolicy,
          wifiAvailable: wifiAvailable,
          mobileDataAvailable: mobileDataAvailable,
          nowUtc: nowUtc,
        );
      } on ArgumentError {
        return TripTrackingBackupSyncPolicy.evaluate(
          networkPolicy: networkPolicy,
          wifiAvailable: wifiAvailable,
          mobileDataAvailable: mobileDataAvailable,
          syncsUsedInWindow: -1,
        );
      }
      if (!decision.mayAttemptSync) return decision;
      await recordAuthorizedAttempt(nowUtc);
      return decision;
    });
  }

  Map<String, Object?> toSafeSummary(DateTime nowUtc) {
    final used = safeUsedInWindowAt(nowUtc);
    final usageVerified = used != null;
    return {
      'schemaVersion': 1,
      'durableScope': _safeScopeForSummary(_durableScope),
      'usedInWindow': used,
      'usageVerified': usageVerified,
      'usageFailureFailsClosed': !usageVerified,
      'rollingWindowHours': 24,
      'freeSyncLimitPerWindow': 6,
      'localAttemptLedgerIsCanonical': true,
      'remoteCountersCanOverrideLocalUsage': false,
      'firebaseAuthDoesNotSupplyUsageCounter': true,
      'accountScopeMustBeDeviceLocal': true,
      'uploadMustReserveBeforeNetwork': true,
      'reservationSerializedBeforeUpload': true,
      'blockedAttemptConsumesFreeSync': false,
      'freeSyncQuotaAppliesToTripBackups': true,
      'freeSyncLimitMatchesHostedPolicy':
          HostedUsageLimits.freeUserSyncsPer24HourWindow == 6,
      'remoteQuotaResetCanOverrideLocalWindow': false,
      'cloudFunctionCanGrantExtraFreeSyncs': false,
      'firestoreCounterCanConsumeFreeSync': false,
      'failedNetworkUploadConsumesFreeSyncAfterReservation': true,
      'failedPreflightConsumesFreeSync': false,
      'quotaScopeIncludesDeviceId': true,
      'quotaScopeIncludesAccountUid': true,
      'quotaScopeIncludesModuleToken': true,
      'hiveRemainsSourceOfTruth': true,
      'firestoreMirrorOnly': true,
      'tokensIncluded': false,
      'preciseLocationIncluded': false,
      'rawTripPayloadIncluded': false,
    };
  }

  Future<T> _enqueueReservation<T>(Future<T> Function() task) {
    final result = _reservationTail.then((_) => task());
    _reservationTail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

class TripTrackingFreeSyncUsageSummaryValidation {
  const TripTrackingFreeSyncUsageSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripTrackingFreeSyncUsageSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) reasons.add('unsupported_schema');
    if (summary['rollingWindowHours'] != 24 ||
        summary['freeSyncLimitPerWindow'] != 6 ||
        summary['freeSyncLimitMatchesHostedPolicy'] != true) {
      reasons.add('free_sync_limit_contract_mismatch');
    }
    if (summary['localAttemptLedgerIsCanonical'] != true ||
        summary['remoteCountersCanOverrideLocalUsage'] != false ||
        summary['remoteQuotaResetCanOverrideLocalWindow'] != false ||
        summary['cloudFunctionCanGrantExtraFreeSyncs'] != false ||
        summary['firestoreCounterCanConsumeFreeSync'] != false) {
      reasons.add('remote_quota_authority_claimed');
    }
    if (summary['uploadMustReserveBeforeNetwork'] != true ||
        summary['reservationSerializedBeforeUpload'] != true ||
        summary['blockedAttemptConsumesFreeSync'] != false ||
        summary['failedPreflightConsumesFreeSync'] != false) {
      reasons.add('reservation_boundary_missing');
    }
    if (summary['quotaScopeIncludesDeviceId'] != true ||
        summary['quotaScopeIncludesAccountUid'] != true ||
        summary['quotaScopeIncludesModuleToken'] != true ||
        summary['accountScopeMustBeDeviceLocal'] != true) {
      reasons.add('quota_scope_boundary_missing');
    }
    if (summary['hiveRemainsSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true) {
      reasons.add('source_of_truth_boundary_missing');
    }
    if (summary['tokensIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['rawTripPayloadIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_quota_material');
    }
    return TripTrackingFreeSyncUsageSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
}

String _safeScopeForSummary(String value) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean.contains(':') ||
      !_safeScopePattern.hasMatch(clean)) {
    return 'invalid_scope';
  }
  return clean.length <= 80 ? clean : '${clean.substring(0, 77)}...';
}

final RegExp _safeScopePattern = RegExp(r'^[A-Za-z0-9_.-]+$');

String? _safeScopeComponent(String value, {required int maxLength}) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean != value ||
      clean.contains(':') ||
      clean.length > maxLength ||
      !_safeScopePattern.hasMatch(clean) ||
      _looksLikeCredential(clean)) {
    return null;
  }
  return clean;
}

bool _looksLikeCredential(String value) {
  final lower = value.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.startsWith('pk.') ||
      lower.startsWith('sk.');
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
}
