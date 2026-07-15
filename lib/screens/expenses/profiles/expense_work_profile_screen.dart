import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/expense_work_profile_store.dart';

class ExpenseWorkProfileScreen extends StatelessWidget {
  const ExpenseWorkProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = ExpenseWorkProfileScope.of(context);
    final active = profiles.activeWorkProfile;
    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Work profiles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add work profile',
                onPressed: () => _editProfile(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _ProfileExplanation(),
          const SizedBox(height: 14),
          for (final profile in profiles.profiles) ...[
            _ProfileTile(
              profile: profile,
              selected: profile.id == active.id,
              onSelect: () => profiles.select(profile.id),
              onEdit: profile.isDefault
                  ? null
                  : () => _editProfile(context, existing: profile),
              onDelete: profile.isDefault
                  ? null
                  : () => _deleteProfile(context, profile),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add work profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context, {
    ExpenseWorkProfile? existing,
  }) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'New work profile' : 'Rename work profile',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use profiles only when you want expenses separated by job, contract, or work line. The default works without any setup.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Profile name',
                hintText: 'Example: Evening delivery',
              ),
              onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;
    final profiles = ExpenseWorkProfileScope.of(context);
    final saved = await profiles.save(
      ExpenseWorkProfile(
        id: existing?.id ?? '',
        name: trimmed,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: existing?.updatedAt ?? DateTime.now(),
      ),
    );
    if (existing == null) await profiles.select(saved.id);
  }

  Future<void> _deleteProfile(
    BuildContext context,
    ExpenseWorkProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete work profile?'),
        content: Text(
          '“${profile.name}” will no longer be available for new expenses. Existing expenses keep their saved profile ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ExpenseWorkProfileScope.of(context).delete(profile.id);
  }
}

class _ProfileExplanation extends StatelessWidget {
  const _ProfileExplanation();

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.work_outline_rounded, color: Color(0xFF82D2FF)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Maintainiac always includes a default profile. Create more only if you want separate expense records and recaps for different work.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onSelect,
    this.onEdit,
    this.onDelete,
  });

  final ExpenseWorkProfile profile;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF173542) : const Color(0xFF11181C),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.work_outline_rounded,
                color: selected ? const Color(0xFF82D2FF) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      profile.isDefault
                          ? 'Always available'
                          : selected
                          ? 'Active for new expenses'
                          : 'Tap to make active',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Rename',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
