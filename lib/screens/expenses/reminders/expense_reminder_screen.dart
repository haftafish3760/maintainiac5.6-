import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../categories/expense_categories.dart';
import '../data/expense_reminder_draft.dart';
import '../data/expense_reminder_store.dart';
import '../../../shared/records/maintainiac_record_lifecycle.dart';
import '../../../shared/state/expense_settings_store.dart';

class ExpenseReminderScreen extends StatefulWidget {
  const ExpenseReminderScreen({super.key, this.initialReminderId});

  final String? initialReminderId;

  @override
  State<ExpenseReminderScreen> createState() => _ExpenseReminderScreenState();
}

class _ExpenseReminderScreenState extends State<ExpenseReminderScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  late final List<String> _categories;
  var _category = 'Fuel';
  var _channel = 'In-app';
  var _cadence = ExpenseReminderCadence.once;
  var _dueAt = DateTime.now().add(const Duration(days: 30));
  ExpenseReminderRecord? _editingReminder;
  MaintainiacRecordDraftStore? _draftStore;
  Timer? _draftTimer;
  var _restoringDraft = false;
  var _draftFailureShown = false;
  var _openedInitialReminder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _categories = {
      for (final category in [
        ...defaultExpenseCategories,
        ...otherExpenseCategories,
      ])
        category.category,
    }.toList()..sort();
    if (!_categories.contains(_category)) _category = _categories.first;
    _titleController.addListener(_scheduleDraftSave);
    _detailsController.addListener(_scheduleDraftSave);
    unawaited(_openDraftStore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.initialReminderId?.trim() ?? '';
    if (_openedInitialReminder || id.isEmpty) return;
    _openedInitialReminder = true;
    final reminder = ExpenseReminderScope.of(context).recordById(id);
    if (reminder != null && !reminder.isDeleted) _beginEditing(reminder);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    unawaited(_saveDraftNow());
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _draftTimer?.cancel();
      unawaited(_saveDraftNow());
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ExpenseReminderScope.of(context).records;
    final settings = ExpenseSettingsScope.of(context);
    final categories = {
      ..._categories,
      ...settings.customCategoryNames,
      _category,
    }.toList()..sort();
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
            _buildReminderForm(context, categories),
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
                  onEnabledChanged: (value) =>
                      _setReminderActive(reminder, value),
                  onDelete: () => _removeReminder(reminder),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderForm(BuildContext context, List<String> categories) {
    return RecordFormPanel(
      children: [
        RecordTextField(label: 'Reminder title', controller: _titleController),
        const SizedBox(height: 10),
        RecordDropdownField<String>(
          label: 'Expense category',
          value: _category,
          items: categories,
          itemLabel: (value) => value,
          onChanged: (value) => setState(() {
            _category = value;
            _scheduleDraftSave();
          }),
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
          onChanged: (value) => setState(() {
            _cadence = value;
            _scheduleDraftSave();
          }),
        ),
        const SizedBox(height: 10),
        RecordDropdownField<String>(
          label: 'Delivery preference',
          value: _channel,
          items: const ['In-app', 'Push', 'Sound', 'All'],
          itemLabel: (value) => value,
          onChanged: (value) => setState(() {
            _channel = value;
            _scheduleDraftSave();
          }),
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
    setState(() {
      _dueAt = date;
      _scheduleDraftSave();
    });
  }

  Future<void> _saveReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this reminder a title first.')),
      );
      return;
    }
    final saved = await _saveReminderLocally(title);
    if (saved == null) return;
    await _clearDraftAfterConfirmedSave(saved.id);
    if (!mounted) return;
    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense reminder saved on this device.')),
    );
  }

  Future<void> _removeReminder(ExpenseReminderRecord reminder) async {
    final controller = ExpenseReminderScope.of(context);
    try {
      await controller.delete(reminder.id);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder removed. It can be restored.'),
        action: SnackBarAction(
          label: 'Restore',
          onPressed: () => _restoreReminder(controller, reminder.id),
        ),
      ),
    );
  }

  Future<void> _setReminderActive(
    ExpenseReminderRecord reminder,
    bool active,
  ) async {
    try {
      await ExpenseReminderScope.of(context).setActive(reminder, active);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  Future<void> _restoreReminder(
    ExpenseReminderController controller,
    String reminderId,
  ) async {
    try {
      await controller.restore(reminderId);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  Future<ExpenseReminderRecord?> _saveReminderLocally(String title) async {
    try {
      return await ExpenseReminderScope.of(context).save(
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
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
      return null;
    }
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
    unawaited(_restoreEditingDraft(reminder));
  }

  void _clearForm() {
    final draftId = _draftId;
    setState(() {
      _editingReminder = null;
      _titleController.clear();
      _detailsController.clear();
      _category = _categories.contains('Fuel') ? 'Fuel' : _categories.first;
      _channel = 'In-app';
      _cadence = ExpenseReminderCadence.once;
      _dueAt = DateTime.now().add(const Duration(days: 30));
    });
    final store = _draftStore;
    if (store != null) unawaited(ExpenseReminderDraft.clear(store, draftId));
  }

  Future<void> _clearDraftAfterConfirmedSave(String savedReminderId) async {
    final store = _draftStore;
    if (store == null) return;
    try {
      await ExpenseReminderDraft.clear(store, _draftId);
      if (_editingReminder != null) {
        await ExpenseReminderDraft.clear(
          store,
          ExpenseReminderDraft.idForEditing(savedReminderId),
        );
      }
    } catch (_) {
      // The confirmed local reminder remains authoritative. A stale checkpoint
      // is safer than turning a successful save into an apparent failure.
    }
  }

  String get _draftId => _editingReminder == null
      ? ExpenseReminderDraft.newReminderId
      : ExpenseReminderDraft.idForEditing(_editingReminder!.id);

  Future<void> _openDraftStore() async {
    final store = await MaintainiacRecordDraftStore.create();
    if (!mounted) return;
    _draftStore = store;
    if (_hasCurrentFormContent) {
      _scheduleDraftSave();
      return;
    }
    _applyDraft(
      ExpenseReminderDraft.load(store, ExpenseReminderDraft.newReminderId),
    );
  }

  Future<void> _restoreEditingDraft(ExpenseReminderRecord reminder) async {
    final store = _draftStore;
    if (store == null) return;
    _applyDraft(
      ExpenseReminderDraft.load(
        store,
        ExpenseReminderDraft.idForEditing(reminder.id),
      ),
    );
  }

  void _applyDraft(ExpenseReminderDraft? draft) {
    if (draft == null || !mounted) return;
    _restoringDraft = true;
    setState(() {
      _titleController.text = draft.title;
      _detailsController.text = draft.details;
      _category = _categories.contains(draft.category)
          ? draft.category
          : _category;
      _channel =
          const ['In-app', 'Push', 'Sound', 'All'].contains(draft.channel)
          ? draft.channel
          : _channel;
      _cadence = draft.cadence;
      _dueAt = draft.dueAt;
    });
    _restoringDraft = false;
  }

  void _scheduleDraftSave() {
    if (_restoringDraft) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 200), _saveDraftNow);
  }

  bool get _hasCurrentFormContent =>
      _titleController.text.trim().isNotEmpty ||
      _detailsController.text.trim().isNotEmpty ||
      _editingReminder != null;

  Future<void> _saveDraftNow() async {
    if (_restoringDraft) return;
    final store = _draftStore;
    if (store == null) return;
    try {
      await ExpenseReminderDraft(
        id: _draftId,
        title: _titleController.text,
        category: _category,
        channel: _channel,
        cadence: _cadence,
        dueAt: _dueAt,
        details: _detailsController.text,
        editingReminderId: _editingReminder?.id,
      ).save(store);
      _draftFailureShown = false;
    } on StateError catch (error) {
      if (!mounted || _draftFailureShown) return;
      _draftFailureShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
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
