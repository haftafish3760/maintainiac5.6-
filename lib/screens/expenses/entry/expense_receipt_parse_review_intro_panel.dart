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
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _ReceiptReviewInstructionChip(
              icon: Icons.receipt_long_rounded,
              label: _modeLabel,
              color: const Color(0xFF34A9E8),
            ),
            _ReceiptReviewInstructionChip(
              icon: needsLineReview
                  ? Icons.manage_search_rounded
                  : Icons.verified_rounded,
              label: needsLineReview
                  ? 'Check highlighted lines'
                  : 'No line warnings',
              color: needsLineReview
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF8EF6A4),
            ),
            _ReceiptReviewInstructionChip(
              icon: hasWarnings
                  ? Icons.warning_amber_rounded
                  : Icons.document_scanner_rounded,
              label: _ocrStatusLabel,
              color: hasWarnings
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF8EF6A4),
            ),
            _ReceiptReviewInstructionChip(
              icon: reviewGuidance.reviewIcon,
              label: reviewGuidance.reviewLabel,
              color: reviewGuidance.reviewColor,
            ),
            _ReceiptReviewInstructionChip(
              icon: reviewGuidance.classificationIcon,
              label: reviewGuidance.classificationLabel,
              color: reviewGuidance.classificationColor,
            ),
            if (reviewGuidance.materialPrepLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.inventory_2_rounded,
                label: reviewGuidance.materialPrepLabel,
                color: const Color(0xFF34A9E8),
              ),
            if (reviewGuidance.readyLineLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.playlist_add_check_rounded,
                label: reviewGuidance.readyLineLabel,
                color: const Color(0xFF8EF6A4),
              ),
            if (reviewGuidance.reviewLineLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.manage_search_rounded,
                label: reviewGuidance.reviewLineLabel,
                color: const Color(0xFFFFD166),
              ),
            if (reviewGuidance.lineMapLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.format_list_numbered_rounded,
                label: reviewGuidance.lineMapLabel,
                color: const Color(0xFF34A9E8),
              ),
            if (reviewGuidance.parserTaskSummaryLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.rule_folder_rounded,
                label: reviewGuidance.parserTaskSummaryLabel,
                color: const Color(0xFF34A9E8),
              ),
            if (reviewGuidance.receiptBrainLimitLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.sd_storage_rounded,
                label: reviewGuidance.receiptBrainLimitLabel,
                color: reviewGuidance.receiptBrainLimitColor,
              ),
            if (reviewGuidance.downstreamReadinessLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.hub_rounded,
                label: reviewGuidance.downstreamReadinessLabel,
                color: reviewGuidance.downstreamReadinessColor,
              ),
            if (reviewGuidance.classificationReadinessLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.call_split_rounded,
                label: reviewGuidance.classificationReadinessLabel,
                color: reviewGuidance.classificationReadinessColor,
              ),
            if (reviewGuidance.itemFamilyReviewLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: reviewGuidance.itemFamilyReviewIcon,
                label: reviewGuidance.itemFamilyReviewLabel,
                color: reviewGuidance.itemFamilyReviewColor,
              ),
            if (reviewGuidance.lineIdentityLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.format_list_numbered_rtl_rounded,
                label: reviewGuidance.lineIdentityLabel,
                color: reviewGuidance.lineIdentityColor,
              ),
            if (reviewGuidance.coverageReviewLabel.isNotEmpty)
              _ReceiptReviewInstructionChip(
                icon: Icons.vertical_align_bottom_rounded,
                label: reviewGuidance.coverageReviewLabel,
                color: reviewGuidance.coverageReviewColor,
              ),
            for (final field in reviewGuidance.fieldStatusChips)
              _ReceiptReviewInstructionChip(
                icon: field.icon,
                label: field.label,
                color: field.color,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_showBottomSectionAlert) ...[
          _buildBottomSectionAlert(),
          const SizedBox(height: 8),
        ],
        Text(
          reviewGuidance.detailText,
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
      _ReceiptDetailEntryMode.basicReceipt => 'Basic receipt review',
      _ReceiptDetailEntryMode.quickClassify => 'Simple price review',
      _ReceiptDetailEntryMode.detailedItems => 'Detailed item review',
    };
  }

  String get _ocrStatusLabel {
    final diagnostics = ocrDiagnostics;
    if (diagnostics == null) return 'OCR not measured';
    if (ocrWarnings.isNotEmpty) {
      return '${ocrWarnings.length} OCR ${ocrWarnings.length == 1 ? 'warning' : 'warnings'}';
    }
    return diagnostics.severity == ReceiptOcrReviewSeverity.good
        ? 'OCR looked good'
        : 'OCR needs review';
  }
}
