import 'package:flutter/material.dart';

import '../../shared/calendar/employee_calendar.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/profiles/employee_directory_models.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'employee_permission_review_screen.dart';
import 'employee_profile_widgets.dart';
import 'employee_work_time_entry_screen.dart';

class EmployeeProfileDetailScreen extends StatelessWidget {
  const EmployeeProfileDetailScreen({
    super.key,
    required this.record,
    required this.records,
    required this.onSave,
    this.onQueueInvite,
  });

  final EmployeeDirectoryRecord record;
  final List<EmployeeDirectoryRecord> records;
  final ValueChanged<EmployeeDirectoryRecord> onSave;
  final VoidCallback? onQueueInvite;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.dashboard,
      maxWidth: 640,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        children: [
          const GlobalOdometerHeader(section: AppSection.dashboard),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        style: const TextStyle(
                          color: Color(0xFFF5F8F9),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${record.roleLabel} / ${record.status.label}',
                        style: const TextStyle(
                          color: Color(0xFFBCC8CD),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                CompactActionButton(
                  label: 'Permissions',
                  icon: Icons.security_rounded,
                  onPressed: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      EmployeePermissionReviewScreen(
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
            title: 'Employee Information',
            trailing: CompactActionButton(
              label: 'Edit Info',
              onPressed: () => _openEditInfo(context),
            ),
            child: Column(
              children: [
                ProfileFieldLine(label: 'Name', value: record.name),
                ProfileFieldLine(label: 'Phone', value: record.phone),
                ProfileFieldLine(label: 'Email', value: record.email),
                ProfileFieldLine(
                  label: 'Employee Role',
                  value: record.roleLabel,
                ),
                ProfileFieldLine(label: 'Status', value: record.status.label),
                ProfileFieldLine(
                  label: 'Pay',
                  value: employeePaySummary(record),
                ),
                if (record.canQueueInvite && onQueueInvite != null) ...[
                  const SizedBox(height: 8),
                  CompactActionButton(
                    label: 'Queue Invite',
                    icon: Icons.mail_outline_rounded,
                    onPressed: onQueueInvite!,
                  ),
                ],
              ],
            ),
          ),
          ProfileSection(
            title: 'Vehicle Assignment',
            child: Column(
              children: [
                ProfileFieldLine(
                  label: 'Assigned',
                  value: record.assignedVehicleLabel.isEmpty
                      ? 'No vehicle assigned'
                      : record.assignedVehicleLabel,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The assigned vehicle appears first when a company has multiple vehicles.',
                  style: TextStyle(
                    color: Color(0xFF9EADB3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ProfileSection(
            title: 'Employee Calendar',
            trailing: IconButton(
              tooltip: 'Calendar settings',
              onPressed: () => _openCalendarSettings(context),
              icon: const Icon(
                Icons.settings_rounded,
                color: Color(0xFFEAF0F2),
              ),
            ),
            child: EmployeeCalendar(employee: record),
          ),
          ProfileSection(
            title: 'Work time',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record manual hours or submit time for approval. Calendar and pay-period recaps read these source-owned records.',
                  style: TextStyle(
                    color: Color(0xFF9EADB3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                CompactActionButton(
                  label: 'Record Work Time',
                  icon: Icons.timer_rounded,
                  onPressed: () => Navigator.of(context).push(
                    appNativeRoute<void>(
                      context,
                      EmployeeWorkTimeEntryScreen(employeeId: record.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Employee info editor is next in this flow.'),
      ),
    );
  }

  void _openCalendarSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Employee Calendar Settings',
              style: TextStyle(
                color: Color(0xFFF5F8F9),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ProfileFieldLine(
              label: 'Pay period',
              value: employeePaySummary(record),
            ),
            const ProfileFieldLine(
              label: 'Daily recap',
              value: 'Shown after a calendar day is selected',
            ),
            const ProfileFieldLine(
              label: 'Detailed recap',
              value: 'Dedicated recap screen planned for full reporting',
            ),
          ],
        ),
      ),
    );
  }
}
