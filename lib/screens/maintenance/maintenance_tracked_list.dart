part of 'maintenance_screen.dart';

class _TrackedMaintenanceList extends StatelessWidget {
  const _TrackedMaintenanceList({required this.records});

  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tracked Maintenance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${records.length}',
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          for (final record in records) ...[
            _MaintenanceRow(record: record),
            if (record != records.last) const SizedBox(height: 8),
          ],
        ],
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
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF111719),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5),
                ),
              ),
            ),
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
                      style: const TextStyle(
                        color: Color(0xFFF3F7F8),
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
                      style: const TextStyle(
                        color: Color(0xFFC8D2D6),
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
            _ThresholdBadge(record: record, color: color),
          ],
        ),
      ),
    );
  }
}

class _ThresholdBadge extends StatelessWidget {
  const _ThresholdBadge({required this.record, required this.color});

  final MaintenanceRecord record;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = record.timeOnly
        ? '${record.monthsRemaining.clamp(-99, 999)} mo'
        : formatMiles(record.milesRemaining);
    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
