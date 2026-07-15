part of 'expense_settings_screen.dart';

class _BackupScheduleSettingsPanel extends StatelessWidget {
  const _BackupScheduleSettingsPanel({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    final schedule = settings.backupSchedule;
    final isScheduled =
        settings.backupSyncMode == ExpenseBackupSyncMode.scheduled;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.scheduledBackup,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            strings.scheduledBackupIntro,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _BackupSyncModeChoice(
            title: strings.backUpOnMySchedule,
            detail: schedule.hasSelectedTimes
                ? strings.scheduledBackupRunsAt(
                    _backupScheduleTimesLabel(context, schedule),
                  )
                : strings.scheduledBackupNeedsTime,
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
                  label: Text(_backupScheduleTimeLabel(context, minutes)),
                  onDeleted: () => _removeTime(settings, schedule, minutes),
                ),
              OutlinedButton.icon(
                onPressed: () => _addTime(context, settings, schedule),
                icon: const Icon(Icons.add_alarm_outlined),
                label: Text(strings.addBackupTime),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ExpenseBackupTransport>(
            initialValue: schedule.transport,
            decoration: InputDecoration(
              labelText: strings.scheduledBackupConnection,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: ExpenseBackupTransport.wifiOnly,
                child: Text(strings.wifiOnly),
              ),
              DropdownMenuItem(
                value: ExpenseBackupTransport.wifiAndCellular,
                child: Text(strings.wifiOrMobileData),
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
            Text(
              strings.scheduledBackupDeviceConsent,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

String _backupScheduleTimesLabel(
  BuildContext context,
  ExpenseBackupSchedule schedule,
) => schedule.timesMinutesAfterMidnight
    .map((time) => _backupScheduleTimeLabel(context, time))
    .join(', ');

String _backupScheduleTimeLabel(BuildContext context, int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
}
