import 'package:flutter/material.dart';

import 'categories/expense_categories.dart';
import '../../shared/state/expense_settings_store.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/industrial_panel_surface.dart';

class ExpenseSettingsScreen extends StatefulWidget {
  const ExpenseSettingsScreen({super.key});

  @override
  State<ExpenseSettingsScreen> createState() => _ExpenseSettingsScreenState();
}

class _ExpenseSettingsScreenState extends State<ExpenseSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ExpenseSettingsScope.of(context);
    return AppScreenShell(
      section: AppSection.expenses,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        children: [
          const GlobalOdometerHeader(section: AppSection.expenses),
          const SizedBox(height: 10),
          const _SettingsIntro(),
          const SizedBox(height: 12),
          _TopThreeSettingsPanel(
            autoTrackTopThree: settings.autoTrackTopThree,
            onAutoTrackChanged: settings.setAutoTrackTopThree,
          ),
          const SizedBox(height: 12),
          _CategorySettingsSection(
            title: 'Quick Expense Buttons',
            categories: defaultExpenseCategories,
            active: true,
            onCategoryPressed: _showCategorySettings,
          ),
          const SizedBox(height: 12),
          _CategorySettingsSection(
            title: 'Other Categories',
            categories: otherExpenseCategories,
            active: false,
            onCategoryPressed: _showCategorySettings,
          ),
          const SizedBox(height: 12),
          _SettingsSwitchPanel(
            title: 'Category Automation',
            rows: [
              _SettingsSwitchRowData(
                label: 'Automatically update the 12 quick expense buttons',
                value: settings.autoTrackQuickCategories,
                onChanged: settings.setAutoTrackQuickCategories,
              ),
              _SettingsCommandRowData(
                label: 'Reset expense categories to default',
                onPressed: () => _resetCategoryLayout(settings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSwitchPanel(
            title: 'Receipts And OCR',
            rows: [
              _SettingsSwitchRowData(
                label: 'Confirm OCR totals before posting',
                value: settings.confirmOcrTotals,
                onChanged: settings.setConfirmOcrTotals,
              ),
              _SettingsSwitchRowData(
                label: 'Allow multiple photos per receipt',
                value: settings.allowMultipleReceiptPhotos,
                onChanged: settings.setAllowMultipleReceiptPhotos,
              ),
              _SettingsSwitchRowData(
                label: 'Save optimized receipt image copy',
                value: settings.saveOptimizedReceiptCopy,
                onChanged: settings.setSaveOptimizedReceiptCopy,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsSwitchPanel(
            title: 'Reminder Notifications',
            rows: [
              _SettingsSwitchRowData(
                label: 'In-app notifications',
                value: settings.inAppNotifications,
                onChanged: settings.setInAppNotifications,
              ),
              _SettingsSwitchRowData(
                label: 'Push notifications',
                value: settings.pushNotifications,
                onChanged: settings.setPushNotifications,
              ),
              _SettingsSwitchRowData(
                label: 'Audible notifications',
                value: settings.audibleNotifications,
                onChanged: settings.setAudibleNotifications,
              ),
              _SettingsSwitchRowData(
                label: 'Remind me about unfinished drafts',
                value: settings.draftReminder,
                onChanged: settings.setDraftReminder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategorySettings(ExpenseCategoryDefinition category, bool active) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2E3A40),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingsActionButton(
                  label: active
                      ? 'Remove from quick buttons'
                      : 'Add to quick buttons',
                  icon: active ? Icons.remove_rounded : Icons.add_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _SettingsActionButton(
                  label: 'Use in Top Three',
                  icon: Icons.vertical_align_top_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _SettingsActionButton(
                  label: 'Edit category',
                  icon: Icons.edit_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetCategoryLayout(ExpenseSettingsController settings) {
    settings.resetCategoryLayout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense category layout reset to the release defaults.'),
      ),
    );
  }
}

class _TopThreeSettingsPanel extends StatelessWidget {
  const _TopThreeSettingsPanel({
    required this.autoTrackTopThree,
    required this.onAutoTrackChanged,
  });

  final bool autoTrackTopThree;
  final ValueChanged<bool> onAutoTrackChanged;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Top Three',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const _SettingsTopThreeStrip(),
          const SizedBox(height: 10),
          _AutoTopThreeToggleCopy(
            value: autoTrackTopThree,
            onChanged: onAutoTrackChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsTopThreeStrip extends StatelessWidget {
  const _SettingsTopThreeStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _SettingsTopThreeCard(
            label: 'Fuel',
            business: r'$0.00',
            personal: r'$0.00',
            color: Color(0xFF1E9AD6),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _SettingsTopThreeCard(
            label: 'Food',
            business: r'$0.00',
            personal: r'$0.00',
            color: Color(0xFFE05C3F),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _SettingsTopThreeCard(
            label: 'Materials',
            business: r'$0.00',
            personal: r'$0.00',
            color: Color(0xFF398862),
          ),
        ),
      ],
    );
  }
}

class _SettingsTopThreeCard extends StatelessWidget {
  const _SettingsTopThreeCard({
    required this.label,
    required this.business,
    required this.personal,
    required this.color,
  });

  final String label;
  final String business;
  final String personal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _SettingsTopThreeLine(label: 'Business', value: business),
          const SizedBox(height: 4),
          _SettingsTopThreeLine(label: 'Personal', value: personal),
        ],
      ),
    );
  }
}

class _SettingsTopThreeLine extends StatelessWidget {
  const _SettingsTopThreeLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AutoTopThreeToggleCopy extends StatelessWidget {
  const _AutoTopThreeToggleCopy({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF66737A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD166)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Allow Maintainiac to automatically track your top three expense categories.',
              style: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Set up the expense command center. The top three cards, quick buttons, and other categories here use the same category list as the add-expense button.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE8ECEE),
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _CategorySettingsSection extends StatelessWidget {
  const _CategorySettingsSection({
    required this.title,
    required this.categories,
    required this.active,
    required this.onCategoryPressed,
  });

  final String title;
  final List<ExpenseCategoryDefinition> categories;
  final bool active;
  final void Function(ExpenseCategoryDefinition category, bool active)
  onCategoryPressed;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520 ? 5 : 4;
          final tileWidth =
              (constraints.maxWidth - ((columns - 1) * 8)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              for (final category in categories)
                SizedBox(
                  width: tileWidth,
                  child: _SettingsIconTile(
                    category: category,
                    active: active,
                    onPressed: () => onCategoryPressed(category, active),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsIconTile extends StatelessWidget {
  const _SettingsIconTile({
    required this.category,
    required this.active,
    required this.onPressed,
  });

  final ExpenseCategoryDefinition category;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: category.gradient,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: category.gradient.last.withValues(alpha: .48),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                      const BoxShadow(
                        color: Color(0xAA000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _categoryInitials(category.label),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFD32222)
                          : const Color(0xFF28A745),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFE8ECEE),
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryInitials(String label) {
    final words = label
        .split(RegExp(r'[\s/&-]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return words.take(2).map((word) => word.characters.first).join();
  }
}

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
