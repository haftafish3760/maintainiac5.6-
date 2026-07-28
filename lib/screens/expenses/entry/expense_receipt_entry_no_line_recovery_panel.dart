part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryNoLineRecoveryPanel
    on _ExpenseReceiptEntryScreenState {
  Future<void> _beginManualReceiptLineEntry() async {
    if (_detailEntryMode == _ReceiptDetailEntryMode.basicReceipt) {
      _selectReceiptDetailMode(_ReceiptDetailEntryMode.quickClassify);
    }
    await _addReceiptLineForMode(
      use: _ExpenseLineUse.business,
      category: widget.initialCategory ?? 'Uncategorized',
    );
  }

  Widget _buildReceiptNoLineRecoveryPanel() {
    return ReceiptFormPanel(
      title: _receiptNoLineTitleLabel,
      subtitle: _receiptNoLineSubtitleLabel,
      icon: Icons.edit_note_rounded,
      accentColor: const Color(0xFFFFD166),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Receipt Reading',
                value: _receiptNoLineOcrOutcomeLabel,
                color: const Color(0xFF34A9E8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Receipt Details',
                value: _receiptNoLineParserOutcomeLabel,
                color: const Color(0xFFFFD166),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'What Happened',
                value: _receiptNoLineReasonLabel,
                color: const Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptReviewStepMetric(
                label: 'Next Step',
                value: _receiptNoLineNextStepLabel,
                color: const Color(0xFF8EF6A4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReceiptNoLineRecoveryChip(
              icon: Icons.business_center_rounded,
              label: 'Use Total As Business',
              color: const Color(0xFF34A9E8),
              onPressed: () => _addReceiptTotalLine(
                use: _ExpenseLineUse.business,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
            ),
            _ReceiptNoLineRecoveryChip(
              icon: Icons.person_rounded,
              label: 'Use Total As Personal',
              color: const Color(0xFF8F9BA1),
              onPressed: () => _addReceiptTotalLine(
                use: _ExpenseLineUse.personal,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
            ),
            _ReceiptNoLineRecoveryChip(
              icon: Icons.call_split_rounded,
              label: 'Split Total',
              color: const Color(0xFFFFD166),
              onPressed: () => _addReceiptTotalLine(
                use: _ExpenseLineUse.split,
                category: widget.initialCategory ?? 'Uncategorized',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _beginManualReceiptLineEntry,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _detailEntryMode == _ReceiptDetailEntryMode.basicReceipt
                ? 'Use Basic Receipt Lines'
                : 'Add Line Manually',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD166),
            foregroundColor: const Color(0xFF101416),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
