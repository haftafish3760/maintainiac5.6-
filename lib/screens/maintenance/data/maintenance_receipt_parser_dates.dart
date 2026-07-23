part of 'maintenance_receipt_parser.dart';

final _nextDueDateSignal = RegExp(
  r'\b(?:next (?:service )?due|next service date|next oil change|service due date|due date)\b',
);

_ReceiptDateRead _nextDueDate(List<_SourceRow> rows, String locale) {
  for (final row in rows) {
    if (!_nextDueDateSignal.hasMatch(row.comparisonText)) continue;
    final read = _receiptDate([row], locale, null, skipNextDueRows: false);
    if (read.date != null || read.ambiguousNumeric || read.unsupportedLocale) {
      return read;
    }
  }
  return const _ReceiptDateRead(null);
}

int? _wholeMonthInterval(DateTime? serviceDate, DateTime? dueDate) {
  if (serviceDate == null || dueDate == null || !dueDate.isAfter(serviceDate)) {
    return null;
  }
  final months =
      (dueDate.year - serviceDate.year) * 12 +
      dueDate.month -
      serviceDate.month;
  if (months < 1 || months > 36) return null;
  final expectedDay = serviceDate.day.clamp(
    1,
    _daysInMonth(dueDate.year, dueDate.month),
  );
  return dueDate.day == expectedDay ? months : null;
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
