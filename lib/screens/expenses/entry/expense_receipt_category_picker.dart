part of 'expense_receipt_entry_screen.dart';

class _ExpenseCategorySearch extends StatelessWidget {
  const _ExpenseCategorySearch({
    required this.selectedCategory,
    required this.controller,
    required this.matches,
    required this.onSelected,
    this.compact = false,
  });

  final String selectedCategory;
  final TextEditingController controller;
  final List<String> matches;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCategoryBrowser(context),
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            decoration: BoxDecoration(
              color: const Color(0xFF101315),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF40484D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sell_outlined, color: Color(0xFFB7BEC4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CATEGORY (OPTIONAL)',
                        style: TextStyle(
                          color: Color(0xFFB7BEC4),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedCategory == 'Uncategorized'
                            ? 'Choose a category'
                            : selectedCategory,
                        style: const TextStyle(
                          color: Color(0xFFF5F7F8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB7BEC4),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
                ? 'Category (optional)'
                : 'Category (optional): $selectedCategory',
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
              hintText: 'Search categories',
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
            label: const Text('Choose category'),
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
      backgroundColor: const Color(0xFF101315),
      showDragHandle: true,
      builder: (context) {
        var pendingCategory = selectedCategory;
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
            return StatefulBuilder(
              builder: (context, setSheetState) => SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: [
                          _CategoryBrowserHeader(
                            selectedCategory: pendingCategory,
                          ),
                          const SizedBox(height: 10),
                          _CategoryBrowserTile(
                            category: 'Uncategorized',
                            selectedCategory: pendingCategory,
                            onTap: () => setSheetState(
                              () => pendingCategory = 'Uncategorized',
                            ),
                          ),
                          if (homeCategories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const _CategoryBrowserSectionTitle(
                              'Home Categories',
                            ),
                            const SizedBox(height: 6),
                            for (final category in homeCategories)
                              _CategoryBrowserTile(
                                category: category,
                                selectedCategory: pendingCategory,
                                onTap: () => setSheetState(
                                  () => pendingCategory = category,
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          const _CategoryBrowserSectionTitle(
                            'Other Categories',
                          ),
                          const SizedBox(height: 6),
                          for (final category in otherCategories)
                            _CategoryBrowserTile(
                              category: category,
                              selectedCategory: pendingCategory,
                              onTap: () => setSheetState(
                                () => pendingCategory = category,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF40484D)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(pendingCategory),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF297A2D),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
