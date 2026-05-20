import 'package:flutter/material.dart';

import 'active_workday_screen.dart';
import 'calendar.dart';
import 'dashboard_panels.dart';
import 'start_day_panel.dart';
import 'vehicle_profile_flow.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_screen_shell.dart';

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
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: GlobalOdometerHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
        const SliverToBoxAdapter(child: AlertCenterStrip()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: PreDayStartContent(onStartDay: _startDay)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: DashboardMonthCalendar()),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }

  void _startDay() {
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
