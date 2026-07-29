// Expense work-profile editor screen. This source owner collects profile
// identity only; profile persistence remains in ExpenseWorkProfileController.

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';

class ExpenseWorkProfileEditorScreen extends StatefulWidget {
  const ExpenseWorkProfileEditorScreen({
    super.key,
    required this.initialName,
    required this.isEditing,
  });

  final String initialName;
  final bool isEditing;

  @override
  State<ExpenseWorkProfileEditorScreen> createState() =>
      _ExpenseWorkProfileEditorScreenState();
}

class _ExpenseWorkProfileEditorScreenState
    extends State<ExpenseWorkProfileEditorScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final value = _name.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this work profile a name.')),
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit work profile' : 'New work profile';
    return AppScreenShell(
      section: AppSection.expenses,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            const AppBackButton(),
            const SizedBox(height: 8),
            AppScreenHeader(title: title),
            const SizedBox(height: 14),
            const _ProfilePurposePanel(),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Work profile name',
                hintText: 'Example: Evening delivery',
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(widget.isEditing ? 'Save changes' : 'Create profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePurposePanel extends StatelessWidget {
  const _ProfilePurposePanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF152127),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF36515B)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'Use a separate profile when you need records and recaps kept apart for another employer, business, contract, or type of work. Existing records keep their saved profile identity.',
          style: TextStyle(height: 1.35),
        ),
      ),
    );
  }
}
