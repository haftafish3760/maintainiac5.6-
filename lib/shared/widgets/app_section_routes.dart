part of 'app_screen_shell.dart';

void openAppSectionRoot(BuildContext context, AppSection section) {
  final navigator = Navigator.of(context, rootNavigator: true);
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
    appNativeRoute<void>(context, screen!),
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
