part of 'app_screen_shell.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({super.key, required this.currentSection});

  final AppSection currentSection;

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    final items = [
      const _AppNavItem(
        Icons.dashboard_rounded,
        'Dashboard',
        AppSection.dashboard,
      ),
      const _AppNavItem(
        Icons.receipt_long_rounded,
        'Expenses',
        AppSection.expenses,
        ExpensesScreen(),
      ),
      const _AppNavItem(
        Icons.description_rounded,
        'Invoices',
        AppSection.invoices,
        InvoicesScreen(),
      ),
      const _AppNavItem(
        Icons.inventory_2_rounded,
        'Materials',
        AppSection.materials,
        WorkSupplyScreen(),
      ),
      const _AppNavItem(
        Icons.build_rounded,
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
                              Icon(
                                item.icon,
                                size: iconSize,
                                color: item.section == widget.currentSection
                                    ? const Color(0xFF55D68A)
                                    : const Color(0xFFD3DBDE),
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
