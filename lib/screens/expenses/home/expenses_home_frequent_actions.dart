part of 'expenses_home_screen.dart';

class _FrequentActionsPanel extends StatelessWidget {
  const _FrequentActionsPanel({required this.period, required this.anchorDate});

  final _ExpenseViewPeriod period;
  final DateTime anchorDate;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final settings = ExpenseSettingsScope.of(context);
    final range = period.rangeFor(anchorDate);
    final categories = settings.autoTrackQuickCategories
        ? _topExpenseCategories(ledger, range)
        : _quickCategoriesFromSettings(settings);
    final detail = settings.autoTrackQuickCategories
        ? 'Showing the top 10 categories for this period. Tap one to review matching entries.'
        : 'Showing your 10 home categories. Tap one to review matching entries.';
    return _SolidSection(
      backgroundColor: _coolPanel,
      borderColor: const Color(0xFF295E73),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            eyebrow: 'CATEGORY TOTALS',
            title: 'Expense categories',
            detail: detail,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.end,
            children: [
              _SmallTextButton(
                label: 'Other Categories',
                icon: Icons.grid_view_rounded,
                onTap: () => _showOtherCategories(context),
              ),
              _SmallTextButton(
                label: 'Edit Home Buttons',
                icon: Icons.edit_rounded,
                onTap: () => _showQuickActionSettings(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 360 ? 2 : 3;
              final spacing = 8.0;
              final width =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    SizedBox(
                      width: width,
                      child: _QuickExpenseTile(
                        category: category,
                        range: range,
                        periodLabel: period.buttonLabel,
                        initialDate: anchorDate,
                        onTap: () {
                          _showCategoryEntries(
                            context,
                            category,
                            range,
                            period.rangeLabel(anchorDate),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
