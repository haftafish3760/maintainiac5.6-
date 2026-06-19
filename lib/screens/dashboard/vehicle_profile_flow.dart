import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';
import 'vehicle_profile_detail.dart';
import 'vehicle_profile_widgets.dart';

const _savedVehiclePreviews = [
  VehicleProfilePreview(
    nickname: 'Truck 1',
    year: '2021',
    make: 'Ford',
    model: 'Transit',
    odometer: '298,150',
    status: 'Active',
  ),
  VehicleProfilePreview(
    nickname: 'Backup Van',
    year: '2017',
    make: 'Chevrolet',
    model: 'Express',
    odometer: '142,880',
    status: 'Available',
  ),
];

List<VehicleProfilePreview> get savedVehiclePreviews =>
    List.unmodifiable(_savedVehiclePreviews);

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
                const Text(
                  '🚚',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 20, height: 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeVehicle.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 24),
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
      _vehicleRoute(SavedVehiclesScreen(activeVehicle: activeVehicle)),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }
}

VehicleProfilePreview get defaultVehicleProfile => _savedVehiclePreviews.first;

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
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      appBar: AppBar(
        title: const Text('Saved Vehicles'),
        backgroundColor: const Color(0xFF101416),
        foregroundColor: const Color(0xFFE2E8EA),
      ),
      body: VehicleFormBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
            const VehicleSectionPlateTitle('VEHICLE PROFILES'),
            const SizedBox(height: 12),
            const VehicleHelperText(
              'Choose a saved vehicle, then use it for the day, edit its profile, or add another vehicle.',
            ),
            const SizedBox(height: 12),
            for (final vehicle in _savedVehiclePreviews) ...[
              SavedVehicleButton(
                vehicle: vehicle,
                selected: vehicle.nickname == _selectedVehicle.nickname,
                onSelect: () => _selectVehicle(vehicle),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 18),
            _VehicleSelectorActions(
              onUseVehicle: _confirmSelectedVehicle,
              onEditVehicle: () =>
                  _openVehicleProfile(context, _selectedVehicle),
              onAddVehicle: () => Navigator.of(
                context,
              ).push(_vehicleRoute(const AddVehicleProfileScreen())),
            ),
          ],
        ),
      ),
    );
  }

  void _selectVehicle(VehicleProfilePreview vehicle) {
    setState(() => _selectedVehicle = vehicle);
  }

  void _confirmSelectedVehicle() {
    Navigator.of(context).pop(_selectedVehicle);
  }

  void _openVehicleProfile(
    BuildContext context,
    VehicleProfilePreview vehicle,
  ) {
    Navigator.of(
      context,
    ).push(_vehicleRoute(VehicleProfileDetailScreen(vehicle: vehicle)));
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
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: const Color(0xFF101416),
        foregroundColor: const Color(0xFFE2E8EA),
      ),
      body: VehicleFormBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
          children: [
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
              onSubmitted: (_) => _savePreviewVehicle(),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: _savePreviewVehicle,
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

  void _savePreviewVehicle() {
    final nickname = _nicknameController.text.trim();
    Navigator.of(context).pop(
      VehicleProfilePreview(
        nickname: nickname.isEmpty ? 'New Vehicle' : nickname,
        year: _yearController.text.trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        odometer: '0',
        status: 'Available',
      ),
    );
  }
}

Route<T> _vehicleRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
