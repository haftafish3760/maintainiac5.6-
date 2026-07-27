part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryManualFlowEditors
    on _ExpenseReceiptEntryScreenState {
  Future<void> _showManualReceiptCategoryScope(BuildContext context) async {
    final applyToAll = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Optional categories',
                style: TextStyle(
                  color: Color(0xFFF2F7F8),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose one category for the whole receipt, or choose categories independently on each item.',
                style: TextStyle(
                  color: Color(0xFFB7C8CE),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.format_list_bulleted_rounded),
                title: const Text('Category per item'),
                subtitle: const Text(
                  'Best for mixed receipts. Leave any item uncategorized if needed.',
                ),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.sell_outlined),
                title: const Text('One category for this receipt'),
                subtitle: const Text(
                  'Apply one optional category to every item.',
                ),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || applyToAll == null) return;
    if (!applyToAll) {
      _selectReceiptCategoryScope(false);
      return;
    }
    final category = await _pickManualReceiptCategory(context);
    if (!context.mounted || category == null) return;
    _selectReceiptCategory(category);
    _selectReceiptCategoryScope(true);
  }

  Future<String?> _pickManualReceiptCategory(BuildContext context) {
    final categories = _availableExpenseCategoryNames(context).toList()..sort();
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text('Choose receipt category'),
              subtitle: Text('Categories are optional.'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('No category'),
              onTap: () => Navigator.of(sheetContext).pop('Uncategorized'),
            ),
            for (final category in categories)
              ListTile(
                title: Text(category),
                trailing: category == _receiptCategory
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(category),
              ),
          ],
        ),
      ),
    );
  }
}
