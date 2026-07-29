part of 'work_supply_job_form_screen.dart';

extension _WorkSupplyJobFormActions on _WorkSupplyJobFormScreenState {
  Future<void> _pickDay() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _scheduledDay,
    );
    if (picked != null) _change(() => _scheduledDay = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    _change(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _pickRepeatUntil() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _repeatUntil ?? _scheduledDay,
      firstDate: _scheduledDay,
    );
    if (picked != null) _change(() => _repeatUntil = picked);
  }

  DateTime _atTime(TimeOfDay time) => DateTime(
    _scheduledDay.year,
    _scheduledDay.month,
    _scheduledDay.day,
    time.hour,
    time.minute,
  );

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final start = _scheduleJob ? _atTime(_startTime) : null;
    final end = _scheduleJob
        ? _atTime(
            _endTime,
          ).add(_endsNextDay ? const Duration(days: 1) : Duration.zero)
        : null;
    if (start != null && end != null && !end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish time must be after start time.')),
      );
      return;
    }
    if (_scheduleJob &&
        _repeatRule == JobRepeatRule.selectedWeekdays &&
        _repeatWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one repeat day.')),
      );
      return;
    }
    final repeatRule = _scheduleJob ? _repeatRule : JobRepeatRule.none;
    _dirty = false;
    Navigator.of(context).pop(
      WorkSupplyJobDraft(
        name: _name.text.trim(),
        clientName: _clientName.text.trim(),
        clientPhone: _clientPhone.text.trim(),
        clientEmail: _clientEmail.text.trim(),
        serviceAddress: _serviceAddress.text.trim(),
        notes: _notes.text.trim(),
        scheduledStart: start,
        scheduledEnd: end,
        scheduleEnabled: _scheduleJob,
        repeatRule: repeatRule,
        repeatWeekdays: repeatRule == JobRepeatRule.selectedWeekdays
            ? (_repeatWeekdays.toList()..sort())
            : const <int>[],
        repeatUntil: repeatRule == JobRepeatRule.none ? null : _repeatUntil,
        inAppReminder: _inAppReminder,
        pushReminder: _pushReminder,
        soundReminder: _soundReminder,
        reminderLeadMinutes: _reminderLeadMinutes,
        estimateId: widget.initialDraft?.estimateId ?? '',
      ),
    );
  }

  String? _optionalEmailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _requestClose() async {
    if (!_dirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this job?'),
        content: const Text('The job has not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _dirty = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }
}
