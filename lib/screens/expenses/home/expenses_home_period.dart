part of 'expenses_home_screen.dart';

enum _ExpenseViewPeriod {
  day('Daily', 'DAILY', 'Daily expenses', 'Daily total'),
  week('Weekly', 'WEEKLY', 'Weekly expenses', 'Weekly total'),
  month('Monthly', 'MONTHLY', 'Monthly expenses', 'Monthly total'),
  yearToDate('YTD', 'YEAR TO DATE', 'Year-to-date expenses', 'YTD total');

  const _ExpenseViewPeriod(
    this.buttonLabel,
    this.eyebrow,
    this.title,
    this.totalCaption,
  );

  final String buttonLabel;
  final String eyebrow;
  final String title;
  final String totalCaption;

  String get statPrefix => this == yearToDate ? 'YTD' : buttonLabel;

  ExpenseDateRange rangeFor(DateTime date) {
    final today = _dateOnly(date);
    return switch (this) {
      _ExpenseViewPeriod.day => ExpenseDateRange(start: today, end: today),
      _ExpenseViewPeriod.week => _weekRange(today),
      _ExpenseViewPeriod.month => ExpenseDateRange(
        start: DateTime(today.year, today.month),
        end: DateTime(today.year, today.month + 1, 0),
      ),
      _ExpenseViewPeriod.yearToDate => ExpenseDateRange(
        start: DateTime(today.year),
        end: today.year == DateTime.now().year
            ? _dateOnly(DateTime.now())
            : DateTime(today.year, 12, 31),
      ),
    };
  }

  String rangeLabel(DateTime date) {
    final range = rangeFor(date);
    return switch (this) {
      _ExpenseViewPeriod.day => _longDate(range.start),
      _ExpenseViewPeriod.week =>
        '${_shortDate(range.start)} - ${_shortDate(range.end)}',
      _ExpenseViewPeriod.month =>
        '${_monthName(range.start.month)} ${range.start.year}',
      _ExpenseViewPeriod.yearToDate => range.start.year.toString(),
    };
  }
}

class _ExpensePeriodSelectorPanel extends StatelessWidget {
  const _ExpensePeriodSelectorPanel({
    required this.period,
    required this.anchorDate,
    required this.scopeLabel,
    required this.onChanged,
    required this.onShift,
    required this.onToday,
  });

  final _ExpenseViewPeriod period;
  final DateTime anchorDate;
  final String scopeLabel;
  final ValueChanged<_ExpenseViewPeriod> onChanged;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return _SolidSection(
      backgroundColor: _ink,
      borderColor: _line,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            eyebrow: 'VIEW',
            title: 'Expense records:',
            detail: scopeLabel,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 6.0;
              final width = (constraints.maxWidth - spacing * 3) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: 6,
                children: [
                  for (final option in _ExpenseViewPeriod.values)
                    SizedBox(
                      width: width,
                      child: _PeriodChoiceButton(
                        label: option.buttonLabel,
                        selected: option == period,
                        onTap: () => onChanged(option),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _PeriodNavigator(
            period: period,
            label: period.rangeLabel(anchorDate),
            onPrevious: () => onShift(-1),
            onNext: () => onShift(1),
            onToday: onToday,
          ),
        ],
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.period,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final _ExpenseViewPeriod period;
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final helper = switch (period) {
      _ExpenseViewPeriod.day => 'Selected day',
      _ExpenseViewPeriod.week => 'Selected week',
      _ExpenseViewPeriod.month => 'Selected month',
      _ExpenseViewPeriod.yearToDate => 'Selected year',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line, width: 1.1),
      ),
      child: Row(
        children: [
          _ArrowButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
          Expanded(
            child: Column(
              children: [
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9FAAAF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          _SmallTextButton(
            label: 'Current',
            icon: Icons.today_rounded,
            onTap: onToday,
          ),
          const SizedBox(width: 6),
          _ArrowButton(icon: Icons.chevron_right_rounded, onTap: onNext),
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
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: _gold, size: 24),
      ),
    );
  }
}

class _PeriodChoiceButton extends StatelessWidget {
  const _PeriodChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _gold : const Color(0xFF101719),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFFFFE3A0) : _line,
              width: 1.1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF11181B) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
