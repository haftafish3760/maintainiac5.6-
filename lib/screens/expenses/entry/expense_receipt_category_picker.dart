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
        final otherCategories = _availableExpenseCategoryNames(context)
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
