part of 'expense_export_models.dart';

Map<String, Object?> _expenseExportCommandCenterOcrContract(
  ExpenseExportSnapshot snapshot,
) {
  final contract = {
    'schema': ExpenseExportSnapshot.commandCenterOcrContractSchema,
    'privacyScope': ExpenseExportSnapshot.commandCenterOcrPrivacyScope,
    'contentPolicy': ExpenseExportSnapshot.commandCenterOcrContentPolicy,
    'rangeStart': snapshot.range.start.toIso8601String(),
    'rangeEnd': snapshot.range.end.toIso8601String(),
    'categoryFilter': snapshot.categoryFilter.name,
    'source': snapshot.source.name,
    'destination': snapshot.destination.name,
    'receiptCount': snapshot.receiptCount,
    'receiptsWithOcrReview': snapshot.receiptsWithOcrReview,
    'receiptsNeedingOcrReview': snapshot.receiptsNeedingOcrReview,
    'ocrReadsSaved': snapshot.ocrReadsSaved,
    'ocrCleanReadCount': snapshot.ocrCleanReadCount,
    'ocrReadStatus': snapshot.ocrReadStatus,
    'ocrReadSummary': snapshot.ocrReadSummary,
    'ocrWarningCount': snapshot.totalOcrWarningCount,
    'ocrBlockingWarningCount': snapshot.totalOcrBlockingWarningCount,
    'ocrPartialWarningCount': snapshot.totalOcrPartialWarningCount,
    'ocrReviewWarningCount': snapshot.totalOcrReviewWarningCount,
    'ocrSourceCounts': snapshot.ocrSourceCounts,
    'ocrTopSource': snapshot.ocrTopSource,
    'ocrPrimaryWarningKindCounts': snapshot.ocrPrimaryWarningKindCounts,
    'ocrRecoveryActionCounts': snapshot.ocrRecoveryActionCounts,
    'ocrRecoveryTargetCounts': snapshot.ocrRecoveryTargetCounts,
    'ocrTopCheck': snapshot.ocrTopCheck,
    'ocrTopPrimaryIssue': snapshot.ocrTopPrimaryIssue,
    'ocrTopPrimaryAction': snapshot.ocrTopPrimaryAction,
    'ocrTopRecoveryAction': snapshot.ocrTopRecoveryAction,
    'ocrTopRecoveryTarget': snapshot.ocrTopRecoveryTarget,
  };
  assert(_isCommandCenterOcrContractSafe(contract));
  return contract;
}
