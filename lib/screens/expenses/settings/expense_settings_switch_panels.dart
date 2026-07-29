part of 'expense_settings_screen.dart';

class _SettingsSwitchPanel extends StatelessWidget {
  const _SettingsSwitchPanel({required this.title, required this.rows});

  final String title;
  final List<_SettingsPanelRowData> rows;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final row in rows) _SettingsPanelRow(row: row),
        ],
      ),
    );
  }
}

class _BackupSyncModeSettingsPanel extends StatelessWidget {
  const _BackupSyncModeSettingsPanel({
    required this.settings,
    required this.onBackupNow,
  });

  final ExpenseSettingsController settings;
  final Future<void> Function() onBackupNow;

  @override
  Widget build(BuildContext context) {
    final mode = settings.backupSyncMode;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense Cloud Backup',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Receipt records always save on this device first. Choose when an enabled cloud backup may upload.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _BackupSyncModeChoice(
            title: 'Manual backup',
            detail: 'Only upload when you tap Back Up Now.',
            selected: mode == ExpenseBackupSyncMode.manual,
            onTap: () =>
                settings.setBackupSyncMode(ExpenseBackupSyncMode.manual),
          ),
          const SizedBox(height: 8),
          _BackupSyncModeChoice(
            title: 'Back up after each saved change',
            detail:
                'Upload after a saved Expense change when cloud backup is enabled.',
            selected: mode == ExpenseBackupSyncMode.immediate,
            onTap: () =>
                settings.setBackupSyncMode(ExpenseBackupSyncMode.immediate),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onBackupNow,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Back Up Now'),
          ),
        ],
      ),
    );
  }
}

class _BackupSyncModeChoice extends StatelessWidget {
  const _BackupSyncModeChoice({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFFFD166) : const Color(0xFF445159);
    return Material(
      color: selected ? const Color(0xFF3A3016) : const Color(0xFF101719),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFFD166)
                    : const Color(0xFFC8D0D3),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

sealed class _SettingsPanelRowData {
  const _SettingsPanelRowData(this.label);

  final String label;
}

class _SettingsSwitchRowData extends _SettingsPanelRowData {
  const _SettingsSwitchRowData({
    required String label,
    required this.value,
    required this.onChanged,
  }) : super(label);

  final bool value;
  final ValueChanged<bool> onChanged;
}

class _SettingsCommandRowData extends _SettingsPanelRowData {
  const _SettingsCommandRowData({
    required String label,
    required this.onPressed,
  }) : super(label);

  final VoidCallback onPressed;
}

class _SettingsPanelRow extends StatelessWidget {
  const _SettingsPanelRow({required this.row});

  final _SettingsPanelRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Color(0xFFFFD166), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          switch (row) {
            _SettingsSwitchRowData(:final value, :final onChanged) =>
              Switch.adaptive(value: value, onChanged: onChanged),
            _SettingsCommandRowData(:final onPressed) => IconButton(
              onPressed: onPressed,
              tooltip: row.label,
              icon: const Icon(
                Icons.restart_alt_rounded,
                color: Color(0xFFE8ECEE),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1976B9),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }
}

List<ExpenseCategoryDefinition> _quickCategoriesFromSettings(
  ExpenseSettingsController settings,
) {
  final saved = settings.quickCategoryOrder;
  if (saved.isEmpty) {
    return defaultExpenseCategories.take(6).toList(growable: false);
  }
  final output = <ExpenseCategoryDefinition>[];
  for (final categoryName in saved) {
    final match = _categoryByName(categoryName);
    if (match != null &&
        !output.any((item) => _sameCategory(item.category, match.category))) {
      output.add(match);
    }
  }
  return output.isEmpty
      ? defaultExpenseCategories.take(6).toList(growable: false)
      : output;
}

List<ExpenseCategoryDefinition> _topThreeFromSettings(
  ExpenseSettingsController settings,
) {
  final output = <ExpenseCategoryDefinition>[];
  for (final categoryName in settings.topThreeCategories) {
    final match = _categoryByName(categoryName);
    if (match != null &&
        !output.any((item) => _sameCategory(item.category, match.category))) {
      output.add(match);
    }
  }
  if (output.isEmpty) {
    return defaultExpenseCategories.take(3).toList(growable: false);
  }
  return output;
}

List<ExpenseCategoryDefinition> _categoriesNotIn(
  List<ExpenseCategoryDefinition> active,
) {
  return _allExpenseCategories
      .where(
        (category) => !active.any(
          (item) => _sameCategory(item.category, category.category),
        ),
      )
      .toList(growable: false);
}

ExpenseCategoryDefinition? _categoryByName(String categoryName) {
  for (final category in _allExpenseCategories) {
    if (_sameCategory(category.category, categoryName)) return category;
  }
  return null;
}
