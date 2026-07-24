import 'package:flutter/material.dart';

import '../../screens/expenses/settings/expense_settings_screen.dart';
import '../../screens/expenses/home/expenses_home_screen.dart';
import '../../screens/invoices/settings/invoice_settings_screen.dart';
import '../../screens/invoices/home/invoices_home_screen.dart';
import '../../screens/maintenance/maintenance_settings_screen.dart';
import '../../screens/maintenance/maintenance_screen.dart';
import '../../screens/work_supplies/work_supply_screen.dart';
import '../../screens/work_supplies/work_supply_settings_screen.dart';
import '../../screens/settings/dashboard_settings.dart';
import '../../screens/settings/system_settings.dart';
import '../navigation/app_page_routes.dart';
import '../context/operational_context_store.dart';
import '../odometer/open_odometer_entry.dart';
import '../odometer/odometer_vehicle_snapshot.dart';
import '../state/app_state.dart';
import '../state/global_odometer.dart';
import '../trip_tracking/trip_tracking_controller.dart';
import 'app_banner_ad_reserve.dart';
import 'industrial_panel_surface.dart';

part 'app_textured_background.dart';
part 'global_odometer_header.dart';
part 'global_vehicle_picker.dart';
part 'app_bottom_navigation.dart';
part 'app_section_routes.dart';
part 'app_background_painter.dart';

class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.body,
    this.maxWidth = 600,
    this.section = AppSection.dashboard,
    this.floatingActionButton,
    this.pinnedHeader,
  });

  final Widget body;
  final double maxWidth;
  final AppSection section;
  final Widget? floatingActionButton;
  final Widget? pinnedHeader;

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
              child: pinnedHeader == null
                  ? body
                  : Column(
                      children: [
                        pinnedHeader!,
                        Expanded(child: body),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
