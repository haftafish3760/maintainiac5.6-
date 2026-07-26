part of 'expense_allocation_screen.dart';

class _ReportPeriodSelector extends StatelessWidget {
  const _ReportPeriodSelector({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final _ReportPeriod value;
  final String label;
  final ValueChanged<_ReportPeriod> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _ArrowButton(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final option in _ReportPeriod.values) ...[
                Expanded(
                  child: _SelectorButton(
                    label: option.buttonLabel,
                    selected: option == value,
                    onTap: () => onChanged(option),
                  ),
                ),
                if (option != _ReportPeriod.values.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        icon: Icon(icon, color: const Color(0xFFF0B43C), size: 24),
      ),
    );
  }
}

class _LimitSelector extends StatelessWidget {
  const _LimitSelector({required this.value, required this.onChanged});

  final ExpenseAllocationLimit value;
  final ValueChanged<ExpenseAllocationLimit> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      child: Row(
        children: [
          for (final option in ExpenseAllocationLimit.values) ...[
            Expanded(
              child: _SelectorButton(
                label: switch (option) {
                  ExpenseAllocationLimit.top10 => 'Top 10',
                  ExpenseAllocationLimit.top25 => 'Top 25',
                  ExpenseAllocationLimit.all => 'All',
                },
                selected: option == value,
                onTap: () => onChanged(option),
              ),
            ),
            if (option != ExpenseAllocationLimit.values.last)
              const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
