part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryWorkProfile on _ExpenseReceiptEntryScreenState {
  Widget _buildWorkProfilePanel(BuildContext context) {
    final profilesController = ExpenseWorkProfileScope.of(context);
    final active = profilesController.profileById(
      _expenseContext.workProfileId,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF293135),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3C494E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Color(0xFFB7C8CE)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work profile',
                    style: TextStyle(
                      color: Color(0xFFF2F7F8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    active?.name ?? _expenseContext.workProfileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB7C8CE)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _chooseWorkProfile(context, profilesController),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseWorkProfile(
    BuildContext context,
    ExpenseWorkProfileController profiles,
  ) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Use a work profile'),
              subtitle: Text(
                'New expenses keep this profile as their context.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create work profile'),
              onTap: () => Navigator.of(sheetContext).pop('_create_work_'),
            ),
            for (final profile in profiles.activeProfiles)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(profile.name),
                trailing: profile.id == _expenseContext.workProfileId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(profile.id),
              ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    final profile = selection == '_create_work_'
        ? await _createWorkProfile(context, profiles)
        : profiles.profileById(selection);
    if (profile == null) return;
    await OperationalContextScope.of(
      context,
    ).setWorkProfile(workProfileId: profile.id, workProfileName: profile.name);
    AppStateScope.of(context).setWorkProfile(profile.name);
    if (!mounted) return;
    _setReceiptEntryState(() {
      _expenseContext = ExpenseReceiptContextSnapshot(
        workProfileId: profile.id,
        workProfileName: profile.name,
        vehicleId: _expenseContext.vehicleId,
        vehicleLabel: _expenseContext.vehicleLabel,
      );
    });
    _scheduleDraftSave();
  }

  Future<ExpenseWorkProfileRecord?> _createWorkProfile(
    BuildContext context,
    ExpenseWorkProfileController profiles,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create work profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return null;
    final now = DateTime.now();
    return profiles.save(
      ExpenseWorkProfileRecord(
        id: '',
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
