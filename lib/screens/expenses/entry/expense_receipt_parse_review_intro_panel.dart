part of 'expense_receipt_entry_screen.dart';

class _ReceiptAppAssistedReviewIntroPanel extends StatelessWidget {
  const _ReceiptAppAssistedReviewIntroPanel({
    required this.lineCount,
    required this.unreviewedLineCount,
    required this.receiptTotalLabel,
    required this.detailMode,
    required this.ocrDiagnostics,
    required this.parseDiagnostics,
    required this.ocrWarnings,
    required this.onAddMissingBottomSection,
  });

  final int lineCount;
  final int unreviewedLineCount;
  final String receiptTotalLabel;
  final _ReceiptDetailEntryMode detailMode;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final ExpenseReceiptParseDiagnostics? parseDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;
  final VoidCallback onAddMissingBottomSection;

  @override
  Widget build(BuildContext context) {
    final hasWarnings = ocrWarnings.isNotEmpty;
    final needsLineReview = unreviewedLineCount > 0;
    final reviewGuidance = _ReceiptAssistedReviewGuidance.from(
      detailMode: detailMode,
      lineCount: lineCount,
      unreviewedLineCount: unreviewedLineCount,
      diagnostics: ocrDiagnostics,
      parseDiagnostics: parseDiagnostics,
      hasWarnings: hasWarnings,
    );
    final accent = hasWarnings || needsLineReview
        ? const Color(0xFFFFD166)
        : const Color(0xFF8EF6A4);
    return ReceiptFormPanel(
      title: 'Review What The App Filled In',
      subtitle:
          'Check the store, date, total, tax, and item prices. Then classify the receipt as Business, Personal, or Mixed before saving.',
      icon: Icons.fact_check_rounded,
      accentColor: accent,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Lines Found',
                value: '$lineCount',
                color: const Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Needs Review',
                value: '$unreviewedLineCount',
                color: needsLineReview
                    ? const Color(0xFFFFD166)
                    : const Color(0xFF8EF6A4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Total',
                value: receiptTotalLabel,
                color: const Color(0xFF34A9E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ReceiptReviewNextStepCallout(
          label: reviewGuidance.primaryNextStepLabel,
          color: reviewGuidance.primaryNextStepColor,
          icon: reviewGuidance.primaryNextStepIcon,
        ),
        const SizedBox(height: 6),
        Text(
          _modeLabel,
          style: const TextStyle(
            color: Color(0xFF8BBFDD),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          needsLineReview
              ? 'Check highlighted lines • $_ocrStatusLabel'
              : 'No line warnings • $_ocrStatusLabel',
          style: TextStyle(
            color: needsLineReview
                ? const Color(0xFFFFD166)
                : const Color(0xFF8EF6A4),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (_showBottomSectionAlert) ...[
          _buildBottomSectionAlert(),
          const SizedBox(height: 8),
        ],
        Text(
          '$lineCount ${lineCount == 1 ? 'line is' : 'lines are'} ready below. '
          'Edit anything that does not match the receipt, then choose Business, Personal, or Split before saving.',
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.22,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String get _modeLabel {
    return switch (detailMode) {
      _ReceiptDetailEntryMode.basicReceipt => 'Simple receipt review',
      _ReceiptDetailEntryMode.quickClassify => 'Basic price review',
      _ReceiptDetailEntryMode.detailedItems => 'Detailed item review',
    };
  }

  String get _ocrStatusLabel {
    final diagnostics = ocrDiagnostics;
    if (ocrWarnings.isNotEmpty) {
      return '${ocrWarnings.length} receipt reading ${ocrWarnings.length == 1 ? 'warning' : 'warnings'}';
    }
    if (diagnostics == null) return 'Receipt text is ready for review';
    return diagnostics.severity == ReceiptOcrReviewSeverity.good
        ? 'Receipt reading looked good'
        : 'Receipt reading needs review';
  }

}
