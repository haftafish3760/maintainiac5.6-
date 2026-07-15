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

class _ReceiptReviewStyleSettingsPanel extends StatelessWidget {
  const _ReceiptReviewStyleSettingsPanel({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt Review Style',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose what Maintainiac shows after it reads or imports a receipt.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final style in ExpenseReceiptReviewStyle.values) ...[
            _ReceiptReviewStyleChoice(
              style: style,
              selected: settings.receiptReviewStyle == style,
              onTap: () => settings.setReceiptReviewStyle(style),
            ),
            if (style != ExpenseReceiptReviewStyle.values.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CloudSyncSettingsPanel extends StatelessWidget {
  const _CloudSyncSettingsPanel({required this.settings});

  final ExpenseSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense Backup And Sync',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Every expense saves to this device first. Cloud sync remains queued until an account and connection are available.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _SyncChoice<ExpenseCloudSyncPreference>(
            label: 'When to sync',
            value: settings.cloudSyncPreference,
            values: ExpenseCloudSyncPreference.values,
            itemLabel: (value) => switch (value) {
              ExpenseCloudSyncPreference.manual => 'Only when I sync',
              ExpenseCloudSyncPreference.wifiOnly => 'Automatically on Wi-Fi',
              ExpenseCloudSyncPreference.wifiOrCellular =>
                'Automatically on Wi-Fi or cellular',
            },
            onChanged: settings.setCloudSyncPreference,
          ),
          const SizedBox(height: 10),
          _SyncChoice<ExpenseReceiptCopyRetention>(
            label: 'Receipt copy after verified backup',
            value: settings.receiptCopyRetention,
            values: ExpenseReceiptCopyRetention.values,
            itemLabel: (value) => switch (value) {
              ExpenseReceiptCopyRetention.keepOriginal =>
                'Keep original app copy',
              ExpenseReceiptCopyRetention.keepOptimizedCopy =>
                'Keep smaller readable app copy',
              ExpenseReceiptCopyRetention.cloudOnlyAfterVerifiedUpload =>
                'Remove app copy after verified backup',
            },
            onChanged: settings.setReceiptCopyRetention,
          ),
          const SizedBox(height: 8),
          const Text(
            'These choices never delete gallery photos or any file outside Maintainiac-managed storage.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SyncChoice<T> extends StatelessWidget {
  const _SyncChoice({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final Future<void> Function(T value) onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final choice in values)
        DropdownMenuItem(value: choice, child: Text(itemLabel(choice))),
    ],
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

class _ReceiptReviewStyleChoice extends StatelessWidget {
  const _ReceiptReviewStyleChoice({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final ExpenseReceiptReviewStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? const Color(0xFFFFD166) : const Color(0xFF445159);
    final fill = selected ? const Color(0xFF3A3016) : const Color(0xFF101719);
    return Material(
      color: fill,
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
                      style.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      style.description,
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
