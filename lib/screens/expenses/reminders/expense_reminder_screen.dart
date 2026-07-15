import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../categories/expense_categories.dart';
import '../data/expense_reminder_store.dart';

class ExpenseReminderScreen extends StatefulWidget {
  const ExpenseReminderScreen({super.key});

  @override
  State<ExpenseReminderScreen> createState() => _ExpenseReminderScreenState();
}

class _ExpenseReminderScreenState extends State<ExpenseReminderScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  late final List<String> _categories;
  var _category = 'Fuel';
  var _channel = 'In-app';
  var _cadence = ExpenseReminderCadence.once;
  var _dueAt = DateTime.now().add(const Duration(days: 30));
  ExpenseReminderRecord? _editingReminder;

  @override
  void initState() {
    super.initState();
    _categories = {
      for (final category in [
        ...defaultExpenseCategories,
        ...otherExpenseCategories,
      ])
        category.category,
    }.toList()..sort();
    if (!_categories.contains(_category)) _category = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ExpenseReminderScope.of(context).records;
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const AppScreenHeader(title: 'Expense reminders'),
            const SizedBox(height: 10),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 10),
            _buildReminderForm(context),
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Saved reminders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final reminder in reminders)
                _ReminderCard(
                  reminder: reminder,
                  onEdit: () => _beginEditing(reminder),
                  onEnabledChanged: (value) => ExpenseReminderScope.of(
                    context,
                  ).setActive(reminder, value),
                  onDelete: () =>
                      ExpenseReminderScope.of(context).delete(reminder.id),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderForm(BuildContext context) {
    return RecordFormPanel(
      children: [
        RecordTextField(label: 'Reminder title', controller: _titleController),
        const SizedBox(height: 10),
        RecordDropdownField<String>(
          label: 'Expense category',
          value: _category,
          items: _categories,
          itemLabel: (value) => value,
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('First due date'),
          subtitle: Text(_formatDate(_dueAt)),
          trailing: const Icon(Icons.calendar_month_rounded),
          onTap: _pickDueDate,
        ),
        const SizedBox(height: 10),
        RecordDropdownField<ExpenseReminderCadence>(
          label: 'Repeat',
          value: _cadence,
          items: ExpenseReminderCadence.values,
          itemLabel: (value) => value.label,
          onChanged: (value) => setState(() => _cadence = value),
        ),
        const SizedBox(height: 10),
        RecordDropdownField<String>(
          label: 'Delivery preference',
          value: _channel,
          items: const ['In-app', 'Push', 'Sound', 'All'],
          itemLabel: (value) => value,
          onChanged: (value) => setState(() => _channel = value),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Details optional',
          controller: _detailsController,
        ),
        const SizedBox(height: 8),
        Text(
          'This saves the reminder on this device. Push or sound delivery only works after those app-wide notification permissions are enabled.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_editingReminder != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _clearForm,
              child: const Text('Cancel editing'),
            ),
          ),
        FilledButton.icon(
          onPressed: _saveReminder,
          icon: const Icon(Icons.notifications_active_rounded),
          label: Text(
            _editingReminder == null ? 'Save reminder' : 'Update reminder',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    setState(() => _dueAt = date);
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this reminder a title first.')),
      );
      return;
    }
    await ExpenseReminderScope.of(context).save(
      ExpenseReminderRecord(
        id: _editingReminder?.id ?? '',
        title: title,
        category: _category,
        channel: _channel,
        dueAt: _dueAt,
        cadence: _cadence,
        details: _detailsController.text,
        createdAt: _editingReminder?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense reminder saved on this device.')),
    );
  }

  static String _formatDate(DateTime value) {
    return '${value.month}/${value.day}/${value.year}';
  }

  void _beginEditing(ExpenseReminderRecord reminder) {
    setState(() {
      _editingReminder = reminder;
      _titleController.text = reminder.title;
      _detailsController.text = reminder.details;
      _category = reminder.category;
      _channel = reminder.channel;
      _cadence = reminder.cadence;
      _dueAt = reminder.dueAt;
    });
  }

  void _clearForm() {
    setState(() {
      _editingReminder = null;
      _titleController.clear();
      _detailsController.clear();
      _category = _categories.contains('Fuel') ? 'Fuel' : _categories.first;
      _channel = 'In-app';
      _cadence = ExpenseReminderCadence.once;
      _dueAt = DateTime.now().add(const Duration(days: 30));
    });
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final ExpenseReminderRecord reminder;
  final VoidCallback onEdit;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final due = reminder.nextOccurrenceAfter(DateTime.now());
    return Card(
      child: ListTile(
        onTap: onEdit,
        title: Text(reminder.title),
        subtitle: Text(
          '${reminder.category} • Next ${due.month}/${due.day}/${due.year} • ${reminder.cadence.label}',
        ),
        leading: Switch(value: reminder.active, onChanged: onEnabledChanged),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit reminder',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete reminder',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
