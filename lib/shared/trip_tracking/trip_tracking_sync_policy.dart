import '../firebase/hosted_usage_limits.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingBackupSyncPolicy {
  const TripTrackingBackupSyncPolicy._();

  static const int freeSyncsPerWindow =
      HostedUsageLimits.freeUserSyncsPer24HourWindow;
  static const int maximumVerifiableSyncsUsedInWindow = 999;

  static TripTrackingBackupSyncDecision evaluate({
    required TripTrackingBackupNetworkPolicy networkPolicy,
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    int? syncsUsedInWindow,
  }) {
    final networkKnown = wifiAvailable != null && mobileDataAvailable != null;
    final networkAllowed = networkKnown
        ? networkPolicy.allows(
            wifiAvailable: wifiAvailable,
            mobileDataAvailable: mobileDataAvailable,
          )
        : false;
    final safeSyncsUsed = _verifiableSyncsUsedInWindow(syncsUsedInWindow);
    final remaining = safeSyncsUsed == null
        ? null
        : HostedUsageLimits.freeSyncsRemaining(
            syncsUsedInWindow: safeSyncsUsed,
          );
    final freeSyncAllowed =
        safeSyncsUsed != null &&
        HostedUsageLimits.canUseFreeSync(syncsUsedInWindow: safeSyncsUsed);
    final reasonCode = _reasonCode(
      networkKnown: networkKnown,
      networkAllowed: networkAllowed,
      freeSyncAllowed: freeSyncAllowed,
      syncsUsedInWindow: syncsUsedInWindow,
    );
    return TripTrackingBackupSyncDecision(
      networkPolicy: networkPolicy,
      networkKnown: networkKnown,
      networkAllowed: networkAllowed,
      freeSyncAllowed: freeSyncAllowed,
      freeSyncsRemaining: remaining,
      reasonCode: reasonCode,
    );
  }
}

class TripTrackingFreeSyncWindowCounter {
  const TripTrackingFreeSyncWindowCounter({
    required this.windowStartedAtUtc,
    required this.syncsUsed,
  });

  final DateTime windowStartedAtUtc;
  final int syncsUsed;

  TripTrackingFreeSyncWindowCounter recordAttempt(DateTime nowUtc) {
    final normalizedNow = nowUtc.toUtc();
    if (_clockMovedBeforeWindow(normalizedNow)) {
      return TripTrackingFreeSyncWindowCounter(
        windowStartedAtUtc: windowStartedAtUtc.toUtc(),
        syncsUsed: -1,
      );
    }
    if (!_sameWindow(normalizedNow)) {
      return TripTrackingFreeSyncWindowCounter(
        windowStartedAtUtc: normalizedNow,
        syncsUsed: 1,
      );
    }
    if (_hasInvalidUsageCount) {
      return TripTrackingFreeSyncWindowCounter(
        windowStartedAtUtc: windowStartedAtUtc.toUtc(),
        syncsUsed: -1,
      );
    }
    return TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: windowStartedAtUtc.toUtc(),
      syncsUsed: syncsUsed + 1,
    );
  }

  int usedInWindowAt(DateTime nowUtc) {
    if (_clockMovedBeforeWindow(nowUtc.toUtc())) return -1;
    if (!_sameWindow(nowUtc.toUtc())) return 0;
    if (_hasInvalidUsageCount) return -1;
    return syncsUsed;
  }

  DateTime expiresAtUtc() =>
      windowStartedAtUtc.toUtc().add(const Duration(hours: 24));

  int? secondsUntilResetAt(DateTime nowUtc) {
    if (_clockMovedBeforeWindow(nowUtc.toUtc())) return 86400;
    if (!_sameWindow(nowUtc.toUtc())) return 0;
    final remaining = expiresAtUtc().difference(nowUtc.toUtc()).inSeconds;
    if (remaining < 0) return 0;
    return remaining > 86400 ? 86400 : remaining;
  }

  Map<String, Object?> toSafeSummary(DateTime nowUtc) {
    final used = usedInWindowAt(nowUtc);
    return {
      'schemaVersion': 1,
      'windowState': used < 0
          ? 'invalid'
          : used == 0
          ? 'empty_or_reset'
          : 'active',
      'syncsUsedInWindow': used,
      'freeSyncsRemaining': used < 0
          ? null
          : HostedUsageLimits.freeSyncsRemaining(syncsUsedInWindow: used),
      'secondsUntilReset': secondsUntilResetAt(nowUtc),
      'windowHours': 24,
      'freePlanSyncLimit': TripTrackingBackupSyncPolicy.freeSyncsPerWindow,
      'hiveRemainsSourceOfTruth': true,
      'firestoreMirrorOnly': true,
      'canOverrideLocalDaytimeData': false,
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    };
  }

  bool _sameWindow(DateTime nowUtc) {
    final start = windowStartedAtUtc.toUtc();
    return !nowUtc.isBefore(start) &&
        nowUtc.difference(start) < const Duration(hours: 24);
  }

  bool _clockMovedBeforeWindow(DateTime nowUtc) =>
      nowUtc.toUtc().isBefore(windowStartedAtUtc.toUtc());

  bool get _hasInvalidUsageCount =>
      syncsUsed < 0 ||
      syncsUsed >
          TripTrackingBackupSyncPolicy.maximumVerifiableSyncsUsedInWindow;
}

