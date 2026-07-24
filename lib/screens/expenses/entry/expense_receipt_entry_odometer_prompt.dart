part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOdometerPrompt
    on _ExpenseReceiptEntryScreenState {
  Future<void> _promptForOdometerIfNeeded() async {
    if (_odometerPromptEvaluated ||
        _isEditingReceipt ||
        _expenseOdometerReading != null ||
        !mounted) {
      return;
    }
    _odometerPromptEvaluated = true;
    final category = widget.initialCategory?.trim() ?? '';

    final controller = TextEditingController(
      text: GlobalOdometerScope.of(context).reading.toString(),
    );
    String? validationMessage;
    final reading = await showDialog<int?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Expense Odometer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.isEmpty
                    ? 'Enter the vehicle odometer shown when this expense happened.'
                    : 'Enter the vehicle odometer shown for this $category expense.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Odometer reading',
                  errorText: validationMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Add Later'),
            ),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim();
                final value = int.tryParse(raw);
                if (value == null || value < 0) {
                  setDialogState(
                    () =>
                        validationMessage = 'Enter the whole odometer number.',
                  );
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (reading == null) return;
    _setReceiptEntryState(() => _expenseOdometerReading = reading);
    await _saveDraftNow();
  }

  Future<void> _editExpenseOdometerReading() async {
    final controller = TextEditingController(
      text: (_expenseOdometerReading ?? GlobalOdometerScope.of(context).reading)
          .toString(),
    );
    String? validationMessage;
    final reading = await showDialog<int?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Expense Odometer'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Odometer reading',
                errorText: validationMessage,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null || value < 0) {
                    setDialogState(
                      () => validationMessage =
                          'Enter the whole odometer number.',
                    );
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (!mounted || reading == null) return;
    _setReceiptEntryState(() => _expenseOdometerReading = reading);
    await _saveDraftNow();
  }
}
