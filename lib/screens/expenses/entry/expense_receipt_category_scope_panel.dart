part of 'expense_receipt_entry_screen.dart';

class _ReceiptCategoryScopePanel extends StatefulWidget {
  const _ReceiptCategoryScopePanel({
    required this.categoryAppliesToAll,
    required this.selectedCategory,
    required this.onScopeSelected,
    required this.onCategorySelected,
  });

  final bool categoryAppliesToAll;
  final String selectedCategory;
  final ValueChanged<bool> onScopeSelected;
  final ValueChanged<String> onCategorySelected;

  @override
  State<_ReceiptCategoryScopePanel> createState() =>
      _ReceiptCategoryScopePanelState();
}

class _ReceiptCategoryScopePanelState
    extends State<_ReceiptCategoryScopePanel> {
  late final TextEditingController _categorySearchController;

  @override
  void initState() {
    super.initState();
    _categorySearchController = TextEditingController(
      text: widget.selectedCategory == 'Uncategorized'
          ? ''
          : widget.selectedCategory,
    )..addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _ReceiptCategoryScopePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory == widget.selectedCategory) return;
    final category = widget.selectedCategory == 'Uncategorized'
        ? ''
        : widget.selectedCategory;
    if (_categorySearchController.text != category) {
      _categorySearchController.text = category;
    }
  }

  @override
  void dispose() {
    _categorySearchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final query = _categorySearchController.text.trim().toLowerCase();
    final matches = _availableExpenseCategoryNames(context)
        .where(
          (category) => query.isEmpty || category.toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
    return ReceiptFormPanel(
      title: 'Receipt Category Setup',
      subtitle:
          'Does one category apply to the whole receipt? Categories stay optional either way.',
      icon: Icons.account_tree_rounded,
      accentColor: const Color(0xFF34A9E8),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReceiptCategoryScopeButton(
              selected: widget.categoryAppliesToAll,
              label: 'One Category',
              helper: 'Apply one optional category to every line.',
              icon: Icons.playlist_add_check_rounded,
              onPressed: () => widget.onScopeSelected(true),
            ),
            const SizedBox(height: 8),
            _ReceiptCategoryScopeButton(
              selected: !widget.categoryAppliesToAll,
              label: 'Category Per Line',
              helper: 'Choose an optional category as each line is entered.',
              icon: Icons.format_list_bulleted_rounded,
              onPressed: () => widget.onScopeSelected(false),
            ),
          ],
        ),
        if (widget.categoryAppliesToAll) ...[
          const SizedBox(height: 10),
          _ExpenseCategorySearch(
            selectedCategory: widget.selectedCategory,
            controller: _categorySearchController,
            matches: matches,
            onSelected: (category) {
              _categorySearchController.text = category == 'Uncategorized'
                  ? ''
                  : category;
              widget.onCategorySelected(category);
            },
          ),
        ],
      ],
    );
  }
}

class _ReceiptCategoryScopeButton extends StatelessWidget {
  const _ReceiptCategoryScopeButton({
    required this.selected,
    required this.label,
    required this.helper,
    required this.icon,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final String helper;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF34A9E8) : const Color(0xFF11181B);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE8ECEE),
        backgroundColor: color,
        padding: const EdgeInsets.all(10),
        side: BorderSide(
          color: selected ? const Color(0xFFFFD166) : const Color(0xFF56666E),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(helper, style: const TextStyle(fontSize: 11, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
