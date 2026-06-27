import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_permission_catalog.dart';
import 'employee_permission_editor_screen.dart';
import 'employee_permission_models.dart';
import 'employee_profile_widgets.dart';

class EmployeePermissionReviewScreen extends StatelessWidget {
  const EmployeePermissionReviewScreen({
    super.key,
    required this.record,
    required this.records,
    required this.onSave,
  });

  final EmployeeDirectoryRecord record;
  final List<EmployeeDirectoryRecord> records;
  final ValueChanged<EmployeeDirectoryRecord> onSave;

  @override
  Widget build(BuildContext context) {
    final enabledAreas = employeePermissionCatalog
        .where(_areaHasAccess)
        .toList();
    final otherCount = record.structuredPermissions
        .where((permission) => permission.contains('.other.'))
        .length;
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 640,
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
                    '${record.name} Access',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF5F8F9),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                CompactActionButton(
                  label: 'Edit Permissions',
                  icon: Icons.tune_rounded,
                  onPressed: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      EmployeePermissionEditorScreen(
                        record: record,
                        records: records,
                        onSave: onSave,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Access Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileFieldLine(label: 'Role', value: record.roleLabel),
                ProfileFieldLine(
                  label: 'Setup',
                  value: record.customizedRole
                      ? 'Custom permission setup'
                      : 'Role starting point',
                ),
                ProfileFieldLine(
                  label: 'Allowed areas',
                  value: enabledAreas.isEmpty
                      ? 'No app areas are allowed yet'
                      : enabledAreas.map((area) => area.title).join(', '),
                ),
                ProfileFieldLine(
                  label: 'Other employees',
                  value: otherCount == 0
                      ? 'No other employee access'
                      : 'Can work with other employee information in $otherCount permission choices',
                ),
                const SizedBox(height: 8),
                const Text(
                  'This page shows what this employee can currently do in the app. Use Edit Permissions to change access.',
                  style: TextStyle(
                    color: Color(0xFFCAD2D5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Granted Permissions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (enabledAreas.isEmpty)
                  const Text(
                    'No permissions are granted yet.',
                    style: TextStyle(
                      color: Color(0xFFEAF0F2),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  for (final area in enabledAreas)
                    _AreaGrantBlock(area: area, grants: _grantsForArea(area)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _areaHasAccess(EmployeePermissionArea area) {
    return area.items.any(
      (item) => item.verbs.any(
        (verb) =>
            record.structuredPermissions.contains(
              permissionKey(area, item, verb, 'own'),
            ) ||
            record.structuredPermissions.contains(
              permissionKey(area, item, verb, 'other'),
            ),
      ),
    );
  }

  List<_GrantLine> _grantsForArea(EmployeePermissionArea area) {
    final grants = <_GrantLine>[];
    for (final item in area.items) {
      for (final verb in item.verbs) {
        if (record.structuredPermissions.contains(
          permissionKey(area, item, verb, 'own'),
        )) {
          grants.add(
            _GrantLine(
              label: '${verb.label} ${item.title}',
              detail:
                  'This employee can ${verb.label.toLowerCase()} their own ${item.title.toLowerCase()}.',
            ),
          );
        }
        if (record.structuredPermissions.contains(
          permissionKey(area, item, verb, 'other'),
        )) {
          grants.add(
            _GrantLine(
              label: '${verb.label} other employees\' ${item.title}',
              detail: _otherAccessDetail(
                permissionKey(area, item, verb, 'other'),
              ),
            ),
          );
        }
      }
    }
    return grants;
  }

  String _otherAccessDetail(String permissionId) {
    final roleNames =
        record.allowedEmployeeRoleNamesByPermission[permissionId] ?? const {};
    final employeeIds =
        record.allowedEmployeeIdsByPermission[permissionId] ?? const {};
    if (roleNames.isEmpty && employeeIds.isEmpty) {
      return 'Other employee access is on, but no role or employee target is selected yet.';
    }
    final parts = <String>[];
    if (roleNames.isNotEmpty) {
      parts.add('roles: ${roleNames.map(employeeRoleLabel).join(', ')}');
    }
    if (employeeIds.isNotEmpty) {
      parts.add('${employeeIds.length} specific employees');
    }
    return 'Applies to ${parts.join(' and ')}.';
  }
}

class _AreaGrantBlock extends StatelessWidget {
  const _AreaGrantBlock({required this.area, required this.grants});

  final EmployeePermissionArea area;
  final List<_GrantLine> grants;

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            area.title,
            style: const TextStyle(
              color: Color(0xFFF2F5F6),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          for (final grant in grants)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF73F0A2),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          grant.label,
                          style: const TextStyle(
                            color: Color(0xFFEAF0F2),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          grant.detail,
                          style: const TextStyle(
                            color: Color(0xFF9EADB3),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GrantLine {
  const _GrantLine({required this.label, required this.detail});

  final String label;
  final String detail;
}
