part of 'expense_ledger_models.dart';

class ExpenseLedgerSummary {
  const ExpenseLedgerSummary({
    required this.total,
    required this.business,
    required this.personal,
    required this.recordCount,
  });

  final double total;
  final double business;
  final double personal;
  final int recordCount;
}

class ExpenseDateRange {
  const ExpenseDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

double? _clampedPercent(double? value) {
  if (value == null) return null;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}
