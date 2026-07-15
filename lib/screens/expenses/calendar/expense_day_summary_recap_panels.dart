part of 'expense_calendar.dart';

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
          if (metrics.unclassifiedExpense > 0)
            _CalendarRecapRow(
              label: 'Needs Classification',
              value: _money(metrics.unclassifiedExpense),
              color: const Color(0xFFFFD166),
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
