// Calendar ownership: one-time changes to a Calendar-native repeating plan.
// It never alters source-owned jobs, expenses, trips, or work-time records.

import 'package:flutter/material.dart';

import '../widgets/app_back_button.dart';
import '../navigation/app_page_routes.dart';
import 'calendar_schedule_record.dart';
import 'calendar_schedule_recurrence_contract.dart';
import 'month_year_picker.dart';

class CalendarScheduleExceptionEditorScreen extends StatefulWidget {
  const CalendarScheduleExceptionEditorScreen({
    super.key,
    required this.record,
  });

  final CalendarScheduleRecord record;

  @override
  State<CalendarScheduleExceptionEditorScreen> createState() =>
      _CalendarScheduleExceptionEditorScreenState();
}

class _CalendarScheduleExceptionEditorScreenState
    extends State<CalendarScheduleExceptionEditorScreen> {
  late List<CalendarScheduleException> _exceptions;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _exceptions = [...widget.record.exceptions]
      ..sort((left, right) => left.day.compareTo(right.day));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1F2528),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saving ? null : _addException,
      icon: const Icon(Icons.add_rounded),
      label: const Text('One-time change'),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
        children: [
          const AppBackButton(),
          const SizedBox(height: 8),
          const Text(
            'One-time schedule changes',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.record.title,
            style: const TextStyle(
              color: Color(0xFF65B8FF),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Skip one occurrence or give it a one-time start and end. The repeating schedule remains unchanged.',
            style: TextStyle(color: Color(0xFFB7C4CA), height: 1.3),
          ),
          const SizedBox(height: 16),
          if (_exceptions.isEmpty)
            const _EmptyExceptionPanel()
          else
            for (final exception in _exceptions)
              _ExceptionTile(
                exception: exception,
                onRemove: _saving ? null : () => _remove(exception),
              ),
        ],
      ),
    ),
  );

  Future<void> _addException() async {
    final result = await showModalBottomSheet<CalendarScheduleException>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) => _ExceptionForm(
        initialDay: widget.record.startsAt,
        originalStart: widget.record.startsAt,
        originalEnd: widget.record.endsAt,
      ),
    );
    if (result == null || !mounted) return;
    final next = [
      for (final exception in _exceptions)
        if (!_sameDay(exception.day, result.day)) exception,
      result,
    ]..sort((left, right) => left.day.compareTo(right.day));
    await _save(next);
  }

  Future<void> _remove(CalendarScheduleException exception) async {
    final next = [
      for (final value in _exceptions)
        if (!_sameDay(value.day, exception.day)) value,
    ];
    await _save(next);
  }

  Future<void> _save(List<CalendarScheduleException> value) async {
    final controller = CalendarScheduleScope.maybeOf(context);
    if (controller == null) return;
    setState(() => _saving = true);
    await controller.save(widget.record.copyWith(exceptions: value));
    if (mounted) {
      setState(() {
        _exceptions = value;
        _saving = false;
      });
    }
  }
}

class _EmptyExceptionPanel extends StatelessWidget {
  const _EmptyExceptionPanel();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF172126),
      border: Border.all(color: const Color(0xFF53656D)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'No one-time changes. Add one only when this occurrence differs from the repeating plan.',
      style: TextStyle(color: Color(0xFFE8ECEE), height: 1.3),
    ),
  );
}

/// Management actions shared by the main schedule editor. Removal is a soft
/// delete and remains explicitly confirmed by the person using the app.
class CalendarScheduleManagementActions extends StatelessWidget {
  const CalendarScheduleManagementActions({
    super.key,
    required this.record,
    required this.disabled,
  });