class TripTrackingBackupSyncDecision {
  const TripTrackingBackupSyncDecision({
    required this.networkPolicy,
    required this.networkKnown,
    required this.networkAllowed,
    required this.freeSyncAllowed,
    required this.freeSyncsRemaining,
    required this.reasonCode,
  });

  final TripTrackingBackupNetworkPolicy networkPolicy;
  final bool networkKnown;
  final bool networkAllowed;
  final bool freeSyncAllowed;
  final int? freeSyncsRemaining;
  final String reasonCode;

  bool get mayAttemptSync => networkAllowed && freeSyncAllowed;

  String get networkLabel {
    return switch (networkPolicy) {
      TripTrackingBackupNetworkPolicy.wifiOnly => 'Wi-Fi only',
      TripTrackingBackupNetworkPolicy.wifiAndMobileData =>
        'Wi-Fi or mobile data',
      TripTrackingBackupNetworkPolicy.mobileDataOnly => 'mobile data only',
    };
  }

  String get dashboardLabel {
    final freeLabel = _freeSyncLabel;
    return 'Sync: $networkLabel; $freeLabel';
  }

  String get _freeSyncLabel {
    if (reasonCode == 'free_sync_limit_invalid') {
      return 'free sync usage unverified';
    }
    final remaining = freeSyncsRemaining;
    if (remaining == null) return 'free sync usage pending';
    return '$remaining free sync${remaining == 1 ? '' : 's'} left';
  }

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'networkPolicy': networkPolicy.name,
    'networkKnown': networkKnown,
    'networkAllowed': networkAllowed,
    'freeSyncAllowed': freeSyncAllowed,
    'freeSyncsRemaining': freeSyncsRemaining,
    'mayAttemptSync': mayAttemptSync,
    'reasonCode': reasonCode,
    'label': dashboardLabel,
    'freePlanSyncLimit': TripTrackingBackupSyncPolicy.freeSyncsPerWindow,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'canOverrideLocalDaytimeData': false,
    'canUploadRawGps': false,
    'tokensIncluded': false,
    'locationDataIncluded': false,
    'rawModuleDataIncluded': false,
  };

  String get userFacingReason {
    return switch (reasonCode) {
      'sync_ready' => 'Backup sync is ready.',
      'network_unknown' => 'Backup sync is waiting for network status.',
      'network_policy_blocked' =>
        'Backup sync is waiting for the selected network.',
      'free_sync_limit_invalid' =>
        'Free backup sync usage could not be verified.',
      'free_sync_limit_unknown' =>
        'Free backup sync usage is still being verified.',
      'free_sync_limit_reached' =>
        'Free backup sync limit reached for this 24-hour window.',
      _ => 'Backup sync is waiting.',
    };
  }
}

String _reasonCode({
  required bool networkKnown,
  required bool networkAllowed,
  required bool freeSyncAllowed,
  required int? syncsUsedInWindow,
}) {
  if (syncsUsedInWindow != null && syncsUsedInWindow < 0) {
    return 'free_sync_limit_invalid';
  }
  if (syncsUsedInWindow != null &&
      syncsUsedInWindow >
          TripTrackingBackupSyncPolicy.maximumVerifiableSyncsUsedInWindow) {
    return 'free_sync_limit_invalid';
  }
  if (!networkKnown) return 'network_unknown';
  if (!networkAllowed) return 'network_policy_blocked';
  if (syncsUsedInWindow == null) return 'free_sync_limit_unknown';
  if (!freeSyncAllowed) return 'free_sync_limit_reached';
  return 'sync_ready';
}

int? _verifiableSyncsUsedInWindow(int? value) {
  if (value == null) return null;
  if (value < 0 ||
      value > TripTrackingBackupSyncPolicy.maximumVerifiableSyncsUsedInWindow) {
    return null;
  }
  return value;
}
