part of 'expense_receipt_entry_screen.dart';

class _ReceiptSavePanel extends StatelessWidget {
  const _ReceiptSavePanel({
    required this.lineCount,
    required this.total,
    required this.splitPercentIssueCount,
    required this.onSave,
  });

  final int lineCount;
  final double total;
  final int splitPercentIssueCount;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final canSave = lineCount > 0 && total > 0 && splitPercentIssueCount == 0;
    final saveLabel =
        'Save $lineCount ${lineCount == 1 ? 'Item' : 'Items'} | ${_money(total)}';
    return ReceiptFormPanel(
      title: 'Save Receipt',
      subtitle: splitPercentIssueCount > 0
          ? splitPercentIssueCount == 1
                ? 'One split line needs a business percent.'
                : '$splitPercentIssueCount split lines need business percents.'
          : canSave
          ? 'Save this reviewed expense to the ledger for the selected vehicle and work profile.'
          : 'Enter the receipt total and complete its Business, Personal, or Split classification first.',
      icon: Icons.save_rounded,
      accentColor: const Color(0xFF58D67D),
      children: [
        FilledButton.icon(
          onPressed: canSave ? onSave : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(saveLabel),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptTotalsPanel extends StatelessWidget {
  const _ReceiptTotalsPanel({
    required this.detailMode,
    required this.lineSubtotal,
    required this.receiptSubtotalController,
    required this.salesTaxController,
    required this.receiptTotalController,
    this.totalHelperText,
  });

  final _ReceiptDetailEntryMode detailMode;
  final double lineSubtotal;
  final TextEditingController receiptSubtotalController;
  final TextEditingController salesTaxController;
  final TextEditingController receiptTotalController;
  final String? totalHelperText;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Receipt Total',
      subtitle:
          'Review the subtotal, sales tax, and final total exactly as printed.',
      icon: Icons.calculate_rounded,
      accentColor: const Color(0xFF58D67D),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: const Color(0xFF101719),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF445159)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Line subtotal',
                  style: TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                _money(lineSubtotal),
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RecordTextField(
                label: 'Receipt Subtotal',
                controller: receiptSubtotalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                helperText: 'Before tax, if shown.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RecordTextField(
                label: 'Sales Tax',
                controller: salesTaxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                helperText:
                    'Enter the tax amount shown on the receipt, if any.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RecordTextField(
          label: 'Final Total After Tax',
          controller: receiptTotalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText:
              totalHelperText ?? 'Final amount paid, including sales tax.',
        ),
      ],
    );
  }
}
