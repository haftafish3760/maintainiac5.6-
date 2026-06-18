import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_back_button.dart';
import 'app_screen_shell.dart' hide GlobalOdometerHeader;
import '../odometer/global_odometer_header.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.currentIndex,
    required this.child,
    super.key,
  });

  final String title;
  final int currentIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  AppScreenHeader(
                    title: title,
                    showBack: false,
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFFE2E8EA),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFFE2E8EA),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 4, 10, 8),
                    child: GlobalOdometerHeader(),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFF070908),
        indicatorColor: const Color(0xFF173C5D),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => _open(context, index),
        destinations: const [
          NavigationDestination(
            icon: Text('🏠', style: TextStyle(fontSize: 24)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Text('🧾', style: TextStyle(fontSize: 24)),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Text('💵', style: TextStyle(fontSize: 24)),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Text('📦', style: TextStyle(fontSize: 24)),
            label: 'Materials',
          ),
          NavigationDestination(
            icon: Text('🛠️', style: TextStyle(fontSize: 24)),
            label: 'Maintenance',
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) {
    final section = switch (index) {
      0 => AppSection.dashboard,
      1 => AppSection.expenses,
      2 => AppSection.invoices,
      3 => AppSection.materials,
      _ => AppSection.maintenance,
    };
    openAppSectionRoot(context, section);
  }
}
