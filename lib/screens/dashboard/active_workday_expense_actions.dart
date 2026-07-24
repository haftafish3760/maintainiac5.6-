part of 'active_workday_screen.dart';

extension _ActiveWorkdayExpenseActions on _ActiveWorkdayScreenState {
  Future<void> _openExpenseAndRecord({
    required String title,
    required String saveLabel,
    required ActiveWorkdayEventType eventType,
    String? category,
  }) async {
    final promptedOdometer = await _recordOdometerReading(
      title: title,
      saveLabel: saveLabel,
    );
    if (!mounted || promptedOdometer == null) return;

    final saved = await Navigator.of(context).push<ExpenseReceiptRecord>(
      appNativeRoute<ExpenseReceiptRecord>(
        context,
        ExpenseReceiptEntryScreen(
          initialCategory: category,
          initialOdometerReading: promptedOdometer,
        ),
      ),
    );
    if (!mounted || saved == null) return;

    final recorded = await ActiveWorkdayScope.of(context).addEvent(
      type: eventType,
      odometerReading: saved.odometerReading ?? promptedOdometer,
      note: category == 'Fuel' ? 'Fuel expense saved' : 'Expense saved',
    );
    if (!mounted || recorded != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The expense saved, but it could not be added to today. Open the expense to try again.',
        ),
      ),
    );
  }
}
