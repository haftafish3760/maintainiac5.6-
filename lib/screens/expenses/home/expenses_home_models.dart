part of 'expenses_home_screen.dart';

class _MoneyStatData {
  const _MoneyStatData(
    this.label,
    this.value,
    this.color, {
    this.scope,
    this.range,
    this.detail,
  });

  final String label;
  final String value;
  final Color color;
  final String? scope;
  final ExpenseDateRange? range;
  final String? detail;
}

ExpenseDateRange _weekRange(DateTime day) {
  final start = DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - DateTime.monday),
  );
  return ExpenseDateRange(
    start: start,
    end: start.add(const Duration(days: 6)),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

String _longDate(DateTime date) =>
    '${_monthName(date.month)} ${date.day}, ${date.year}';

String _monthName(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _LedgerEntryData {
  const _LedgerEntryData({
    required this.receiptId,
    required this.day,
    required this.date,
    required this.store,
    required this.scope,
    required this.category,
    required this.amount,
    required this.status,
    required this.color,
  });

  factory _LedgerEntryData.fromReceipt(ExpenseReceiptRecord receipt) {
    final firstLine = receipt.lines.isEmpty ? null : receipt.lines.first;
    final category = firstLine?.category ?? 'Uncategorized';
    return _LedgerEntryData(
      receiptId: receipt.id,
      day: _weekdayLabel(receipt.receiptDate),
      date: '${receipt.receiptDate.month}/${receipt.receiptDate.day}',
      store: receipt.title,
      scope: firstLine?.use.label ?? 'Business',
      category: category,
      amount: _money(receipt.total),
      status: 'Saved',
      color: _colorForExpenseCategory(category),
    );
  }

  final String receiptId;
  final String day;
  final String date;
  final String store;
  final String scope;
  final String category;
  final String amount;
  final String status;
  final Color color;
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

bool _sameExpenseCategory(String left, String right) {
  if (left == right) {
    return true;
  }
  return _normalizedExpenseCategory(left) == _normalizedExpenseCategory(right);
}

bool _receiptHasScope(ExpenseReceiptRecord receipt, String scope) {
  return receipt.lines.any((line) {
    return switch (scope) {
      'Business' =>
        line.use == ExpenseLineUse.business || line.use == ExpenseLineUse.split,
      'Personal' =>
        line.use == ExpenseLineUse.personal || line.use == ExpenseLineUse.split,
      _ => line.use.label == scope,
    };
  });
}

String _normalizedExpenseCategory(String category) {
  final value = category.trim().toLowerCase();
  return switch (value) {
    'repairs' => 'repair',
    'material' || 'materials' || 'supplies' => 'materials',
    _ => value,
  };
}

String _weekdayLabel(DateTime date) {
  return const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][date.weekday -
      1];
}

Color _colorForExpenseCategory(String category) {
  return switch (category) {
    'Fuel' => _red,
    'Parking' || 'Tolls' => _green,
    'Materials' || 'Tools' || 'Supplies' || 'Office Supplies' => _blue,
    _ => _gold,
  };
}
