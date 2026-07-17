import '../firebase/hosted_usage_limits.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingBackupSyncPolicy {
  const TripTrackingBackupSyncPolicy._();

  static const int freeSyncsPerWindow =
      HostedUsageLimits.freeUserSyncsPer24HourWindow;

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
    final remaining = syncsUsedInWindow == null
        ? null
        : HostedUsageLimits.freeSyncsRemaining(
            syncsUsedInWindow: syncsUsedInWindow,
          );
    final freeSyncAllowed =
        syncsUsedInWindow != null &&
        HostedUsageLimits.canUseFreeSync(syncsUsedInWindow: syncsUsedInWindow);
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
    if (!_sameWindow(normalizedNow)) {
      return TripTrackingFreeSyncWindowCounter(
        windowStartedAtUtc: normalizedNow,
        syncsUsed: 1,
      );
    }
    return TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: windowStartedAtUtc.toUtc(),
      syncsUsed: syncsUsed < 0 ? 1 : syncsUsed + 1,
    );
  }

  int usedInWindowAt(DateTime nowUtc) {
    if (!_sameWindow(nowUtc.toUtc())) return 0;
    if (syncsUsed < 0) return -1;
    return syncsUsed;
  }

  bool _sameWindow(DateTime nowUtc) {
    final start = windowStartedAtUtc.toUtc();
    return !nowUtc.isBefore(start) &&
        nowUtc.difference(start) < const Duration(hours: 24);
  }
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
    final remaining = freeSyncsRemaining;
    final freeLabel = remaining == null
        ? 'free sync usage pending'
        : '$remaining free sync${remaining == 1 ? '' : 's'} left';
    return 'Sync: $networkLabel; $freeLabel';
  }

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
  if (!networkKnown) return 'network_unknown';
  if (!networkAllowed) return 'network_policy_blocked';
  if (syncsUsedInWindow == null) return 'free_sync_limit_unknown';
  if (!freeSyncAllowed) return 'free_sync_limit_reached';
  return 'sync_ready';
}
