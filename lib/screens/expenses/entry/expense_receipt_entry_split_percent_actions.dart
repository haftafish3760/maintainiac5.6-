part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntrySplitPercentActions
    on _ExpenseReceiptEntryScreenState {
  Future<ExpenseSplitAllocation?> _chooseSplitAllocation(int index) async {
    final method = await _chooseSplitAllocationMethod(index);
    if (!mounted || method == null) return null;
    if (method == ExpenseSplitAllocationMethod.percentage) {
      final percent = await _chooseSplitBusinessPercent(index);
      if (percent == null) return null;
      return ExpenseSplitAllocation(method: method, businessValue: percent);
    }
    return _chooseSplitValue(index: index, method: method);
  }

  Future<ExpenseSplitAllocationMethod?> _chooseSplitAllocationMethod(
    int index,
  ) {
    return showModalBottomSheet<ExpenseSplitAllocationMethod>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          child: ReceiptFormPanel(
            title: 'Split method',
            subtitle:
                'Choose how to enter the business portion for line ${index + 1}. The personal remainder is calculated automatically.',
            icon: Icons.call_split_rounded,
            accentColor: const Color(0xFF3B7C73),
            children: [
              for (final method in ExpenseSplitAllocationMethod.values) ...[
                _SplitAllocationMethodButton(
                  method: method,
                  onPressed: () => Navigator.of(context).pop(method),
                ),
                if (method != ExpenseSplitAllocationMethod.values.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<ExpenseSplitAllocation?> _chooseSplitValue({
    required int index,
    required ExpenseSplitAllocationMethod method,
  }) async {
    final line = _lines[index];
    final initialValue = line.splitAllocation?.method == method
        ? line.splitAllocation!.businessValue
        : method == ExpenseSplitAllocationMethod.amount
        ? line.subtotal.abs() / 2
        : line.quantity / 2;
    final controller = TextEditingController(text: _formatNumber(initialValue));
    try {
      return await showModalBottomSheet<ExpenseSplitAllocation>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              10,
              10,
              MediaQuery.viewInsetsOf(context).bottom + 14,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                ReceiptFormPanel(
                  title: method == ExpenseSplitAllocationMethod.amount
                      ? 'Business dollar amount'
                      : 'Business quantity',
                  subtitle: method == ExpenseSplitAllocationMethod.amount
                      ? 'Enter the business dollar portion. The remaining line amount stays personal.'
                      : 'Enter the business quantity. The remaining receipt quantity stays personal.',
                  icon: method == ExpenseSplitAllocationMethod.amount
                      ? Icons.attach_money_rounded
                      : Icons.numbers_rounded,
                  accentColor: const Color(0xFF3B7C73),
                  children: [
                    Text(
                      line.displayDescription,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      method == ExpenseSplitAllocationMethod.amount
                          ? 'Printed line amount: ${_money(line.subtotal)}'
                          : 'Printed quantity: ${_formatNumber(line.quantity)} ${line.stockUnit}',
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RecordTextField(
                      label: method == ExpenseSplitAllocationMethod.amount
                          ? 'Business amount'
                          : 'Business quantity',
                      helperText: method == ExpenseSplitAllocationMethod.amount
                          ? 'For a return, enter the positive portion; the receipt return sign is preserved.'
                          : 'Must be from 0 through the printed quantity.',
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final allocation = _splitAllocationForValue(
                          value: controller.text,
                          method: method,
                          line: line,
                        );
                        if (allocation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                method == ExpenseSplitAllocationMethod.amount
                                    ? 'Enter an amount within this printed line total.'
                                    : 'Enter a quantity within this printed line quantity.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(allocation);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Use Split'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<double?> _chooseSplitBusinessPercent(int index) async {
    final line = _lines[index];
    final initial = line.use == _ExpenseLineUse.split
        ? line.effectiveBusinessPercent
        : .5;
    final customController = TextEditingController(
      text: (initial * 100).round().toString(),
    );
    try {
      return await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                MediaQuery.viewInsetsOf(context).bottom + 14,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ReceiptFormPanel(
                    title: 'Split Receipt Line ${index + 1}',
                    subtitle:
                        'Choose the business portion for this line. The rest counts as personal.',
                    icon: Icons.call_split_rounded,
                    accentColor: const Color(0xFF3B7C73),
                    children: [
                      Text(
                        line.displayDescription,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Line amount: ${_money(line.subtotal)}',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SplitPercentButton(
                            label: '25% Business',
                            percent: .25,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '50% Business',
                            percent: .5,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '75% Business',
                            percent: .75,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RecordTextField(
                        label: 'Custom Business %',
                        helperText:
                            'Enter 0 to 100. Example: 80 means 80% business and 20% personal.',
                        controller: customController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          final entered = _customSplitBusinessPercent(
                            customController.text,
                          );
                          if (entered == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a business percentage from 0 to 100.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(entered);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Use Custom Split'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      customController.dispose();
    }
  }
}

ExpenseSplitAllocation? _splitAllocationForValue({
  required String value,
  required ExpenseSplitAllocationMethod method,
  required _ExpenseReceiptLine line,
}) {
  final parsed = method == ExpenseSplitAllocationMethod.amount
      ? _parseMoneyInput(value)
      : double.tryParse(value.trim());
  if (parsed == null || !parsed.isFinite) return null;
  final signedValue =
      method == ExpenseSplitAllocationMethod.amount &&
          line.subtotal < 0 &&
          parsed > 0
      ? -parsed
      : parsed;
  final allocation = ExpenseSplitAllocation(
    method: method,
    businessValue: signedValue,
  );
  return allocation.isValidFor(line.toLedgerLine()) ? allocation : null;
}

class _SplitAllocationMethodButton extends StatelessWidget {
  const _SplitAllocationMethodButton({
    required this.method,
    required this.onPressed,
  });

  final ExpenseSplitAllocationMethod method;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = switch (method) {
      ExpenseSplitAllocationMethod.percentage => (
        Icons.percent_rounded,
        'Percentage',
        'Enter the business percent of this line.',
      ),
      ExpenseSplitAllocationMethod.amount => (
        Icons.attach_money_rounded,
        'Dollar amount',
        'Enter the business dollar portion of this line.',
      ),
      ExpenseSplitAllocationMethod.quantity => (
        Icons.numbers_rounded,
        'Quantity',
        'Enter the business portion of the printed quantity.',
      ),
    };
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(detail, style: const TextStyle(fontSize: 11)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(54),
      ),
    );
  }
}

double? _customSplitBusinessPercent(String value) {
  final normalized = value.replaceAll('%', '').trim();
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed < 0 || parsed > 100) {
    return null;
  }
  return parsed / 100;
}
