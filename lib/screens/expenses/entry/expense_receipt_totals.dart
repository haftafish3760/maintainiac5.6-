part of 'expense_receipt_entry_screen.dart';

class _ReceiptSavePanel extends StatelessWidget {
  const _ReceiptSavePanel({
    required this.lineCount,
    required this.total,
    required this.onSave,
  });

  final int lineCount;
  final double total;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Save Receipt',
      subtitle: 'Save these lines to the expense ledger for this vehicle.',
      icon: Icons.save_rounded,
      accentColor: const Color(0xFF58D67D),
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check_rounded),
          label: Text('Save $lineCount Lines | ${_money(total)}'),
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
    required this.lineSubtotal,
    required this.receiptSubtotalController,
    required this.salesTaxController,
    required this.receiptTotalController,
  });

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
      title: 'Receipt Totals',
      subtitle:
          'Enter the subtotal, sales tax, and final total exactly as the receipt shows them.',
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
          label: 'Receipt Total',
          controller: receiptTotalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'Final amount paid.',
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
