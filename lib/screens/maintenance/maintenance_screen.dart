import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/state/app_state.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/calendar/maintenance_calendar.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../dashboard/vehicle_profile_detail.dart';
import '../dashboard/vehicle_profile_widgets.dart';
import 'maintenance_item_detail_screen.dart';
import 'maintenance_models.dart';
import 'maintenance_log_service_screen.dart';
import 'maintenance_record_list_screen.dart';
import 'maintenance_svg_icon.dart';
import 'maintenance_work_source_screen.dart';

part 'maintenance_header_section.dart';
part 'maintenance_recap_strip.dart';
part 'maintenance_tracked_list.dart';
part 'maintenance_action_grid.dart';
part 'maintenance_priority_helpers.dart';
part 'maintenance_vehicle_overview.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (state.maintenance.isEmpty) {
      return AppScreenShell(
        section: AppSection.maintenance,
        body: ListView(
          key: const PageStorageKey('maintenance-first-setup'),
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
          children: const [
            GlobalOdometerHeader(section: AppSection.maintenance),
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
        key: const PageStorageKey('maintenance-home'),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: [
          const GlobalOdometerHeader(section: AppSection.maintenance),
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
            child: _MaintenanceRecapStrip(records: records),
          ),
          if (_hasMaintenanceAlerts(state)) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _MaintenanceVehicleOverview(
                vehicles: state.vehicles,
                allRecords: state.maintenance,
                activeVehicle: activeVehicle,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceActionGrid(records: records),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _TrackedMaintenanceList(records: records),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _MaintenanceCalendarPanel(),
          ),
        ],
      ),
    );
  }
}

bool _hasMaintenanceAlerts(AppStateController state) {
  if (state.vehicles.length <= 1) return false;
  for (final record in state.maintenance) {
    if (!record.setupComplete) return true;
    if (record.timeOnly && record.monthsRemaining <= 0) return true;
    if (!record.timeOnly && record.milesRemaining <= 900) return true;
  }
  return false;
}

class _MaintenanceCalendarPanel extends StatelessWidget {
  const _MaintenanceCalendarPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            'Maintenance Calendar',
            style: TextStyle(
              color: Color(0xFFE7EEF1),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        MaintenanceCalendar(),
      ],
    );
  }
}
