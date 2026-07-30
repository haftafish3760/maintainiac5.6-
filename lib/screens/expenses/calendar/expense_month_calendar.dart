part of 'expense_calendar.dart';

/// Expense screen host for the shared Maintainiac Calendar tile layout.
/// Expense records remain source-owned and the shared Calendar opens their
/// owner detail flow instead of creating a second expense record editor.
class ExpenseMonthCalendar extends StatelessWidget {
  const ExpenseMonthCalendar({super.key});

  @override
  Widget build(BuildContext context) => const ExpenseAppCalendar();
}
