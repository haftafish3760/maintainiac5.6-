import 'package:flutter/material.dart';

import '../../shared/profiles/employee_directory_models.dart';
import 'employee_permission_models.dart';
import 'employee_profile_widgets.dart';

class PermissionTargetPicker extends StatefulWidget {
  const PermissionTargetPicker({
    super.key,
    required this.permissionId,
    required this.employees,
    required this.roles,
    required this.employeeTargets,
    required this.onChanged,
  });

  final String permissionId;
  final List<EmployeeDirectoryRecord> employees;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employeeTargets;
  final VoidCallback onChanged;

  @override
  State<PermissionTargetPicker> createState() => _PermissionTargetPickerState();
}

class _PermissionTargetPickerState extends State<PermissionTargetPicker> {
  String _employeeQuery = '';

  @override
  Widget build(BuildContext context) {
    final selectedRoles = widget.roles.putIfAbsent(
      widget.permissionId,
      () => {},
    );
    final selectedEmployees = widget.employeeTargets.putIfAbsent(
      widget.permissionId,
      () => {},
    );
    final employees = [...widget.employees]
      ..sort((a, b) => a.name.compareTo(b.name));
    final filteredEmployees = employees.where((employee) {
      return employee.name.toLowerCase().contains(_employeeQuery.toLowerCase());
    }).toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF344247)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose roles or specific employees.',
            style: TextStyle(
              color: Color(0xFFEAF0F2),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final roleName in employeePermissionRoleNames)
                RoleChip(
                  label: employeeRoleLabel(roleName),
                  selected: selectedRoles.contains(roleName),
                  onTap: () {
                    selectedRoles.contains(roleName)
                        ? selectedRoles.remove(roleName)
                        : selectedRoles.add(roleName);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
            ],
          ),
          if (employees.length > 10) ...[
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => setState(() => _employeeQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search employees',
                hintStyle: TextStyle(color: Color(0xFF9EADB3)),
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Specific employees:',
            style: TextStyle(
              color: Color(0xFF9EADB3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final employee in filteredEmployees)
                RoleChip(
                  label: '${employee.name} / ${employee.roleLabel}',
                  selected: selectedEmployees.contains(employee.id),
                  onTap: () {
                    selectedEmployees.contains(employee.id)
                        ? selectedEmployees.remove(employee.id)
                        : selectedEmployees.add(employee.id);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
