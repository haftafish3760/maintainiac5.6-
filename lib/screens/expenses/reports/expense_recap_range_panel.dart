part of 'expense_recap_screen.dart';

class _RecapRangePanel extends StatelessWidget {
  const _RecapRangePanel({
    required this.period,
    required this.anchorDate,
    required this.customRange,
    required this.onPeriodChanged,
    required this.onShift,
    required this.onCustomRangeChanged,
  });

  final ExpenseRecapPeriod period;
  final DateTime anchorDate;
  final ExpenseDateRange customRange;
  final ValueChanged<ExpenseRecapPeriod> onPeriodChanged;
  final ValueChanged<int> onShift;
  final ValueChanged<ExpenseDateRange> onCustomRangeChanged;

  @override
  Widget build(BuildContext context) {
    return _RecapPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecapPanelHeader(
            eyebrow: 'RANGE',
            title: 'Recap period',
            detail: 'Choose the time window for every visible tile.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in ExpenseRecapPeriod.values)
                _PeriodChip(
                  label: option.label,
                  selected: option == period,
                  onTap: () => onPeriodChanged(option),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _IconSquare(
                icon: Icons.chevron_left_rounded,
                onTap: () => onShift(-1),
              ),
              Expanded(
                child: Text(
                  period.rangeLabel(anchorDate, customRange: customRange),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _IconSquare(
                icon: Icons.chevron_right_rounded,
                onTap: () => onShift(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CustomRangeButtons(
            range: customRange,
            onChanged: onCustomRangeChanged,
          ),
        ],
      ),
    );
  }
}

class _CustomRangeButtons extends StatelessWidget {
  const _CustomRangeButtons({required this.range, required this.onChanged});

  final ExpenseDateRange range;
  final ValueChanged<ExpenseDateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _SmallRecapButton(
          label: 'Start',
          icon: Icons.first_page_rounded,
          onTap: () => _pickDate(context, isStart: true),
        ),
        _SmallRecapButton(
          label: 'End',
          icon: Icons.last_page_rounded,
          onTap: () => _pickDate(context, isStart: false),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? range.start : range.end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    final clean = _dateOnly(picked);
    final next = isStart
        ? ExpenseDateRange(
            start: clean,
            end: clean.isAfter(range.end) ? clean : range.end,
          )
        : ExpenseDateRange(
            start: clean.isBefore(range.start) ? clean : range.start,
            end: clean,
          );
    onChanged(next);
  }
}
