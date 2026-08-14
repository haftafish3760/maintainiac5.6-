part of 'expense_receipt_entry_screen.dart';

class _CategoryBrowserHeader extends StatelessWidget {
  const _CategoryBrowserHeader({required this.selectedCategory});

  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Expense Category',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedCategory == 'Uncategorized'
                ? 'Choose No Category, one of your home categories, or browse the full list.'
                : 'Current category: $selectedCategory',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBrowserSectionTitle extends StatelessWidget {
  const _CategoryBrowserSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFFFD166),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _CategoryBrowserTile extends StatelessWidget {
  const _CategoryBrowserTile({
    required this.category,
    required this.selectedCategory,
    required this.onTap,
  });

  final String category;
  final String selectedCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = category == selectedCategory;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? _receiptReferenceBlue : _receiptSetupChoiceSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? _receiptReferenceBlue : _receiptReferenceBorder,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _categoryDisplayName(category),
                  style: TextStyle(
                    color: selected ? Colors.white : _receiptReferenceText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChoiceChip extends StatelessWidget {
  const _CategoryChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? const Color(0xFFFFD166) : const Color(0xFF1F2528),
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF101416)
                    : const Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _homeCategoryNames(BuildContext context) {
  final settings = ExpenseSettingsScope.of(context);
  final saved = settings.quickCategoryOrder;
  final home = saved.isEmpty
      ? defaultExpenseCategories.take(10).map((category) => category.category)
      : saved.take(10);
  return _uniqueCategoryNames(home);
}

List<String> _availableExpenseCategoryNames(BuildContext context) {
  final settings = ExpenseSettingsScope.of(context);
  return _uniqueCategoryNames([
    ..._expenseCategoryNames,
    ...settings.customCategoryNames,
  ]);
}

List<String> _uniqueCategoryNames(Iterable<String> categories) {
  final output = <String>[];
  for (final category in categories) {
    if (category.trim().isEmpty ||
        output.any((item) => _sameCategory(item, category))) {
      continue;
    }
    output.add(category);
  }
  return output;
}

String _categoryDisplayName(String category) {
  return category == 'Uncategorized' ? 'No Category' : category;
}

bool _sameCategory(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}
