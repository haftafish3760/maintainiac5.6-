import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/global_odometer.dart';
import '../theme/app_theme.dart';
import 'industrial_panel.dart';

class GlobalOdometerHeader extends StatelessWidget {
  const GlobalOdometerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final vehicle = state.activeVehicle;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: IndustrialPanel(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          children: [
            const Text(
              'ACTIVE VEHICLE',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.menu_rounded, size: 28, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openVehiclePicker(context, state),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(child: _VehicleText(vehicle: vehicle)),
                        const SizedBox(width: 6),
                        const _OdometerText(),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.ink,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.settings_rounded, color: AppColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openVehiclePicker(BuildContext context, AppStateController state) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1F2528),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Active Vehicle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final vehicle in state.vehicles) ...[
                _VehicleOption(
                  vehicle: vehicle,
                  selected:
                      vehicle.displayName == state.activeVehicle?.displayName,
                  onTap: () {
                    state.selectVehicle(vehicle);
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleText extends StatelessWidget {
  const _VehicleText({required this.vehicle});

  final VehicleProfile? vehicle;

  @override
  Widget build(BuildContext context) {
    final active = vehicle;
    final details = active == null
        ? 'Add or select a vehicle'
        : [
            active.year,
            active.make,
            active.model,
          ].where((part) => part.trim().isNotEmpty).join(' ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          active?.nickname ?? 'Vehicle Required',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        if (details.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2F383D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _OdometerText extends StatelessWidget {
  const _OdometerText();

  @override
  Widget build(BuildContext context) {
    final controller = GlobalOdometerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Text(
        controller.displayValue,
        style: const TextStyle(
          color: Color(0xFF1D5A3E),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _VehicleOption extends StatelessWidget {
  const _VehicleOption({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleProfile vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121719),
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58D67D)
                  : const Color(0xFF66737A),
              width: 1.1,
            ),
          ),
          child: Text(
            vehicle.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
