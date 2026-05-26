import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/record_form_fields.dart';

class ExpenseReminderScreen extends StatefulWidget {
  const ExpenseReminderScreen({super.key});

  @override
  State<ExpenseReminderScreen> createState() => _ExpenseReminderScreenState();
}

class _ExpenseReminderScreenState extends State<ExpenseReminderScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  var _category = 'Fuel';
  var _channel = 'In-app';

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const AppScreenHeader(title: 'Expense Reminder'),
            const SizedBox(height: 10),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 10),
            RecordFormPanel(
              children: [
                RecordTextField(
                  label: 'Reminder Title Required',
                  controller: _titleController,
                ),
                const SizedBox(height: 10),
                RecordDropdownField<String>(
                  label: 'Expense Category',
                  value: _category,
                  items: const [
                    'Fuel',
                    'Repair',
                    'Insurance',
                    'Loan/Lease',
                    'Parking',
                    'Tolls',
                    'Registration',
                  ],
                  itemLabel: (value) => value,
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 10),
                RecordDropdownField<String>(
                  label: 'Notification',
                  value: _channel,
                  items: const ['In-app', 'Push', 'Sound', 'All'],
                  itemLabel: (value) => value,
                  onChanged: (value) => setState(() => _channel = value),
                ),
                const SizedBox(height: 10),
                RecordTextField(
                  label: 'Details Optional',
                  controller: _detailsController,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Save Reminder Draft'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
