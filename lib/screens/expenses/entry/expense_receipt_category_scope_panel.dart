part of 'expense_receipt_entry_screen.dart';

/// Category selection for the first receipt screen.  This intentionally does
/// not ask about per-line rules: choosing a category here means it applies to
/// the whole receipt; leaving it blank keeps category optional later.
class _ReceiptWholeCategoryPicker extends StatefulWidget {
  const _ReceiptWholeCategoryPicker({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  State<_ReceiptWholeCategoryPicker> createState() =>
      _ReceiptWholeCategoryPickerState();
}

class _ReceiptWholeCategoryPickerState
    extends State<_ReceiptWholeCategoryPicker> {
  late String _pendingCategory;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _pendingCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final homeCategories = _homeCategoryNames(context);
    final normalizedQuery = _query.trim().toLowerCase();
    bool matchesQuery(String category) {
      if (normalizedQuery.isEmpty) return true;
      return category.toLowerCase().contains(normalizedQuery) ||
          _categoryDisplayName(
            category,
          ).toLowerCase().contains(normalizedQuery);
    }

    final visibleHomeCategories = homeCategories
        .where(matchesQuery)
        .toList(growable: false);
    final visibleOtherCategories = _availableExpenseCategoryNames(context)
        .where(
          (category) =>
              category != 'Uncategorized' &&
              !homeCategories.any((home) => _sameCategory(home, category)) &&
              matchesQuery(category),
        )
        .toList(growable: false);
    final showNoCategory =
        normalizedQuery.isEmpty ||
        'no category'.contains(normalizedQuery) ||
        'uncategorized'.contains(normalizedQuery);
    final hasMatches =
        showNoCategory ||
        visibleHomeCategories.isNotEmpty ||
        visibleOtherCategories.isNotEmpty;
    return Scaffold(
      backgroundColor: _receiptReferencePage,
      body: SafeArea(
        child: Column(
          children: [
            const _ReceiptCategoryPickerHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: const Text(
                'Select one category for this receipt, or choose No Category to decide later. You can review or change it before saving.',
                style: TextStyle(
                  color: _receiptReferenceMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: _ReceiptSetupSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        style: const TextStyle(
                          color: _receiptReferenceText,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search categories',
                          hintStyle: const TextStyle(
                            color: _receiptReferenceMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _receiptReferenceMuted,
                          ),
                          filled: true,
                          fillColor: _receiptSetupChoiceSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _receiptReferenceBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _receiptReferenceBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _receiptReferenceBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.zero,
                          children: [
                            if (showNoCategory)
                              _CategoryBrowserTile(
                                category: 'Uncategorized',
                                selectedCategory: _pendingCategory,
                                onTap: () => setState(
                                  () => _pendingCategory = 'Uncategorized',
                                ),
                              ),
                            if (visibleHomeCategories.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const _CategoryBrowserSectionTitle(
                                'Common categories',
                              ),
                              const SizedBox(height: 6),
                              for (final category in visibleHomeCategories)
                                _CategoryBrowserTile(
                                  category: category,
                                  selectedCategory: _pendingCategory,
                                  onTap: () => setState(
                                    () => _pendingCategory = category,
                                  ),
                                ),
                            ],
                            if (visibleOtherCategories.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const _CategoryBrowserSectionTitle(
                                'All categories',
                              ),
                              const SizedBox(height: 6),
                              for (final category in visibleOtherCategories)
                                _CategoryBrowserTile(
                                  category: category,
                                  selectedCategory: _pendingCategory,
                                  onTap: () => setState(
                                    () => _pendingCategory = category,
                                  ),
                                ),
                            ],
                            if (!hasMatches)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No matching categories. Try a different search.',
                                  style: TextStyle(
                                    color: _receiptReferenceMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: _ReceiptSetupSection(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onCategorySelected(_pendingCategory);
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _receiptReferenceGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCategoryPickerHeader extends StatelessWidget {
  const _ReceiptCategoryPickerHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: _receiptReferenceText,
            iconSize: 30,
          ),
          const Expanded(
            child: Text(
              'Select a category',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _receiptReferenceText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
