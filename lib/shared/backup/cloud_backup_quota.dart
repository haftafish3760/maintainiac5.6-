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
    this.downloadAllowanceBytes = 0,
  });

  const CloudBackupEntitlement.localOnly()
    : planId = 'local_only',
      displayName = 'Local only',
      quotaBytes = 0,
      dailySyncLimit = 0,
      immediateSyncAllowed = false,
      policyVersion = 0,
      downloadAllowanceBytes = 0;

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
    final downloadAllowanceBytes = payload['downloadAllowanceBytes'];
    const maximumHostedBytes = 1024 * 1024 * 1024 * 1024;
    if (planId is! String ||
        !RegExp(r'^[A-Za-z0-9_.-]{1,80}$').hasMatch(planId) ||
        displayName is! String ||
        displayName.trim() != displayName ||
        displayName.isEmpty ||
        displayName.length > 120 ||
        quotaBytes is! int ||
        quotaBytes < 0 ||
        (quotaBytes > 0 && quotaBytes < 1024) ||
        quotaBytes > maximumHostedBytes ||
        dailySyncLimit is! int ||
        dailySyncLimit < 0 ||
        dailySyncLimit > 100 ||
        immediateSyncAllowed is! bool ||
        policyVersion is! int ||
        policyVersion <= 0 ||
        policyVersion > 9007199254740991) {
      return null;
    }
    if (downloadAllowanceBytes != null &&
        (downloadAllowanceBytes is! int ||
            downloadAllowanceBytes < 0 ||
            downloadAllowanceBytes > maximumHostedBytes)) {
      return null;
    }
    return CloudBackupEntitlement(
      planId: planId,
      displayName: displayName,
      quotaBytes: quotaBytes,
      dailySyncLimit: dailySyncLimit,
      immediateSyncAllowed: immediateSyncAllowed,
      policyVersion: policyVersion,
      downloadAllowanceBytes: downloadAllowanceBytes as int? ?? 0,
    );
  }

  final String planId;
  final String displayName;
  final int quotaBytes;
  final int dailySyncLimit;
  final bool immediateSyncAllowed;
  final int policyVersion;
  final int downloadAllowanceBytes;

  bool get hasCloudStorage => quotaBytes > 0;
  String get quotaLabel => AppStorageGuard.formatBytes(quotaBytes);
  String get downloadAllowanceLabel =>
      AppStorageGuard.formatBytes(downloadAllowanceBytes);
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
            // A local clock rollback must not make an already-recorded sync
            // disappear and grant another user-authorized attempt. Future
            // entries are conservatively consumed until they age out.
            .where((attempt) => !attempt.isBefore(windowStart))
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
