part of 'maintenance_screen.dart';

class _MaintenanceRecapStrip extends StatelessWidget {
  const _MaintenanceRecapStrip({required this.records});

  final List<MaintenanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final overdue = records
        .where(
          (record) => !record.setupComplete
              ? false
              : record.timeOnly
              ? record.monthsRemaining <= 0
              : record.milesRemaining <= 0,
        )
        .length;
    final dueSoon = records
        .where(
          (record) => !record.setupComplete
              ? false
              : record.timeOnly
              ? record.monthsRemaining > 0 && record.monthsRemaining <= 3
              : record.milesRemaining > 0 && record.milesRemaining <= 900,
        )
        .length;
    final notSetUp = records.where((record) => !record.setupComplete).length;

    final tiles = [
      _MaintenanceRecapTile(
        label: 'Needs Attention',
        value: overdue.toString(),
        color: overdue > 0 ? AppColors.red : AppActionColors.positive,
        onTap: () => _openList(
          context,
          title: 'Needs Attention',
          records: records.where(
            (record) =>
                record.setupComplete &&
                (record.timeOnly
                    ? record.monthsRemaining <= 0
                    : record.milesRemaining <= 0),
          ),
        ),
      ),
      _MaintenanceRecapTile(
        label: 'Due Soon',
        value: dueSoon.toString(),
        color: dueSoon > 0 ? AppColors.yellow : AppActionColors.positive,
        onTap: () => _openList(
          context,
          title: 'Due Soon',
          records: records.where(
            (record) =>
                record.setupComplete &&
                (record.timeOnly
                    ? record.monthsRemaining > 0 && record.monthsRemaining <= 3
                    : record.milesRemaining > 0 &&
                          record.milesRemaining <= 900),
          ),
        ),
      ),
      _MaintenanceRecapTile(
        label: 'Tracked',
        value: records.length.toString(),
        color: AppActionColors.primary,
        onTap: () =>
            _openList(context, title: 'Tracked Maintenance', records: records),
      ),
      _MaintenanceRecapTile(
        label: 'Setup Needed',
        value: notSetUp.toString(),
        color: notSetUp > 0 ? AppColors.orange : AppActionColors.primary,
        onTap: () => _openList(
          context,
          title: 'Not Set Up Yet',
          records: records.where((record) => !record.setupComplete),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }

  void _openList(
    BuildContext context, {
    required String title,
    required Iterable<MaintenanceRecord> records,
  }) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        MaintenanceRecordListScreen(title: title, records: records.toList()),
      ),
    );
  }
}

class _MaintenanceRecapTile extends StatelessWidget {
  const _MaintenanceRecapTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111719),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color, width: 1.2),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
