import '../storage/app_storage_guard.dart';

@Deprecated('Use CloudBackupEntitlement for account backup decisions.')
enum CloudBackupTier {
  localOnly('Local only', 0),
  freeTrial('Free cloud backup', 100 * 1024 * 1024),
  adFreeStarter('Ad-free starter', 250 * 1024 * 1024),
  oneGig('1 GB backup', 1024 * 1024 * 1024),
  fleet('Fleet backup', 50 * 1024 * 1024 * 1024);

  const CloudBackupTier(this.label, this.quotaBytes);

  final String label;
  final int quotaBytes;

  bool get hasCloudStorage => quotaBytes > 0;
  String get quotaLabel => AppStorageGuard.formatBytes(quotaBytes);
}

class CloudBackupEntitlement {
  const CloudBackupEntitlement({
    required this.planId,
    required this.displayName,
    required this.quotaBytes,
    required this.dailySyncLimit,
    required this.immediateSyncAllowed,
    required this.policyVersion,
  });

  const CloudBackupEntitlement.localOnly()
    : planId = 'local_only',
      displayName = 'Local only',
      quotaBytes = 0,
      dailySyncLimit = 0,
      immediateSyncAllowed = false,
      policyVersion = 0;

  /// Decodes a policy supplied after authenticated account authorization.
  /// Invalid or incomplete input deliberately grants no cloud capability.
  static CloudBackupEntitlement? tryParseServerPayload(
    Map<Object?, Object?> payload,
  ) {
    final planId = payload['planId'];
    final displayName = payload['displayName'];
    final quotaBytes = payload['storageQuotaBytes'];
    final dailySyncLimit = payload['dailySyncLimit'];
    final immediateSyncAllowed = payload['immediateSyncAllowed'];
    final policyVersion = payload['policyVersion'];
    if (planId is! String ||
        planId.trim().isEmpty ||
        displayName is! String ||
        displayName.trim().isEmpty ||
        quotaBytes is! int ||
        quotaBytes < 0 ||
        dailySyncLimit is! int ||
        dailySyncLimit < 0 ||
        immediateSyncAllowed is! bool ||
        policyVersion is! int ||
        policyVersion <= 0) {
      return null;
    }
    return CloudBackupEntitlement(
      planId: planId.trim(),
      displayName: displayName.trim(),
      quotaBytes: quotaBytes,
      dailySyncLimit: dailySyncLimit,
      immediateSyncAllowed: immediateSyncAllowed,
      policyVersion: policyVersion,
    );
  }

  final String planId;
  final String displayName;
  final int quotaBytes;
  final int dailySyncLimit;
  final bool immediateSyncAllowed;
  final int policyVersion;

  bool get hasCloudStorage => quotaBytes > 0;
  String get quotaLabel => AppStorageGuard.formatBytes(quotaBytes);
}

class CloudBackupQuotaPolicy {
  const CloudBackupQuotaPolicy._();

  static CloudBackupQuotaCheck check({
    required CloudBackupEntitlement entitlement,
    required int usedBytes,
    required int pendingBytes,
    bool backupEnabled = false,
  }) {
    final safeUsed = usedBytes < 0 ? 0 : usedBytes;
    final safePending = pendingBytes < 0 ? 0 : pendingBytes;
    return CloudBackupQuotaCheck(
      entitlement: entitlement,
      usedBytes: safeUsed,
      pendingBytes: safePending,
      backupEnabled: backupEnabled,
    );
  }
}

/// Local view of a server-authorized rolling sync allowance. The server must
/// enforce this same limit; this model prevents the app from knowingly
/// scheduling an unapproved upload before it reaches the server.
class CloudBackupSyncAllowance {
  const CloudBackupSyncAllowance._({
    required this.entitlement,
    required this.nowUtc,
    required this.attemptsInWindowUtc,
  });

  static const _window = Duration(hours: 24);

  static CloudBackupSyncAllowance evaluate({
    required CloudBackupEntitlement entitlement,
    required Iterable<DateTime> attemptedAt,
    required DateTime now,
  }) {
    final nowUtc = now.toUtc();
    final windowStart = nowUtc.subtract(_window);
    final attempts =
        attemptedAt
            .map((attempt) => attempt.toUtc())
            .where(
              (attempt) =>
                  !attempt.isBefore(windowStart) && !attempt.isAfter(nowUtc),
            )
            .toSet()
            .toList()
          ..sort();
    return CloudBackupSyncAllowance._(
      entitlement: entitlement,
      nowUtc: nowUtc,
      attemptsInWindowUtc: List.unmodifiable(attempts),
    );
  }

  final CloudBackupEntitlement entitlement;
  final DateTime nowUtc;
  final List<DateTime> attemptsInWindowUtc;

  int get limit => entitlement.dailySyncLimit;
  int get used => attemptsInWindowUtc.length;
  int get remaining => (limit - used).clamp(0, limit);
  bool get allowsAttempt => entitlement.hasCloudStorage && used < limit;

  DateTime? get nextEligibleAtUtc {
    if (allowsAttempt || attemptsInWindowUtc.isEmpty) return null;
    return attemptsInWindowUtc.first.add(_window);
  }
}

class CloudBackupQuotaCheck {
  const CloudBackupQuotaCheck({
    required this.entitlement,
    required this.usedBytes,
    required this.pendingBytes,
    required this.backupEnabled,
  });

  final CloudBackupEntitlement entitlement;
  final int usedBytes;
  final int pendingBytes;
  final bool backupEnabled;

  int get quotaBytes => entitlement.quotaBytes;
  int get afterSaveBytes => usedBytes + pendingBytes;
  int get remainingBytes => (quotaBytes - usedBytes).clamp(0, quotaBytes);
  int get remainingAfterSaveBytes =>
      (quotaBytes - afterSaveBytes).clamp(0, quotaBytes);

  bool get isLocalOnly => !backupEnabled || !entitlement.hasCloudStorage;
  bool get allowsLocalSave => true;
  bool get willAttemptCloudBackup => !isLocalOnly && wouldFitCloudTier;
  bool get wouldFitCloudTier =>
      entitlement.hasCloudStorage && afterSaveBytes <= quotaBytes;
  bool get wouldExceedCloudTier =>
      entitlement.hasCloudStorage && afterSaveBytes > quotaBytes;

  String get usedLabel => AppStorageGuard.formatBytes(usedBytes);
  String get pendingLabel => AppStorageGuard.formatBytes(pendingBytes);
  String get quotaLabel => entitlement.quotaLabel;
  String get remainingLabel => AppStorageGuard.formatBytes(remainingBytes);
  String get remainingAfterSaveLabel =>
      AppStorageGuard.formatBytes(remainingAfterSaveBytes);

  String get statusLabel {
    if (isLocalOnly) return 'Off';
    if (wouldExceedCloudTier) return 'Over limit';
    return 'Ready';
  }

  String get detailLabel {
    if (isLocalOnly) {
      return 'Cloud backup is off or no authorized cloud plan is available. Local saving still works.';
    }
    if (wouldExceedCloudTier) {
      return 'This save would put cloud backup at ${AppStorageGuard.formatBytes(afterSaveBytes)} of $quotaLabel.';
    }
    return '$remainingAfterSaveLabel left after this save.';
  }
}
