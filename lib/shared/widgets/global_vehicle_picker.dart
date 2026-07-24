part of 'app_screen_shell.dart';

void openGlobalVehiclePicker(
  BuildContext context, {
  required AppSection section,
}) {
  final state = AppStateScope.of(context);
  final operationalContext = OperationalContextScope.maybeOf(context);
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1F2528),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Active Vehicle',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _CompanyScopeOption(
              section: section,
              selected: state.activeVehicle == null,
              onTap: () {
                state.selectCompanyScope();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            for (final vehicle in state.vehicles) ...[
              _ActiveVehicleOption(
                vehicle: vehicle,
                selected: vehicle.id == state.activeVehicle?.id,
                onTap: () async {
                  final odometer = GlobalOdometerScope.of(context);
                  final switched = await odometer.switchVehicleById(
                    odometerVehicleIdForVehicleId(
                      vehicle.id,
                      fallbackLabel: vehicle.nickname,
                    ),
                  );
                  if (!context.mounted) return;
                  if (!switched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'End or review the active GPS trip before switching vehicles.',
                        ),
                      ),
                    );
                    return;
                  }
                  state.selectVehicle(vehicle);
                  if (operationalContext != null) {
                    await operationalContext.setActiveVehicle(
                      vehicleId: odometer.vehicleId,
                      vehicleLabel: vehicle.nickname,
                      usage: vehicle.usage,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ActiveVehicleOption extends StatelessWidget {
  const _ActiveVehicleOption({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleProfile vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? const [Color(0xFF245C3C), Color(0xFF12301F)]
                  : const [Color(0xFF2D3B42), Color(0xFF172126)],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58D67D)
                  : const Color(0xFF66737A),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        vehicle.year,
                        vehicle.make,
                        vehicle.model,
                      ].where((part) => part.trim().isNotEmpty).join(' '),
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: Color(0xFF58D67D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyScopeOption extends StatelessWidget {
  const _CompanyScopeOption({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _companyScopeLabel(section);
    final detail = _companyScopePickerDetail(section);
    final icon = switch (section) {
      AppSection.expenses => Icons.receipt_long_rounded,
      AppSection.materials => Icons.inventory_2_rounded,
      AppSection.invoices => Icons.request_quote_rounded,
      AppSection.maintenance => Icons.build_rounded,
      AppSection.dashboard => Icons.dashboard_rounded,
    };
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E5A78), Color(0xFF102D3D)],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58D67D)
                  : const Color(0xFF55C7F0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD166)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_rounded : Icons.chevron_right_rounded,
                color: selected
                    ? const Color(0xFF58D67D)
                    : const Color(0xFFE8ECEE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _companyScopePickerDetail(AppSection section) {
  return switch (section) {
    AppSection.expenses =>
      'Use this when you want expense records across the whole company.',
    AppSection.materials =>
      'Use this when inventory belongs to the company instead of one vehicle.',
    AppSection.invoices =>
      'Use this when invoice records belong to the whole company.',
    AppSection.maintenance =>
      'Use this when maintenance records are not tied to one vehicle.',
    AppSection.dashboard =>
      'Use this to review company totals instead of one vehicle.',
  };
}
