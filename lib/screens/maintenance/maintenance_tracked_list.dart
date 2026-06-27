part of 'maintenance_screen.dart';

class _TrackedMaintenanceList extends StatelessWidget {
  const _TrackedMaintenanceList({required this.records});

  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Tracked Maintenance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE7EEF1),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${records.length}',
                style: const TextStyle(
                  color: Color(0xFFC8D2D6),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (records.isEmpty) const _TrackedMaintenanceEmptyState(),
        for (final record in records) ...[
          _MaintenanceRow(record: record),
          if (record != records.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TrackedMaintenanceEmptyState extends StatelessWidget {
  const _TrackedMaintenanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: const Text(
        'No maintenance items are tracked for this vehicle yet.',
        style: TextStyle(color: Color(0xFFE2E8EA), fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({required this.record});

  final MaintenanceRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _recordColor(record);
    final textColor = _rowTextColor(color);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          MaintenanceItemDetailScreen(record: record),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF101416), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Center(
                child: MaintenanceSvgIcon(itemName: record.itemName, size: 34),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recordStatus(record),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: .86),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ThresholdBadge(record: record, textColor: textColor),
          ],
        ),
      ),
    );
  }
}

class _ThresholdBadge extends StatelessWidget {
  const _ThresholdBadge({required this.record, required this.textColor});

  final MaintenanceRecord record;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final label = record.timeOnly
        ? '${record.monthsRemaining.clamp(-99, 999)} mo'
        : formatMiles(record.milesRemaining);
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: textColor.withValues(alpha: .65)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

Color _rowTextColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > .43 ? const Color(0xFF101416) : Colors.white;
}