  final CalendarScheduleRecord record;
  final bool disabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: disabled
            ? null
            : () => Navigator.of(context).push(
                appNativeRoute<void>(
                  context,
                  CalendarScheduleExceptionEditorScreen(record: record),
                ),
              ),
        icon: const Icon(Icons.edit_calendar_rounded),
        label: const Text('Manage one-time changes'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: const Color(0xFFE8ECEE),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: disabled ? null : () => _confirmRemove(context),
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('Remove schedule'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: const Color(0xFFFFB4AB),
          side: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
      ),
    ],
  );

  Future<void> _confirmRemove(BuildContext context) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this schedule?'),
        content: const Text(
          'This removes future Calendar occurrences. It does not alter any Jobs, Expenses, Trips, or other source records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep schedule'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    final controller = CalendarScheduleScope.maybeOf(context);
    if (controller == null) return;
    await controller.remove(record.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ExceptionTile extends StatelessWidget {
  const _ExceptionTile({required this.exception, required this.onRemove});
  final CalendarScheduleException exception;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF172126),
    child: ListTile(
      title: Text(
        calendarFullDateLabel(exception.day),
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        exception.cancelled
            ? 'Skipped occurrence'
            : _timeChangeLabel(context, exception),
        style: const TextStyle(color: Color(0xFFB7C4CA)),
      ),
      trailing: IconButton(
        tooltip: 'Remove one-time change',
        onPressed: onRemove,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ),
  );
}

class _ExceptionForm extends StatefulWidget {
  const _ExceptionForm({
    required this.initialDay,
    required this.originalStart,
    required this.originalEnd,
  });
  final DateTime initialDay;
  final DateTime originalStart;
  final DateTime? originalEnd;
  @override
  State<_ExceptionForm> createState() => _ExceptionFormState();
}

class _ExceptionFormState extends State<_ExceptionForm> {
  late DateTime _day;
  late DateTime _start;
  DateTime? _end;
  var _skip = true;
  @override
  void initState() {
    super.initState();
    _day = DateUtils.dateOnly(widget.initialDay);
    _start = widget.originalStart;
    _end = widget.originalEnd;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'One-time change',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(calendarFullDateLabel(_day)),
          ),
          SwitchListTile(
            value: _skip,
            onChanged: (value) => setState(() => _skip = value),
            title: const Text(
              'Skip this occurrence',
              style: TextStyle(color: Color(0xFFE8ECEE)),
            ),
          ),
          if (!_skip) ...[
            OutlinedButton.icon(
              onPressed: () => _pickTime(start: true),
              icon: const Icon(Icons.schedule_rounded),
              label: Text(
                'Starts · ${TimeOfDay.fromDateTime(_start).format(context)}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickTime(start: false),
              icon: const Icon(Icons.schedule_rounded),
              label: Text(
                _end == null
                    ? 'Add end time'
                    : 'Ends · ${TimeOfDay.fromDateTime(_end!).format(context)}',
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _save,
            child: const Text('Save one-time change'),
          ),
        ],
      ),
    ),
  );
  Future<void> _pickDay() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _day = value);
  }

  Future<void> _pickTime({required bool start}) async {
    final original = start
        ? _start
        : (_end ?? _start.add(const Duration(hours: 1)));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(original),
    );
    if (time != null && mounted) {
      setState(() {
        final value = DateTime(
          _day.year,
          _day.month,
          _day.day,
          time.hour,
          time.minute,
        );
        if (start) {
          _start = value;
        } else {
          _end = value.isAfter(_start) ? value : null;
        }
      });
    }
  }

  void _save() => Navigator.of(context).pop(
    CalendarScheduleException(
      day: _day,
      cancelled: _skip,
      startOverride: _skip ? null : _start,
      endOverride: _skip ? null : _end,
    ),
  );
}

String _timeChangeLabel(BuildContext context, CalendarScheduleException value) {
  final start = value.startOverride;
  if (start == null) return 'One-time time change';
  final time = TimeOfDay.fromDateTime(start).format(context);
  final end = value.endOverride == null
      ? ''
      : '–${TimeOfDay.fromDateTime(value.endOverride!).format(context)}';
  return 'Rescheduled · $time$end';
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
