import 'dart:async';

import 'package:flutter/material.dart';

import 'active_workday_screen.dart';
import '../../shared/calendar/calendar.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'dashboard_panels.dart';
import 'start_day_panel.dart';
import 'vehicle_profile_flow.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/context/operational_context_store.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'data/active_workday_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreenShell(body: _PreDayDashboardBody());
  }
}

class _PreDayDashboardBody extends StatefulWidget {
  const _PreDayDashboardBody();

  @override
  State<_PreDayDashboardBody> createState() => _PreDayDashboardBodyState();
}

class _PreDayDashboardBodyState extends State<_PreDayDashboardBody> {
  var _activeVehicle = defaultVehicleProfile;

  @override
  Widget build(BuildContext context) {
    final operationalContext = OperationalContextScope.maybeOf(context);
    final activeContext = operationalContext?.context;
    final contextLabel = activeContext == null
        ? 'Local dashboard'
        : '${activeContext.dashboardMode.label} / '
              '${activeContext.mileageMode.label} / '
              '${activeContext.syncMode.label}';
    final workProfile = activeContext?.workProfileName ?? 'Business';
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: GlobalOdometerHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: DashboardContextSelectors(
            activeVehicle: _activeVehicle,
            workProfile: workProfile,
            onVehicleChanged: (vehicle) {
              setState(() => _activeVehicle = vehicle);
              if (operationalContext != null) {
                unawaited(
                  operationalContext.setActiveVehicle(
                    vehicleId: odometerVehicleIdForLabel(vehicle.nickname),
                    vehicleLabel: vehicle.nickname,
                    usage: vehicle.usage,
                  ),
                );
              }
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: MessageBoardStrip()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (activeContext == null || activeContext.isContractorDashboard)
          const SliverToBoxAdapter(child: ContractorDashboardLauncher()),
        if (activeContext != null)
          SliverToBoxAdapter(
            child: OperationalContextStrip(contextLabel: contextLabel),
          ),
        if (activeContext != null)
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: PreDayStartContent(onStartDay: _startDay)),
        const SliverToBoxAdapter(child: SizedBox(height: 76)),
        const SliverToBoxAdapter(child: DashboardCalendar()),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }

  Future<void> _startDay() async {
    final operationalContext = OperationalContextScope.maybeOf(context);
    final activeContext = operationalContext?.context;
    final workProfile = activeContext?.workProfileName ?? 'Business';
    final saved = await openOdometerEntry(
      context,
      title: 'Starting Odometer',
      saveLabel: 'Start Day',
    );
    if (!saved || !mounted) return;
    final odometer = GlobalOdometerScope.of(context);
    await ActiveWorkdayScope.of(context).startDay(
      vehicleId:
          activeContext?.activeVehicleId ??
          odometerVehicleIdForLabel(_activeVehicle.nickname),
      vehicleLabel:
          activeContext?.activeVehicleLabel ?? _activeVehicle.nickname,
      workProfileId: activeContext?.workProfileId ?? workProfile,
      startOdometer: odometer.reading,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      appSlideRoute(
        ActiveWorkdayScreen(
          activeVehicle: _activeVehicle,
          workProfileName: workProfile,
        ),
      ),
    );
  }
}
