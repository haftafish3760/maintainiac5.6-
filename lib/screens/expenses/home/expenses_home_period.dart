part of 'expenses_home_screen.dart';

enum _ExpenseViewPeriod {
  day('Daily', 'DAILY', 'Daily expenses', 'Daily total'),
  week('Weekly', 'WEEKLY', 'Weekly expenses', 'Weekly total'),
  month('Monthly', 'MONTHLY', 'Monthly expenses', 'Monthly total'),
  yearToDate('YTD', 'YEAR TO DATE', 'Year-to-date expenses', 'YTD total');

  const _ExpenseViewPeriod(
    this.buttonLabel,
    this.eyebrow,
    this.title,
    this.totalCaption,
  );

  final String buttonLabel;
  final String eyebrow;
  final String title;
  final String totalCaption;

  String get statPrefix => this == yearToDate ? 'YTD' : buttonLabel;

  ExpenseDateRange rangeFor(DateTime date) {
    final today = _dateOnly(date);
    return switch (this) {
      _ExpenseViewPeriod.day => ExpenseDateRange(start: today, end: today),
      _ExpenseViewPeriod.week => _weekRange(today),
      _ExpenseViewPeriod.month => ExpenseDateRange(
        start: DateTime(today.year, today.month),
        end: DateTime(today.year, today.month + 1, 0),
      ),
      _ExpenseViewPeriod.yearToDate => ExpenseDateRange(
        start: DateTime(today.year),
        end: today.year == DateTime.now().year
            ? _dateOnly(DateTime.now())
            : DateTime(today.year, 12, 31),
      ),
    };
  }

  String rangeLabel(DateTime date) {
    final range = rangeFor(date);
    return switch (this) {
      _ExpenseViewPeriod.day => _longDate(range.start),
      _ExpenseViewPeriod.week =>
        '${_shortDate(range.start)} - ${_shortDate(range.end)}',
      _ExpenseViewPeriod.month =>
        '${_monthName(range.start.month)} ${range.start.year}',
      _ExpenseViewPeriod.yearToDate => range.start.year.toString(),
    };
  }
}
