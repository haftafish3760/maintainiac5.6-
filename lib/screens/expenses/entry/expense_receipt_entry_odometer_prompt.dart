part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOdometerPrompt
    on _ExpenseReceiptEntryScreenState {
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
