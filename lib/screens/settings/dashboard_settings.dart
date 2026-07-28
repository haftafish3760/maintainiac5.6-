import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../dashboard/active_workday_quick_action_editor.dart';
import 'trip_tracking_settings_screen.dart';

class DashboardSettingsScreen extends StatelessWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      pinnedHeader: const AppScreenHeader(title: 'Dashboard Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
        children: const [
          GlobalOdometerHeader(),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _DashboardSettingsPanel(),
          ),
        ],
      ),
    );
  }
}

class _DashboardSettingsPanel extends StatelessWidget {
  const _DashboardSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dashboard Settings',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Trip tracking layout, quick actions, dashboard elements, and telemetry readouts.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _DashboardSettingRow(
            title: 'GPS-Assisted Trip Tracking',
            detail:
                'Location permission, battery profile, low-speed equipment mode, and walking-review preferences.',
            icon: Icons.gps_fixed_rounded,
            onTap: () => Navigator.of(
              context,
            ).push(appSlideRoute(const TripTrackingSettingsScreen())),
          ),
          _DashboardSettingRow(
            title: 'Customize Quick Actions',
            detail:
                'Choose the actions shown on Active Day, including fuel, expenses, payments, GPS review, stops, trip details, and reminders.',
            icon: Icons.tune_rounded,
            onTap: () => Navigator.of(
              context,
            ).push(appSlideRoute<void>(const ActiveWorkdayQuickActionEditor())),
          ),
          const _DashboardSettingRow(
            title: 'Active Day command center',
            detail:
                'Your current workday shows time, verified miles, quick actions, and recorded activity. Financial totals are based on saved ledger records, never estimates.',
          ),
          const _DashboardSettingRow(
            title: 'Default Start Day Position',
            detail: 'Right side now. Later this becomes user movable.',
          ),
        ],
      ),
    );
  }
}

class _DashboardSettingRow extends StatelessWidget {
  const _DashboardSettingRow({
    required this.title,
    required this.detail,
    this.icon,
    this.onTap,
  });

  final String title;
  final String detail;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            decoration: BoxDecoration(
              color: const Color(0xFF202A2E),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF445158)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFFFFD166), size: 22),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E8EA),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCAD2D5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFE2E8EA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
