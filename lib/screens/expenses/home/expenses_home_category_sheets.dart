part of 'expenses_home_screen.dart';

class _ExpenseFab extends StatelessWidget {
  const _ExpenseFab({required this.initialDate});

  final DateTime initialDate;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      onPressed: () => _openReceipt(context, initialDate: initialDate),
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Expense',
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
      ),
    );
  }
}

class _OtherCategoriesSheet extends StatelessWidget {
  const _OtherCategoriesSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final categories = [...defaultExpenseCategories, ...otherExpenseCategories];
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        const _SheetTitleRow(
          title: 'Other Categories',
          detail: 'Tap any category to review matching expense entries.',
        ),
        const SizedBox(height: 10),
        _SolidSection(
          backgroundColor: _paper,
          borderColor: const Color(0xFF3E4A50),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PickerTitle('All Expense Categories'),
              const SizedBox(height: 8),
              _PickerGrid(categories: categories),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetTitleRow extends StatelessWidget {
  const _SheetTitleRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return _SolidSection(
      backgroundColor: _ink,
      borderColor: _line,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: _SectionHeader(
              eyebrow: 'ADD EXPENSE',
              title: title,
              detail: detail,
            ),
          ),
          _SmallTextButton(
            label: 'Edit Home',
            icon: Icons.edit_rounded,
            onTap: () {
              Navigator.of(context).pop();
              _showQuickActionSettings(context);
            },
          ),
        ],
      ),
    );
  }
}
