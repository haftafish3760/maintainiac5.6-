// Source-owned Job detail. Calendar links here; this screen does not create a
// duplicate job record or rely on calendar-only state.

import 'package:flutter/material.dart';

import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import 'work_supply_job_draft_mapping.dart';
import 'work_supply_job_form_models.dart';
import 'work_supply_job_form_screen.dart';
import 'job_schedule_exceptions_screen.dart';

class MaintainiacJobDetailScreen extends StatelessWidget {
  const MaintainiacJobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final job = MaintainiacJobScope.of(context).jobById(jobId);
    if (job == null) return const _MissingJobDetailScreen();
    return AppScreenShell(
      section: AppSection.materials,
      maxWidth: 720,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 8),
          AppScreenHeader(title: job.name),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _editJob(context, job),
            icon: const Icon(Icons.edit_calendar_rounded),
            label: const Text('Edit job and schedule'),
          ),
          if (job.repeatRule != 'none') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                appNativeRoute<void>(
                  context,
                  JobScheduleExceptionsScreen(jobId: job.id),
                ),
              ),
              icon: const Icon(Icons.repeat_rounded),
              label: const Text('Manage recurring visits'),
            ),
          ],
          const SizedBox(height: 10),
          _JobDetailSection(
            title: 'Job overview',
            rows: [
              _JobDetailRow('Job number', _valueOr(job.number, 'Not assigned')),
              _JobDetailRow('Status', job.archived ? 'Archived' : 'Active'),
              _JobDetailRow(
                'Work profile',
                _valueOr(job.workProfileId, 'Not assigned'),
              ),
              _JobDetailRow('Scheduled', _scheduleLabel(job)),
              _JobDetailRow('Repeat', _repeatLabel(job)),
              _JobDetailRow(
                'One-time visit changes',
                job.scheduleExceptions.isEmpty
                    ? 'None'
                    : '${job.scheduleExceptions.length} saved change${job.scheduleExceptions.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          _JobDetailSection(
            title: 'Customer and service location',
            rows: [
              _JobDetailRow(
                'Customer',
                _valueOr(job.customerReference, 'Not assigned'),
              ),
              _JobDetailRow(
                'Phone',
                _valueOr(job.customerPhone, 'Not provided'),
              ),
              _JobDetailRow(
                'Email',
                _valueOr(job.customerEmail, 'Not provided'),
              ),
              _JobDetailRow('Address', _valueOr(job.address, 'Not provided')),
            ],
          ),
          _JobDetailSection(
            title: 'People and vehicles',
            rows: [
              _JobDetailRow(
                'Assigned people',
                _listOr(job.assignedMemberIds, 'No assignments yet'),
              ),
              _JobDetailRow(
                'Vehicles',
                _listOr(job.vehicleIds, 'No vehicles assigned'),
              ),
            ],
          ),
          _JobDetailSection(
            title: 'Linked business records',
            rows: [
              _JobDetailRow(
                'Estimate',
                _valueOr(job.estimateId, 'No estimate linked'),
              ),
              _JobDetailRow(
                'Invoice',
                _valueOr(job.invoiceId, 'No invoice linked'),
              ),
            ],
          ),
          _JobDetailSection(
            title: 'Reminder plan',
            rows: [
              _JobDetailRow('Channels', _reminderLabel(job)),
              _JobDetailRow('Lead time', '${job.reminderLeadMinutes} minutes'),
            ],
          ),
          _JobDetailSection(
            title: 'Notes and audit',
            rows: [
              _JobDetailRow('Notes', _valueOr(job.notes, 'No notes')),
              _JobDetailRow('Created', _dateTimeLabel(job.createdAt)),
              _JobDetailRow('Last updated', _dateTimeLabel(job.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editJob(BuildContext context, MaintainiacJobRecord job) async {
    final draft = await Navigator.of(context).push<WorkSupplyJobDraft>(
      appNativeRoute(
        context,
        WorkSupplyJobFormScreen(
          initialDay: job.scheduledStart ?? DateTime.now(),
          initialDraft: workSupplyJobDraftFromRecord(job),
        ),
      ),
    );
    if (draft == null || !context.mounted) return;
    try {
      await MaintainiacJobScope.of(context).save(
        maintainiacJobRecordFromDraft(
          draft: draft,
          existing: job,
          now: DateTime.now().toUtc(),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update job: $error')));
    }
  }
}

class _MissingJobDetailScreen extends StatelessWidget {
  const _MissingJobDetailScreen();

  @override
  Widget build(BuildContext context) => AppScreenShell(
    section: AppSection.materials,
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        AppScreenHeader(title: 'Job unavailable'),
        SizedBox(height: 12),
        Text(
          'This job is no longer available in the source record store.',
          style: TextStyle(
            color: Color(0xFFE2E8EA),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _JobDetailSection extends StatelessWidget {
  const _JobDetailSection({required this.title, required this.rows});

  final String title;
  final List<_JobDetailRow> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D282C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF46565E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF0F4F5),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows) row,
        ],
      ),
    ),
  );
}

class _JobDetailRow extends StatelessWidget {
  const _JobDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9DB0B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE2E8EA),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _valueOr(String value, String fallback) =>
    value.trim().isEmpty ? fallback : value.trim();
String _listOr(List<String> values, String fallback) =>
    values.isEmpty ? fallback : values.join(', ');
String _repeatLabel(MaintainiacJobRecord job) {
  final repeat = switch (job.repeatRule.trim()) {
    '' || 'none' => 'Does not repeat',
    'daily' => 'Every day',
    'weekly' => 'Every week',
    'everyTwoWeeks' => 'Every 2 weeks',
    'monthly' => 'Every month',
    'selectedWeekdays' => _weekdayScheduleLabel(job.repeatWeekdays),
    final value => value,
  };
  final until = job.repeatUntil;
  if (until == null || repeat == 'Does not repeat') return repeat;
  return '$repeat through ${until.month}/${until.day}/${until.year}';
}

String _weekdayScheduleLabel(List<int> weekdays) {
  const labels = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };
  final selected = [for (final day in weekdays) labels[day]].nonNulls;
  return selected.isEmpty
      ? 'Selected weekdays (not configured)'
      : 'Selected weekdays: ${selected.join(', ')}';
}

String _reminderLabel(MaintainiacJobRecord job) {
  final values = <String>[
    if (job.inAppReminder) 'In app',
    if (job.pushReminder) 'Phone notification',
    if (job.soundReminder) 'Sound',
  ];
  return values.isEmpty ? 'No reminder enabled' : values.join(', ');
}

String _scheduleLabel(MaintainiacJobRecord job) {
  final start = job.scheduledStart;
  if (start == null) return 'Unscheduled';
  final end = job.scheduledEnd;
  final startLabel = _dateTimeLabel(start);
  return end == null ? startLabel : '$startLabel – ${_dateTimeLabel(end)}';
}

String _dateTimeLabel(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day}/${value.year} $hour:$minute $suffix';
}
