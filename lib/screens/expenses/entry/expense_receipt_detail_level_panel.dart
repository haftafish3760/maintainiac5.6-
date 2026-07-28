part of 'expense_receipt_entry_screen.dart';

class _ReceiptDetailLevelPanel extends StatefulWidget {
  const _ReceiptDetailLevelPanel({
    required this.selectedMode,
    required this.onSelected,
  });

  final _ReceiptDetailEntryMode selectedMode;
  final ValueChanged<_ReceiptDetailEntryMode> onSelected;

  @override
  State<_ReceiptDetailLevelPanel> createState() =>
      _ReceiptDetailLevelPanelState();
}

class _ReceiptDetailLevelPanelState extends State<_ReceiptDetailLevelPanel> {
  var _showChoices = false;

  @override
  Widget build(BuildContext context) {
    final currentStyle = widget.selectedMode.settingsStyle;
    return ReceiptFormPanel(
      title: 'Receipt Detail',
      subtitle:
          'This receipt uses ${currentStyle.label}. Your default stays in Receipt Settings.',
      icon: Icons.tune_rounded,
      accentColor: const Color(0xFF34A9E8),
      children: [
        _ReceiptDetailLevelCurrentChoice(
          style: currentStyle,
          showingChoices: _showChoices,
          onChangePressed: () => setState(() => _showChoices = !_showChoices),
        ),
        if (_showChoices) ...[
          const SizedBox(height: 8),
          const Text(
            'Change this receipt only',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          for (final mode in _ReceiptDetailEntryMode.values) ...[
            _ReceiptDetailLevelChoice(
              mode: mode,
              selected: mode == widget.selectedMode,
              onTap: () {
                widget.onSelected(mode);
                setState(() => _showChoices = false);
              },
            ),
            if (mode != _ReceiptDetailEntryMode.values.last)
              const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _ReceiptDetailLevelCurrentChoice extends StatelessWidget {
  const _ReceiptDetailLevelCurrentChoice({
    required this.style,
    required this.showingChoices,
    required this.onChangePressed,
  });

  final ExpenseReceiptReviewStyle style;
  final bool showingChoices;
  final VoidCallback onChangePressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF56666E)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFFFFD166)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.label,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.description,
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onChangePressed,
              icon: Icon(
                showingChoices
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.tune_rounded,
                size: 17,
              ),
              label: Text(showingChoices ? 'Close' : 'Change'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8FC9FF),
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDetailLevelChoice extends StatelessWidget {
  const _ReceiptDetailLevelChoice({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _ReceiptDetailEntryMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = mode.settingsStyle;
    final border = selected ? const Color(0xFFFFD166) : const Color(0xFF56666E);
    return Material(
      color: selected ? const Color(0xFF302916) : const Color(0xFF11181B),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFFD166)
                    : const Color(0xFFC8D0D3),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      style.description,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptSummaryUsePanel extends StatefulWidget {
  const _ReceiptSummaryUsePanel({
    required this.detailMode,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onUseSelected,
  });

  final _ReceiptDetailEntryMode detailMode;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<_ExpenseLineUse> onUseSelected;

  @override
  State<_ReceiptSummaryUsePanel> createState() =>
      _ReceiptSummaryUsePanelState();
}

class _ReceiptSummaryUsePanelState extends State<_ReceiptSummaryUsePanel> {
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
  void dispose() {
    _categorySearchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const showOptionalCategory = true;
    final query = _categorySearchController.text.trim().toLowerCase();
    final matches = _availableExpenseCategoryNames(context)
        .where(
          (category) => query.isEmpty || category.toLowerCase().contains(query),
        )
        .take(8)
        .toList(growable: false);
    return ReceiptFormPanel(
      title: 'How Should This Receipt Count?',
      subtitle:
          'Optionally choose one category for the entire receipt, then mark the final amount Business, Personal, or Split.',
      icon: Icons.rule_folder_rounded,
      accentColor: const Color(0xFFFFD166),
      children: [
        if (showOptionalCategory) ...[
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
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReceiptSummaryUseButton(
              label: 'Business',
              icon: Icons.business_center_rounded,
              color: const Color(0xFF2E78B7),
              onPressed: () => widget.onUseSelected(_ExpenseLineUse.business),
            ),
            _ReceiptSummaryUseButton(
              label: 'Personal',
              icon: Icons.person_rounded,
              color: const Color(0xFF59636A),
              onPressed: () => widget.onUseSelected(_ExpenseLineUse.personal),
            ),
            _ReceiptSummaryUseButton(
              label: 'Split',
              icon: Icons.call_split_rounded,
              color: const Color(0xFF3B7C73),
              onPressed: () => widget.onUseSelected(_ExpenseLineUse.split),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptSummaryUseButton extends StatelessWidget {
  const _ReceiptSummaryUseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(132, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
