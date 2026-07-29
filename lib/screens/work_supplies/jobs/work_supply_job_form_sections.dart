part of 'work_supply_job_form_screen.dart';

extension _WorkSupplyJobFormSections on _WorkSupplyJobFormScreenState {
  Widget _intro() {
    return const Text(
      'Create a direct job now, or review information imported from a saved estimate.',
      style: TextStyle(color: Color(0xFFC7D0D4), height: 1.35),
    );
  }

  Widget _scheduleSection() {
    return _section(
      title: 'Schedule',
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _scheduleJob,
          title: const Text('Schedule this job'),
          subtitle: const Text('Turn off to keep it in the unscheduled queue.'),
          onChanged: (value) => _change(() => _scheduleJob = value),
        ),
        if (_scheduleJob) ...[
          _choiceRow(
            label: 'Date',
            value: appShortDateLabel(_scheduledDay),
            onTap: _pickDay,
          ),
          _choiceRow(
            label: 'Start time',
            value: _startTime.format(context),
            onTap: () => _pickTime(isStart: true),
          ),
          _choiceRow(
            label: 'Estimated finish',
            value: _endTime.format(context),
            onTap: () => _pickTime(isStart: false),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _endsNextDay,
            title: const Text('Ends the next day'),
            subtitle: const Text(
              'Use for overnight work, routes, and after-hours service.',
            ),
            onChanged: (value) => _change(() => _endsNextDay = value),
          ),
          DropdownButtonFormField<JobRepeatRule>(
            initialValue: _repeatRule,
            decoration: const InputDecoration(labelText: 'Repeat'),
            items: [
              for (final rule in JobRepeatRule.values)
                DropdownMenuItem(value: rule, child: Text(rule.label)),
            ],
            onChanged: (value) {
              if (value != null) _change(() => _repeatRule = value);
            },
          ),
          if (_repeatRule == JobRepeatRule.selectedWeekdays) ...[
            const SizedBox(height: 8),
            const Text('Repeats on'),
            Wrap(
              spacing: 6,
              children: [
                for (final weekday in _jobScheduleWeekdays)
                  FilterChip(
                    label: Text(weekday.label),
                    selected: _repeatWeekdays.contains(weekday.value),
                    onSelected: (selected) => _change(() {
                      if (selected) {
                        _repeatWeekdays.add(weekday.value);
                      } else {
                        _repeatWeekdays.remove(weekday.value);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose one or more days. The first scheduled date is always included.',
              style: TextStyle(color: Color(0xFFC7D0D4), height: 1.3),
            ),
          ],
          if (_repeatRule != JobRepeatRule.none)
            _choiceRow(
              label: 'Repeat until',
              value: _repeatUntil == null
                  ? 'No end date'
                  : appShortDateLabel(_repeatUntil!),
              onTap: _pickRepeatUntil,
            ),
          if (_repeatUntil != null && _repeatRule != JobRepeatRule.none)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _change(() => _repeatUntil = null),
                child: const Text('Clear repeat end date'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _reminderSection() {
    return _section(
      title: 'Reminder preferences',
      children: [
        const Text(
          'Preferences are saved with the job. Phone delivery, sound selection, and system settings still require the shared notification service.',
          style: TextStyle(color: Color(0xFFC7D0D4), height: 1.3),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _inAppReminder,
          title: const Text('In-app reminder'),
          onChanged: (value) => _change(() => _inAppReminder = value ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _pushReminder,
          title: const Text('Phone push notification'),
          onChanged: (value) => _change(() => _pushReminder = value ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _soundReminder,
          title: const Text('Audible reminder'),
          subtitle: const Text('Independent of in-app and push delivery.'),
          onChanged: (value) => _change(() => _soundReminder = value ?? false),
        ),
        if (_inAppReminder || _pushReminder || _soundReminder)
          DropdownButtonFormField<int>(
            initialValue: _reminderLeadMinutes,
            decoration: const InputDecoration(labelText: 'Remind me'),
            items: const [
              DropdownMenuItem(value: 15, child: Text('15 minutes before')),
              DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              DropdownMenuItem(value: 60, child: Text('1 hour before')),
              DropdownMenuItem(value: 1440, child: Text('1 day before')),
            ],
            onChanged: (value) {
              if (value != null) {
                _change(() => _reminderLeadMinutes = value);
              }
            },
          ),
      ],
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
      ),
    );
  }

  Widget _choiceRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_calendar_rounded),
      onTap: onTap,
    );
  }
}

class _JobScheduleWeekday {
  const _JobScheduleWeekday(this.value, this.label);

  final int value;
  final String label;
}

const _jobScheduleWeekdays = <_JobScheduleWeekday>[
  _JobScheduleWeekday(DateTime.monday, 'Mon'),
  _JobScheduleWeekday(DateTime.tuesday, 'Tue'),
  _JobScheduleWeekday(DateTime.wednesday, 'Wed'),
  _JobScheduleWeekday(DateTime.thursday, 'Thu'),
  _JobScheduleWeekday(DateTime.friday, 'Fri'),
  _JobScheduleWeekday(DateTime.saturday, 'Sat'),
  _JobScheduleWeekday(DateTime.sunday, 'Sun'),
];
