import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'maintenance_models.dart';
import 'maintenance_svg_icon.dart';
import 'maintenance_work_source_screen.dart';

part 'maintenance_header_section.dart';
part 'maintenance_tracked_list.dart';
part 'maintenance_action_grid.dart';
part 'maintenance_priority_helpers.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (state.maintenance.isEmpty) {
      return AppScreenShell(
        section: AppSection.maintenance,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
          children: const [
            GlobalOdometerHeader(),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MaintenanceTrackingSelectionPanel(showCancel: false),
            ),
          ],
        ),
      );
    }

    final activeVehicle =
        state.activeVehicle ??
        (state.vehicles.isEmpty ? null : state.vehicles.first);
    final records =
        state.maintenance
            .where((record) => record.vehicleName == activeVehicle?.nickname)
            .toList()
          ..sort(_compareMaintenancePriority);

    return AppScreenShell(
      section: AppSection.maintenance,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceHeader(
              state: state,
              activeVehicle: activeVehicle,
              records: records,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TrackedMaintenanceList(records: records),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceActionGrid(),
          ),
        ],
      ),
    );
  }
}
