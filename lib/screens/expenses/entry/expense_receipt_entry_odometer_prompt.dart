part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOdometerPrompt
    on _ExpenseReceiptEntryScreenState {
  Future<void> _promptForOdometerIfNeeded() async {
    if (_odometerPromptEvaluated || _isEditingReceipt || !mounted) return;
    _odometerPromptEvaluated = true;
    final category = widget.initialCategory?.trim() ?? '';
    if (category.isEmpty) return;
    final settings = ExpenseSettingsScope.of(context);
    if (!settings.shouldPromptForOdometer(category)) return;

    final controller = TextEditingController(
      text: GlobalOdometerScope.of(context).reading.toString(),
    );
    var suppressForCategory = false;
    final reading = await showDialog<int?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add an odometer reading?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Optional for $category. You can skip this expense.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Odometer reading',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: suppressForCategory,
                title: Text("Don't ask again for $category"),
                onChanged: (value) =>
                    setDialogState(() => suppressForCategory = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(
                  controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                Navigator.of(
                  context,
                ).pop(value == null || value < 1 ? null : value);
              },
              child: const Text('Add reading'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (suppressForCategory) {
      await settings.setOdometerPromptSuppressed(category, true);
    }
    if (reading == null) return;
    _setReceiptEntryState(() => _expenseOdometerReading = reading);
    await _saveDraftNow();
  }

  Future<void> _editExpenseOdometerReading() async {
    final controller = TextEditingController(
      text: (_expenseOdometerReading ?? GlobalOdometerScope.of(context).reading)
          .toString(),
    );
    final reading = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odometer reading'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Optional vehicle odometer',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(-1),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(
                controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
              );
              Navigator.of(
                context,
              ).pop(value == null || value < 1 ? null : value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || reading == null) return;
    _setReceiptEntryState(
      () => _expenseOdometerReading = reading < 0 ? null : reading,
    );
    await _saveDraftNow();
  }
}
