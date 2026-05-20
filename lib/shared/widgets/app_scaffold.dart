import 'package:flutter/material.dart';

import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/invoices/invoices_screen.dart';
import '../../screens/maintenance/maintenance_screen.dart';
import '../theme/app_theme.dart';
import 'global_odometer_header.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
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
            icon: Text('🛠️', style: TextStyle(fontSize: 24)),
            label: 'Maintenance',
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) {
    if (index == currentIndex) return;
    final Widget screen = switch (index) {
      0 => const DashboardScreen(),
      1 => const ExpensesScreen(),
      2 => const InvoicesScreen(),
      _ => const MaintenanceScreen(),
    };
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }
}
