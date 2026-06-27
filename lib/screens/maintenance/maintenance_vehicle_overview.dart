part of 'maintenance_screen.dart';

class _MaintenanceVehicleOverview extends StatelessWidget {
  const _MaintenanceVehicleOverview({
    required this.vehicles,
    required this.allRecords,
    required this.activeVehicle,
  });

  final List<VehicleProfile> vehicles;
  final List<MaintenanceRecord> allRecords;
  final VehicleProfile? activeVehicle;

  @override
  Widget build(BuildContext context) {
    final rows = <_VehicleMaintenanceRow>[];
    for (final vehicle in vehicles) {
      final records =
          allRecords
              .where((record) => record.vehicleName == vehicle.nickname)
              .toList()
            ..sort(_compareMaintenancePriority);
      final attention = records.where(_needsAttention).length;
      final notSetUp = records.where((record) => !record.setupComplete).length;
      if (attention == 0 && notSetUp == 0) continue;
      rows.add(
        _VehicleMaintenanceRow(
          vehicle: vehicle,
          records: records,
          attention: attention,
          notSetUp: notSetUp,
          selected: activeVehicle?.nickname == vehicle.nickname,
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            'Vehicle Maintenance Alerts',
            style: TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final row in rows) ...[
          row,
          if (row != rows.last) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _VehicleMaintenanceRow extends StatelessWidget {
  const _VehicleMaintenanceRow({
    required this.vehicle,
    required this.records,
    required this.attention,
    required this.notSetUp,
    required this.selected,
  });

  final VehicleProfile vehicle;
  final List<MaintenanceRecord> records;
  final int attention;
  final int notSetUp;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final border = attention > 0
        ? AppColors.red
        : notSetUp > 0
        ? AppColors.orange
        : const Color(0xFF5D6A71);
    final summary = records.isEmpty
        ? 'No maintenance tracked'
        : attention > 0
        ? '$attention needs attention'
        : notSetUp > 0
        ? '$notSetUp not set up'
        : '${records.length} tracked';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        appNativeRoute<void>(
          context,
          VehicleProfileDetailScreen(vehicle: _previewFor(vehicle)),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xFF151C1F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                vehicle.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE7EEF1),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              summary,
              style: TextStyle(color: border, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  VehicleProfilePreview _previewFor(VehicleProfile vehicle) {
    return VehicleProfilePreview(
      nickname: vehicle.nickname,
      year: vehicle.year,
      make: vehicle.make,
      model: vehicle.model,
      odometer: '',
      status: attention > 0
          ? '$attention maintenance alert'
          : '$notSetUp setup needed',
      usage: vehicle.usage,
    );
  }
}

bool _needsAttention(MaintenanceRecord record) {
  if (!record.setupComplete) return false;
  return record.timeOnly
      ? record.monthsRemaining <= 0
      : record.milesRemaining <= 0;
}
