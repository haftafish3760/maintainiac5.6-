import 'package:flutter/material.dart';

import '../../shared/profiles/user_profile_models.dart';
import 'employee_permission_catalog.dart';
import 'employee_permission_models.dart';
import 'employee_profile_widgets.dart';

class EmployeeAccessSetupPreview extends StatelessWidget {
  const EmployeeAccessSetupPreview({
    super.key,
    required this.role,
    required this.permissions,
    required this.customized,
    required this.onCustomize,
    required this.onSavePack,
    required this.onReview,
  });

  final UserRole role;
  final Set<String> permissions;
  final bool customized;
  final VoidCallback onCustomize;
  final VoidCallback onSavePack;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final areaSummaries = [
      for (final area in employeePermissionCatalog)
        if (_countForArea(area, permissions) > 0)
          '${area.title}: ${_countForArea(area, permissions)} actions',
    ];
    final summary = areaSummaries.isEmpty
        ? 'No app access is granted yet.'
        : areaSummaries.take(5).join(' / ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2226),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF344247)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            customized
                ? 'Custom permission setup for ${role.label}.'
                : '${role.label} role starting point is selected.',
            style: const TextStyle(
              color: Color(0xFFEAF0F2),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9EADB3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This employee currently has ${permissions.length} permission actions. Review view, create, edit, share, export, and manage access before saving.',
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CompactActionButton(
                label: 'Set Up Permissions',
                icon: Icons.tune_rounded,
                onPressed: onCustomize,
              ),
              CompactActionButton(
                label: 'Review Setup',
                icon: Icons.info_outline_rounded,
                onPressed: onReview,
              ),
              CompactActionButton(
                label: 'Save Setup',
                icon: Icons.bookmark_add_rounded,
                onPressed: onSavePack,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countForArea(EmployeePermissionArea area, Set<String> enabled) {
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

class PermissionPackDefinitionSheet extends StatelessWidget {
  const PermissionPackDefinitionSheet({
    super.key,
    required this.title,
    required this.permissions,
  });

  final String title;
  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(14),
        shrinkWrap: true,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF5F8F9),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final area in employeePermissionCatalog)
            if (_countForArea(area) > 0)
              ProfileFieldLine(
                label: area.title,
                value: '${_countForArea(area)} enabled actions',
              ),
        ],
      ),
    );
  }

  int _countForArea(EmployeePermissionArea area) {
    var count = 0;
    for (final item in area.items) {
      for (final verb in item.verbs) {
        if (permissions.contains(permissionKey(area, item, verb, 'own'))) {
          count++;
        }
        if (permissions.contains(permissionKey(area, item, verb, 'other'))) {
          count++;
        }
      }
    }
    return count;
  }
}
