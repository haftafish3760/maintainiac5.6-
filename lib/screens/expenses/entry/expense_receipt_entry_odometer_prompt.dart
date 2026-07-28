part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryOdometerPrompt
    on _ExpenseReceiptEntryScreenState {
  Future<void> _editExpenseOdometerReading() async {
    final reading = await openOdometerEntryResult(
      context,
      title: 'Add Odometer To Expense',
      saveLabel: 'Use For Expense',
    );
    if (!mounted || reading == null) return;
    _setReceiptEntryState(() => _expenseOdometerReading = reading);
    await _saveDraftNow();
  }
}
