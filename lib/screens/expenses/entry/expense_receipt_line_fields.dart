part of 'expense_receipt_entry_screen.dart';

class _LineUseBanner extends StatelessWidget {
  const _LineUseBanner({required this.use, this.onChanged});

  final _ExpenseLineUse use;
  final ValueChanged<_ExpenseLineUse>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final option in const [
          _ExpenseLineUse.business,
          _ExpenseLineUse.personal,
          _ExpenseLineUse.split,
        ])
          _LineChoiceButton(
            label: option.label,
            selected: option == use,
            selectedColor: _colorFor(option),
            onPressed: onChanged == null ? null : () => onChanged!(option),
          ),
      ],
    );
  }

  Color _colorFor(_ExpenseLineUse option) => switch (option) {
    _ExpenseLineUse.business => const Color(0xFF2E78B7),
    _ExpenseLineUse.personal => const Color(0xFF59636A),
    _ExpenseLineUse.split => const Color(0xFF3B7C73),
    _ExpenseLineUse.unclassified => const Color(0xFF11181B),
  };
}

class _ParserReviewNotice extends StatelessWidget {
  const _ParserReviewNotice({required this.line});

  final _ExpenseReceiptLine line;

  @override
  Widget build(BuildContext context) {
    final color = line.parserBadgeColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            line.parserNeedsReview
                ? Icons.rule_rounded
                : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.parserReviewSummary,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if ((line.parserReviewReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.parserReviewReason!.trim(),
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                if (line.parserNeedsReview) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Saving this line marks it reviewed. Change anything that looks wrong before saving.',
                    style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitAllocationFields extends StatelessWidget {
  const _SplitAllocationFields({
    required this.method,
    required this.businessPercentController,
    required this.businessAmountController,
    required this.businessPercent,
    required this.businessAmount,
    required this.lineTotal,
    required this.onMethodChanged,
  });

  final ExpenseSplitAllocationMethod method;
  final TextEditingController businessPercentController;
  final TextEditingController businessAmountController;
  final double? businessPercent;
  final double? businessAmount;
  final double? lineTotal;
  final ValueChanged<ExpenseSplitAllocationMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final enteredBusinessPercent = businessPercent;
    final enteredBusinessAmount = businessAmount;
    final usesAmount = method == ExpenseSplitAllocationMethod.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Business portion of this item',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _LineChoiceButton(
              label: 'Percentage',
              selected: !usesAmount,
              selectedColor: const Color(0xFF3B7C73),
              onPressed: () =>
                  onMethodChanged(ExpenseSplitAllocationMethod.percentage),
            ),
            _LineChoiceButton(
              label: 'Dollar amount',
              selected: usesAmount,
              selectedColor: const Color(0xFF3B7C73),
              onPressed: () =>
                  onMethodChanged(ExpenseSplitAllocationMethod.amount),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RecordTextField(
          label: usesAmount ? 'Business dollar amount' : 'Business percent',
          controller: usesAmount
              ? businessAmountController
              : businessPercentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: usesAmount
              ? 'The remaining amount is personal.'
              : 'The remaining percentage is personal.',
        ),
        const SizedBox(height: 7),
        Text(
          _allocationSummary(
            usesAmount: usesAmount,
            amount: enteredBusinessAmount,
            percent: enteredBusinessPercent,
            total: lineTotal,
          ),
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  String _allocationSummary({
    required bool usesAmount,
    required double? amount,
    required double? percent,
    required double? total,
  }) {
    if (usesAmount) {
      if (amount == null) return 'Enter the business amount before saving.';
      if (total == null) {
        return 'Business ${_money(amount)}. Enter the printed line total to calculate personal.';
      }
      return 'Business ${_money(amount)} | Personal ${_money(total - amount)}';
    }
    if (percent == null) return 'Enter the business percentage before saving.';
    if (total == null) {
      return 'Business ${_percent(percent)} | Personal ${_percent(1 - percent)}';
    }
    return 'Business ${_money(total * percent)} | Personal ${_money(total * (1 - percent))}';
  }
}

class _LineChoiceButton extends StatelessWidget {
  const _LineChoiceButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? selectedColor : const Color(0xFF11181B),
          foregroundColor: selected ? Colors.white : const Color(0xFFC8D0D3),
          disabledBackgroundColor: const Color(0xFF20292D),
          disabledForegroundColor: const Color(0xFF7B898F),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(label),
      ),
    );
  }
}

class _FuelReceiptFields extends StatelessWidget {
  const _FuelReceiptFields({
    required this.odometerController,
    required this.unitPriceController,
    required this.fuelType,
    required this.fillType,
    required this.onFuelTypeChanged,
    required this.onFillTypeChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController unitPriceController;
  final String fuelType;
  final String fillType;
  final ValueChanged<String> onFuelTypeChanged;
  final ValueChanged<String> onFillTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecordTextField(
          label: 'Odometer Reading',
          helperText: 'Required for MPG and business/personal fuel allocation.',
          controller: odometerController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RecordDropdownField<String>(
                label: 'Fuel Or Energy Type',
                value: fuelType,
                items: const ['Gasoline', 'Diesel', 'Electric'],
                itemLabel: (value) => value,
                onChanged: onFuelTypeChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RecordDropdownField<String>(
                label: 'Fill Type',
                value: fillType,
                items: const ['Full fill-up', 'Partial fill'],
                itemLabel: (value) => value,
                onChanged: onFillTypeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: fuelType == 'Electric' ? 'Price Per kWh' : 'Price Per Gallon',
          helperText: 'Optional if the receipt only shows the line total.',
          controller: unitPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
