part of 'expense_receipt_entry_screen.dart';

class _ExpenseCategorySearch extends StatelessWidget {
  const _ExpenseCategorySearch({
    required this.selectedCategory,
    required this.controller,
    required this.matches,
    required this.onSelected,
  });

  final String selectedCategory;
  final TextEditingController controller;
  final List<String> matches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF56666E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selectedCategory == 'Uncategorized'
                ? 'Expense Category: No category selected'
                : 'Expense Category: $selectedCategory',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search expense categories',
              hintStyle: const TextStyle(
                color: Color(0xFF9FAAAF),
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFFFFD166),
              ),
              filled: true,
              fillColor: const Color(0xFF0B1113),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFF56666E)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFF56666E)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFFFD166)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openCategoryBrowser(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            label: const Text('Browse All Categories'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE8ECEE),
              minimumSize: const Size.fromHeight(42),
              side: const BorderSide(color: Color(0xFFFFD166)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in matches)
                _CategoryChoiceChip(
                  label: _categoryDisplayName(category),
                  selected: category == selectedCategory,
                  onTap: () => onSelected(category),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCategoryBrowser(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) {
        final homeCategories = _homeCategoryNames(context);
        final otherCategories = _expenseCategoryNames
            .where(
              (category) =>
                  category != 'Uncategorized' &&
                  !homeCategories.any((home) => _sameCategory(home, category)),
            )
            .toList(growable: false);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .42,
          maxChildSize: .92,
          builder: (context, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  _CategoryBrowserHeader(selectedCategory: selectedCategory),
                  const SizedBox(height: 10),
                  _CategoryBrowserTile(
                    category: 'Uncategorized',
                    selectedCategory: selectedCategory,
                    onTap: () => Navigator.of(context).pop('Uncategorized'),
                  ),
                  if (homeCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _CategoryBrowserSectionTitle('Home Categories'),
                    const SizedBox(height: 6),
                    for (final category in homeCategories)
                      _CategoryBrowserTile(
                        category: category,
                        selectedCategory: selectedCategory,
                        onTap: () => Navigator.of(context).pop(category),
                      ),
                  ],
                  const SizedBox(height: 12),
                  const _CategoryBrowserSectionTitle('Other Categories'),
                  const SizedBox(height: 6),
                  for (final category in otherCategories)
                    _CategoryBrowserTile(
                      category: category,
                      selectedCategory: selectedCategory,
                      onTap: () => Navigator.of(context).pop(category),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;
    onSelected(selected);
  }
}

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
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        tileColor: selected ? const Color(0xFFFFD166) : const Color(0xFF101719),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: selected ? const Color(0xFFFFD166) : const Color(0xFF445159),
          ),
        ),
        title: Text(
          _categoryDisplayName(category),
          style: TextStyle(
            color: selected ? const Color(0xFF101416) : const Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        subtitle: category == 'Uncategorized'
            ? const Text(
                'Skip category for this receipt line.',
                style: TextStyle(
                  color: Color(0xFF9FAAAF),
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        trailing: selected
            ? const Icon(Icons.check_rounded, color: Color(0xFF101416))
            : null,
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
    return Material(
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
