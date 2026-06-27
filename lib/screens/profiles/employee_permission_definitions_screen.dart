import 'package:flutter/material.dart';

import '../../shared/widgets/app_screen_shell.dart';
import 'employee_permission_catalog.dart';
import 'employee_profile_widgets.dart';

class EmployeePermissionDefinitionsScreen extends StatelessWidget {
  const EmployeePermissionDefinitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Expanded(
                  child: Text(
                    'Permission Definitions',
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
          const ProfileSection(
            title: 'Permission Levels',
            child: _DefinitionText(
              'Each app area is controlled by specific actions. View lets an employee see that information, create lets them add new information, and edit lets them change existing information.',
            ),
          ),
          const ProfileSection(
            title: 'Employee Controls',
            child: _DefinitionText(
              'Other employee access is granted per action. A manager can be allowed to view one role, edit another role, or target specific employees instead of a whole role.',
            ),
          ),
          const ProfileSection(
            title: 'Record Actions',
            child: _DefinitionText(
              'Every permission item answers what the employee can view, create, edit, delete, share, export, assign, or manage inside this app.',
            ),
          ),
          const ProfileSection(
            title: 'Custom Roles',
            child: _DefinitionText(
              'Role templates are starting points. A company can customize an employee without changing every other employee with that same title.',
            ),
          ),
          const ProfileSection(
            title: 'Backend Enforcement',
            child: _DefinitionText(
              'These local settings are the permission contract that Firestore rules and functions must enforce when cloud backup is enabled.',
            ),
          ),
          ProfileSection(
            title: 'App Areas Covered',
            child: Column(
              children: [
                for (final area in employeePermissionCatalog)
                  ProfileFieldLine(label: area.title, value: area.summary),
              ],
            ),
          ),
          const ProfileSection(
            title: 'High-impact Defaults',
            child: _DefinitionText(
              'Pay, employees, company payments, role management, delete actions, exports, and profit views start locked down unless a trusted role template grants them.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DefinitionText extends StatelessWidget {
  const _DefinitionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFEAF0F2),
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
