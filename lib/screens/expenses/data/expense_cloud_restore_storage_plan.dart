import 'expense_cloud_restore_codec.dart';

enum ExpenseCloudRestoreMode { full, smart, recordsOnly }

/// Storage facts required before an Expense restore may begin.
///
/// This is deliberately pure: the restore UI supplies measured local storage
/// and structured-record estimates, then refuses a transfer that cannot safely
/// finish on-device.
class ExpenseCloudRestoreStoragePlan {
  const ExpenseCloudRestoreStoragePlan._({
    required this.mode,
    required this.knownDownloadBytes,
    required this.installedBytes,
    required this.temporaryBytes,
    required this.requiredAvailableBytes,
    required this.availableBytes,
    required this.proofsWithUnknownSize,
  });

  factory ExpenseCloudRestoreStoragePlan.forMode({
    required ExpenseCloudRestoreMode mode,
    required ExpenseCloudRestoreEstimate estimate,
    required int availableBytes,
    int structuredRecordBytes = 0,
  }) {
    final records = structuredRecordBytes < 0 ? 0 : structuredRecordBytes;
    final proofBytes = mode == ExpenseCloudRestoreMode.full
        ? estimate.knownProofBytes
        : 0;
    final unknownProofs = mode == ExpenseCloudRestoreMode.full
        ? estimate.proofsWithUnknownSize
        : 0;
    final installed = records + proofBytes;
    // A downloaded proof must coexist with its retained installed copy until
    // its hash and write both succeed.
    final temporary = records + proofBytes;
    return ExpenseCloudRestoreStoragePlan._(
      mode: mode,
      knownDownloadBytes: records + proofBytes,
      installedBytes: installed,
      temporaryBytes: temporary,
      requiredAvailableBytes: installed + temporary,
      availableBytes: availableBytes < 0 ? 0 : availableBytes,
      proofsWithUnknownSize: unknownProofs,
    );
  }

  final ExpenseCloudRestoreMode mode;
  final int knownDownloadBytes;
  final int installedBytes;
  final int temporaryBytes;
  final int requiredAvailableBytes;
  final int availableBytes;
  final int proofsWithUnknownSize;

  bool get hasCompleteDownloadEstimate => proofsWithUnknownSize == 0;
  bool get hasEnoughAvailableStorage =>
      availableBytes >= requiredAvailableBytes;
  bool get canStart => hasCompleteDownloadEstimate && hasEnoughAvailableStorage;
}
