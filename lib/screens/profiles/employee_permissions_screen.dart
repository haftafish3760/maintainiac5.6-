import 'dart:async';

import 'package:flutter/material.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/profiles/employee_directory_store.dart';
import '../../shared/profiles/employee_preview_data.dart';
import '../../shared/profiles/user_profile_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_add_screen.dart';
import 'employee_permission_defaults.dart';
import 'employee_permission_definitions_screen.dart';
import 'employee_profile_detail_screen.dart';
import 'employee_profile_widgets.dart';

class EmployeePermissionsScreen extends StatefulWidget {
  const EmployeePermissionsScreen({super.key, this.directoryController});

  final EmployeeDirectoryController? directoryController;

  @override
  State<EmployeePermissionsScreen> createState() =>
      _EmployeePermissionsScreenState();
}

class _EmployeePermissionsScreenState extends State<EmployeePermissionsScreen> {
  EmployeeDirectoryController? _ownedController;
  EmployeeDirectoryController? _controller;
  var _showActive = true;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.directoryController;
    _controller?.addListener(_onDirectoryChanged);
    if (_controller == null) {
      unawaited(_loadDirectory());
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onDirectoryChanged);
    _ownedController?.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    final controller = await EmployeeDirectoryController.createOrMemory();
    if (!mounted) return;
    controller.addListener(_onDirectoryChanged);
    setState(() {
      _ownedController = controller;
      _controller = controller;
    });
  }

  void _onDirectoryChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final records = _recordsFor(controller);
    final visible = records.where((record) {
      final activeMatches = _showActive ? record.isActive : !record.isActive;
      final text = '${record.name} ${record.roleLabel} ${record.email}'
          .toLowerCase();
      return activeMatches && text.contains(_query.toLowerCase().trim());
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 640,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: CompactActionButton(
                    label: 'Add New Employee',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: controller == null
                        ? () {}
                        : () => _openAddEmployee(context, controller, records),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('employee-permission-definitions-button'),
                  tooltip: 'Permission definitions',
                  onPressed: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      const EmployeePermissionDefinitionsScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Active',
                    selected: _showActive,
                    onTap: () => setState(() => _showActive = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentButton(
                    label: 'Inactive',
                    selected: !_showActive,
                    onTap: () => setState(() => _showActive = false),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search employees',
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
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 18),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final record = visible[index];
                return _EmployeeRow(
                  record: record,
                  onTap: () =>
                      _openProfile(context, controller, record, records),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openProfile(
    BuildContext context,
    EmployeeDirectoryController? controller,
    EmployeeDirectoryRecord record,
    List<EmployeeDirectoryRecord> records,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        EmployeeProfileDetailScreen(
          record: record,
          records: records,
          onSave: (next) {
            unawaited(controller?.saveRecord(next));
          },
          onQueueInvite: () {
            unawaited(controller?.queueInvite(record.id));
            Navigator.of(context).maybePop();
          },
        ),
      ),
    );
  }

  void _openAddEmployee(
    BuildContext context,
    EmployeeDirectoryController controller,
    List<EmployeeDirectoryRecord> records,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        EmployeeAddScreen(
          records: records,
          onSave: (record) {
            unawaited(controller.saveRecord(record));
          },
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.record, required this.onTap});

  final EmployeeDirectoryRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF46545A)),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        title: Text(
          record.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF2F5F6),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${record.roleLabel} / ${record.status.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF9EADB3),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF101416) : Colors.white,
        backgroundColor: selected
            ? const Color(0xFFE9F0F2)
            : const Color(0xFF11181B),
        side: const BorderSide(color: Color(0xFF65757C)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

List<EmployeeDirectoryRecord> _recordsFor(
  EmployeeDirectoryController? controller,
) {
  final records = controller?.records ?? const [];
  if (records.isNotEmpty) return combinedEmployeePreviewRecords(records);
  final now = DateTime(2026, 6, 21, 8);
  return [
    _seed(
      'alex',
      'Alex Supervisor',
      '(555) 010-1001',
      'alex@example.com',
      UserRole.fieldManager,
      'Work Truck 1',
      '34.00',
      now,
    ),
    _seed(
      'drew',
      'Drew Office',
      '(555) 010-1002',
      'drew@example.com',
      UserRole.officeManager,
      'Office',
      '28.50',
      now,
    ),
    _seed(
      'casey',
      'Casey Technician',
      '(555) 010-1003',
      'casey@example.com',
      UserRole.technician,
      'Service Van 2',
      '31.00',
      now,
    ),
    _seed(
      'morgan',
      'Morgan Helper',
      '(555) 010-1004',
      'morgan@example.com',
      UserRole.helper,
      'Work Truck 1',
      '21.00',
      now,
    ),
    _seed(
      'riley',
      'Riley Driver',
      '(555) 010-1005',
      'riley@example.com',
      UserRole.driver,
      'Delivery Van 4',
      '24.00',
      now,
    ),
  ];
}

EmployeeDirectoryRecord _seed(
  String id,
  String name,
  String phone,
  String email,
  UserRole role,
  String vehicle,
  String rate,
  DateTime now,
) {
  return EmployeeDirectoryRecord(
    id: id,
    ownerProfileId: 'local-owner',
    name: name,
    phone: phone,
    email: email,
    roleLabel: role.label,
    roleName: role.name,
    customizedRole: false,
    permissions: permissionsForRole(role),
    structuredPermissions: structuredPermissionsForRoleName(role.name),
    allowedEmployeeRoleNames: const {},
    allowedEmployeeRoleNamesByPermission: const {},
    allowedEmployeeIdsByPermission: const {},
    allowedModules: allowedModulesForPermissions(permissionsForRole(role)),
    allowedExpenseCategories: const {},
    payType: 'hourly',
    payFrequency: 'weekly',
    grossRate: rate,
    payPeriodStartDay: 'monday',
    overtimePolicy: 'timeAndHalf',
    overtimeRate: '',
    assignedVehicleLabel: vehicle,
    status: EmployeeInviteStatus.readyToInvite,
    createdAt: now,
    updatedAt: now,
  );
}
