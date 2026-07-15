import 'package:flutter/material.dart';

import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../../../shared/context/operational_context_store.dart';
import '../data/expense_reminder_store.dart';
import '../categories/expense_categories.dart';

class ExpenseReminderScreen extends StatefulWidget {
  const ExpenseReminderScreen({super.key});

  @override
  State<ExpenseReminderScreen> createState() => _ExpenseReminderScreenState();
}

class _ExpenseReminderScreenState extends State<ExpenseReminderScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  var _category = 'Fuel';
  var _channel = ExpenseReminderChannel.inApp;
  var _frequency = ExpenseReminderFrequency.once;
  late DateTime _dueDate = _dateOnly(DateTime.now().add(const Duration(days: 7)));

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ExpenseReminderScope.of(context);
    final activeContext = OperationalContextScope.of(context).context;
    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const GlobalOdometerHeader(section: AppSection.expenses),
          const SizedBox(height: 10),
          RecordFormPanel(
            children: [
              const Text(
                'Expense reminder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep a future or recurring expense visible. You can still change or remove it later.',
              ),
              const SizedBox(height: 12),
              RecordTextField(label: 'Reminder title', controller: _titleController),
              const SizedBox(height: 10),
              RecordDropdownField<String>(
                label: 'Expense category',
                value: _category,
                items: [
                  for (final category in [
                    ...defaultExpenseCategories,
                    ...otherExpenseCategories,
                  ])
                    category.category,
                ],
                itemLabel: (value) => value,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 10),
              _DateRow(date: _dueDate, onPressed: _pickDueDate),
              const SizedBox(height: 10),
              RecordDropdownField<ExpenseReminderFrequency>(
                label: 'Repeat',
                value: _frequency,
                items: ExpenseReminderFrequency.values,
                itemLabel: (value) => value.label,
                onChanged: (value) => setState(() => _frequency = value),
              ),
              const SizedBox(height: 10),
              RecordDropdownField<ExpenseReminderChannel>(
                label: 'Notification preference',
                value: _channel,
                items: ExpenseReminderChannel.values,
                itemLabel: (value) => value.label,
                onChanged: (value) => setState(() => _channel = value),
              ),
              const SizedBox(height: 10),
              RecordTextField(label: 'Notes (optional)', controller: _detailsController),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _save(
                  reminders,
                  activeContext.workProfileId,
                  activeContext.activeVehicleId,
                ),
                icon: const Icon(Icons.notifications_active_rounded),
                label: const Text('Save reminder'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SavedReminderList(
            reminders: reminders,
            workProfileId: activeContext.workProfileId,
            vehicleId: activeContext.activeVehicleId,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = _dateOnly(picked));
  }

  Future<void> _save(
    ExpenseReminderController reminders,
    String workProfileId,
    String vehicleId,
  ) async {
    try {
      await reminders.save(
        ExpenseReminderRecord(
          id: '',
          title: _titleController.text,
          category: _category,
          details: _detailsController.text,
          workProfileId: workProfileId,
          vehicleId: vehicleId,
          dueAt: _dueDate,
          frequency: _frequency,
          channel: _channel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      _titleController.clear();
      _detailsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense reminder saved.')));
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give this reminder a title first.')));
    }
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onPressed});
  final DateTime date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_rounded),
    label: Text('Due ${MaterialLocalizations.of(context).formatMediumDate(date)}'),
  );
}

class _SavedReminderList extends StatelessWidget {
  const _SavedReminderList({
    required this.reminders,
    required this.workProfileId,
    required this.vehicleId,
  });
  final ExpenseReminderController reminders;
  final String workProfileId;
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final entries = reminders.upcomingForScope(
      workProfileId: workProfileId,
      vehicleId: vehicleId,
    );
    if (entries.isEmpty) return const SizedBox.shrink();
    return RecordFormPanel(
      children: [
        const Text(
          'Upcoming reminders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        for (final reminder in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reminder.title),
            subtitle: Text('${reminder.category} · ${reminder.dueLabel(DateTime.now())} · ${reminder.frequency.label}'),
            trailing: IconButton(
              tooltip: 'Delete reminder',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => reminders.remove(reminder.id),
            ),
          ),
      ],
    );
  }
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
