// Guided Gig/Delivery Start Day context selection.
//
// Owns the pre-odometer choice of vehicle and work profile. It does not
// persist selections, create workdays, or alter odometer truth. Consumed by
// the Gig dashboard before its explicit odometer-entry step.

import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../expenses/data/expense_work_profile_store.dart';

class GigStartDayContextChoice {
  const GigStartDayContextChoice({
    required this.vehicleId,
    required this.workProfileId,
  });

  final String vehicleId;
  final String workProfileId;
}

/// The normal one-vehicle, one-profile path should never add a needless
/// confirmation screen before the physical odometer entry.
bool shouldSkipGigStartDayContextSelection({
  required int vehicleCount,
  required int workProfileCount,
}) => vehicleCount == 1 && workProfileCount == 1;

Future<GigStartDayContextChoice?> openGigStartDaySetupSheet(
  BuildContext context, {
  required List<VehicleProfile> vehicles,
  required List<ExpenseWorkProfile> workProfiles,
  required String initialVehicleId,
  required String initialWorkProfileId,
}) {
  return showModalBottomSheet<GigStartDayContextChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (context) => _GigStartDaySetupSheet(
      vehicles: vehicles,
      workProfiles: workProfiles,
      initialVehicleId: initialVehicleId,
      initialWorkProfileId: initialWorkProfileId,
    ),
  );
}

class _GigStartDaySetupSheet extends StatefulWidget {
  const _GigStartDaySetupSheet({
    required this.vehicles,
    required this.workProfiles,
    required this.initialVehicleId,
    required this.initialWorkProfileId,
  });

  final List<VehicleProfile> vehicles;
  final List<ExpenseWorkProfile> workProfiles;
  final String initialVehicleId;
  final String initialWorkProfileId;

  @override
  State<_GigStartDaySetupSheet> createState() => _GigStartDaySetupSheetState();
}

class _GigStartDaySetupSheetState extends State<_GigStartDaySetupSheet> {
  late String _vehicleId = widget.initialVehicleId;
  late String _workProfileId = widget.initialWorkProfileId;

  VehicleProfile get _vehicle => widget.vehicles.firstWhere(
    (vehicle) => vehicle.id == _vehicleId,
    orElse: () => widget.vehicles.first,
  );

  ExpenseWorkProfile get _workProfile => widget.workProfiles.firstWhere(
    (profile) => profile.id == _workProfileId,
    orElse: () => widget.workProfiles.first,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start Your Delivery Day',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101416),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Confirm the work profile and vehicle for this day. You will enter the physical odometer next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF273237),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final showWorkProfile = widget.workProfiles.length > 1;
                final showVehicle = widget.vehicles.length > 1;
                final canSitSideBySide =
                    showWorkProfile &&
                    showVehicle &&
                    constraints.maxWidth >= 390 &&
                    _workProfile.name.length <= 20 &&
                    _vehicle.displayName.length <= 24;
                final cardWidth = canSitSideBySide
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth.clamp(178.0, 266.0).toDouble();
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (showWorkProfile)
                      SizedBox(
                        width: cardWidth,
                        child: _ContextSelector(
                          label: 'Work profile',
                          value: _workProfile.name,
                          icon: Icons.work_rounded,
                          onTap: _chooseWorkProfile,
                        ),
                      ),
                    if (showVehicle)
                      SizedBox(
                        width: cardWidth,
                        child: _ContextSelector(
                          label: 'Vehicle',
                          value: _vehicle.displayName,
                          icon: Icons.directions_car_filled_rounded,
                          onTap: _chooseVehicle,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            const _NextOdometerPanel(),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    GigStartDayContextChoice(
                      vehicleId: _vehicle.id,
                      workProfileId: _workProfile.id,
                    ),
                  ),
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('Enter Odometer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseVehicle() async {
    if (widget.vehicles.length < 2) return;
    final selected = await _pickChoice(
      context,
      title: 'Choose vehicle',
      options: widget.vehicles
          .map((vehicle) => _ChoiceOption(vehicle.id, vehicle.displayName))
          .toList(growable: false),
      selectedId: _vehicleId,
    );
    if (selected != null && mounted) setState(() => _vehicleId = selected);
  }

  Future<void> _chooseWorkProfile() async {
    if (widget.workProfiles.length < 2) return;
    final selected = await _pickChoice(
      context,
      title: 'Choose work profile',
      options: widget.workProfiles
          .map((profile) => _ChoiceOption(profile.id, profile.name))
          .toList(growable: false),
      selectedId: _workProfileId,
    );
    if (selected != null && mounted) {
      setState(() => _workProfileId = selected);
    }
  }
}

class _ContextSelector extends StatelessWidget {
  const _ContextSelector({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF173444)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF273237),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF101416),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Choose',
                  style: const TextStyle(
                    color: Color(0xFF455157),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextOdometerPanel extends StatelessWidget {
  const _NextOdometerPanel();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF101719),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.speed_rounded, color: Color(0xFF9EC7D8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Next, enter the number currently shown on the physical odometer.',
                style: TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption(this.id, this.label);

  final String id;
  final String label;
}

Future<String?> _pickChoice(
  BuildContext context, {
  required String title,
  required List<_ChoiceOption> options,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF2E3A40),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in options) ...[
              ListTile(
                title: Text(option.label),
                trailing: Icon(
                  option.id == selectedId
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                ),
                onTap: () => Navigator.of(context).pop(option.id),
              ),
              if (option != options.last) const Divider(height: 1),
            ],
          ],
        ),
      ),
    ),
  );
}
