part of 'maintenance_screen.dart';

class _MaintenanceHeader extends StatelessWidget {
  const _MaintenanceHeader({
    required this.state,
    required this.activeVehicle,
    required this.records,
  });

  final AppStateController state;
  final VehicleProfile? activeVehicle;
  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final next = records.isEmpty ? null : records.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maintenance',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFFE7EEF1),
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (activeVehicle != null) ...[
          const SizedBox(height: 2),
          Text(
            activeVehicle!.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC8D2D6),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _MaintenanceMessage(record: next, trackedCount: records.length),
      ],
    );
  }
}

class _MaintenanceMessage extends StatelessWidget {
  const _MaintenanceMessage({required this.record, required this.trackedCount});

  final MaintenanceRecord? record;
  final int trackedCount;

  @override
  Widget build(BuildContext context) {
    final color = record == null
        ? const Color(0xFF20B24A)
        : _recordColor(record!);
    final title = record == null
        ? 'Ready to set up maintenance tracking'
        : 'Next tracked item: ${record!.itemName}';
    final detail = record == null
        ? 'Add the services, renewals, and reminders you want the app to track.'
        : _messageDetail(record!, trackedCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: record == null
                ? const MaintenanceSvgIcon(itemName: 'Wrench', size: 36)
                : MaintenanceSvgIcon(itemName: record!.itemName, size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _messageDetail(MaintenanceRecord record, int trackedCount) {
    final lead = record.timeOnly
        ? '${record.monthsRemaining.clamp(-99, 999)} months remaining'
        : '${formatMiles(record.milesRemaining)} miles remaining';
    final suffix = trackedCount == 1
        ? '1 tracked item'
        : '$trackedCount tracked items';
    return '$lead. Open the item to log service, adjust intervals, or review reminders. $suffix.';
  }
}
