import 'package:flutter/material.dart';

import 'active_workday_screen.dart';
import '../../shared/calendar/calendar.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'dashboard_panels.dart';
import 'start_day_panel.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/context/operational_context_store.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/state/app_state.dart';
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
  final _workProfile = 'Business';

  @override
  Widget build(BuildContext context) {
    final operationalContext = OperationalContextScope.maybeOf(context);
    final activeContext = operationalContext?.context;
    final contextLabel = activeContext == null
        ? 'Local dashboard'
        : '${activeContext.dashboardMode.label} / '
              '${activeContext.mileageMode.label} / '
              '${activeContext.syncMode.label}';
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: GlobalOdometerHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: DashboardContextSelectors(
            activeVehicle: _activeVehicle,
            workProfile: _workProfile,
            onVehicleChanged: (vehicle) {
              setState(() => _activeVehicle = vehicle);
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
    final saved = await openOdometerEntry(
      context,
      title: 'Starting Odometer',
      saveLabel: 'Start Day',
    );
    if (!saved || !mounted) return;
    final odometer = GlobalOdometerScope.of(context);
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    if (activeVehicle == null) return;
    await ActiveWorkdayScope.of(context).startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: activeVehicle.nickname,
      workProfileId:
          OperationalContextScope.maybeOf(context)?.context.workProfileId ??
          _workProfile,
      startOdometer: odometer.reading,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      appSlideRoute(
        ActiveWorkdayScreen(
          activeVehicle: VehicleProfilePreview(
            nickname: activeVehicle.nickname,
            year: activeVehicle.year,
            make: activeVehicle.make,
            model: activeVehicle.model,
            odometer: odometer.displayValue,
            status: 'ACTIVE',
            usage: activeVehicle.usage,
          ),
          workProfileName: _workProfile,
        ),
      ),
    );
  }
}
