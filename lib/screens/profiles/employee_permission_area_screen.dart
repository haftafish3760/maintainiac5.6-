import 'package:flutter/material.dart';

import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_permission_models.dart';
import 'employee_permission_target_picker.dart';
import 'employee_profile_widgets.dart';

class EmployeePermissionAreaScreen extends StatelessWidget {
  const EmployeePermissionAreaScreen({
    super.key,
    required this.area,
    required this.employeeName,
    required this.records,
    required this.enabled,
    required this.roles,
    required this.employeeTargets,
    required this.onChanged,
  });

  final EmployeePermissionArea area;
  final String employeeName;
  final List<EmployeeDirectoryRecord> records;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employeeTargets;
  final VoidCallback onChanged;

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
                    area.title,
                    style: const TextStyle(
                      color: Color(0xFFF5F8F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  area.summary,
                  style: const TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose what this employee can do here. If other employee access is allowed, select the roles or specific employees it applies to.',
                  style: TextStyle(
                    color: Color(0xFF9EADB3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _AreaProgressLine(area: area, enabled: enabled),
          ),
          for (final item in area.items)
            _PermissionItemBlock(
              area: area,
              item: item,
              employeeName: employeeName,
              records: records,
              enabled: enabled,
              roles: roles,
              employeeTargets: employeeTargets,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _AreaProgressLine extends StatelessWidget {
  const _AreaProgressLine({required this.area, required this.enabled});

  final EmployeePermissionArea area;
  final Set<String> enabled;

  @override
  Widget build(BuildContext context) {
    final granted = _enabledCount();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF344247)),
      ),
      child: Text(
        granted == 0
            ? 'Nothing in ${area.title} is granted yet.'
            : '$granted permissions are currently granted in ${area.title}.',
        style: const TextStyle(
          color: Color(0xFFEAF0F2),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  int _enabledCount() {
    var count = 0;
    for (final item in area.items) {
      for (final verb in item.verbs) {
        if (enabled.contains(permissionKey(area, item, verb, 'own'))) {
          count++;
        }
        if (enabled.contains(permissionKey(area, item, verb, 'other'))) {
          count++;
        }
      }
    }
    return count;
  }
}

class _PermissionItemBlock extends StatelessWidget {
  const _PermissionItemBlock({
    required this.area,
    required this.item,
    required this.employeeName,
    required this.records,
    required this.enabled,
    required this.roles,
    required this.employeeTargets,
    required this.onChanged,
  });

  final EmployeePermissionArea area;
  final EmployeePermissionItem item;
  final String employeeName;
  final List<EmployeeDirectoryRecord> records;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employeeTargets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: item.highImpact
              ? const Color(0xFF9B6432)
              : const Color(0xFF46545A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFFF2F5F6),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            style: const TextStyle(
              color: Color(0xFF9EADB3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final verb in item.verbs)
            _PermissionAction(
              area: area,
              item: item,
              verb: verb,
              employeeName: employeeName,
              records: records,
              enabled: enabled,
              roles: roles,
              employeeTargets: employeeTargets,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _PermissionAction extends StatelessWidget {
  const _PermissionAction({
    required this.area,
    required this.item,
    required this.verb,
    required this.employeeName,
    required this.records,
    required this.enabled,
    required this.roles,
    required this.employeeTargets,
    required this.onChanged,
  });

  final EmployeePermissionArea area;
  final EmployeePermissionItem item;
  final PermissionVerb verb;
  final String employeeName;
  final List<EmployeeDirectoryRecord> records;
  final Set<String> enabled;
  final Map<String, Set<String>> roles;
  final Map<String, Set<String>> employeeTargets;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ownKey = permissionKey(area, item, verb, 'own');
    final otherKey = permissionKey(area, item, verb, 'other');
    final own = enabled.contains(ownKey);
    final other = enabled.contains(otherKey);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PermissionDecision(
            value: own,
            label: permissionSentence(employeeName, item, verb),
            onChanged: (value) {
              _setEnabled(ownKey, value);
              if (!value) {
                _setEnabled(otherKey, false);
              }
              onChanged();
            },
          ),
          if (own)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PermissionDecision(
                    value: other,
                    label: otherEmployeeSentence(item, verb),
                    onChanged: (value) {
                      _setEnabled(otherKey, value);
                      onChanged();
                    },
                  ),
                  if (other)
                    PermissionTargetPicker(
                      permissionId: otherKey,
                      employees: records,
                      roles: roles,
                      employeeTargets: employeeTargets,
                      onChanged: onChanged,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _setEnabled(String key, bool value) {
    if (value) {
      enabled.add(key);
    } else {
      enabled.remove(key);
      roles.remove(key);
      employeeTargets.remove(key);
    }
  }
}
