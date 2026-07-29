// Job schedule-exception screen. This Jobs-owner UI changes source schedule
// occurrences; Calendar reads the result and never persists a duplicate.

import 'package:flutter/material.dart';

import '../../../shared/calendar/app_date_picker.dart';
import '../../../shared/jobs/maintainiac_job_schedule_exception.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';

class JobScheduleExceptionsScreen extends StatelessWidget {
  const JobScheduleExceptionsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final job = MaintainiacJobScope.of(context).jobById(jobId);
    if (job == null) return const _MissingJobScheduleScreen();
    final exceptions = job.scheduleExceptions;
    return AppScreenShell(
      section: AppSection.materials,
      maxWidth: 720,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 8),
          AppScreenHeader(title: 'Manage recurring visits'),
          const SizedBox(height: 10),
          const _ScheduleExceptionGuide(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _skipVisit(context, job),
                icon: const Icon(Icons.event_busy_rounded),
                label: const Text('Skip visit'),
              ),
              OutlinedButton.icon(
                onPressed: () => _rescheduleVisit(context, job),
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text('Reschedule visit'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (exceptions.isEmpty)
            const _ScheduleExceptionEmptyState()
          else
            for (final exception in exceptions)
              _ScheduleExceptionRow(
                exception: exception,
                onDelete: () => _deleteException(context, job, exception),
              ),
        ],
      ),
    );
  }

  Future<void> _skipVisit(
    BuildContext context,
    MaintainiacJobRecord job,
  ) async {
    final day = await _pickDay(context, job);
    if (day == null || !context.mounted) return;
    if (!_isPlannedOccurrence(job, day)) {
      _showNotOccurrence(context);
      return;
    }
    await _saveException(
      context,
      job,
      MaintainiacJobScheduleException(day: day, cancelled: true),
    );
  }

  Future<void> _rescheduleVisit(
    BuildContext context,
    MaintainiacJobRecord job,
  ) async {
    final day = await _pickDay(context, job);
    if (day == null || !context.mounted) return;
    if (!_isPlannedOccurrence(job, day)) {
      _showNotOccurrence(context);
      return;
    }
    final start = job.scheduledStart!;
    final end = job.scheduledEnd ?? start.add(const Duration(hours: 1));
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (startTime == null || !context.mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(end),
    );
    if (endTime == null || !context.mounted) return;
    final overrideStart = _atTime(day, startTime);
    final overrideEnd = _atTime(day, endTime);
    if (!overrideEnd.isAfter(overrideStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish time must be after start time.')),
      );
      return;
    }
    await _saveException(
      context,
      job,
      MaintainiacJobScheduleException(
        day: day,
        startOverride: overrideStart,
        endOverride: overrideEnd,
      ),
    );
  }

  Future<DateTime?> _pickDay(BuildContext context, MaintainiacJobRecord job) =>
      showAppDatePicker(
        context: context,
        initialDate: job.scheduledStart ?? DateTime.now(),
        firstDate: job.scheduledStart,
      );

  bool _isPlannedOccurrence(MaintainiacJobRecord job, DateTime day) {
    final start = job.scheduledStart;
    if (start == null) return false;
    return maintainiacJobScheduleHasOccurrenceOn(
      sourceRecordId: job.id,
      scheduledStart: start,
      repeatRule: job.repeatRule,
      repeatWeekdays: job.repeatWeekdays,
      repeatUntil: job.repeatUntil,
      day: day,
    );
  }

  void _showNotOccurrence(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choose a date that matches this recurring schedule.'),
      ),
    );
  }

  Future<void> _saveException(
    BuildContext context,
    MaintainiacJobRecord job,
    MaintainiacJobScheduleException exception,
  ) async {
    try {
      final updated = replaceMaintainiacJobScheduleException(
        job.scheduleExceptions,
        exception,
      );
      await MaintainiacJobScope.of(
        context,
      ).save(job.copyWith(scheduleExceptions: updated));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update visit: $error')));
    }
  }

  Future<void> _deleteException(
    BuildContext context,
    MaintainiacJobRecord job,
    MaintainiacJobScheduleException exception,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove visit exception?'),
        content: const Text('The normal recurring visit will be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep exception'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    try {
      await MaintainiacJobScope.of(context).save(
        job.copyWith(
          scheduleExceptions: [
            for (final value in job.scheduleExceptions)
              if (!_sameDay(value.day, exception.day)) value,
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove visit: $error')));
    }
  }
}

class _ScheduleExceptionGuide extends StatelessWidget {
  const _ScheduleExceptionGuide();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF1D282C),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF46565E)),
    ),
    child: const Text(
      'Skip a one-time visit or move it to another time on the same date. '
      'These changes stay with this Job; Calendar only displays them.',
      style: TextStyle(color: Color(0xFFE2E8EA), height: 1.3),
    ),
  );
}

class _ScheduleExceptionEmptyState extends StatelessWidget {
  const _ScheduleExceptionEmptyState();

  @override
  Widget build(BuildContext context) => const Text(
    'No one-time visit changes. Every occurrence follows the recurring schedule.',
    style: TextStyle(color: Color(0xFFC7D0D4), height: 1.3),
  );
}

class _ScheduleExceptionRow extends StatelessWidget {
  const _ScheduleExceptionRow({
    required this.exception,
    required this.onDelete,
  });

  final MaintainiacJobScheduleException exception;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        exception.cancelled ? Icons.event_busy_rounded : Icons.update_rounded,
      ),
      title: Text(_dateLabel(exception.day)),
      subtitle: Text(
        exception.cancelled
            ? 'Visit skipped'
            : '${_timeLabel(exception.startOverride)} – ${_timeLabel(exception.endOverride)}',
      ),
      trailing: IconButton(
        tooltip: 'Remove visit exception',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ),
  );
}

class _MissingJobScheduleScreen extends StatelessWidget {
  const _MissingJobScheduleScreen();

  @override
  Widget build(BuildContext context) => AppScreenShell(
    section: AppSection.materials,
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        AppScreenHeader(title: 'Job unavailable'),
        SizedBox(height: 12),
        Text('This Job is no longer available in the source record store.'),
      ],
    ),
  );
}

DateTime _atTime(DateTime day, TimeOfDay time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);
bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
String _dateLabel(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';
String _timeLabel(DateTime? value) {
  if (value == null) return 'Time not set';
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}
