part of 'expenses_home_screen.dart';

class _ExpenseCategoryEntriesScreen extends StatelessWidget {
  const _ExpenseCategoryEntriesScreen({
    required this.category,
    required this.range,
    required this.rangeLabel,
  });

  final ExpenseCategoryDefinition category;
  final ExpenseDateRange range;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final entries = _categoryEntriesForRange(context, category, range);
    final title = _categoryExpenseTitle(category);
    return AppScreenShell(
      section: AppSection.expenses,
      floatingActionButton: _CategoryExpenseFab(
        category: category,
        initialDate: range.end,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
        children: [
          AppScreenHeader(title: title),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(section: AppSection.expenses),
          const SizedBox(height: 8),
          _SolidSection(
            backgroundColor: _coolPanel,
            borderColor: const Color(0xFF295E73),
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: _SectionHeader(
              eyebrow: 'CATEGORY RECORDS',
              title: title,
              detail: '$rangeLabel | ${_expenseScopeLabel(context)}',
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            _EmptyLedgerMessage(
              actionLabel: 'Add $title',
              onAction: () =>
                  _openCategory(context, category, initialDate: range.end),
            )
          else
            for (final entry in entries) _LedgerRow(entry: entry),
        ],
      ),
    );
  }
}

class _CategoryExpenseFab extends StatelessWidget {
  const _CategoryExpenseFab({
    required this.category,
    required this.initialDate,
  });

  final ExpenseCategoryDefinition category;
  final DateTime initialDate;

  @override
  Widget build(BuildContext context) {
    final title = _categoryExpenseTitle(category);
    return FloatingActionButton.extended(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      onPressed: () =>
          _openCategory(context, category, initialDate: initialDate),
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add $title',
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
      ),
    );
  }
}

String _categoryExpenseTitle(ExpenseCategoryDefinition category) {
  final label = category.label.trim();
  if (label.toLowerCase().endsWith('expense') ||
      label.toLowerCase().endsWith('expenses')) {
    return label;
  }
  return '$label Expense';
}
