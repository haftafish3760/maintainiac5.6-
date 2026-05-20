import 'package:flutter/material.dart';

import '../../screens/expenses/expenses_screen.dart';
import '../../screens/invoices/invoices_screen.dart';
import '../../screens/maintenance/maintenance_screen.dart';
import '../navigation/app_page_routes.dart';
import '../state/global_odometer.dart';
import 'flow_placeholder_screen.dart';
import 'industrial_panel_surface.dart';
import 'odometer_entry_sheet.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.body,
    this.maxWidth = 600,
    this.section = AppSection.dashboard,
  });

  final Widget body;
  final double maxWidth;
  final AppSection section;

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
  const GlobalOdometerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IndustrialPanelSurface(
        padding: const EdgeInsets.fromLTRB(9, 5, 9, 7),
        child: Column(
          children: [
            Text(
              'ODOMETER',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                    onPressed: () => _openUtilityFlow(
                      context,
                      title: 'Main Menu',
                      icon: Icons.menu_rounded,
                      summary:
                          'This will become the app-wide menu for alerts, records, profile tools, exports, and app-level shortcuts.',
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.menu_rounded, size: 24),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _GlobalOdometerDigits(),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _openOdometerEditor(context),
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 30,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Edit odometer',
                            icon: const Icon(Icons.edit_rounded, size: 18),
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
                    onPressed: () => _openUtilityFlow(
                      context,
                      title: 'Settings',
                      icon: Icons.settings_rounded,
                      summary:
                          'This will hold global settings, trip tracking preferences, screen options, privacy controls, and quick-action setup.',
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.settings_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openOdometerEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFE2E8EA),
      builder: (context) => const OdometerEntrySheet(
        title: 'Edit Odometer',
        saveLabel: 'Save Reading',
      ),
    );
  }

  void _openUtilityFlow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String summary,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FlowPlaceholderScreen(title: title, icon: icon, summary: summary),
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
                                textScaler: TextScaler.noScaling,
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
    if (item.section == currentSection) {
      return;
    }

    final navigator = Navigator.of(context);
    if (item.section == AppSection.dashboard) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    final route = appSlideRoute<void>(item.screen!);
    if (navigator.canPop()) {
      navigator.pushReplacement(route);
      return;
    }
    navigator.push(route);
  }
}

class _AppNavItem {
  const _AppNavItem(this.icon, this.label, this.section, [this.screen]);

  final String icon;
  final String label;
  final AppSection section;
  final Widget? screen;
}

enum AppSection { dashboard, expenses, invoices, maintenance }

class AppBannerAdReserve extends StatelessWidget {
  const AppBannerAdReserve({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF222A2E), Color(0xFF151B1E)],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF4E5A60)),
          bottom: BorderSide(color: Color(0xFF050607)),
        ),
      ),
      child: const Text(
        'Ad space',
        style: TextStyle(
          color: Color(0xFFC4CED3),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

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
                color: const Color(0xFFD2D9DC),
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

class _GlobalOdometerDigits extends StatelessWidget {
  const _GlobalOdometerDigits();

  @override
  Widget build(BuildContext context) {
    final controller = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _OdometerDigits(value: controller.displayValue),
    );
  }
}

class _OdometerDigits extends StatelessWidget {
  const _OdometerDigits({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101112),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF050606), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < value.length; index++)
            Container(
              width: 23,
              height: 32,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: index == value.length - 1 ? 0 : 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: index == value.length - 1
                      ? const [Color(0xFFE44A3B), Color(0xFF8E140F)]
                      : const [Color(0xFFFBF8EC), Color(0xFFD9D3BF)],
                ),
                border: Border.all(color: const Color(0xFF17191B), width: 1.2),
              ),
              child: Text(
                value[index],
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: index == value.length - 1
                      ? Colors.white
                      : const Color(0xFF16191B),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1,
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
