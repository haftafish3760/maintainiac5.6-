import 'work_supply_models.dart';

class WorkSupplyInventoryRecap {
  const WorkSupplyInventoryRecap({
    required this.label,
    required this.records,
    required this.totalSpent,
    required this.receiptCount,
    required this.itemCount,
    required this.start,
    required this.end,
  });

  final String label;
  final List<WorkSupplyInventoryRecord> records;
  final double totalSpent;
  final int receiptCount;
  final int itemCount;
  final DateTime start;
  final DateTime end;
}

List<WorkSupplyInventoryRecap> buildWorkSupplyInventoryRecaps({
  required List<WorkSupplyInventoryRecord> records,
  required DateTime today,
}) {
  final day = _dayKey(today);
  final monthStart = DateTime.utc(day.year, day.month);
  final nextMonth = day.month == 12
      ? DateTime.utc(day.year + 1)
      : DateTime.utc(day.year, day.month + 1);
  final monthEnd = nextMonth.subtract(const Duration(days: 1));
  return [
    _recap('Past 7 Days', records, day.subtract(const Duration(days: 6)), day),
    _recap(
      'Past 30 Days',
      records,
      day.subtract(const Duration(days: 29)),
      day,
    ),
    _recap(
      'Past 90 Days',
      records,
      day.subtract(const Duration(days: 89)),
      day,
    ),
    _recap('This Month', records, monthStart, monthEnd),
    _recap('Year To Date', records, DateTime.utc(day.year), day),
  ];
}

WorkSupplyInventoryRecap buildWorkSupplyMonthRecap({
  required List<WorkSupplyInventoryRecord> records,
  required DateTime month,
}) {
  final start = DateTime.utc(month.year, month.month);
  final next = month.month == 12
      ? DateTime.utc(month.year + 1)
      : DateTime.utc(month.year, month.month + 1);
  final end = next.subtract(const Duration(days: 1));
  return _recap('Month Total', records, start, end);
}

WorkSupplyInventoryRecap buildWorkSupplyDayRecap({
  required List<WorkSupplyInventoryRecord> records,
  required DateTime day,
}) {
  final key = _dayKey(day);
  return _recap('Selected Day', records, key, key);
}

WorkSupplyInventoryRecap _recap(
  String label,
  List<WorkSupplyInventoryRecord> records,
  DateTime start,
  DateTime end,
) {
  final filtered = [
    for (final record in records)
      if (_isWithin(record.loggedAt, start, end)) record,
  ];
  return WorkSupplyInventoryRecap(
    label: label,
    records: filtered,
    totalSpent: filtered.fold<double>(
      0,
      (sum, record) => sum + record.lineTotal,
    ),
    receiptCount: filtered.where((record) => record.receiptLinked).length,
    itemCount: filtered.length,
    start: start,
    end: end,
  );
}

bool _isWithin(DateTime? value, DateTime start, DateTime end) {
  if (value == null) return false;
  final day = _dayKey(value);
  return !day.isBefore(start) && !day.isAfter(end);
}

DateTime _dayKey(DateTime day) => DateTime.utc(day.year, day.month, day.day);
