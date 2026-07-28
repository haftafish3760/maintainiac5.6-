import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'vehicle_profile_detail.dart';
import 'vehicle_profile_widgets.dart';
import 'vehicle_tire_configuration_selector.dart';

VehicleProfilePreview _previewForVehicle(VehicleProfile vehicle) {
  return VehicleProfilePreview(
    id: vehicle.id,
    nickname: vehicle.nickname,
    year: vehicle.year,
    make: vehicle.make,
    model: vehicle.model,
    odometer: '',
    status: 'Available',
    usage: vehicle.usage,
    tireSizeStatus: vehicle.tireSizeStatus,
    speedometerCalibrationStatus: vehicle.speedometerCalibrationStatus,
    tireConfigurationRevision: vehicle.tireConfigurationRevision,
    tireConfigurationUpdatedAt: vehicle.tireConfigurationUpdatedAt,
  );
}

class ActiveVehicleDrawer extends StatelessWidget {
  const ActiveVehicleDrawer({
    super.key,
    required this.activeVehicle,
    required this.onChanged,
    this.fullWidth = false,
  });

  final VehicleProfilePreview activeVehicle;
  final ValueChanged<VehicleProfilePreview> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final drawer = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: VehicleProfilePanel(
        label: 'ACTIVE VEHICLE',
        child: InkWell(
          onTap: () => _openSavedVehicles(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(
              children: [
                const Text('🚚', style: TextStyle(fontSize: 20, height: 1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeVehicle.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFEAF2F5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      if (activeVehicle.odometer.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${activeVehicle.status == 'LIVE GPS' ? 'Live odometer' : 'Odometer'} ${activeVehicle.odometer}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFC9D9E0),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFEAF2F5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return drawer;
    }

    return Center(
      child: FractionallySizedBox(widthFactor: 0.72, child: drawer),
    );
  }

  Future<void> _openSavedVehicles(BuildContext context) async {
    final selected = await Navigator.of(context).push<VehicleProfilePreview>(
      appNativeRoute(
        context,
        SavedVehiclesScreen(activeVehicle: activeVehicle),
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

VehicleProfilePreview get defaultVehicleProfile => VehicleProfilePreview(
  id: 'vehicle_work_truck_1',
  nickname: 'Work Truck 1',
  year: '2018',
  make: 'Ford',
  model: 'F-150',
  odometer: '',
  status: 'Active',
);

class SavedVehiclesScreen extends StatefulWidget {
  const SavedVehiclesScreen({super.key, required this.activeVehicle});

  final VehicleProfilePreview activeVehicle;

  @override
  State<SavedVehiclesScreen> createState() => _SavedVehiclesScreenState();
}

class _SavedVehiclesScreenState extends State<SavedVehiclesScreen> {
  late var _selectedVehicle = widget.activeVehicle;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final vehicles = appState.vehicles
        .map(_previewForVehicle)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: VehicleFormBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
            const AppScreenHeader(title: 'Saved Vehicles'),
            const SizedBox(height: 12),
            const VehicleSectionPlateTitle('VEHICLE PROFILES'),
            const SizedBox(height: 12),
            const VehicleHelperText(
              'Choose a saved vehicle, then use it for the day, edit its profile, or add another vehicle.',
            ),
            const SizedBox(height: 12),
            for (final vehicle in vehicles) ...[
              SavedVehicleButton(
                vehicle: vehicle,
                selected: vehicle.id == _selectedVehicle.id,
                onSelect: () => _selectVehicle(vehicle),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 18),
            _VehicleSelectorActions(
              onUseVehicle: _confirmSelectedVehicle,
              onEditVehicle: () =>
                  _openVehicleProfile(context, _selectedVehicle),
              onAddVehicle: _openAddVehicle,
            ),
          ],
        ),
      ),
    );
  }

  void _selectVehicle(VehicleProfilePreview vehicle) {
    setState(() => _selectedVehicle = vehicle);
  }

  Future<void> _confirmSelectedVehicle() async {
    final selected = AppStateScope.of(context).vehicles.firstWhere(
      (vehicle) => vehicle.id == _selectedVehicle.id,
      orElse: () => AppStateScope.of(context).activeVehicle!,
    );
    final odometer = GlobalOdometerScope.of(context);
    final targetOdometerVehicleId = odometerVehicleIdForVehicleId(
      selected.id,
      fallbackLabel: selected.nickname,
    );
    if (odometer.vehicleId != targetOdometerVehicleId) {
      final switched = await odometer.switchVehicleById(
        targetOdometerVehicleId,
      );
      if (!mounted) return;
      if (!switched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review the active trip before switching vehicles.'),
          ),
        );
        return;
      }
    }
    await AppStateScope.of(context).selectVehicle(selected);
    if (!mounted) return;
    Navigator.of(context).pop(_selectedVehicle);
  }

  Future<void> _openVehicleProfile(
    BuildContext context,
    VehicleProfilePreview vehicle,
  ) async {
    final outcome = await Navigator.of(context)
        .push<VehicleProfileDetailOutcome>(
          appNativeRoute(
            context,
            VehicleProfileDetailScreen(
              vehicle: vehicle,
              canDelete: AppStateScope.of(context).vehicles.length > 1,
              onDelete: () async {
                final appState = AppStateScope.of(context);
                await appState.deleteVehicle(vehicle.id);
                return _previewForVehicle(appState.activeVehicle!);
              },
            ),
          ),
        );
    if (!context.mounted || outcome == null) return;
    if (outcome.deleted) {
      setState(() => _selectedVehicle = outcome.vehicle);
      return;
    }
    final edited = outcome.vehicle;
    await AppStateScope.of(context).updateVehicle(
      VehicleProfile(
        id: edited.id,
        nickname: edited.nickname,
        year: edited.year,
        make: edited.make,
        model: edited.model,
        usage: edited.usage,
        tireSizeStatus: edited.tireSizeStatus,
        speedometerCalibrationStatus: edited.speedometerCalibrationStatus,
        tireConfigurationRevision: edited.tireConfigurationRevision,
        tireConfigurationUpdatedAt: edited.tireConfigurationUpdatedAt,
      ),
    );
    if (mounted) setState(() => _selectedVehicle = edited);
  }

  Future<void> _openAddVehicle() async {
    final added = await Navigator.of(context).push<VehicleProfilePreview>(
      appNativeRoute(context, const AddVehicleProfileScreen()),
    );
    if (!mounted || added == null) return;
    setState(() => _selectedVehicle = added);
  }
}

class _VehicleSelectorActions extends StatelessWidget {
  const _VehicleSelectorActions({
    required this.onUseVehicle,
    required this.onEditVehicle,
    required this.onAddVehicle,
  });

  final VoidCallback onUseVehicle;
  final VoidCallback onEditVehicle;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SelectorActionButton(
          icon: Icons.check_rounded,
          label: 'Use Vehicle',
          color: AppActionColors.positive,
          onPressed: onUseVehicle,
        ),
        const SizedBox(height: 8),
        _SelectorActionButton(
          icon: Icons.edit_note_rounded,
          label: 'Edit Vehicle',
          color: const Color(0xFF2E6FA8),
          onPressed: onEditVehicle,
        ),
        const SizedBox(height: 8),
        _SelectorActionButton(
          icon: Icons.add_rounded,
          label: 'Add Vehicle',
          color: const Color(0xFF59636A),
          onPressed: onAddVehicle,
        ),
      ],
    );
  }
}

