// Calendar ownership: create and edit Calendar-native appointments only.
// Jobs, invoices, expenses, and other source records keep their own editors.

import 'package:flutter/material.dart';

import '../context/operational_context_store.dart';
import '../widgets/app_back_button.dart';
import 'calendar_day_flow_support.dart';
import 'calendar_flow_models.dart';
import 'calendar_schedule_record.dart';
import 'calendar_schedule_exception_editor_screen.dart';
import 'calendar_schedule_recurrence_contract.dart';
import 'month_year_picker.dart';

class CalendarScheduleEditorScreen extends StatefulWidget {
  const CalendarScheduleEditorScreen({
    super.key,
    required this.day,
    required this.source,
    this.record,
    this.employeeId,
  });

  final DateTime day;
  final CalendarFlowSource source;
  final CalendarScheduleRecord? record;
  final String? employeeId;

  @override
  State<CalendarScheduleEditorScreen> createState() =>
      _CalendarScheduleEditorScreenState();
}

class _CalendarScheduleEditorScreenState
    extends State<CalendarScheduleEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _details;
  late DateTime _start;
  DateTime? _end;
  late CalendarScheduleFrequency _frequency;
  late int _interval;
  late Set<int> _weekdays;
  DateTime? _until;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _title = TextEditingController(text: record?.title ?? '');
    _details = TextEditingController(text: record?.details ?? '');
    _start =
        record?.startsAt ??
        DateTime(widget.day.year, widget.day.month, widget.day.day, 9);
    _end = record?.endsAt;
    _frequency = record?.rule.frequency ?? CalendarScheduleFrequency.once;
    _interval = record?.rule.interval ?? 1;
    _weekdays = {...?record?.rule.weekdays};
    _until = record?.rule.until;
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = OperationalContextScope.maybeOf(context)?.context;
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            const AppBackButton(),
            const SizedBox(height: 8),
            Text(
              widget.record == null ? 'Schedule item' : 'Edit schedule item',
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A calendar appointment plans work. It does not mark a job, trip, or expense complete.',
              style: TextStyle(color: Color(0xFFB7C4CA), height: 1.3),
            ),
            const SizedBox(height: 16),
            _field('Title', _title, hint: 'Example: Jones Tree Work'),
            const SizedBox(height: 12),
            _field(
              'Notes',
              _details,
              hint: 'Optional arrival window, task, or contact note',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _ScheduleDateTimeCard(
              label: 'Starts',
              value: _start,
              onPressed: () => _pickStart(context),
            ),
            const SizedBox(height: 8),
            _ScheduleDateTimeCard(
              label: _end == null ? 'Add end time' : 'Ends',
              value: _end,
              onPressed: () => _pickEnd(context),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CalendarScheduleFrequency>(
              initialValue: _frequency,
              dropdownColor: const Color(0xFF2A3135),
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontWeight: FontWeight.w700,
              ),
              decoration: _decoration('Repeats'),
              items: [
                for (final frequency in CalendarScheduleFrequency.values)
                  DropdownMenuItem(
                    value: frequency,
                    child: Text(_frequencyLabel(frequency)),
                  ),
              ],
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            if (_frequency != CalendarScheduleFrequency.once) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _interval,
                dropdownColor: const Color(0xFF2A3135),
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontWeight: FontWeight.w700,
                ),
                decoration: _decoration('Repeat interval'),
                items: [
                  for (var interval = 1; interval <= 12; interval++)
                    DropdownMenuItem(
                      value: interval,
                      child: Text(_intervalLabel(_frequency, interval)),
                    ),
                ],
                onChanged: (value) => setState(() => _interval = value!),
              ),
              if (_usesWeekdays(_frequency)) ...[
                const SizedBox(height: 12),
                const Text(
                  'REPEAT ON',
                  style: TextStyle(
                    color: Color(0xFFB7C4CA),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (
                      var day = DateTime.monday;
                      day <= DateTime.sunday;
                      day++
                    )
                      FilterChip(
                        label: Text(_weekdayLabel(day)),
                        selected: _weekdays.contains(day),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _weekdays.add(day);
                          } else {
                            _weekdays.remove(day);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _frequency == CalendarScheduleFrequency.customDays
                      ? 'Choose one or more days for a custom schedule.'
                      : 'Leave all days unselected to repeat on the start day only.',
                  style: const TextStyle(
                    color: Color(0xFFB7C4CA),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _ScheduleDateTimeCard(
                label: _until == null
                    ? 'No repeat end date'
                    : 'Repeats through',
                value: _until,
                showTime: false,
                onPressed: () => _pickUntil(context),
              ),
            ],
            const SizedBox(height: 12),
            _ContextCard(
              vehicle:
                  active?.activeVehicleLabel ?? 'No active vehicle selected',
              profile:
                  active?.workProfileName ?? 'No active work profile selected',
              source: widget.source,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.event_available_rounded),
              label: Text(_saving ? 'Saving schedule…' : 'Save schedule'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF65B8FF),
                foregroundColor: const Color(0xFF071116),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (widget.record != null) ...[
              const SizedBox(height: 10),
              CalendarScheduleManagementActions(
                record: widget.record!,
                disabled: _saving,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    textCapitalization: TextCapitalization.sentences,
    style: const TextStyle(color: Color(0xFFE8ECEE)),
    decoration: _decoration(label).copyWith(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A1A7)),
    ),
  );

  Future<void> _pickStart(BuildContext context) async {
    final value = await _pickDateTime(context, _start);
    if (value != null && mounted) {
      setState(() => _start = value);
    }
  }

  Future<void> _pickEnd(BuildContext context) async {
    final value = await _pickDateTime(
      context,
      _end ?? _start.add(const Duration(hours: 1)),
    );
    if (value != null && mounted) {
      setState(() => _end = value.isAfter(_start) ? value : null);
    }
  }

  Future<void> _pickUntil(BuildContext context) async {
    final initial = _until ?? _start;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(_start.year, _start.month, _start.day),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() => _until = DateTime(date.year, date.month, date.day));
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!context.mounted || date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!context.mounted || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this schedule item a title.')),
      );
      return;
    }
    if (_frequency == CalendarScheduleFrequency.customDays &&
        _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one day for a custom schedule.'),
        ),
      );
      return;
    }
    final controller = CalendarScheduleScope.maybeOf(context);
    if (controller == null) return;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final active = OperationalContextScope.maybeOf(context)?.context;
    final existing = widget.record;
    final now = DateTime.now();
    await controller.save(
      CalendarScheduleRecord(
        id: existing?.id ?? 'calendar-${now.microsecondsSinceEpoch}',
        title: title,
        details: _details.text.trim(),
        startsAt: _start,
        endsAt: _end,
        recordedAt: existing?.recordedAt ?? now,
        rule: CalendarScheduleRule(
          frequency: _frequency,
          interval: _interval,
          until: _until,
          weekdays: _weekdays,
        ),
        vehicleId: active?.activeVehicleId ?? '',
        workProfileId: active?.workProfileId ?? '',
        employeeId: widget.employeeId?.trim() ?? existing?.employeeId ?? '',
        // A Dashboard projection can open any schedule. Editing there must not
        // re-home an employee or source-calendar appointment into Dashboard.
        screenScope: existing?.screenScope ?? widget.source.name,
        // The platform does not expose an IANA identifier through core Dart.
        // Keep it null rather than persisting an ambiguous abbreviation such as
        // "EST"; the projection retains the actual signed offset instead.
        timezoneId: existing?.timezoneId,
      ),
    );
    if (mounted) navigator.pop();
  }
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(
    color: Color(0xFFB7C4CA),
    fontWeight: FontWeight.w800,
  ),
  enabledBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF59636A)),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF65B8FF), width: 2),
  ),
);

