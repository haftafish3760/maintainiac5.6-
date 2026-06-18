import 'package:flutter/material.dart';

import '../../shared/widgets/app_screen_shell.dart';

class MaintenanceSettingsScreen extends StatelessWidget {
  const MaintenanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.maintenance,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        children: const [
          GlobalOdometerHeader(section: AppSection.maintenance),
          SizedBox(height: 10),
          _MaintenanceSettingsPanel(),
        ],
      ),
    );
  }
}

class _MaintenanceSettingsPanel extends StatelessWidget {
  const _MaintenanceSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF172023),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5D6A71)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Maintenance Settings',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Controls for tracked items, intervals, reminder channels, receipt defaults, and vehicle-specific service rules.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
