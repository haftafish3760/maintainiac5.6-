import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_add_permission_group_advanced_screen.dart';
import 'employee_add_permission_setup_models.dart';
import 'employee_profile_widgets.dart';

class EmployeeAddPermissionSetupScreen extends StatefulWidget {
  const EmployeeAddPermissionSetupScreen({
    super.key,
    required this.initialRecord,
    required this.records,
    required this.onApply,
  });

  final EmployeeDirectoryRecord initialRecord;
  final List<EmployeeDirectoryRecord> records;
  final ValueChanged<EmployeeDirectoryRecord> onApply;

  @override
  State<EmployeeAddPermissionSetupScreen> createState() =>
      _EmployeeAddPermissionSetupScreenState();
}

class _EmployeeAddPermissionSetupScreenState
    extends State<EmployeeAddPermissionSetupScreen> {
  late final Set<String> _enabled = {
    ...widget.initialRecord.structuredPermissions,
  };
  late final Map<String, Set<String>> _roles = {
    for (final entry
        in widget.initialRecord.allowedEmployeeRoleNamesByPermission.entries)
      entry.key: {...entry.value},
  };
  late final Map<String, Set<String>> _employees = {
    for (final entry
        in widget.initialRecord.allowedEmployeeIdsByPermission.entries)
      entry.key: {...entry.value},
  };

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 680,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Set Up Permissions',
                    style: const TextStyle(
                      color: Color(0xFFF5F8F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                CompactActionButton(
                  label: 'Apply',
                  icon: Icons.check_rounded,
                  onPressed: _applyAndClose,
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Small Crew Setup',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.initialRecord.roleLabel} access for ${widget.initialRecord.name}.',
                  style: const TextStyle(
                    color: Color(0xFFEAF0F2),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quick setup uses View, Create, and Edit. Each category has separate rows for this employee\'s own or assigned records and for other employees or team records.',
                  style: TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                _PresetStrip(
                  onHelper: () => _applyPreset(AddCrewPreset.helper),
                  onTech: () => _applyPreset(AddCrewPreset.technician),
                  onDriver: () => _applyPreset(AddCrewPreset.driver),
                  onOffice: () => _applyPreset(AddCrewPreset.office),
                ),
              ],
            ),
          ),
          for (final group in addPermissionGroups)
            _CrewPermissionGroupCard(
              group: group,
              ownActions: _actionsFor(group, 'own'),
              otherActions: _actionsFor(group, 'other'),
              onChanged: (scope, action, enabled) =>
                  setState(() => _setAction(group, scope, action, enabled)),
              onAdvanced: () => _openGroupAdvanced(group),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton.icon(
              onPressed: _applyAndClose,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply Permissions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1BAE70),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<AddPermissionAction> _actionsFor(
    AddCrewPermissionGroup group,
    String scope,
  ) {
    return {
      for (final action in AddPermissionAction.values)
        if (group.rules.any((rule) => rule.hasAction(_enabled, scope, action)))
          action,
    };
  }

  void _setAction(
    AddCrewPermissionGroup group,
    String scope,
    AddPermissionAction action,
    bool enabled,
  ) {
    if (enabled) {
      for (final rule in group.rules) {
        rule.addAction(_enabled, scope, AddPermissionAction.view);
        rule.addAction(_enabled, scope, action);
      }
      return;
    }
    for (final rule in group.rules) {
      if (action == AddPermissionAction.view) {
        rule.removeScope(_enabled, scope, _roles, _employees);
      } else {
        rule.removeAction(_enabled, scope, action);
      }
    }
  }

  void _setPresetActions(
    AddCrewPermissionGroup group,
    String scope,
    Set<AddPermissionAction> actions,
  ) {
    for (final rule in group.rules) {
      rule.removeScope(_enabled, scope, _roles, _employees);
    }
    for (final action in actions) {
      _setAction(group, scope, action, true);
    }
  }

  void _applyPreset(AddCrewPreset preset) {
    setState(() {
      _enabled.clear();
      _roles.clear();
      _employees.clear();
      for (final group in addPermissionGroups) {
        final presetSetup = switch (preset) {
          AddCrewPreset.helper => group.helper,
          AddCrewPreset.technician => group.technician,
          AddCrewPreset.driver => group.driver,
          AddCrewPreset.office => group.office,
        };
        _setPresetActions(group, 'own', presetSetup.own);
        _setPresetActions(group, 'other', presetSetup.other);
      }
    });
  }

  void _openGroupAdvanced(AddCrewPermissionGroup group) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        EmployeeAddPermissionGroupAdvancedScreen(
          group: group,
          enabled: _enabled,
          roles: _roles,
          employees: _employees,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  void _applyAndClose() {
    widget.onApply(_recordWithCurrentPermissions());
    Navigator.of(context).maybePop();
  }

  EmployeeDirectoryRecord _recordWithCurrentPermissions() {
    return widget.initialRecord.copyWith(
      structuredPermissions: _enabled,
      allowedEmployeeRoleNamesByPermission: _roles,
      allowedEmployeeIdsByPermission: _employees,
      customizedRole: true,
      updatedAt: DateTime.now(),
    );
  }
}

class _PresetStrip extends StatelessWidget {
  const _PresetStrip({
    required this.onHelper,
    required this.onTech,
    required this.onDriver,
    required this.onOffice,
  });

  final VoidCallback onHelper;
  final VoidCallback onTech;
  final VoidCallback onDriver;
  final VoidCallback onOffice;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PresetButton(label: 'Helper', onTap: onHelper),
        _PresetButton(label: 'Technician', onTap: onTech),
        _PresetButton(label: 'Driver', onTap: onDriver),
        _PresetButton(label: 'Office', onTap: onOffice),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF65757C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _CrewPermissionGroupCard extends StatelessWidget {
  const _CrewPermissionGroupCard({
    required this.group,
    required this.ownActions,
    required this.otherActions,
    required this.onChanged,
    required this.onAdvanced,
  });

  final AddCrewPermissionGroup group;
  final Set<AddPermissionAction> ownActions;
  final Set<AddPermissionAction> otherActions;
  final void Function(String scope, AddPermissionAction action, bool enabled)
  onChanged;
  final VoidCallback onAdvanced;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: group.title,
      trailing: TextButton(
        onPressed: onAdvanced,
        child: const Text(
          'Advanced',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.detail,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ScopeActionRow(
            label: 'Their own / assigned records',
            actions: ownActions,
            onChanged: (action, enabled) => onChanged('own', action, enabled),
          ),
          const SizedBox(height: 8),
          _ScopeActionRow(
            label: 'Other employees / team records',
            actions: otherActions,
            onChanged: (action, enabled) => onChanged('other', action, enabled),
          ),
        ],
      ),
    );
  }
}

class _ScopeActionRow extends StatelessWidget {
  const _ScopeActionRow({
    required this.label,
    required this.actions,
    required this.onChanged,
  });

  final String label;
  final Set<AddPermissionAction> actions;
  final void Function(AddPermissionAction action, bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEAF0F2),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final action in AddPermissionAction.values) ...[
              Expanded(
                child: _ActionButton(
                  action: action,
                  selected: actions.contains(action),
                  onTap: () => onChanged(action, !actions.contains(action)),
                ),
              ),
              if (action != AddPermissionAction.values.last)
                const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final AddPermissionAction action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
        size: 18,
      ),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        backgroundColor: selected
            ? const Color(0xFFE9F0F2)
            : const Color(0xFF11181B),
        side: BorderSide(
          color: selected ? const Color(0xFFE9F0F2) : const Color(0xFF65757C),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