class _ScheduleDateTimeCard extends StatelessWidget {
  const _ScheduleDateTimeCard({
    required this.label,
    required this.value,
    required this.onPressed,
    this.showTime = true,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onPressed;
  final bool showTime;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.schedule_rounded),
    label: Text(
      value == null
          ? label
          : showTime
          ? '$label · ${calendarFullDateLabel(value!)} · ${TimeOfDay.fromDateTime(value!).format(context)}'
          : '$label · ${calendarFullDateLabel(value!)}',
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: const Color(0xFFE8ECEE),
      alignment: Alignment.centerLeft,
    ),
  );
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.vehicle,
    required this.profile,
    required this.source,
  });
  final String vehicle;
  final String profile;
  final CalendarFlowSource source;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF101719),
      border: Border.all(color: const Color(0xFF445159)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'SCHEDULE CONTEXT\n${calendarScreenTitle(source)} · $vehicle\n$profile',
      style: const TextStyle(
        color: Color(0xFFE8ECEE),
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
    ),
  );
}

String _frequencyLabel(CalendarScheduleFrequency value) => switch (value) {
  CalendarScheduleFrequency.once => 'Does not repeat',
  CalendarScheduleFrequency.daily => 'Every day',
  CalendarScheduleFrequency.weekly => 'Every week',
  CalendarScheduleFrequency.biweekly => 'Every other week',
  CalendarScheduleFrequency.monthly => 'Every month',
  CalendarScheduleFrequency.customDays => 'Custom days',
};

bool _usesWeekdays(CalendarScheduleFrequency value) =>
    value == CalendarScheduleFrequency.weekly ||
    value == CalendarScheduleFrequency.biweekly ||
    value == CalendarScheduleFrequency.customDays;

String _intervalLabel(CalendarScheduleFrequency frequency, int interval) {
  final unit = switch (frequency) {
    CalendarScheduleFrequency.daily => interval == 1 ? 'day' : 'days',
    CalendarScheduleFrequency.monthly => interval == 1 ? 'month' : 'months',
    CalendarScheduleFrequency.weekly ||
    CalendarScheduleFrequency.customDays => interval == 1 ? 'week' : 'weeks',
    CalendarScheduleFrequency.biweekly =>
      interval == 1 ? '2 weeks' : '${interval * 2} weeks',
    CalendarScheduleFrequency.once => 'time',
  };
  return 'Every $interval $unit';
}

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => 'Mon',
  DateTime.tuesday => 'Tue',
  DateTime.wednesday => 'Wed',
  DateTime.thursday => 'Thu',
  DateTime.friday => 'Fri',
  DateTime.saturday => 'Sat',
  DateTime.sunday => 'Sun',
  _ => '',
};
