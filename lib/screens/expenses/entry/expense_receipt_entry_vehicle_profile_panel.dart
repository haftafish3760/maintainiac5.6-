part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryVehicleProfile
    on _ExpenseReceiptEntryScreenState {
  Widget _buildVehicleProfilePanel(BuildContext context) {
    final profiles = ExpenseVehicleProfileScope.of(context);
    final selected = profiles.profileById(_expenseContext.vehicleId);
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
            const Icon(Icons.directions_car_outlined, color: Color(0xFFB7C8CE)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vehicle profile',
                    style: TextStyle(
                      color: Color(0xFFF2F7F8),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.displayName ?? _expenseContext.vehicleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB7C8CE)),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _chooseVehicleProfile(context, profiles),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseVehicleProfile(
    BuildContext context,
    ExpenseVehicleProfileController profiles,
  ) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Use a vehicle profile'),
              subtitle: Text(
                'This receipt keeps the selected vehicle context.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create vehicle profile'),
              onTap: () => Navigator.of(sheetContext).pop('_create_vehicle_'),
            ),
            for (final profile in profiles.activeProfiles)
              ListTile(
                leading: const Icon(Icons.directions_car_outlined),
                title: Text(profile.displayName),
                trailing: profile.id == _expenseContext.vehicleId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(profile.id),
              ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    if (!context.mounted) return;
    final profile = selection == '_create_vehicle_'
        ? await _createVehicleProfile(context, profiles)
        : profiles.profileById(selection);
    if (!context.mounted) return;
    if (profile == null) return;
    await OperationalContextScope.of(context).setActiveVehicle(
      vehicleId: profile.id,
      vehicleLabel: profile.nickname,
      usage: profile.usage,
    );
    if (!mounted) return;
    _setReceiptEntryState(() {
      _expenseContext = ExpenseReceiptContextSnapshot(
        workProfileId: _expenseContext.workProfileId,
        workProfileName: _expenseContext.workProfileName,
        vehicleId: profile.id,
        vehicleLabel: profile.nickname,
        jobId: _expenseContext.jobId,
        jobLabel: _expenseContext.jobLabel,
      );
    });
    _scheduleDraftSave();
  }

  Future<ExpenseVehicleProfileRecord?> _createVehicleProfile(
    BuildContext context,
    ExpenseVehicleProfileController profiles,
  ) async {
    final name = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create vehicle profile'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Vehicle name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(name.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    name.dispose();
    if (result == null || result.trim().isEmpty) return null;
    final now = DateTime.now();
    return profiles.save(
      ExpenseVehicleProfileRecord(
        id: '',
        nickname: result,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
