import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_permission_area_screen.dart';
import 'employee_permission_catalog.dart';
import 'employee_permission_models.dart';
import 'employee_profile_widgets.dart';

class EmployeePermissionEditorScreen extends StatefulWidget {
  const EmployeePermissionEditorScreen({
    super.key,
    required this.record,
    required this.records,
    required this.onSave,
  });

  final EmployeeDirectoryRecord record;
  final List<EmployeeDirectoryRecord> records;
  final ValueChanged<EmployeeDirectoryRecord> onSave;

  @override
  State<EmployeePermissionEditorScreen> createState() =>
      _EmployeePermissionEditorScreenState();
}

class _EmployeePermissionEditorScreenState
    extends State<EmployeePermissionEditorScreen> {
  late final Set<String> _enabled = {...widget.record.structuredPermissions};
  late final Map<String, Set<String>> _roles = {
    for (final entry
        in widget.record.allowedEmployeeRoleNamesByPermission.entries)
      entry.key: {...entry.value},
  };
  late final Map<String, Set<String>> _employees = {
    for (final entry in widget.record.allowedEmployeeIdsByPermission.entries)
      entry.key: {...entry.value},
  };
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final areas = employeePermissionCatalog.where((area) {
      final text =
          '${area.title} ${area.summary} ${area.items.map((e) => e.title).join(' ')}'
              .toLowerCase();
      return text.contains(_query.toLowerCase().trim());
    }).toList();

    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 680,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
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
                    'Edit ${widget.record.name} Access',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF5F8F9),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                CompactActionButton(
                  label: 'Save',
                  icon: Icons.save_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search app areas',
                hintStyle: const TextStyle(color: Color(0xFF9EADB3)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9EADB3),
                ),
                filled: true,
                fillColor: const Color(0xFF11181B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
              itemCount: areas.length,
              itemBuilder: (context, index) => _AreaRow(
                area: areas[index],
                enabled: _enabled,
                onTap: () => _openArea(context, areas[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openArea(BuildContext context, EmployeePermissionArea area) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        EmployeePermissionAreaScreen(
          area: area,
          employeeName: widget.record.name,
          records: widget.records,
          enabled: _enabled,
          roles: _roles,
          employeeTargets: _employees,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(
      widget.record.copyWith(
        structuredPermissions: _enabled,
        allowedEmployeeRoleNamesByPermission: _roles,
        allowedEmployeeIdsByPermission: _employees,
        customizedRole: true,
        updatedAt: DateTime.now(),
      ),
    );
    Navigator.of(context).maybePop();
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({
    required this.area,
    required this.enabled,
    required this.onTap,
  });

  final EmployeePermissionArea area;
  final Set<String> enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = _enabledCount();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF46545A)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          area.title,
          style: const TextStyle(
            color: Color(0xFFF2F5F6),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          count == 0
              ? '${area.summary}  No permissions granted'
              : '${area.summary}  $count permissions granted',
          style: const TextStyle(
            color: Color(0xFF9EADB3),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
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
