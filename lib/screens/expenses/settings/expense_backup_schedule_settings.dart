part of 'expense_settings_screen.dart';

class _BackupScheduleSettingsPanel extends StatelessWidget {
  const _BackupScheduleSettingsPanel({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final schedule = settings.backupSchedule;
    final isScheduled =
        settings.backupSyncMode == ExpenseBackupSyncMode.scheduled;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Scheduled Backup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose the times and connection type. Nothing transfers until you turn scheduled backup on.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _BackupSyncModeChoice(
            title: 'Back up on my schedule',
            detail: schedule.hasSelectedTimes
                ? 'Runs at ${_backupScheduleTimesLabel(schedule)}.'
                : 'Add at least one time before a backup can run.',
            selected: isScheduled,
            onTap: () =>
                settings.setBackupSyncMode(ExpenseBackupSyncMode.scheduled),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in schedule.timesMinutesAfterMidnight)
                InputChip(
                  label: Text(_backupScheduleTimeLabel(minutes)),
                  onDeleted: () => _removeTime(settings, schedule, minutes),
                ),
              OutlinedButton.icon(
                onPressed: () => _addTime(context, settings, schedule),
                icon: const Icon(Icons.add_alarm_outlined),
                label: const Text('Add time'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ExpenseBackupTransport>(
            initialValue: schedule.transport,
            decoration: const InputDecoration(
              labelText: 'Connection for scheduled backup',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: ExpenseBackupTransport.wifiOnly,
                child: Text('Wi-Fi only'),
              ),
              DropdownMenuItem(
                value: ExpenseBackupTransport.wifiAndCellular,
                child: Text('Wi-Fi or mobile data'),
              ),
            ],
            onChanged: (transport) {
              if (transport == null) return;
              settings.setBackupSchedule(
                ExpenseBackupSchedule.normalized(
                  timesMinutesAfterMidnight: schedule.timesMinutesAfterMidnight,
                  transport: transport,
                ),
              );
            },
          ),
          if (isScheduled) ...[
            const SizedBox(height: 8),
            const Text(
              'Scheduled backup is enabled only on this device. A restored device always asks again.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addTime(
    BuildContext context,
    ExpenseSettingsController settings,
    ExpenseBackupSchedule schedule,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (selected == null) return;
    await settings.setBackupSchedule(
      ExpenseBackupSchedule.normalized(
        timesMinutesAfterMidnight: [
          ...schedule.timesMinutesAfterMidnight,
          selected.hour * 60 + selected.minute,
        ],
        transport: schedule.transport,
      ),
    );
  }

  Future<void> _removeTime(
    ExpenseSettingsController settings,
    ExpenseBackupSchedule schedule,
    int minutes,
  ) => settings.setBackupSchedule(
    ExpenseBackupSchedule.normalized(
      timesMinutesAfterMidnight: schedule.timesMinutesAfterMidnight.where(
        (time) => time != minutes,
      ),
      transport: schedule.transport,
    ),
  );
}

String _backupScheduleTimesLabel(ExpenseBackupSchedule schedule) =>
    schedule.timesMinutesAfterMidnight.map(_backupScheduleTimeLabel).join(', ');

String _backupScheduleTimeLabel(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}
