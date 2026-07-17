/// Server-issued hosted usage policy. The client has no built-in storage,
/// export, or AI allowance; absent or malformed grants authorize nothing.
class HostedUsageGrant {
  const HostedUsageGrant({
    required this.storageQuotaBytes,
    required this.monthlyExportLimit,
    required this.aiInputTokenLimit,
    required this.aiOutputTokenLimit,
    required this.policyVersion,
  });

  static HostedUsageGrant? tryParse(Map<Object?, Object?> payload) {
    final storage = payload['storageQuotaBytes'];
    final exports = payload['monthlyExportLimit'];
    final input = payload['aiInputTokenLimit'];
    final output = payload['aiOutputTokenLimit'];
    final version = payload['policyVersion'];
    if (storage is! int ||
        storage < 0 ||
        exports is! int ||
        exports < 0 ||
        input is! int ||
        input < 0 ||
        output is! int ||
        output < 0 ||
        version is! int ||
        version <= 0) {
      return null;
    }
    return HostedUsageGrant(
      storageQuotaBytes: storage,
      monthlyExportLimit: exports,
      aiInputTokenLimit: input,
      aiOutputTokenLimit: output,
      policyVersion: version,
    );
  }

  final int storageQuotaBytes;
  final int monthlyExportLimit;
  final int aiInputTokenLimit;
  final int aiOutputTokenLimit;
  final int policyVersion;
}

class HostedUsageLimits {
  const HostedUsageLimits._();

  static const int maxAccountsPerInstallInReviewWindow = 2;
  static const int maxAccountsPerIpInReviewWindow = 2;
  static const int freeUserSyncsPer24HourWindow = 6;

  static bool canUseFreeSync({required int syncsUsedInWindow}) =>
      syncsUsedInWindow >= 0 &&
      syncsUsedInWindow < freeUserSyncsPer24HourWindow;

  static int freeSyncsRemaining({required int syncsUsedInWindow}) {
    if (syncsUsedInWindow < 0) return freeUserSyncsPer24HourWindow;
    final remaining = freeUserSyncsPer24HourWindow - syncsUsedInWindow;
    return remaining <= 0 ? 0 : remaining;
  }
}
