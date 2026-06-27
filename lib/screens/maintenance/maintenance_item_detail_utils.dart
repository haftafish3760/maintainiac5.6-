part of 'maintenance_item_detail_screen.dart';

DateTime _addMonths(DateTime date, int months) {
  return DateTime(date.year, date.month + months, date.day);
}

int _monthsBetween(DateTime start, DateTime end) {
  final months = (end.year - start.year) * 12 + end.month - start.month;
  return end.day < start.day
      ? (months - 1).clamp(0, 999)
      : months.clamp(0, 999);
}

String _formatNumber(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
