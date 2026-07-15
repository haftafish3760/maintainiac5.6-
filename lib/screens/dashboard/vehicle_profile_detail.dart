import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';
import 'vehicle_profile_widgets.dart';

class VehicleProfileDetailOutcome {
  const VehicleProfileDetailOutcome.updated(this.vehicle) : deleted = false;

  const VehicleProfileDetailOutcome.deleted(this.vehicle) : deleted = true;

  final VehicleProfilePreview vehicle;
  final bool deleted;
}

class VehicleProfileDetailScreen extends StatefulWidget {
  const VehicleProfileDetailScreen({
    super.key,
    required this.vehicle,
    this.canDelete = false,
    this.onDelete,
  });

  final VehicleProfilePreview vehicle;
  final bool canDelete;
  final Future<VehicleProfilePreview> Function()? onDelete;

  @override
  State<VehicleProfileDetailScreen> createState() =>
      _VehicleProfileDetailScreenState();
}

class _VehicleProfileDetailScreenState
    extends State<VehicleProfileDetailScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _yearController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  final _nicknameFocus = FocusNode();
  final _yearFocus = FocusNode();
  final _makeFocus = FocusNode();
  final _modelFocus = FocusNode();
  late final _initialNickname = widget.vehicle.nickname;
  late final _initialYear = widget.vehicle.year;
  late final _initialMake = widget.vehicle.make;
  late final _initialModel = widget.vehicle.model;
  late final _initialUsage = widget.vehicle.usage;
  late var _usage = widget.vehicle.usage;
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.vehicle.nickname);
    _yearController = TextEditingController(text: widget.vehicle.year);
    _makeController = TextEditingController(text: widget.vehicle.make);
    _modelController = TextEditingController(text: widget.vehicle.model);
  }

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
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1F2528),

        body: VehicleFormBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
            children: [
              const VehicleSectionPlateTitle('VEHICLE PROFILE'),
              const SizedBox(height: 18),
              ..._editFields(),
              const SizedBox(height: 16),
              VehicleUsageSelector(
                value: _usage,
                onChanged: (usage) => setState(() => _usage = usage),
              ),
              const SizedBox(height: 16),
              _ProfileFactRow(
                label: 'Odometer',
                value: widget.vehicle.odometer,
              ),
              _ProfileFactRow(label: 'Status', value: widget.vehicle.status),
              const SizedBox(height: 20),
              _ProfileActionRow(
                onSave: _saveChanges,
                onDelete: widget.canDelete && widget.onDelete != null
                    ? _deleteVehicle
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _editFields() {
    return [
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
        onSubmitted: (_) => _saveChanges(),
      ),
    ];
  }

  bool get _hasChanges {
    return _nicknameController.text != _initialNickname ||
        _yearController.text != _initialYear ||
        _makeController.text != _initialMake ||
        _modelController.text != _initialModel ||
        _usage != _initialUsage;
  }

  void _saveChanges() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      VehicleProfileDetailOutcome.updated(
        VehicleProfilePreview(
          id: widget.vehicle.id,
          nickname: _nicknameController.text.trim().isEmpty
              ? widget.vehicle.nickname
              : _nicknameController.text.trim(),
          year: _yearController.text.trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          odometer: widget.vehicle.odometer,
          status: widget.vehicle.status,
          usage: _usage,
        ),
      ),
    );
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text(
          '${widget.vehicle.nickname} will be removed from your saved vehicles. '
          'Existing records keep their vehicle association.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final replacement = await widget.onDelete!();
    if (!mounted) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop(VehicleProfileDetailOutcome.deleted(replacement));
  }

  Future<void> _handleBackNavigation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_hasChanges) {
      _leaveScreen();
      return;
    }

    final choice = await showDialog<_UnsavedVehicleChoice>(
      context: context,
      builder: (context) => const _UnsavedVehicleChangesDialog(),
    );

    if (!mounted || choice == null || choice == _UnsavedVehicleChoice.stay) {
      return;
    }

    if (choice == _UnsavedVehicleChoice.save) {
      _saveChanges();
      return;
    }

    _leaveScreen();
  }

  void _leaveScreen() {
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({required this.onSave, required this.onDelete});

  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 168,
          height: 46,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Save Changes'),
            style: FilledButton.styleFrom(
              backgroundColor: AppActionColors.positive,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(
          width: 150,
          height: 46,
          child: FilledButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: AppActionColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

enum _UnsavedVehicleChoice { stay, discard, save }

class _UnsavedVehicleChangesDialog extends StatelessWidget {
  const _UnsavedVehicleChangesDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2E3A40),
      title: const Text('Save vehicle changes?'),
      content: const Text(
        'You have unsaved vehicle profile changes. Save them before leaving?',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_UnsavedVehicleChoice.stay),
          child: const Text('Keep Editing'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_UnsavedVehicleChoice.discard),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_UnsavedVehicleChoice.save),
          style: FilledButton.styleFrom(
            backgroundColor: AppActionColors.positive,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _ProfileFactRow extends StatelessWidget {
  const _ProfileFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFAAB4B9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2F383D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
