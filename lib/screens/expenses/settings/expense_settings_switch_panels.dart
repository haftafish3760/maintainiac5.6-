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
