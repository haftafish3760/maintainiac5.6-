import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/user_profile_models.dart';
import '../../shared/profiles/user_profile_store.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_add_permission_setup_screen.dart';
import 'employee_permission_defaults.dart';
import 'employee_profile_widgets.dart';

part 'employee_add_screen_helpers.dart';

class EmployeeAddScreen extends StatefulWidget {
  const EmployeeAddScreen({
    super.key,
    required this.onSave,
    this.records = const [],
  });

  final ValueChanged<EmployeeDirectoryRecord> onSave;
  final List<EmployeeDirectoryRecord> records;

  @override
  State<EmployeeAddScreen> createState() => _EmployeeAddScreenState();
}

class _EmployeeAddScreenState extends State<EmployeeAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _rate = TextEditingController();
  var _role = UserRole.helper;
  var _vehicle = 'Work Truck 1';
  var _payType = 'hourly';
  var _payFrequency = 'weekly';
  var _payPeriodStartDay = 'monday';
  var _customizedPermissions = false;
  late Set<String> _structuredPermissions;
  final Map<String, Set<String>> _allowedRolesByPermission = {};
  final Map<String, Set<String>> _allowedEmployeesByPermission = {};

  @override
  void initState() {
    super.initState();
    _structuredPermissions = structuredPermissionsForRoleName(_role.name);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _update(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 640,
      body: Form(
        key: _formKey,
        child: ListView(
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
                  const Expanded(
                    child: Text(
                      'Add Employee',
                      style: TextStyle(
                        color: Color(0xFFF5F8F9),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ProfileSection(
              title: 'Employee Information',
              child: Column(
                children: [
                  _field(_name, 'Name', required: true),
                  _field(
                    _phone,
                    'Phone',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  _field(
                    _email,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            ProfileSection(
              title: 'Role and Permissions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SetupNote(),
                  const SizedBox(height: 8),
                  _roleDropdown(),
                  const SizedBox(height: 8),
                  _permissionSetupButton(),
                ],
              ),
            ),
            ProfileSection(
              title: 'Vehicle Assignment',
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 280,
                  child: _dropdown(
                    value: _vehicle,
                    values: const [
                      'Work Truck 1',
                      'Service Van 2',
                      'Delivery Van 4',
                    ],
                    onChanged: (value) => setState(() => _vehicle = value),
                  ),
                ),
              ),
            ),
            ProfileSection(
              title: 'Pay Setup',
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 180,
                    child: _dropdown(
                      value: _payType,
                      values: const ['hourly', 'salary', 'notTracked'],
                      labels: const {
                        'hourly': 'Hourly',
                        'salary': 'Salary',
                        'notTracked': 'Not tracked',
                      },
                      onChanged: (value) => setState(() => _payType = value),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: _dropdown(
                      value: _payFrequency,
                      values: const [
                        'weekly',
                        'biweekly',
                        'semimonthly',
                        'monthly',
                      ],
                      labels: const {
                        'weekly': 'Weekly',
                        'biweekly': 'Every 2 weeks',
                        'semimonthly': 'Twice a month',
                        'monthly': 'Monthly',
                      },
                      onChanged: (value) =>
                          setState(() => _payFrequency = value),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: _dropdown(
                      value: _payPeriodStartDay,
                      values: const [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday',
                        'sunday',
                      ],
                      labels: const {
                        'monday': 'Starts Monday',
                        'tuesday': 'Starts Tuesday',
                        'wednesday': 'Starts Wednesday',
                        'thursday': 'Starts Thursday',
                        'friday': 'Starts Friday',
                        'saturday': 'Starts Saturday',
                        'sunday': 'Starts Sunday',
                      },
                      onChanged: (value) =>
                          setState(() => _payPeriodStartDay = value),
                    ),
                  ),
                  SizedBox(width: 170, child: _field(_rate, 'Gross rate')),
                  SizedBox(
                    width: 250,
                    child: Text(
                      'Pay period: ${_payPeriodRangeLabel(_payPeriodStartDay)}',
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Employee'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final profile = UserProfileScope.maybeOf(context)?.activeProfile;
    final record = EmployeeDirectoryRecord.create(
      ownerProfileId: profile?.id ?? 'local-owner',
      name: _name.text,
      phone: _formatPhone(_phone.text),
      email: _email.text,
      roleLabel: _role.label,
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
      assignedVehicleLabel: _vehicle,
    );
    widget.onSave(record);
    Navigator.of(context).maybePop();
  }
}
