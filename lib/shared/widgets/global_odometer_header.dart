part of 'app_screen_shell.dart';

class GlobalOdometerHeader extends StatelessWidget {
  const GlobalOdometerHeader({
    super.key,
    this.section = AppSection.dashboard,
    this.onSettingsPressed,
    this.headerLabel,
    this.settingsActionEnabled = true,
    this.showBackButton = false,
    this.profileLabel = 'WORK PROFILE',
    this.profileName,
  });

  final AppSection section;
  final VoidCallback? onSettingsPressed;
  final String? headerLabel;

  /// Settings pages retain the contextual gear but must not push a duplicate
  /// copy of themselves onto the navigation stack.
  final bool settingsActionEnabled;
  final bool showBackButton;
  final String profileLabel;
  final String? profileName;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final operationalContext = OperationalContextScope.maybeOf(context);
    final vehicle = appState.activeVehicle;
    final hasMultipleVehicles = appState.vehicles.length > 1;
    final hasPreviousScreen = showBackButton;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IndustrialPanelSurface(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
            child: Column(
              children: [
                Text(
                  headerLabel ?? _headerLabelFor(section),
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
                      width: 38,
                      height: 40,
                      child: IconButton(
                        onPressed: hasPreviousScreen
                            ? () => Navigator.of(context).maybePop()
                            : () => _openSystemSettings(context),
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          hasPreviousScreen
                              ? Icons.arrow_back_rounded
                              : Icons.menu_rounded,
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
                                    section: section,
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
                      width: 38,
                      height: 40,
                      child: IconButton(
                        onPressed: settingsActionEnabled
                            ? (onSettingsPressed ??
                                  () => _openDashboardSettings(context))
                            : () {},
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 40,
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
                if (operationalContext != null) ...[
                  const SizedBox(height: 5),
                  _ActiveWorkProfileLine(
                    label: profileLabel,
                    profileName:
                        profileName ??
                        operationalContext.context.workProfileName,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVehiclePicker(BuildContext context) {
    openGlobalVehiclePicker(context, section: section);
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

class _ActiveWorkProfileLine extends StatelessWidget {
  const _ActiveWorkProfileLine({
    required this.label,
    required this.profileName,
  });

  final String label;
  final String profileName;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $profileName',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.badge_rounded, color: Color(0xFF20363D), size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label · $profileName',
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              color: Color(0xFF20363D),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
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
    required this.section,
    required this.vehicle,
    required this.canOpenPicker,
  });

  final AppSection section;
  final VehicleProfile? vehicle;
  final bool canOpenPicker;

  @override
  Widget build(BuildContext context) {
    final active = vehicle;
    final title = active?.nickname ?? _companyScopeLabel(section);
    final details = active == null
        ? _companyScopeDetail(section)
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
    final tripTracking = TripTrackingScope.maybeOf(context);
    return AnimatedBuilder(
      animation: tripTracking == null
          ? controller
          : Listenable.merge([controller, tripTracking]),
      builder: (context, _) {
        final odometerDisplay = controller.liveDisplaySnapshot;
        final gpsStatus = odometerDisplay.isLive
            ? tripTracking == null || tripTracking.nativeTracking
                  ? odometerDisplay.deltaLabel
                  : 'GPS paused'
            : null;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          odometerDisplay.displayValue,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF034C2B),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF101416),
                      size: 17,
                    ),
                  ],
                ),
                if (gpsStatus != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    gpsStatus,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF2F383D),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

String _companyScopeLabel(AppSection section) {
  return switch (section) {
    AppSection.expenses => 'All Company Expenses',
    AppSection.materials => 'All Company Inventory',
    AppSection.invoices => 'All Company Invoices',
    AppSection.maintenance => 'All Company Maintenance',
    AppSection.dashboard => 'Company Overview',
  };
}

String _companyScopeDetail(AppSection section) {
  return switch (section) {
    AppSection.expenses => 'Company-wide expense recap and records',
    AppSection.materials => 'Company-wide inventory records',
    AppSection.invoices => 'Company-wide invoice records',
    AppSection.maintenance => 'Company-wide maintenance records',
    AppSection.dashboard => 'All vehicles and work profiles',
  };
}
