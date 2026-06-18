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
        Row(
          children: [
            Expanded(
              child: Text(
                'Maintenance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFE7EEF1),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActiveVehicleChip(state: state, vehicle: activeVehicle),
          ],
        ),
        const SizedBox(height: 8),
        _MaintenanceMessage(record: next, trackedCount: records.length),
      ],
    );
  }
}

class _ActiveVehicleChip extends StatelessWidget {
  const _ActiveVehicleChip({required this.state, required this.vehicle});

  final AppStateController state;
  final VehicleProfile? vehicle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104, maxWidth: 164),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectVehicle(context),
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFAAB4B9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF87949A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    vehicle?.nickname ?? 'Vehicle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF101416),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectVehicle(BuildContext context) async {
    final selected = await showModalBottomSheet<VehicleProfile>(
      context: context,
      backgroundColor: const Color(0xFF2E3A40),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            const Text(
              'Choose Active Vehicle',
              style: TextStyle(
                color: Color(0xFF101416),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final option in state.vehicles) ...[
              ListTile(
                tileColor: const Color(0xFFD3DBDE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                title: Text(
                  option.nickname,
                  style: const TextStyle(
                    color: Color(0xFF101416),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${option.year} ${option.make} ${option.model}',
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.pop(context, option),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
    if (selected != null) state.selectVehicle(selected);
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
        : '${record!.itemName} is next';
    final detail = record == null
        ? 'Add the services, renewals, and reminders you want the app to track.'
        : _messageDetail(record!, trackedCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12),
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
