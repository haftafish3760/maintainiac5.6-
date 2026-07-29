// User-confirmed vehicle and work-profile handoff sheet for an active workday.
//
// Owns selection and physical-odometer boundary input only. It does not save
// workday, vehicle, profile, or odometer records; the durable coordinator does.
// ActiveWorkdayScreen consumes the returned draft after GPS is safely reviewed.

import 'package:flutter/material.dart';

import '../../shared/state/app_state.dart';
import '../expenses/data/expense_work_profile_store.dart';

final class ActiveWorkdayContextHandoffDraft {
  const ActiveWorkdayContextHandoffDraft({
    required this.vehicle,
    required this.workProfile,
    required this.endingOdometer,
    required this.startingOdometer,
  });

  final VehicleProfile vehicle;
  final ExpenseWorkProfile workProfile;
  final int endingOdometer;
  final int startingOdometer;
}

Future<ActiveWorkdayContextHandoffDraft?> openActiveWorkdayContextHandoffSheet(
  BuildContext context, {
  required VehicleProfile currentVehicle,
  required ExpenseWorkProfile currentWorkProfile,
  required int currentOdometer,
  required List<VehicleProfile> vehicles,
  required List<ExpenseWorkProfile> workProfiles,
}) => showModalBottomSheet<ActiveWorkdayContextHandoffDraft>(
  context: context,
  isScrollControlled: true,
  backgroundColor: const Color(0xFFF3F6F7),
  builder: (context) => _ActiveWorkdayContextHandoffSheet(
    currentVehicle: currentVehicle,
    currentWorkProfile: currentWorkProfile,
    currentOdometer: currentOdometer,
    vehicles: vehicles.where((vehicle) => !vehicle.isArchived).toList(),
    workProfiles: workProfiles.where((profile) => !profile.isArchived).toList(),
  ),
);

class _ActiveWorkdayContextHandoffSheet extends StatefulWidget {
  const _ActiveWorkdayContextHandoffSheet({
    required this.currentVehicle,
    required this.currentWorkProfile,
    required this.currentOdometer,
    required this.vehicles,
    required this.workProfiles,
  });

  final VehicleProfile currentVehicle;
  final ExpenseWorkProfile currentWorkProfile;
  final int currentOdometer;
  final List<VehicleProfile> vehicles;
  final List<ExpenseWorkProfile> workProfiles;

  @override
  State<_ActiveWorkdayContextHandoffSheet> createState() =>
      _ActiveWorkdayContextHandoffSheetState();
}

class _ActiveWorkdayContextHandoffSheetState
    extends State<_ActiveWorkdayContextHandoffSheet> {
  late String _vehicleId = widget.currentVehicle.id;
  late String _workProfileId = widget.currentWorkProfile.id;
  late final TextEditingController _endingOdometer = TextEditingController(
    text: '${widget.currentOdometer}',
  );
  late final TextEditingController _startingOdometer = TextEditingController(
    text: '${widget.currentOdometer}',
  );
  String? _error;

  VehicleProfile get _vehicle => widget.vehicles.firstWhere(
    (vehicle) => vehicle.id == _vehicleId,
    orElse: () => widget.currentVehicle,
  );
  ExpenseWorkProfile get _workProfile => widget.workProfiles.firstWhere(
    (profile) => profile.id == _workProfileId,
    orElse: () => widget.currentWorkProfile,
  );
  bool get _sameVehicle => _vehicle.id == widget.currentVehicle.id;

  @override
  void dispose() {
    _endingOdometer.dispose();
    _startingOdometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
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
                      color: Color(0xFF9AA8AD),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Change workday context',
                style: TextStyle(
                  color: Color(0xFF101416),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Confirm the vehicle, work profile, and physical odometer boundary. Your day stays split into separate, reviewable segments.',
                style: TextStyle(
                  color: Color(0xFF435258),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              _selectionField<VehicleProfile>(
                label: 'Vehicle for the next segment',
                value: _vehicle,
                items: widget.vehicles,
                itemLabel: (vehicle) => vehicle.displayName,
                onChanged: (vehicle) {
                  if (vehicle == null) return;
                  setState(() {
                    _vehicleId = vehicle.id;
                    _error = null;
                    if (vehicle.id == widget.currentVehicle.id) {
                      _startingOdometer.text = _endingOdometer.text;
                    } else {
                      _startingOdometer.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              _selectionField<ExpenseWorkProfile>(
                label: 'Work profile for the next segment',
                value: _workProfile,
                items: widget.workProfiles,
                itemLabel: (profile) => profile.name,
                onChanged: (profile) {
                  if (profile == null) return;
                  setState(() {
                    _workProfileId = profile.id;
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endingOdometer,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_sameVehicle) {
                    _startingOdometer.text = _endingOdometer.text;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Current odometer on the outgoing vehicle',
                  helperText: 'Read this directly from the physical odometer.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startingOdometer,
                keyboardType: TextInputType.number,
                readOnly: _sameVehicle,
                decoration: InputDecoration(
                  labelText: _sameVehicle
                      ? 'Same vehicle boundary'
                      : 'Current odometer on the incoming vehicle',
                  helperText: _sameVehicle
                      ? 'The same vehicle keeps one continuous odometer boundary.'
                      : 'Read this directly from the incoming vehicle.',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFF9C2525),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _continue,
                    child: const Text('Review change'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    final ending = int.tryParse(_endingOdometer.text.trim());
    final starting = int.tryParse(_startingOdometer.text.trim());
    if (ending == null || ending < 0 || starting == null || starting < 0) {
      setState(() => _error = 'Enter valid whole-mile odometer readings.');
      return;
    }
    if (_sameVehicle && ending != starting) {
      setState(
        () => _error = 'The same vehicle must use one odometer boundary.',
      );
      return;
    }
    Navigator.of(context).pop(
      ActiveWorkdayContextHandoffDraft(
        vehicle: _vehicle,
        workProfile: _workProfile,
        endingOdometer: ending,
        startingOdometer: starting,
      ),
    );
  }
}

Widget _selectionField<T>({
  required String label,
  required T value,
  required List<T> items,
  required String Function(T item) itemLabel,
  required ValueChanged<T?> onChanged,
}) => DropdownButtonFormField<T>(
  initialValue: value,
  isExpanded: true,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
  items: [
    for (final item in items)
      DropdownMenuItem(
        value: item,
        child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
      ),
  ],
  onChanged: onChanged,
);
