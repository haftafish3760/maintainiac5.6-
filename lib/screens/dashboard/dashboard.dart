import 'package:flutter/material.dart';

import 'active_workday_screen.dart';
import 'calendar.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'dashboard_panels.dart';
import 'start_day_panel.dart';
import 'vehicle_profile_flow.dart';
import '../../shared/navigation/app_page_routes.dart';
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
  final _activeVehicle = defaultVehicleProfile;
  final _workProfile = 'Business';

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: GlobalOdometerHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: MessageBoardStrip()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ContractorDashboardLauncher()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: PreDayStartContent(onStartDay: _startDay)),
        const SliverToBoxAdapter(child: SizedBox(height: 76)),
        const SliverToBoxAdapter(child: DashboardMonthCalendar()),
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
    await ActiveWorkdayScope.of(context).startDay(
      vehicleId: odometerVehicleIdForLabel(_activeVehicle.nickname),
      vehicleLabel: _activeVehicle.nickname,
      workProfileId: _workProfile,
      startOdometer: odometer.reading,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      appSlideRoute(
        ActiveWorkdayScreen(
          activeVehicle: _activeVehicle,
          workProfileName: _workProfile,
        ),
      ),
    );
  }
}
