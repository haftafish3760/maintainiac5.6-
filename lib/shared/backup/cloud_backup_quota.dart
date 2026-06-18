import '../storage/app_storage_guard.dart';

enum CloudBackupTier {
  localOnly('Local only', 0),
  freeTrial('Free cloud backup', 25 * 1024 * 1024),
  adFreeStarter('Ad-free starter', 250 * 1024 * 1024),
  oneGig('1 GB backup', 1024 * 1024 * 1024),
  fleet('Fleet backup', 50 * 1024 * 1024 * 1024);

  const CloudBackupTier(this.label, this.quotaBytes);

  final String label;
  final int quotaBytes;

  bool get hasCloudStorage => quotaBytes > 0;
  String get quotaLabel => AppStorageGuard.formatBytes(quotaBytes);
}

class CloudBackupQuotaPolicy {
  const CloudBackupQuotaPolicy._();

  static const CloudBackupTier defaultTrialTier = CloudBackupTier.freeTrial;

  static CloudBackupQuotaCheck check({
    required CloudBackupTier tier,
    required int usedBytes,
    required int pendingBytes,
    bool backupEnabled = false,
  }) {
    final safeUsed = usedBytes < 0 ? 0 : usedBytes;
    final safePending = pendingBytes < 0 ? 0 : pendingBytes;
    return CloudBackupQuotaCheck(
      tier: tier,
      usedBytes: safeUsed,
      pendingBytes: safePending,
      backupEnabled: backupEnabled,
    );
  }
}

class CloudBackupQuotaCheck {
  const CloudBackupQuotaCheck({
    required this.tier,
    required this.usedBytes,
    required this.pendingBytes,
    required this.backupEnabled,
  });

  final CloudBackupTier tier;
  final int usedBytes;
  final int pendingBytes;
  final bool backupEnabled;

  int get quotaBytes => tier.quotaBytes;
  int get afterSaveBytes => usedBytes + pendingBytes;
  int get remainingBytes => (quotaBytes - usedBytes).clamp(0, quotaBytes);
  int get remainingAfterSaveBytes =>
      (quotaBytes - afterSaveBytes).clamp(0, quotaBytes);

  bool get isLocalOnly => !backupEnabled || !tier.hasCloudStorage;
  bool get allowsLocalSave => true;
  bool get willAttemptCloudBackup => !isLocalOnly && wouldFitCloudTier;
  bool get wouldFitCloudTier =>
      tier.hasCloudStorage && afterSaveBytes <= quotaBytes;
  bool get wouldExceedCloudTier =>
      tier.hasCloudStorage && afterSaveBytes > quotaBytes;

  String get usedLabel => AppStorageGuard.formatBytes(usedBytes);
  String get pendingLabel => AppStorageGuard.formatBytes(pendingBytes);
  String get quotaLabel => tier.quotaLabel;
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
      return 'Cloud backup is off. The first cloud tier is ${CloudBackupQuotaPolicy.defaultTrialTier.quotaLabel}.';
    }
    if (wouldExceedCloudTier) {
      return 'This save would put cloud backup at ${AppStorageGuard.formatBytes(afterSaveBytes)} of $quotaLabel.';
    }
    return '$remainingAfterSaveLabel left after this save.';
  }
}
