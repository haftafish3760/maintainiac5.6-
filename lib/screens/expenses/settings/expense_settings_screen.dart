import 'package:flutter/material.dart';

import '../categories/expense_categories.dart';
import '../reports/expense_recap_models.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';

part 'expense_top_three_settings.dart';
part 'expense_category_settings_sections.dart';
part 'expense_settings_switch_panels.dart';
part 'expense_recap_tile_settings.dart';
part 'expense_settings_helpers.dart';

class ExpenseSettingsScreen extends StatefulWidget {
  const ExpenseSettingsScreen({super.key});

  @override
  State<ExpenseSettingsScreen> createState() => _ExpenseSettingsScreenState();
}

class _ExpenseSettingsScreenState extends State<ExpenseSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ExpenseSettingsScope.of(context);
    final quickCategories = _quickCategoriesFromSettings(settings);
    final otherCategories = _categoriesNotIn(quickCategories);
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
            categories: _topThreeFromSettings(settings),
            autoTrackTopThree: settings.autoTrackTopThree,
            onAutoTrackChanged: settings.setAutoTrackTopThree,
          ),
          const SizedBox(height: 12),
          _CategorySettingsSection(
            title: 'Quick Expense Buttons',
            categories: quickCategories,
            active: true,
            onCategoryPressed: _showCategorySettings,
          ),
          const SizedBox(height: 12),
          _CategorySettingsSection(
            title: 'Other Categories',
            categories: otherCategories,
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
          _RecapTileSettingsPanel(settings: settings),
          const SizedBox(height: 12),
          _ReceiptReviewStyleSettingsPanel(settings: settings),
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
    final settings = ExpenseSettingsScope.of(context);
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
                  onPressed: () {
                    if (active) {
                      settings.removeQuickCategory(category.category);
                    } else {
                      settings.addQuickCategory(category.category);
                    }
                    Navigator.of(context).pop();
                  },
                ),
                _SettingsActionButton(
                  label: 'Use in Top Three',
                  icon: Icons.vertical_align_top_rounded,
                  onPressed: () {
                    settings.useCategoryInTopThree(category.category);
                    Navigator.of(context).pop();
                  },
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
