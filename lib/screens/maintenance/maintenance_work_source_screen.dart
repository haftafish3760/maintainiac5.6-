import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import 'maintenance_models.dart';
import 'maintenance_svg_icon.dart';

class MaintenanceWorkSourceScreen extends StatefulWidget {
  const MaintenanceWorkSourceScreen({super.key});

  @override
  State<MaintenanceWorkSourceScreen> createState() =>
      _MaintenanceWorkSourceScreenState();
}

class _MaintenanceWorkSourceScreenState
    extends State<MaintenanceWorkSourceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            children: const [MaintenanceTrackingSelectionPanel()],
          ),
        ),
      ),
    );
  }
}

class MaintenanceTrackingSelectionPanel extends StatefulWidget {
  const MaintenanceTrackingSelectionPanel({super.key, this.showCancel = true});

  final bool showCancel;

  @override
  State<MaintenanceTrackingSelectionPanel> createState() =>
      _MaintenanceTrackingSelectionPanelState();
}

class _MaintenanceTrackingSelectionPanelState
    extends State<MaintenanceTrackingSelectionPanel> {
  final Set<MaintenanceCatalogItem> _selected = <MaintenanceCatalogItem>{};

  @override
  Widget build(BuildContext context) {
    return _MaintenanceSetupSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppScreenHeader(title: 'Maintenance Setup'),
          const SizedBox(height: 10),
          const Text(
            'Welcome to Maintenance',
            style: TextStyle(
              color: Color(0xFFE9EEF1),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let's get your maintenance tracking set up.",
            style: TextStyle(
              color: Color(0xFFE9EEF1),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select the maintenance items you want Maintainiac to help you track.',
            style: TextStyle(
              color: Color(0xFFCAD4D8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'You can change these selections at any time later in the settings menu.',
            style: TextStyle(
              color: Color(0xFFB8C4C8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in maintenanceCatalog) ...[
            _MaintenanceTrackOption(
              item: item,
              selected: _selected.contains(item),
              onTap: () => _toggle(item),
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.showCancel) ...[
                AppButton(
                  label: 'Cancel',
                  tone: AppButtonTone.destructive,
                  compact: true,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
              ],
              AppButton(
                label: 'Continue',
                tone: AppButtonTone.commit,
                compact: true,
                onPressed: _selected.isEmpty ? null : _continue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggle(MaintenanceCatalogItem item) {
    setState(() {
      _selected.contains(item) ? _selected.remove(item) : _selected.add(item);
    });
  }

  Future<void> _continue() async {
    final state = AppStateScope.of(context);
    final activeVehicle =
        state.activeVehicle ??
        (state.vehicles.isEmpty ? null : state.vehicles.first);
    final vehicleName = activeVehicle?.nickname ?? 'Current Vehicle';
    final vehicleId = activeVehicle?.id ?? '';
    final existingForVehicle = state.maintenance
        .where(
          (record) =>
              activeVehicle != null && record.belongsToVehicle(activeVehicle),
        )
        .map((record) => record.itemName)
        .toSet();

    final selectedItems = maintenanceCatalog
        .where(_selected.contains)
        .where((item) => !existingForVehicle.contains(item.name))
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Those maintenance items are already being tracked.'),
        ),
      );
      if (widget.showCancel && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      await state.addMaintenanceRecords(
        selectedItems
            .map(
              (item) => MaintenanceRecord(
                itemName: item.name,
                vehicleName: vehicleName,
                vehicleId: vehicleId,
                intervalMiles: item.defaultMiles,
                milesSinceService: 0,
                intervalMonths: item.defaultMonths,
                monthsSinceService: 0,
                importance: item.importance,
                timeOnly: item.timeOnly,
              ),
            )
            .toList(),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedItems.length == 1
              ? '${selectedItems.first.name} is now tracked for $vehicleName.'
              : '${selectedItems.length} maintenance items are now tracked for $vehicleName.',
        ),
      ),
    );
    if (widget.showCancel && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _MaintenanceSetupSurface extends StatelessWidget {
  const _MaintenanceSetupSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF303A3E), Color(0xFF20282B), Color(0xFF151B1D)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF4C5A61), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MaintenanceTrackOption extends StatelessWidget {
  const _MaintenanceTrackOption({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MaintenanceCatalogItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFF173A26)
        : const Color(0xFF293237);
    final border = selected
        ? AppActionColors.positive
        : const Color(0xFF647177);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Ink(
          height: 58,
          padding: const EdgeInsets.fromLTRB(8, 0, 9, 0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: border, width: 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9EEF1), Color(0xFFBFC9CE)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF0D1214),
                    width: 1.4,
                  ),
                ),
                child: MaintenanceSvgIcon(itemName: item.name, size: 38),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE9EEF1),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SelectionBox(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: selected ? AppActionColors.positive : const Color(0xFF182024),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? AppActionColors.positive : const Color(0xFFE2E8EA),
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}
