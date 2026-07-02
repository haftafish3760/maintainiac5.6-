part of 'expense_receipt_entry_screen.dart';

class _ReceiptAssistedReviewGuidance {
  const _ReceiptAssistedReviewGuidance({
    required this.reviewLabel,
    required this.reviewIcon,
    required this.reviewColor,
    required this.classificationLabel,
    required this.classificationIcon,
    required this.classificationColor,
    required this.materialPrepLabel,
    required this.readyLineLabel,
    required this.reviewLineLabel,
    required this.lineMapLabel,
    required this.parserTaskSummaryLabel,
    required this.receiptBrainLimitLabel,
    required this.receiptBrainLimitColor,
    required this.downstreamReadinessLabel,
    required this.downstreamReadinessColor,
    required this.classificationReadinessLabel,
    required this.classificationReadinessColor,
    required this.itemFamilyReviewLabel,
    required this.itemFamilyReviewIcon,
    required this.itemFamilyReviewColor,
    required this.lineIdentityLabel,
    required this.lineIdentityColor,
    required this.coverageReviewLabel,
    required this.coverageReviewColor,
    required this.primaryNextStepLabel,
    required this.primaryNextStepIcon,
    required this.primaryNextStepColor,
    required this.fieldStatusChips,
    required this.detailText,
  });

  final String reviewLabel;
  final IconData reviewIcon;
  final Color reviewColor;
  final String classificationLabel;
  final IconData classificationIcon;
  final Color classificationColor;
  final String materialPrepLabel;
  final String readyLineLabel;
  final String reviewLineLabel;
  final String lineMapLabel;
  final String parserTaskSummaryLabel;
  final String receiptBrainLimitLabel;
  final Color receiptBrainLimitColor;
  final String downstreamReadinessLabel;
  final Color downstreamReadinessColor;
  final String classificationReadinessLabel;
  final Color classificationReadinessColor;
  final String itemFamilyReviewLabel;
  final IconData itemFamilyReviewIcon;
  final Color itemFamilyReviewColor;
  final String lineIdentityLabel;
  final Color lineIdentityColor;
  final String coverageReviewLabel;
  final Color coverageReviewColor;
  final String primaryNextStepLabel;
  final IconData primaryNextStepIcon;
  final Color primaryNextStepColor;
  final List<_ReceiptFieldStatusChipData> fieldStatusChips;
  final String detailText;

  factory _ReceiptAssistedReviewGuidance.from({
    required _ReceiptDetailEntryMode detailMode,
    required int lineCount,
    required int unreviewedLineCount,
    required ReceiptOcrDiagnostics? diagnostics,
    required ExpenseReceiptParseDiagnostics? parseDiagnostics,
    required bool hasWarnings,
  }) => _receiptAssistedReviewGuidanceFrom(
    detailMode: detailMode,
    lineCount: lineCount,
    unreviewedLineCount: unreviewedLineCount,
    diagnostics: diagnostics,
    parseDiagnostics: parseDiagnostics,
    hasWarnings: hasWarnings,
  );
}
