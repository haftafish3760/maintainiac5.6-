part of 'employee_add_screen.dart';

extension _EmployeeAddScreenStateHelpers on _EmployeeAddScreenState {
  Widget _roleDropdown() {
    final roles = UserRole.values.where((r) => r != UserRole.owner).toList();
    return DropdownButtonFormField<UserRole>(
      key: const ValueKey('role-template-dropdown'),
      initialValue: _role,
      isExpanded: true,
      dropdownColor: const Color(0xFF11181B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Job title / role'),
      items: [
        for (final role in roles)
          DropdownMenuItem(
            key: ValueKey('role-template-${role.label}'),
            value: role,
            child: Text(role.label),
          ),
      ],
      onChanged: (next) {
        final selected = next ?? _role;
        _update(() {
          _role = selected;
          _crewTitle.text = selected.label;
          _customizedPermissions = false;
          _structuredPermissions = structuredPermissionsForRoleName(
            selected.name,
          );
          _allowedRolesByPermission.clear();
          _allowedEmployeesByPermission.clear();
        });
      },
    );
  }

  Widget _permissionSetupButton() {
    final status = _customizedPermissions
        ? 'Custom permissions selected'
        : '${_role.label} starting permissions selected';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344247)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFFEAF0F2),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_structuredPermissions.length} permission actions are currently selected.',
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            key: const ValueKey('set-up-permissions-button'),
            onPressed: _openPermissionEditor,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Set Up Permissions'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: const Color(0xFF1976B9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
    Map<String, String> labels = const {},
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF11181B),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(''),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(labels[item] ?? item)),
      ],
      onChanged: (next) => onChanged(next ?? value),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFFEAF0F2),
            fontWeight: FontWeight.w800,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFEAF0F2),
            fontWeight: FontWeight.w900,
          ),
          filled: true,
          fillColor: const Color(0xFF1A2226),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      labelStyle: const TextStyle(
        color: Color(0xFFEAF0F2),
        fontWeight: FontWeight.w800,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFFEAF0F2),
        fontWeight: FontWeight.w900,
      ),
      filled: true,
      fillColor: const Color(0xFF1A2226),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  String _formatPhone(String digits) {
    if (digits.length != 10) {
      return digits;
    }
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  void _openPermissionEditor() {
    final draft = EmployeeDirectoryRecord.create(
      ownerProfileId:
          UserProfileScope.maybeOf(context)?.activeProfile.id ?? 'local-owner',
      name: _name.text.trim().isEmpty ? 'New Employee' : _name.text.trim(),
      phone: _formatPhone(_phone.text),
      email: _email.text,
      roleLabel: _crewTitle.text.trim().isEmpty
          ? _role.label
          : _crewTitle.text.trim(),
      roleName: _role.name,
      customizedRole: _customizedPermissions,
      permissions: permissionsForRole(_role),
      structuredPermissions: _structuredPermissions,
      allowedEmployeeRoleNamesByPermission: _allowedRolesByPermission,
      allowedEmployeeIdsByPermission: _allowedEmployeesByPermission,
      payType: _payType,
      payFrequency: _payFrequency,
      grossRate: _rate.text,
      payPeriodStartDay: _payPeriodStartDay,
      payPeriodAnchorDate:
          _payPeriodAnchorDate ?? _alignedPayPeriodAnchor(DateTime.now()),
      assignedVehicleLabel: _vehicle,
    );
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        EmployeeAddPermissionSetupScreen(
          initialRecord: draft,
          records: widget.records,
          onApply: (updated) {
            _update(() {
              _structuredPermissions = {...updated.structuredPermissions};
              _allowedRolesByPermission
                ..clear()
                ..addAll(updated.allowedEmployeeRoleNamesByPermission);
              _allowedEmployeesByPermission
                ..clear()
                ..addAll(updated.allowedEmployeeIdsByPermission);
              _customizedPermissions = true;
            });
          },
        ),
      ),
    );
  }

  String _payPeriodRangeLabel(String startDay) {
    return const {
          'monday': 'Monday-Sunday',
          'tuesday': 'Tuesday-Monday',
          'wednesday': 'Wednesday-Tuesday',
          'thursday': 'Thursday-Wednesday',
          'friday': 'Friday-Thursday',
          'saturday': 'Saturday-Friday',
          'sunday': 'Sunday-Saturday',
        }[startDay] ??
        'Monday-Sunday';
  }
}

class _SetupNote extends StatelessWidget {
  const _SetupNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Pick a role so Maintainiac can start close, then review the actual app permissions before this employee is saved.',
      style: TextStyle(
        color: Color(0xFFCAD2D5),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );
  }
}