class _SelectorActionButton extends StatelessWidget {
  const _SelectorActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 220,
        height: 46,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AddVehicleProfileScreen extends StatefulWidget {
  const AddVehicleProfileScreen({super.key});

  @override
  State<AddVehicleProfileScreen> createState() =>
      _AddVehicleProfileScreenState();
}

class _AddVehicleProfileScreenState extends State<AddVehicleProfileScreen> {
  final _nicknameController = TextEditingController();
  final _yearController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _nicknameFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _makeFocus = FocusNode();
  final _modelFocus = FocusNode();
  VehicleUsage? _usage;
  var _tireSizeStatus = VehicleTireSizeStatus.unknown;
  var _speedometerCalibrationStatus =
      VehicleSpeedometerCalibrationStatus.unknown;

  @override
  void dispose() {
    _nicknameController.dispose();
    _yearController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _nicknameFocus.dispose();
    _yearFocus.dispose();
    _makeFocus.dispose();
    _modelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: VehicleFormBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
            const AppScreenHeader(title: 'Add Vehicle'),
            const SizedBox(height: 12),
            const VehicleSectionPlateTitle('MANUAL VEHICLE DETAILS'),
            const SizedBox(height: 18),
            const VehicleHelperText(
              'Give this vehicle a simple name or number you will recognize later, like Truck 1, Van 2, or Work Car.',
            ),
            const SizedBox(height: 8),
            VehicleField(
              controller: _nicknameController,
              label: 'Vehicle nickname',
              hintText: 'Truck 1',
              focusNode: _nicknameFocus,
              nextFocusNode: _yearFocus,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            VehicleField(
              controller: _yearController,
              label: 'Year',
              hintText: '2021',
              focusNode: _yearFocus,
              nextFocusNode: _makeFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            VehicleField(
              controller: _makeController,
              label: 'Make',
              hintText: 'Ford',
              focusNode: _makeFocus,
              nextFocusNode: _modelFocus,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            VehicleField(
              controller: _modelController,
              label: 'Model',
              hintText: 'Transit',
              focusNode: _modelFocus,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 18),
            VehicleUsageSelector(
              value: _usage,
              onChanged: (usage) => setState(() => _usage = usage),
            ),
            const SizedBox(height: 18),
            VehicleTireConfigurationSelector(
              tireSizeStatus: _tireSizeStatus,
              speedometerCalibrationStatus: _speedometerCalibrationStatus,
              onTireSizeChanged: (value) =>
                  setState(() => _tireSizeStatus = value),
              onSpeedometerCalibrationChanged: (value) =>
                  setState(() => _speedometerCalibrationStatus = value),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: _usage == null ? null : _savePreviewVehicle,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppActionColors.positive,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(190, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreviewVehicle() async {
    final usage = _usage;
    if (usage == null) return;
    final nickname = _nicknameController.text.trim();
    final vehicle = VehicleProfile(
      id: 'vehicle_${DateTime.now().microsecondsSinceEpoch}',
      nickname: nickname.isEmpty ? 'New Vehicle' : nickname,
      year: _yearController.text.trim(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      usage: usage,
      tireSizeStatus: _tireSizeStatus,
      speedometerCalibrationStatus: _speedometerCalibrationStatus,
      tireConfigurationRevision: 1,
      tireConfigurationUpdatedAt: DateTime.now().toUtc(),
    );
    await AppStateScope.of(context).addVehicle(vehicle);
    if (!mounted) return;
    Navigator.of(context).pop(_previewForVehicle(vehicle));
  }
}
