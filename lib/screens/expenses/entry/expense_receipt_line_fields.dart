part of 'expense_receipt_entry_screen.dart';

class _ReceiptItemLineTotal extends StatelessWidget {
  const _ReceiptItemLineTotal({required this.total});

  final double? total;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Line total',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          Text(
            total == null ? '—' : _money(total!),
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppFilledLineReviewNotice extends StatelessWidget {
  const _AppFilledLineReviewNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 18,
            color: Color(0xFF8EF6A4),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Check this app-filled item. Saving this line marks it reviewed.',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptQuantityStepper extends StatelessWidget {
  const _ReceiptQuantityStepper({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  void _change(double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 1;
    final next = (current + delta).clamp(0.0, 999999.0);
    controller.text = next == next.roundToDouble()
        ? next.toInt().toString()
        : next.toStringAsFixed(2);
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
    decoration: BoxDecoration(
      color: const Color(0xFF101315),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF40484D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            IconButton(
              onPressed: () => _change(-1),
              icon: const Icon(Icons.remove_rounded),
              color: Colors.white,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF101315),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            IconButton(
              onPressed: () => _change(1),
              icon: const Icon(Icons.add_rounded),
              color: Colors.white,
            ),
          ],
        ),
      ],
    ),
  );
}

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
    _ExpenseLineUse.business => const Color(0xFFFF8500),
    _ExpenseLineUse.personal => const Color(0xFFFF8500),
    _ExpenseLineUse.split => const Color(0xFFFF8500),
    _ExpenseLineUse.unclassified => const Color(0xFF11181B),
  };
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
    required this.fuelType,
    required this.fillType,
    required this.onFuelTypeChanged,
    required this.onFillTypeChanged,
  });

  final TextEditingController odometerController;
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
      ],
    );
  }
}
