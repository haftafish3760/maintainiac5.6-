import 'package:flutter/material.dart';

import '../../screens/expenses/expense_settings_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/invoices/invoice_settings_screen.dart';
import '../../screens/invoices/invoices_screen.dart';
import '../../screens/maintenance/maintenance_settings_screen.dart';
import '../../screens/maintenance/maintenance_screen.dart';
import '../../screens/work_supplies/work_supply_screen.dart';
import '../../screens/work_supplies/work_supply_settings_screen.dart';
import '../../screens/settings/dashboard_settings.dart';
import '../../screens/settings/system_settings.dart';
import '../navigation/app_page_routes.dart';
import '../state/app_state.dart';
import '../state/global_odometer.dart';
import 'app_banner_ad_reserve.dart';
import 'industrial_panel_surface.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.body,
    this.maxWidth = 600,
    this.section = AppSection.dashboard,
    this.floatingActionButton,
  });

  final Widget body;
  final double maxWidth;
  final AppSection section;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A3337),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBannerAdReserve(),
          AppBottomNavigation(currentSection: section),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: AppTexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class AppTexturedBackground extends StatelessWidget {
  const AppTexturedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _AppBackgroundPainter(),
      child: SizedBox.expand(child: child),
    );
  }
}

class GlobalOdometerHeader extends StatelessWidget {
  const GlobalOdometerHeader({super.key, this.section = AppSection.dashboard});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final vehicle = appState.activeVehicle;
    final hasMultipleVehicles = appState.vehicles.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IndustrialPanelSurface(
        padding: const EdgeInsets.fromLTRB(9, 5, 9, 7),
        child: Column(
          children: [
            Text(
              'ACTIVE VEHICLE',
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
                  child: InkWell(
                    onTap: () => _openVehiclePicker(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Expanded(child: _ActiveVehicleText(vehicle: vehicle)),
                          const SizedBox(width: 6),
                          const _CompactOdometerText(),
                          const SizedBox(width: 3),
                          Icon(
                            hasMultipleVehicles
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.expand_more_rounded,
                            color: const Color(0xFF101416),
                            size: 23,
                          ),
                        ],
                      ),
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
              const _CompanyStockOption(),
              const SizedBox(height: 8),
              for (final vehicle in state.vehicles) ...[
                _ActiveVehicleOption(
                  vehicle: vehicle,
                  selected:
                      vehicle.displayName == state.activeVehicle?.displayName,
                  onTap: () {
                    state.selectVehicle(vehicle);
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

class _ActiveVehicleText extends StatelessWidget {
  const _ActiveVehicleText({required this.vehicle});

  final VehicleProfile? vehicle;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2F383D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactOdometerText extends StatelessWidget {
  const _CompactOdometerText();

  @override
  Widget build(BuildContext context) {
    final controller = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Text(
        controller.displayValue,
        style: const TextStyle(
          color: Color(0xFF1D5A3E),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
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

class _CompanyStockOption extends StatelessWidget {
  const _CompanyStockOption();

  @override
  Widget build(BuildContext context) {
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
          child: const Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: Color(0xFFFFD166)),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All / Company Stock',
                      style: TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Use this when the record belongs to general stock instead of one vehicle.',
                      style: TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFE8ECEE)),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.currentSection});

  final AppSection currentSection;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _AppNavItem('🏠', 'Dashboard', AppSection.dashboard),
      const _AppNavItem(
        '🧾',
        'Expenses',
        AppSection.expenses,
        ExpensesScreen(),
      ),
      const _AppNavItem(
        '📄',
        'Invoices',
        AppSection.invoices,
        InvoicesScreen(),
      ),
      const _AppNavItem(
        '📦',
        'Work Supplies',
        AppSection.materials,
        WorkSupplyScreen(),
      ),
      const _AppNavItem(
        '🛠️',
        'Maintenance',
        AppSection.maintenance,
        MaintenanceScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final navHeight = compact ? 58.0 : 66.0;
        final iconSize = compact ? 22.0 : 24.0;

        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF101416)),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: InkWell(
                      onTap: () => _openSection(context, item),
                      child: SizedBox(
                        height: navHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.icon,
                                style: TextStyle(
                                  fontSize: iconSize + 4,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFFD3DBDE),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSection(BuildContext context, _AppNavItem item) {
    openAppSectionRoot(context, item.section);
  }
}

void openAppSectionRoot(BuildContext context, AppSection section) {
  final navigator = Navigator.of(context);
  if (section == AppSection.dashboard) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final screen = switch (section) {
    AppSection.dashboard => null,
    AppSection.expenses => const ExpensesScreen(),
    AppSection.invoices => const InvoicesScreen(),
    AppSection.materials => const WorkSupplyScreen(),
    AppSection.maintenance => const MaintenanceScreen(),
  };
  navigator.pushAndRemoveUntil(
    appSlideRoute<void>(screen!),
    (route) => route.isFirst,
  );
}

class _AppNavItem {
  const _AppNavItem(this.icon, this.label, this.section, [this.screen]);

  final String icon;
  final String label;
  final AppSection section;
  final Widget? screen;
}

enum AppSection { dashboard, expenses, invoices, maintenance, materials }

class AppSectionScreen extends StatelessWidget {
  const AppSectionScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.summary,
    this.action,
  });

  final String title;
  final IconData icon;
  final String summary;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 130),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFAAB4B9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF101416), width: 1.3),
              ),
              child: Column(
                children: [
                  Icon(icon, color: const Color(0xFF101416), size: 34),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2F383D),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 12), action!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBackgroundPainter extends CustomPainter {
  const _AppBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3337), Color(0xFF354147), Color(0xFF222B30)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AppBackgroundPainter oldDelegate) => false;
}
