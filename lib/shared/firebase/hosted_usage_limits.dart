class HostedUsageLimits {
  const HostedUsageLimits._();

  static const int freeCloudStorageBytes = 25 * 1024 * 1024;
  static const int freeMonthlyExports = 1;
  static const int freeAiInputTokens = 0;
  static const int freeAiOutputTokens = 0;
  static const int maxAccountsPerInstallInReviewWindow = 2;
  static const int maxAccountsPerIpInReviewWindow = 2;

  static const String freeCloudStorageLabel = '25 MB';
  static const String freeExportLabel = '1 export per month';
}
