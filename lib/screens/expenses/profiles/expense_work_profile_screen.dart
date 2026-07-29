import 'package:flutter/material.dart';

import '../../../shared/context/operational_context_store.dart';
import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../data/expense_work_profile_store.dart';
import 'expense_work_profile_editor_screen.dart';

class ExpenseWorkProfileScreen extends StatelessWidget {
  const ExpenseWorkProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = ExpenseWorkProfileScope.of(context);
    final active = profiles.activeWorkProfile;
    final archivedProfiles = profiles.allProfiles
        .where((profile) => profile.isArchived)
        .toList(growable: false);
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
              onSelect: () => _selectProfile(context, profile),
              onEdit: profile.isDefault
                  ? null
                  : () => _editProfile(context, existing: profile),
              onDelete: profile.isDefault
                  ? null
                  : () => _deleteProfile(context, profile),
            ),
            const SizedBox(height: 8),
          ],
          if (archivedProfiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Archived profiles',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final profile in archivedProfiles) ...[
              _ArchivedProfileTile(
                profile: profile,
                onRestore: () => _restoreProfile(context, profile),
              ),
              const SizedBox(height: 8),
            ],
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
    final name = await Navigator.of(context).push<String>(
      appNativeRoute<String>(
        context,
        ExpenseWorkProfileEditorScreen(
          initialName: existing?.name ?? '',
          isEditing: existing != null,
        ),
      ),
    );
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
    if (!context.mounted) return;
    if (existing == null) {
      await _selectProfile(context, saved);
      return;
    }
    if (profiles.activeWorkProfile.id == saved.id) {
      await _syncOperationalContext(context, saved);
    }
  }

  Future<void> _selectProfile(
    BuildContext context,
    ExpenseWorkProfile profile,
  ) async {
    final profiles = ExpenseWorkProfileScope.of(context);
    await profiles.select(profile.id);
    if (!context.mounted) return;
    await _syncOperationalContext(context, profile);
  }

  Future<void> _syncOperationalContext(
    BuildContext context,
    ExpenseWorkProfile profile,
  ) async {
    final operational = OperationalContextScope.maybeOf(context);
    if (operational == null) return;
    await operational.setActiveWorkProfile(
      workProfileId: profile.id,
      workProfileName: profile.name,
    );
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
    final profiles = ExpenseWorkProfileScope.of(context);
    await profiles.delete(profile.id);
    if (!context.mounted) return;
    final active = profiles.activeWorkProfile;
    final operational = OperationalContextScope.maybeOf(context);
    if (operational == null) return;
    await operational.setActiveWorkProfile(
      workProfileId: active.id,
      workProfileName: active.name,
    );
  }

  Future<void> _restoreProfile(
    BuildContext context,
    ExpenseWorkProfile profile,
  ) async {
    await ExpenseWorkProfileScope.of(context).restore(profile.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('“${profile.name}” is available for new expenses.'),
      ),
    );
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

class _ArchivedProfileTile extends StatelessWidget {
  const _ArchivedProfileTile({required this.profile, required this.onRestore});

  final ExpenseWorkProfile profile;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF36515B)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.archive_outlined, color: Color(0xFF9AAAB1)),
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
                    'Existing expenses keep this profile',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRestore, child: const Text('Restore')),
          ],
        ),
      ),
    );
  }
}
