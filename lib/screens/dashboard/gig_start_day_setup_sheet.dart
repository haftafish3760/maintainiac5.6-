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
            const Center(
              child: SizedBox(
                width: 34,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF8FA4AD),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StartSheetIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start workday',
                        style: TextStyle(
                          color: Color(0xFFF3F6F7),
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Step 1 of 2: confirm who and what vehicle this workday uses.',
                        style: TextStyle(
                          color: Color(0xFFC7D5DA),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final showWorkProfile = widget.workProfiles.length > 1;
                final showVehicle = widget.vehicles.length > 1;
                final canSitSideBySide =
                    showWorkProfile &&
                    showVehicle &&
                    _workProfile.name.length <= 14 &&
                    _vehicle.displayName.length <= 16;
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
                          compact: canSitSideBySide,
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
                          compact: canSitSideBySide,
                          onTap: _chooseVehicle,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'The next step asks for the physical odometer reading.',
              textAlign: TextAlign.center,
              style: TextStyle(
              color: Color(0xFFC7D5DA),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  GigStartDayContextChoice(
                    vehicleId: _vehicle.id,
                    workProfileId: _workProfile.id,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue to odometer'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF166D4A),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
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
    required this.compact,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: const Color(0xFF151F23),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF7CC7FF),
                  size: compact ? 20 : 24,
                ),
                SizedBox(width: compact ? 6 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compact && label == 'Work profile' ? 'Profile' : label,
                        style: TextStyle(
                          color: Color(0xFFC7D5DA),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFF3F6F7),
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const Text(
                    'Change',
                    style: TextStyle(
                      color: Color(0xFF7CC7FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7CC7FF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartSheetIcon extends StatelessWidget {
  const _StartSheetIcon();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(color: Color(0xFF1C4A3A), shape: BoxShape.circle),
    child: Padding(
      padding: EdgeInsets.all(10),
      child: Icon(Icons.play_arrow_rounded, color: Color(0xFF77D9AA), size: 24),
    ),
  );
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
                color: Color(0xFFF3F6F7),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in options) ...[
              ListTile(
                title: Text(
                  option.label,
                  style: const TextStyle(
                    color: Color(0xFFF3F6F7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: Icon(
                  option.id == selectedId
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: option.id == selectedId
                      ? const Color(0xFF77D9AA)
                      : const Color(0xFFC7D5DA),
                ),
                onTap: () => Navigator.of(context).pop(option.id),
              ),
              if (option != options.last)
                const Divider(height: 1, color: Color(0xFF526168)),
            ],
          ],
        ),
      ),
    ),
  );
}
