part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntrySplitPercentActions
    on _ExpenseReceiptEntryScreenState {
  Future<ExpenseSplitAllocation?> _chooseSplitAllocation(
    int index, {
    bool allowQuantity = true,
  }) async {
    final line = _lines[index];
    return Navigator.of(context).push<ExpenseSplitAllocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            _SplitDetailsScreen(line: line, allowQuantity: allowQuantity),
      ),
    );
  }

  // Retained for the legacy compact split picker contract.
  // ignore: unused_element
  Future<ExpenseSplitAllocationMethod?> _chooseSplitAllocationMethod(
    int index, {
    required bool allowQuantity,
  }) {
    final methods = ExpenseSplitAllocationMethod.values
        .where(
          (method) =>
              allowQuantity || method != ExpenseSplitAllocationMethod.quantity,
        )
        .toList(growable: false);
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
              for (
                var methodIndex = 0;
                methodIndex < methods.length;
                methodIndex++
              ) ...[
                _SplitAllocationMethodButton(
                  method: methods[methodIndex],
                  onPressed: () =>
                      Navigator.of(context).pop(methods[methodIndex]),
                ),
                if (methodIndex != methods.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Retained for drafts created by the legacy compact split picker.
  // ignore: unused_element
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

  // Retained for backward-compatible split receipt drafts.
  // ignore: unused_element
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

class _SplitDetailsScreen extends StatefulWidget {
  const _SplitDetailsScreen({required this.line, required this.allowQuantity});

  final _ExpenseReceiptLine line;
  final bool allowQuantity;

  @override
  State<_SplitDetailsScreen> createState() => _SplitDetailsScreenState();
}

class _SplitDetailsScreenState extends State<_SplitDetailsScreen> {
  late var _method =
      widget.line.splitAllocation?.method == ExpenseSplitAllocationMethod.amount
      ? ExpenseSplitAllocationMethod.amount
      : ExpenseSplitAllocationMethod.percentage;
  late final _business = TextEditingController(text: _initialBusinessText);
  late final _personal = TextEditingController(text: _initialPersonalText);

  double get _total => widget.line.subtotal.abs();
  double get _businessValue => double.tryParse(_business.text.trim()) ?? 0;
  double get _personalValue => double.tryParse(_personal.text.trim()) ?? 0;
  bool get _isAmount => _method == ExpenseSplitAllocationMethod.amount;
  bool get _isValid {
    if (_isAmount) {
      return (_businessValue + _personalValue - _total).abs() < .01 &&
          _businessValue >= 0 &&
          _personalValue >= 0;
    }
    return (_businessValue + _personalValue - 100).abs() < .01 &&
        _businessValue >= 0 &&
        _personalValue >= 0;
  }

  String get _initialBusinessText {
    final allocation = widget.line.splitAllocation;
    if (allocation == null) {
      return _method == ExpenseSplitAllocationMethod.amount
          ? (_total / 2).toStringAsFixed(2)
          : '50';
    }
    if (allocation.method == ExpenseSplitAllocationMethod.amount) {
      return allocation.businessValue.abs().toStringAsFixed(2);
    }
    return ((allocation.businessPercentFor(widget.line.toLedgerLine()) ?? .5) *
            100)
        .toStringAsFixed(0);
  }

  String get _initialPersonalText {
    final business = double.tryParse(_initialBusinessText) ?? 0;
    final total = _method == ExpenseSplitAllocationMethod.amount ? _total : 100;
    return (total - business).toStringAsFixed(
      _method == ExpenseSplitAllocationMethod.amount ? 2 : 0,
    );
  }

  @override
  void dispose() {
    _business.dispose();
    _personal.dispose();
    super.dispose();
  }

  void _setMethod(ExpenseSplitAllocationMethod method) {
    if (_method == method) return;
    setState(() {
      _method = method;
      final business = method == ExpenseSplitAllocationMethod.amount
          ? _total / 2
          : 50.0;
      final digits = method == ExpenseSplitAllocationMethod.amount ? 2 : 0;
      _business.text = business.toStringAsFixed(digits);
      _personal.text =
          ((method == ExpenseSplitAllocationMethod.amount ? _total : 100) -
                  business)
              .toStringAsFixed(digits);
    });
  }

  void _syncFromBusiness(String value) {
    final entered = double.tryParse(value.trim());
    if (entered == null) return setState(() {});
    final total = _isAmount ? _total : 100.0;
    _personal.text = (total - entered).toStringAsFixed(_isAmount ? 2 : 0);
    setState(() {});
  }

  void _syncFromPersonal(String value) {
    final entered = double.tryParse(value.trim());
    if (entered == null) return setState(() {});
    final total = _isAmount ? _total : 100.0;
    _business.text = (total - entered).toStringAsFixed(_isAmount ? 2 : 0);
    setState(() {});
  }

  void _apply() {
    if (!_isValid) return;
    final signedBusinessAmount = widget.line.subtotal.isNegative
        ? -_businessValue
        : _businessValue;
    final allocation = ExpenseSplitAllocation(
      method: _method,
      businessValue: _isAmount ? signedBusinessAmount : _businessValue / 100,
    );
    if (!allocation.isValidFor(widget.line.toLedgerLine())) return;
    Navigator.of(context).pop(allocation);
  }

  @override
  Widget build(BuildContext context) {
    final businessAmount = _isAmount
        ? _businessValue
        : _total * _businessValue / 100;
    final personalAmount = _isAmount
        ? _personalValue
        : _total * _personalValue / 100;
    final suffix = _isAmount ? r'$' : '%';
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0F),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: _receiptReferenceText,
                  ),
                  const Expanded(
                    child: Text(
                      'Split Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _receiptReferenceText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isValid ? _apply : null,
                    icon: const Icon(Icons.check_rounded),
                    color: _receiptReferenceText,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                children: [
                  _SplitSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.line.displayDescription,
                          style: const TextStyle(
                            color: _receiptReferenceText,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Text(
                              'LINE TOTAL',
                              style: TextStyle(
                                color: _receiptReferenceMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _money(_total),
                              style: const TextStyle(
                                color: _receiptReferenceOrange,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SPLIT BY',
                    style: TextStyle(
                      color: _receiptReferenceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: _SplitModeButton(
                          label: 'Percentage (%)',
                          icon: Icons.percent_rounded,
                          selected: !_isAmount,
                          onTap: () => _setMethod(
                            ExpenseSplitAllocationMethod.percentage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SplitModeButton(
                          label: 'Amount (\$)',
                          icon: Icons.attach_money_rounded,
                          selected: _isAmount,
                          onTap: () =>
                              _setMethod(ExpenseSplitAllocationMethod.amount),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SplitSurface(
                    child: Column(
                      children: [
                        _SplitValueField(
                          label: _isAmount ? 'BUSINESS AMOUNT' : 'BUSINESS %',
                          controller: _business,
                          suffix: suffix,
                          color: const Color(0xFF51D26C),
                          onChanged: _syncFromBusiness,
                        ),
                        const SizedBox(height: 12),
                        _SplitValueField(
                          label: _isAmount ? 'PERSONAL AMOUNT' : 'PERSONAL %',
                          controller: _personal,
                          suffix: suffix,
                          color: const Color(0xFF5D94FF),
                          onChanged: _syncFromPersonal,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isValid
                                ? const Color(0xFF102919)
                                : const Color(0xFF321817),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isValid
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: _isValid
                                    ? const Color(0xFF51D26C)
                                    : const Color(0xFFFF7D73),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isValid
                                      ? 'Allocation is valid.'
                                      : _isAmount
                                      ? 'Business and Personal must equal the line total.'
                                      : 'Business and Personal must equal 100%.',
                                  style: const TextStyle(
                                    color: _receiptReferenceText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SplitSurface(
                    child: Row(
                      children: [
                        Expanded(
                          child: _SplitPreview(
                            label: 'Business',
                            value: _money(businessAmount),
                            color: const Color(0xFF51D26C),
                            icon: Icons.business_center_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SplitPreview(
                            label: 'Personal',
                            value: _money(personalAmount),
                            color: const Color(0xFF5D94FF),
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isValid ? _apply : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('APPLY SPLIT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF297A2D),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitSurface extends StatelessWidget {
  const _SplitSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _receiptReferenceSurface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _receiptReferenceBorder),
    ),
    child: child,
  );
}

class _SplitModeButton extends StatelessWidget {
  const _SplitModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: selected
          ? _receiptReferenceOrange
          : _receiptReferenceText,
      minimumSize: const Size.fromHeight(50),
      side: BorderSide(
        color: selected ? _receiptReferenceOrange : _receiptReferenceBorder,
      ),
      backgroundColor: selected
          ? const Color(0xFF28190C)
          : _receiptReferenceSurface,
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

class _SplitValueField extends StatelessWidget {
  const _SplitValueField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String suffix;
  final Color color;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _receiptReferenceMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: color,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: _receiptReferenceMuted,
            fontSize: 20,
          ),
          filled: true,
          fillColor: const Color(0xFF0B0D0F),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _receiptReferenceBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    ],
  );
}

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
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
