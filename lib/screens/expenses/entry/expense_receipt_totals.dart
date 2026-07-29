part of 'expense_receipt_entry_screen.dart';

class _ReceiptSavePanel extends StatelessWidget {
  const _ReceiptSavePanel({
    required this.detailMode,
    required this.lineCount,
    required this.reviewCount,
    required this.splitPercentIssueCount,
    required this.total,
    required this.onSave,
  });

  final _ReceiptDetailEntryMode detailMode;
  final int lineCount;
  final int reviewCount;
  final int splitPercentIssueCount;
  final double total;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final issueCount = reviewCount + splitPercentIssueCount;
    final canSave = lineCount > 0 && total > 0;
    final saveLabel =
        'Save $lineCount ${lineCount == 1 ? 'Item' : 'Items'} | ${_money(total)}';
    return ReceiptFormPanel(
      title: 'Save Receipt',
      subtitle: canSave
          ? 'Save this reviewed expense to the ledger for the selected vehicle and work profile.'
          : 'Enter the receipt total and complete its Business, Personal, or Split classification first.',
      icon: Icons.save_rounded,
      accentColor: issueCount > 0
          ? const Color(0xFFFFD166)
          : const Color(0xFF58D67D),
      children: [
        if (issueCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF17140B),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFFFD166)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFD166),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reviewCount > 0)
                        Text(
                          reviewCount == 1
                              ? 'One app-filled line still needs review.'
                              : '$reviewCount app-filled lines still need review.',
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                      if (splitPercentIssueCount > 0)
                        Text(
                          splitPercentIssueCount == 1
                              ? 'One mixed line needs a business percent.'
                              : '$splitPercentIssueCount mixed lines need business percents.',
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
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
  });

  final _ReceiptDetailEntryMode detailMode;
  final double lineSubtotal;
  final TextEditingController receiptSubtotalController;
  final TextEditingController salesTaxController;
  final TextEditingController receiptTotalController;

  @override
  Widget build(BuildContext context) {
    final enteredSubtotal = _parseMoneyInput(receiptSubtotalController.text);
    final enteredTax = _parseMoneyInput(salesTaxController.text);
    final enteredTotal = _parseMoneyInput(receiptTotalController.text);
    final inferredTax =
        enteredTax ??
        (enteredSubtotal != null && enteredTotal != null
            ? enteredTotal - enteredSubtotal
            : null);
    final taxRate =
        enteredSubtotal == null ||
            enteredSubtotal <= 0 ||
            inferredTax == null ||
            inferredTax == 0
        ? null
        : inferredTax / enteredSubtotal;

    return ReceiptFormPanel(
      title: 'Receipt Total',
      subtitle: 'Review the subtotal, sales tax, and final total exactly as printed.',
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
                  helperText: 'Leave blank to infer.',
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        RecordTextField(
          label: 'Final Total After Tax',
          controller: receiptTotalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'Final amount paid, including sales tax.',
        ),
        if (inferredTax != null || taxRate != null) ...[
          const SizedBox(height: 8),
          _ReceiptTaxHint(tax: inferredTax ?? 0, taxRate: taxRate),
        ],
      ],
    );
  }
}

class _ReceiptTaxHint extends StatelessWidget {
  const _ReceiptTaxHint({required this.tax, required this.taxRate});

  final double tax;
  final double? taxRate;

  @override
  Widget build(BuildContext context) {
    final rate = taxRate == null ? '' : ' | ${_percent(taxRate!)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF172C22),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2F7D52)),
      ),
      child: Text(
        'Detected sales tax ${_money(tax)}$rate',
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
