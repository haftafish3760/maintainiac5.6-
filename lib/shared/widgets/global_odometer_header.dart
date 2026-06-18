part of 'app_screen_shell.dart';

class GlobalOdometerHeader extends StatelessWidget {
  const GlobalOdometerHeader({super.key, this.section = AppSection.dashboard});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final vehicle = appState.activeVehicle;
    final hasMultipleVehicles = appState.vehicles.length > 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IndustrialPanelSurface(
            padding: const EdgeInsets.fromLTRB(9, 5, 9, 7),
            child: Column(
              children: [
                Text(
                  _headerLabelFor(section),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF101416),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: IconButton(
                        onPressed: () => _openSystemSettings(context),
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Color(0xFF101416),
                          size: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: InkWell(
                                onTap: () => _openVehiclePicker(context),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 2,
                                  ),
                                  child: _ActiveVehicleText(
                                    vehicle: vehicle,
                                    canOpenPicker: hasMultipleVehicles,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: _CompactOdometerText(
                                onTap: () => openOdometerEntry(
                                  context,
                                  title: 'Update Odometer',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: IconButton(
                        onPressed: () => _openDashboardSettings(context),
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFF101416),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVehiclePicker(BuildContext context) {
    final state = AppStateScope.of(context);
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
              _CompanyScopeOption(section: section),
              const SizedBox(height: 8),
              for (final vehicle in state.vehicles) ...[
                _ActiveVehicleOption(
                  vehicle: vehicle,
                  selected:
                      vehicle.displayName == state.activeVehicle?.displayName,
                  onTap: () {
                    state.selectVehicle(vehicle);
                    unawaited(
                      GlobalOdometerScope.of(context).switchVehicleById(
                        odometerVehicleIdForLabel(vehicle.nickname),
                      ),
                    );
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

  void _openSystemSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(appDrawerRoute<void>(const SystemSettingsScreen()));
  }

  void _openDashboardSettings(BuildContext context) {
    final Widget screen = switch (section) {
      AppSection.dashboard => const DashboardSettingsScreen(),
      AppSection.expenses => const ExpenseSettingsScreen(),
      AppSection.invoices => const InvoiceSettingsScreen(),
      AppSection.maintenance => const MaintenanceSettingsScreen(),
      AppSection.materials => const WorkSupplySettingsScreen(),
    };
    Navigator.of(context).push(appDrawerRoute<void>(screen));
  }
}

String _headerLabelFor(AppSection section) {
  return switch (section) {
    AppSection.expenses => 'EXPENSE VIEW',
    AppSection.materials => 'INVENTORY VIEW',
    AppSection.invoices => 'INVOICE VIEW',
    AppSection.maintenance => 'MAINTENANCE VIEW',
    AppSection.dashboard => 'ACTIVE VEHICLE',
  };
}

class _ActiveVehicleText extends StatelessWidget {
  const _ActiveVehicleText({
    required this.vehicle,
    required this.canOpenPicker,
  });

  final VehicleProfile? vehicle;
  final bool canOpenPicker;

  @override
  Widget build(BuildContext context) {
    final active = vehicle;
    final title = active?.nickname ?? 'Vehicle Required';
    final details = active == null
        ? 'Add or select a vehicle'
        : [
            active.year,
            active.make,
            active.model,
          ].where((part) => part.trim().isNotEmpty).join(' ');
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF101416),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              if (details.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF2F383D),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          canOpenPicker
              ? Icons.keyboard_arrow_down_rounded
              : Icons.expand_more_rounded,
          color: const Color(0xFF101416),
          size: 22,
        ),
      ],
    );
  }
}

class _CompactOdometerText extends StatelessWidget {
  const _CompactOdometerText({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  controller.displayValue,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF126D43),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.edit_rounded,
                color: Color(0xFF101416),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  const _CompanyScopeOption({required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final label = switch (section) {
      AppSection.expenses => 'All Company Expenses',
      AppSection.materials => 'All Company Inventory',
      AppSection.invoices => 'All Company Invoices',
      AppSection.maintenance => 'All Company Maintenance',
      AppSection.dashboard => 'Company Overview',
    };
    final detail = switch (section) {
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
        onTap: () => Navigator.of(context).pop(),
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
            border: Border.all(color: const Color(0xFF55C7F0), width: 1.2),
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8ECEE)),
            ],
          ),
        ),
      ),
    );
  }
}
