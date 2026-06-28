part of 'maintenance_screen.dart';

class _MaintenanceServiceHistory extends StatelessWidget {
  const _MaintenanceServiceHistory({required this.events});

  final List<MaintenanceServiceEvent> events;

  @override
  Widget build(BuildContext context) {
    final totalCost = events.fold<double>(
      0,
      (sum, event) => sum + event.totalCost,
    );
    final proofCount = events.fold<int>(
      0,
      (sum, event) => sum + event.receiptProofCount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            'Service History',
            style: TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _ServiceHistorySummary(
          serviceCount: events.length,
          totalCost: totalCost,
          proofCount: proofCount,
        ),
        if (events.isEmpty) ...[
          const SizedBox(height: 8),
          const _ServiceHistoryEmpty(),
        ] else ...[
          const SizedBox(height: 8),
          for (final event in events.take(3)) ...[
            _ServiceHistoryRow(event: event),
            if (event != events.take(3).last) const SizedBox(height: 7),
          ],
        ],
      ],
    );
  }
}

class _ServiceHistorySummary extends StatelessWidget {
  const _ServiceHistorySummary({
    required this.serviceCount,
    required this.totalCost,
    required this.proofCount,
  });

  final int serviceCount;
  final double totalCost;
  final int proofCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HistoryStat(
            label: 'Services',
            value: serviceCount.toString(),
            color: AppActionColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HistoryStat(
            label: 'Spent',
            value: _historyMoneyLabel(totalCost),
            color: AppActionColors.positive,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HistoryStat(
            label: 'Proof',
            value: proofCount.toString(),
            color: proofCount == 0 ? const Color(0xFFCAD2D5) : AppColors.yellow,
          ),
        ),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
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
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceHistoryEmpty extends StatelessWidget {
  const _ServiceHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: const Text(
        'No saved service records for this vehicle yet.',
        style: TextStyle(
          color: Color(0xFFE2E8EA),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ServiceHistoryRow extends StatelessWidget {
  const _ServiceHistoryRow({required this.event});

  final MaintenanceServiceEvent event;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          appNativeRoute<void>(
            context,
            MaintenanceServiceEventDetailScreen(event: event),
          ),
        ),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF151C1F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4E5B62)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.build_circle_outlined,
                color: AppActionColors.primary,
                size: 25,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE7EEF1),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _historyDetail(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _historyDateLabel(event.serviceDate),
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCAD2D5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _historyDetail(MaintenanceServiceEvent event) {
    final cost = event.totalCost > 0
        ? ' • ${_historyMoneyLabel(event.totalCost)}'
        : '';
    final proof = event.receiptProofCount > 0
        ? ' • ${event.receiptProofCount} proof'
        : '';
    return '${formatMiles(event.odometer)} miles$cost$proof';
  }
}

String _historyMoneyLabel(double amount) {
  if (amount <= 0) return r'$0';
  if (amount >= 10000) return '\$${amount.round()}';
  return '\$${amount.toStringAsFixed(2)}';
}

String _historyDateLabel(DateTime date) {
  return '${date.month}/${date.day}/${date.year.toString().substring(2)}';
}
