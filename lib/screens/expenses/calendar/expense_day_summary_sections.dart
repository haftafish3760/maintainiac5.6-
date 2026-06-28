part of 'expense_calendar.dart';

class _CalendarDaySummary extends StatelessWidget {
  const _CalendarDaySummary({
    required this.day,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime day;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF122A34),
        border: Border.all(color: const Color(0xFF295E73)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CalendarNavButton(
                icon: Icons.keyboard_double_arrow_left_rounded,
                tooltip: 'Previous month',
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 3),
              _CalendarNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous day',
                onTap: onPreviousDay,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  calendarFullDateLabel(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _CalendarNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next day',
                onTap: onNextDay,
              ),
              const SizedBox(width: 3),
              _CalendarNavButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                tooltip: 'Next month',
                onTap: onNextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarRecapPeriodSelector extends StatelessWidget {
  const _CalendarRecapPeriodSelector({
    required this.selected,
    required this.selectedDay,
    required this.onSelected,
  });

  final _CalendarRecapPeriod selected;
  final DateTime selectedDay;
  final ValueChanged<_CalendarRecapPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VIEW',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF9FAAAF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Expense records',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            selected.rangeLabel(selectedDay),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 5.0;
              final columns = constraints.maxWidth < 430 ? 3 : 5;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 5,
                children: [
                  for (final period in _CalendarRecapPeriod.values)
                    SizedBox(
                      width: width,
                      child: _CalendarRecapPeriodButton(
                        period: period,
                        selected: selected == period,
                        onTap: () => onSelected(period),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _SmallCalendarButton(
              label: 'Recap',
              icon: Icons.insights_rounded,
              onTap: () {
                Navigator.of(context).push(
                  appNativeRoute<void>(
                    context,
                    ExpenseRecapScreen(
                      initialDate: selectedDay,
                      initialRange: selected.rangeFor(selectedDay),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarOcrDayRecapPanel extends StatelessWidget {
  const _CalendarOcrDayRecapPanel({required this.recap});

  final _CalendarOcrDayRecap recap;

  @override
  Widget build(BuildContext context) {
    final color = recap.needsReview
        ? const Color(0xFFFFD166)
        : recap.hasOcrReads
        ? const Color(0xFF8EF6A4)
        : const Color(0xFFC8D0D3);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            recap.needsReview
                ? Icons.manage_search_rounded
                : Icons.document_scanner_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt read health',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recap.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recap.detailLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarRecapPeriodButton extends StatelessWidget {
  const _CalendarRecapPeriodButton({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  final _CalendarRecapPeriod period;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFD166) : const Color(0xFF172126),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          child: Text(
            period.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF101416) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleExpenseMetricsPanel extends StatelessWidget {
  const _VehicleExpenseMetricsPanel({
    required this.metrics,
    required this.selectedDay,
    required this.dayEntryCount,
    required this.dayTotal,
    required this.ocrRecap,
    required this.period,
  });

  final _VehicleExpenseMetrics metrics;
  final DateTime selectedDay;
  final int dayEntryCount;
  final double dayTotal;
  final _CalendarOcrDayRecap ocrRecap;
  final _CalendarRecapPeriod period;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        border: Border.all(color: const Color(0xFF445159)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense Recap',
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${period.label} | ${period.rangeLabel(selectedDay)}',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          _CalendarRecapRow(
            label: 'Selected Day Entries',
            value: '$dayEntryCount',
            color: const Color(0xFFFFD166),
          ),
          _CalendarRecapRow(
            label: 'Selected Day Total',
            value: _money(dayTotal),
            color: const Color(0xFF34A9E8),
          ),
          const _CalendarRecapDivider('Period Totals'),
          _CalendarRecapRow(
            label: 'Total Expenses',
            value: _money(metrics.totalExpense),
            color: const Color(0xFFFFD166),
          ),
          _CalendarRecapRow(
            label: 'Business',
            value: _money(metrics.businessExpense),
            color: const Color(0xFF58D67D),
          ),
          _CalendarRecapRow(
            label: 'Personal',
            value: _money(metrics.personalExpense),
            color: const Color(0xFF79C8FF),
          ),
          const _CalendarRecapDivider('Receipt Reads'),
          _CalendarRecapRow(
            label: 'Receipt Read Status',
            value: ocrRecap.statusLabel,
            color: ocrRecap.needsReview
                ? const Color(0xFFFFD166)
                : const Color(0xFF8EF6A4),
          ),
          _CalendarRecapRow(
            label: 'Reads Saved',
            value: '${ocrRecap.readCount}',
            color: const Color(0xFF34A9E8),
          ),
          _CalendarRecapRow(
            label: 'Needs Review',
            value: '${ocrRecap.reviewCount}',
            color: ocrRecap.needsReview
                ? const Color(0xFFFFD166)
                : const Color(0xFF8EF6A4),
          ),
          _CalendarRecapRow(
            label: 'Read Summary',
            value: ocrRecap.detailLabel,
            color: const Color(0xFF79C8FF),
          ),
          if (ocrRecap.topRecoveryHint.isNotEmpty)
            _CalendarRecapRow(
              label: 'Top Check',
              value: ocrRecap.topRecoveryHint,
              color: const Color(0xFFFFD166),
            ),
          const _CalendarRecapDivider('Vehicle'),
          _CalendarRecapRow(
            label: 'Vehicle Expenses',
            value: _money(metrics.vehicleExpense),
            color: const Color(0xFF34A9E8),
          ),
          _CalendarRecapRow(
            label: 'Fuel Cost',
            value: _money(metrics.fuelExpense),
            color: const Color(0xFFFF6B63),
          ),
          _CalendarRecapRow(
            label: 'Average MPG',
            value: metrics.mpgLabel,
            color: const Color(0xFF58D67D),
          ),
          _CalendarRecapRow(
            label: 'Vehicle Cost Per Mile',
            value: metrics.vehicleCostPerMileLabel,
            color: const Color(0xFF79C8FF),
          ),
        ],
      ),
    );
  }
}

class _CalendarRecapDivider extends StatelessWidget {
  const _CalendarRecapDivider(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC8D0D3),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CalendarRecapRow extends StatelessWidget {
  const _CalendarRecapRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 7, 0, 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A3439))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFFFFD166), size: 24),
      ),
    );
  }
}
