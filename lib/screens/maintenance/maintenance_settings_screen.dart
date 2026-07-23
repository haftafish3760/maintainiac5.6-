import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart';

class MaintenanceSettingsScreen extends StatelessWidget {
  const MaintenanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.maintenance,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        children: [
          const GlobalOdometerHeader(section: AppSection.maintenance),
          const SizedBox(height: 10),
          const _MaintenanceSettingsPanel(),
          const SizedBox(height: 10),
          const _ArchivedMaintenancePanel(),
        ],
      ),
    );
  }
}

class _ArchivedMaintenancePanel extends StatelessWidget {
  const _ArchivedMaintenancePanel();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final vehicle = state.activeVehicle;
    final archived = vehicle == null
        ? const <MaintenanceRecord>[]
        : state.allMaintenanceRecords
              .where(
                (record) =>
                    record.isArchived && record.belongsToVehicle(vehicle),
              )
              .toList(growable: false);

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
            'Stopped Items',
            style: TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            vehicle == null
                ? 'Select a vehicle to view stopped maintenance items.'
                : archived.isEmpty
                ? 'No stopped maintenance items for ${vehicle.nickname}.'
                : 'These items keep their setup and service history.',
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final record in archived) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF202B2F),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.itemName,
                        style: const TextStyle(
                          color: Color(0xFFE2E8EA),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Restore',
                      tone: AppButtonTone.commit,
                      compact: true,
                      onPressed: () => _restore(context, state, record),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    AppStateController state,
    MaintenanceRecord record,
  ) async {
    try {
      await state.restoreMaintenanceRecord(record.recordId);
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
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
