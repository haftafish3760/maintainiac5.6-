part of 'work_supply_add_items_screen.dart';

class _NonInventoryInlineForm extends StatelessWidget {
  const _NonInventoryInlineForm({
    required this.description,
    required this.expenseCategory,
    required this.onExpenseCategory,
    required this.onChanged,
  });

  final TextEditingController description;
  final String expenseCategory;
  final ValueChanged<String> onExpenseCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = _allExpenseCategories;
    final value =
        categories.any((category) => category.category == expenseCategory)
        ? expenseCategory
        : categories.first.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropdownField<String>(
          label: 'Expense category',
          value: value,
          items: [for (final category in categories) category.category],
          itemLabel: (category) => category,
          onChanged: onExpenseCategory,
        ),
        _Field(
          controller: description,
          label: 'Description (optional)',
          hint: 'Leave blank to save this line as business or personal only',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
