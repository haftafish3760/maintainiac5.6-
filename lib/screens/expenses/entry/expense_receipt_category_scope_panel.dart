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

  @override
  void initState() {
    super.initState();
    _pendingCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
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
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a category',
                    style: TextStyle(
                      color: _receiptReferenceText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional. This choice will apply to the whole receipt.',
                    style: TextStyle(
                      color: _receiptReferenceMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  _CategoryBrowserTile(
                    category: 'Uncategorized',
                    selectedCategory: _pendingCategory,
                    onTap: () =>
                        setState(() => _pendingCategory = 'Uncategorized'),
                  ),
                  if (homeCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _CategoryBrowserSectionTitle('Common categories'),
                    const SizedBox(height: 6),
                    for (final category in homeCategories)
                      _CategoryBrowserTile(
                        category: category,
                        selectedCategory: _pendingCategory,
                        onTap: () =>
                            setState(() => _pendingCategory = category),
                      ),
                  ],
                  const SizedBox(height: 12),
                  const _CategoryBrowserSectionTitle('All categories'),
                  const SizedBox(height: 6),
                  for (final category in otherCategories)
                    _CategoryBrowserTile(
                      category: category,
                      selectedCategory: _pendingCategory,
                      onTap: () => setState(() => _pendingCategory = category),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: _receiptReferenceBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
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
                      onPressed: () {
                        widget.onCategorySelected(_pendingCategory);
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF297A2D),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
