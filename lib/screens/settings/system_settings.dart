import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../work_supplies/jobs/work_supply_jobs_screen.dart';
import 'master_export_screen.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 220),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: AppScreenHeader(title: 'Menu'),
          ),
          const SizedBox(height: 12),
          const GlobalOdometerHeader(),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _SystemSettingsContent(),
          ),
        ],
      ),
    );
  }
}

class _SystemSettingsContent extends StatelessWidget {
  const _SystemSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ScreenNavigationPanel(),
        const SizedBox(height: 12),
        const _SettingsSurface(
          title: 'System Settings',
          intro:
              'App-wide controls will live here when those systems are built.',
          sections: [
            _SettingsSection(
              title: 'Coming Later',
              rows: [
                'Device permissions',
                'Google Drive and iCloud backup',
                'Export controls',
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ScreenNavigationPanel extends StatelessWidget {
  const _ScreenNavigationPanel();

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
            'Screens',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Open the main tools inside Maintainiac.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _ScreenButton(
            label: 'Master Export',
            onTap: () => Navigator.of(
              context,
            ).push(appSlideRoute(const MasterExportScreen())),
          ),
          const SizedBox(height: 8),
          _ScreenButton(
            label: 'Dashboard',
            onTap: () => openAppSectionRoot(context, AppSection.dashboard),
          ),
          _ScreenButton(
            label: 'Expenses',
            onTap: () => openAppSectionRoot(context, AppSection.expenses),
          ),
          _ScreenButton(
            label: 'Materials',
            onTap: () => openAppSectionRoot(context, AppSection.materials),
          ),
          _ScreenButton(
            label: 'Jobs',
            onTap: () => Navigator.of(
              context,
            ).push(appNativeRoute(context, const WorkSupplyJobsScreen())),
          ),
          _ScreenButton(
            label: 'Invoices',
            onTap: () => openAppSectionRoot(context, AppSection.invoices),
          ),
          _ScreenButton(
            label: 'Maintenance',
            onTap: () => openAppSectionRoot(context, AppSection.maintenance),
          ),
        ],
      ),
    );
  }
}

class _ScreenButton extends StatelessWidget {
  const _ScreenButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1976B9), Color(0xFF0F4068)],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF79C8FF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFE8ECEE),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<_SettingsSection> sections;

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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            intro,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final section in sections) ...[
            section,
            if (section != sections.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});

  final String title;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final row in rows) _SettingsRow(label: row),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF202A2E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF445158)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFE2E8EA)),
        ],
      ),
    );
  }
}
